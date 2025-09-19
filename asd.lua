-- 🌀 Wave UI Lib
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wave"))()
local Main = library:Main()

-------------------------------------------------
-- 📂 Tabs
-------------------------------------------------
local CombatTab = Main:Tab("Combat")
local VisualTab = Main:Tab("Visuals")
local MovementTab = Main:Tab("Movement")
local MiscTab = Main:Tab("Misc")

-------------------------------------------------
-- ⚔️ Combat Section
-------------------------------------------------
local Combat = CombatTab:Section("Combat")

Combat:Item("toggle", "Aimlock", function(v) _G.Aimlock = v end)
Combat:Item("slider", "Aim FOV", function(v) _G.FOVSize = v end, {min = 50, max = 500, default = 150})

Combat:Item("toggle", "TriggerBot", function(v) _G.TriggerBot = v end)
Combat:Item("toggle", "FastReload", function(v) _G.FastReload = v end)
Combat:Item("toggle", "AutoReload", function(v) _G.AutoReload = v end)
Combat:Item("toggle", "Godmode (Fake)", function(v) _G.Godmode = v end)

-------------------------------------------------
-- 👁 Visual Section
-------------------------------------------------
local Visual = VisualTab:Section("ESP / FOV")

Visual:Item("toggle", "ESP", function(v) _G.ESP = v end)
Visual:Item("toggle", "FOV Circle", function(v) _G.ShowFOV = v end)
Visual:Item("slider", "FOV Size", function(v) _G.FOVSize = v end, {min = 50, max = 500, default = 150})

-------------------------------------------------
-- 🏃 Movement Section
-------------------------------------------------
local Movement = MovementTab:Section("Movement")

Movement:Item("toggle", "SpeedHack", function(v) _G.SpeedHack = v end)
Movement:Item("slider", "Speed", function(v) _G.SpeedValue = v end, {min = 16, max = 200, default = 50})

Movement:Item("toggle", "HighJump", function(v) _G.HighJump = v end)
Movement:Item("slider", "JumpPower", function(v) _G.JumpValue = v end, {min = 50, max = 500, default = 100})

-------------------------------------------------
-- 🧠 Script Logic
-------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- 🟢 FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 1
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Radius = _G.FOVSize or 150

-- 🎯 Lấy target gần nhất
local function getClosestToCursor()
    local closest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, onscreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onscreen then
                local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mag < dist and mag <= (_G.FOVSize or 150) then
                    closest, dist = plr, mag
                end
            end
        end
    end
    return closest
end

-- 🔴 ESP Highlight
local function applyESP(player)
    if player.Character and not player.Character:FindFirstChild("ESP_Highlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "ESP_Highlight"
        hl.Parent = player.Character
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if _G.ESP then applyESP(plr) end
    end)
end)

-------------------------------------------------
-- 🔄 Main Loop
-------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- ESP
    if _G.ESP then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                applyESP(plr)
            end
        end
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("ESP_Highlight") then
                plr.Character:FindFirstChild("ESP_Highlight"):Destroy()
            end
        end
    end

    -- Speed + Jump
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        hum.WalkSpeed = _G.SpeedHack and (_G.SpeedValue or 50) or 16
        hum.JumpPower = _G.HighJump and (_G.JumpValue or 100) or 50
    end

    -- Aimlock
    if _G.Aimlock then
        local target = getClosestToCursor()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
        end
    end

    -- TriggerBot
    if _G.TriggerBot then
        local target = getClosestToCursor()
        if target then
            mouse1press()
            task.wait()
            mouse1release()
        end
    end

    -- FastReload
    if _G.FastReload and LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
                tool.Ammo.Value = tool.Ammo.MaxValue
            end
        end
    end

    -- AutoReload
    if _G.AutoReload and LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Ammo") and tool.Ammo.Value <= 0 then
                tool.Ammo.Value = tool.Ammo.MaxValue
            end
        end
    end

    -- Godmode
    if _G.Godmode and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MaxHealth
    end

    -- FOV Circle update
    fovCircle.Visible = _G.ShowFOV
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = _G.FOVSize or 150
end)

-------------------------------------------------
-- ⚙️ Misc Section
-------------------------------------------------
local Misc = MiscTab:Section("Settings / Misc")

-- Anti AFK
Misc:Item("toggle", "Anti-AFK", function(v)
    _G.AntiAFK = v
end)

-- UI Toggle Key
Misc:Item("textbox", "UI Keybind", function(v)
    _G.ToggleKey = v
end, {Placeholder = "F4"})

-- Rejoin
Misc:Item("button", "Rejoin Server", function()
    local ts = game:GetService("TeleportService")
    local p = game:GetService("Players").LocalPlayer
    ts:Teleport(game.PlaceId, p)
end)

-- Server Hop
Misc:Item("button", "Server Hop", function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    local data = HttpService:JSONDecode(req)
    for _, s in pairs(data.data) do
        if s.playing < s.maxPlayers then
            table.insert(servers, s.id)
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], game.Players.LocalPlayer)
    end
end)

-- Reset Character
Misc:Item("button", "Reset Character", function()
    local plr = game.Players.LocalPlayer
    if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
        plr.Character:FindFirstChildOfClass("Humanoid").Health = 0
    end
end)

-------------------------------------------------
-- 🔄 Anti-AFK Handler
-------------------------------------------------
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    end
end)

-------------------------------------------------
-- 🔄 UI Toggle Key Handler
-------------------------------------------------
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if _G.ToggleKey and Enum.KeyCode[_G.ToggleKey] and input.KeyCode == Enum.KeyCode[_G.ToggleKey] then
        library:ToggleUI()
    end
end)
