-- 🌀 Wave UI Lib
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wave"))()
local Main = library:Main()
local CombatTab = Main:Tab("Combat")
local VisualTab = Main:Tab("Visuals")
local MovementTab = Main:Tab("Movement")
local MiscTab = Main:Tab("Misc")

-------------------------------------------------
-- ⚔️ Combat Section
-------------------------------------------------
local Combat = CombatTab:Section("Combat")

local AimlockOn = false
Combat:Toggle({
    Name = "Aimlock",
    Flag = "Aimlock",
    Callback = function(state)
        AimlockOn = state
    end
})

local TriggerBotOn = false
Combat:Toggle({
    Name = "TriggerBot",
    Flag = "TriggerBot",
    Callback = function(state)
        TriggerBotOn = state
    end
})

local FastReloadOn = false
Combat:Toggle({
    Name = "FastReload",
    Flag = "FastReload",
    Callback = function(state)
        FastReloadOn = state
    end
})

local AutoReloadOn = false
Combat:Toggle({
    Name = "AutoReload",
    Flag = "AutoReload",
    Callback = function(state)
        AutoReloadOn = state
    end
})

local GodmodeOn = false
Combat:Toggle({
    Name = "Godmode (Fake)",
    Flag = "Godmode",
    Callback = function(state)
        GodmodeOn = state
    end
})

-------------------------------------------------
-- 👁 Visual Section
-------------------------------------------------
local Visual = VisualTab:Section("ESP / FOV")

local ESPOn = false
Visual:Toggle({
    Name = "ESP",
    Flag = "ESP",
    Callback = function(state)
        ESPOn = state
    end
})

local ShowFOV = false
local FOVSize = 150
Visual:Toggle({
    Name = "FOV Circle",
    Flag = "FOVCircle",
    Callback = function(state)
        ShowFOV = state
    end
})
Visual:Slider({
    Name = "FOV Size",
    Flag = "FOVSize",
    Min = 50,
    Max = 500,
    Value = 150,
    Callback = function(v)
        FOVSize = v
    end
})

-------------------------------------------------
-- 🏃 Movement Section
-------------------------------------------------
local Movement = MovementTab:Section("Movement")

local SpeedHackOn = false
local SpeedValue = 50
Movement:Toggle({
    Name = "SpeedHack",
    Flag = "SpeedHack",
    Callback = function(state)
        SpeedHackOn = state
    end
})
Movement:Slider({
    Name = "Speed",
    Flag = "SpeedValue",
    Min = 16,
    Max = 200,
    Value = 50,
    Callback = function(v)
        SpeedValue = v
    end
})

local HighJumpOn = false
local JumpValue = 100
Movement:Toggle({
    Name = "HighJump",
    Flag = "HighJump",
    Callback = function(state)
        HighJumpOn = state
    end
})
Movement:Slider({
    Name = "JumpPower",
    Flag = "JumpValue",
    Min = 50,
    Max = 500,
    Value = 100,
    Callback = function(v)
        JumpValue = v
    end
})

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
fovCircle.Radius = FOVSize

-- Hàm tìm target gần nhất
local function getClosestToCursor()
    local closest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, onscreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onscreen then
                local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mag < dist and mag <= FOVSize then
                    closest, dist = plr, mag
                end
            end
        end
    end
    return closest
end

-- ESP Highlight
local function applyESP(player)
    if player.Character and not player.Character:FindFirstChild("ESP_Highlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "ESP_Highlight"
        hl.Parent = player.Character
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

-------------------------------------------------
-- 🔄 Main Loop
-------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- ESP
    if ESPOn then
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
        hum.WalkSpeed = SpeedHackOn and SpeedValue or 16
        hum.JumpPower = HighJumpOn and JumpValue or 50
    end

    -- Aimlock
    if AimlockOn then
        local target = getClosestToCursor()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
        end
    end

    -- TriggerBot
    if TriggerBotOn then
        local target = getClosestToCursor()
        if target then
            mouse1press()
            task.wait()
            mouse1release()
        end
    end

    -- FastReload
    if FastReloadOn and LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
                tool.Ammo.Value = tool.Ammo.MaxValue
            end
        end
    end

    -- AutoReload
    if AutoReloadOn and LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Ammo") and tool.Ammo.Value <= 0 then
                tool.Ammo.Value = tool.Ammo.MaxValue
            end
        end
    end

    -- Godmode
    if GodmodeOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health =
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MaxHealth
    end

    -- FOV Circle update
    fovCircle.Visible = ShowFOV
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = FOVSize
end)
