-- 🌀 Wave UI Lib
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wave"))()
local Main = library:Main()
local CombatTab = Main:Tab("Combat")
local VisualTab = Main:Tab("Visuals")
local MovementTab = Main:Tab("Movement")
local MiscTab = Main:Tab("Misc") -- 🆕 Tab Misc

-------------------------------------------------
-- ⚙ FLAGS
-------------------------------------------------
local FLAGS = {
    -- Combat
    Aim_Enabled = false,
    Aim_Smooth = 0.18,
    Trigger_Enabled = false,
    FR_Enabled = false,
    AutoReload = false,
    Godmode = false,
    -- Visuals
    ESP = false,
    POV_Circle = false,
    POV_FOV = 150,
    -- Movement
    SpeedHack = false,
    SpeedValue = 50,
    HighJump = false,
    JumpValue = 100,
    -- Misc
    AntiAFK = false,
    ToggleKey = Enum.KeyCode.F4
}

-------------------------------------------------
-- ⚔️ Combat Section
-------------------------------------------------
local Combat = CombatTab:Section("Combat")
Combat:Item("toggle", "Aimlock", function(v) FLAGS.Aim_Enabled = v end)
Combat:Item("slider", "Aim FOV", function(v) FLAGS.POV_FOV = v end, {min = 50, max = 500, default = FLAGS.POV_FOV})
Combat:Item("toggle", "TriggerBot", function(v) FLAGS.Trigger_Enabled = v end)
Combat:Item("toggle", "FastReload", function(v) FLAGS.FR_Enabled = v end)
Combat:Item("toggle", "AutoReload", function(v) FLAGS.AutoReload = v end)
Combat:Item("toggle", "Godmode (Fake)", function(v) FLAGS.Godmode = v end)

-------------------------------------------------
-- 👁 Visual Section
-------------------------------------------------
local Visual = VisualTab:Section("ESP / FOV")
Visual:Item("toggle", "ESP", function(v) FLAGS.ESP = v end)
Visual:Item("toggle", "FOV Circle", function(v) FLAGS.POV_Circle = v end)
Visual:Item("slider", "FOV Size", function(v) FLAGS.POV_FOV = v end, {min = 50, max = 500, default = FLAGS.POV_FOV})

-------------------------------------------------
-- 🏃 Movement Section
-------------------------------------------------
local Movement = MovementTab:Section("Movement")
Movement:Item("toggle", "SpeedHack", function(v) FLAGS.SpeedHack = v end)
Movement:Item("slider", "Speed", function(v) FLAGS.SpeedValue = v end, {min = 16, max = 200, default = FLAGS.SpeedValue})
Movement:Item("toggle", "HighJump", function(v) FLAGS.HighJump = v end)
Movement:Item("slider", "JumpPower", function(v) FLAGS.JumpValue = v end, {min = 50, max = 500, default = FLAGS.JumpValue})

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
fovCircle.Radius = FLAGS.POV_FOV

-- Tìm target gần nhất trong FOV
local function getClosestToCursor()
    local closest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, onscreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onscreen then
                local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if mag < dist and mag <= FLAGS.POV_FOV then
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

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if FLAGS.ESP then applyESP(plr) end
    end)
end)

-------------------------------------------------
-- 🔄 Main Loop
-------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- ESP
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and FLAGS.ESP then
            applyESP(plr)
        elseif plr.Character and plr.Character:FindFirstChild("ESP_Highlight") and not FLAGS.ESP then
            plr.Character:FindFirstChild("ESP_Highlight"):Destroy()
        end
    end

    -- Speed + Jump
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        hum.WalkSpeed = FLAGS.SpeedHack and FLAGS.SpeedValue or 16
        hum.JumpPower = FLAGS.HighJump and FLAGS.JumpValue or 50
    end

    -- Aimlock
    if FLAGS.Aim_Enabled then
        local target = getClosestToCursor()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
        end
    end

    -- FOV Circle
    fovCircle.Visible = FLAGS.POV_Circle
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = FLAGS.POV_FOV
end)

-------------------------------------------------
-- 🔄 Anti-AFK Handler
-------------------------------------------------
LocalPlayer.Idled:Connect(function()
    if FLAGS.AntiAFK then
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), Camera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), Camera.CFrame)
    end
end)

-------------------------------------------------
-- 🔄 UI Toggle Key
-------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == FLAGS.ToggleKey then
        library:ToggleUI()
    end
end)
