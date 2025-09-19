-- ==========================
-- Wave UI Full Script
-- ==========================

-- Safe load Shaman UI
local ok, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Rain-Design/Libraries/main/Shaman/Library.lua"))()
end)
if not ok or not Library then
    warn("KiWar Hub: Failed to load Shaman UI")
    return
end

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")

-- Flags (all toggles + values)
local FLAGS = {
    -- Combat
    Aim_Enabled = false,
    Aim_Smooth = 0.5,
    Aim_Predict = 0.15,
    Aim_Team = false,
    Trigger_Enabled = false,
    Trigger_Delay = 0.05,
    FastAttack = false,
    AF_Enabled = false,
    AF_Range = 50,
    AF_Interval = 0.5,
    AF_Team = false,
    FlyKill = false,
    -- Movement
    MOV_Fly = false,
    MOV_FlySpeed = 50,
    MOV_Noclip = false,
    MOV_InfJump = false,
    AutoDodge = false,
    -- ESP / Hitbox
    ESP_Hitbox = false,
    ESP_HitboxSize = 5,
    -- Misc
    FastReload = false
}

-- ==========================
-- Helper Functions
-- ==========================
local function isAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

-- ==========================
-- Aimbot & Combat Logic
-- ==========================
local Aimbot = {}

function Aimbot:GetClosestTarget()
    local closest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            if not FLAGS.Aim_Team or (plr.Team ~= LocalPlayer.Team) then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local magnitude = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                        if magnitude < dist then
                            dist = magnitude
                            closest = plr
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- AimLock
RunService.RenderStepped:Connect(function()
    if FLAGS.Aim_Enabled then
        local target = Aimbot:GetClosestTarget()
        if target then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local predPos = hrp.Position + (hrp.Velocity or Vector3.new()) * FLAGS.Aim_Predict
                local direction = (predPos - Camera.CFrame.Position).Unit
                local camRot = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction:Lerp(Camera.CFrame.LookVector, FLAGS.Aim_Smooth))
                Camera.CFrame = camRot
            end
        end
    end
end)

-- Trigger Bot
local TriggerCooldown = false
RunService.RenderStepped:Connect(function()
    if FLAGS.Trigger_Enabled and not TriggerCooldown then
        local target = Aimbot:GetClosestTarget()
        if target then
            TriggerCooldown = true
            VirtualUser:Button1Down(Enum.UserInputType.MouseButton1)
            task.wait(FLAGS.Trigger_Delay)
            VirtualUser:Button1Up(Enum.UserInputType.MouseButton1)
            task.wait(0.01)
            TriggerCooldown = false
        end
    end
end)

-- Fast Attack
RunService.RenderStepped:Connect(function()
    if FLAGS.FastAttack then
        VirtualUser:Button1Down(Enum.UserInputType.MouseButton1)
        task.wait(0.05)
        VirtualUser:Button1Up(Enum.UserInputType.MouseButton1)
    end
end)

-- Auto Farm
task.spawn(function()
    while task.wait(FLAGS.AF_Interval) do
        if FLAGS.AF_Enabled then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and isAlive(plr) then
                    if not FLAGS.AF_Team or (plr.Team ~= LocalPlayer.Team) then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude <= FLAGS.AF_Range then
                            VirtualUser:Button1Down(Enum.UserInputType.MouseButton1)
                            task.wait(0.05)
                            VirtualUser:Button1Up(Enum.UserInputType.MouseButton1)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================
-- Movement Logic
-- ==========================
local flying = false
local bodyVelocity, bodyGyro

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Fly
    if FLAGS.MOV_Fly then
        if not flying then
            flying = true
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
            bodyVelocity.Velocity = Vector3.new()
            bodyVelocity.Parent = hrp

            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
            bodyGyro.P = 20e3
            bodyGyro.CFrame = hrp.CFrame
            bodyGyro.Parent = hrp
        end
        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end
        bodyVelocity.Velocity = moveDir.Unit * FLAGS.MOV_FlySpeed
        bodyGyro.CFrame = Camera.CFrame
    else
        if flying then
            flying = false
            if bodyVelocity then bodyVelocity:Destroy() end
            if bodyGyro then bodyGyro:Destroy() end
        end
    end

    -- Noclip
    if FLAGS.MOV_Noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if FLAGS.MOV_InfJump then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Auto Dodge
UserInputService.InputBegan:Connect(function(input)
    if FLAGS.AutoDodge and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- FlyKill
task.spawn(function()
    while task.wait(0.2) do
        if FLAGS.FlyKill then
            local target = Aimbot:GetClosestTarget()
            if target and isAlive(target) then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if hrp and targetHRP then
                    hrp.CFrame = targetHRP.CFrame + Vector3.new(0,15,0)
                    VirtualUser:Button1Down(Enum.UserInputType.MouseButton1)
                    task.wait(0.05)
                    VirtualUser:Button1Up(Enum.UserInputType.MouseButton1)
                end
            end
        end
    end
end)

-- ==========================
-- ESP / Hitbox
-- ==========================
local function ApplyHitbox(size)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(size,size,size)
                hrp.Transparency = 0.7
                hrp.BrickColor = BrickColor.new("Bright red")
                hrp.Material = Enum.Material.Neon
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if FLAGS.ESP_Hitbox then
        ApplyHitbox(FLAGS.ESP_HitboxSize)
    end
end)

-- ==========================
-- UI Setup
-- ==========================
local Window = Library:CreateWindow({Name="KiWar Hub"})

-- Combat Tab
local CombatTab = Window:CreateTab("Combat")
CombatTab:Toggle({Name="AimLock", Flag="Aim_Enabled", Callback=function(state) FLAGS.Aim_Enabled = state end})
CombatTab:Slider({Name="Aim Smooth", Min=0, Max=1, Increment=0.05, Flag="Aim_Smooth", Callback=function(val) FLAGS.Aim_Smooth=val end})
CombatTab:Slider({Name="Aim Predict", Min=0, Max=1, Increment=0.01, Flag="Aim_Predict", Callback=function(val) FLAGS.Aim_Predict=val end})
CombatTab:Toggle({Name="TriggerBot", Flag="Trigger_Enabled", Callback=function(state) FLAGS.Trigger_Enabled=state end})
CombatTab:Slider({Name="Trigger Delay", Min=0, Max=0.5, Increment=0.01, Flag="Trigger_Delay", Callback=function(val) FLAGS.Trigger_Delay=val end})
CombatTab:Toggle({Name="Fast Attack", Flag="FastAttack", Callback=function(state) FLAGS.FastAttack=state end})
CombatTab:Toggle({Name="Auto Farm", Flag="AF_Enabled", Callback=function(state) FLAGS.AF_Enabled=state end})
CombatTab:Slider({Name="AF Range", Min=1, Max=100, Increment=1, Flag="AF_Range", Callback=function(val) FLAGS.AF_Range=val end})
CombatTab:Toggle({Name="FlyKill", Flag="FlyKill", Callback=function(state) FLAGS.FlyKill=state end})

-- Movement Tab
local MoveTab = Window:CreateTab("Movement")
MoveTab:Toggle({Name="Fly", Flag="MOV_Fly", Callback=function(state) FLAGS.MOV_Fly=state end})
MoveTab:Slider({Name="Fly Speed", Min=1, Max=200, Increment=1, Flag="MOV_FlySpeed", Callback=function(val) FLAGS.MOV_FlySpeed=val end})
MoveTab:Toggle({Name="Noclip", Flag="MOV_Noclip", Callback=function(state) FLAGS.MOV_Noclip=state end})
MoveTab:Toggle({Name="Infinite Jump", Flag="MOV_InfJump", Callback=function(state) FLAGS.MOV_InfJump=state end})
MoveTab:Toggle({Name="Auto Dodge", Flag="AutoDodge", Callback=function(state) FLAGS.AutoDodge=state end})

-- ESP Tab
local ESPTab = Window:CreateTab("ESP")
ESPTab:Toggle({Name="Hitbox ESP", Flag="ESP_Hitbox", Callback=function(state) FLAGS.ESP_Hitbox=state end})
ESPTab:Slider({Name="Hitbox Size", Min=1, Max=10, Increment=0.5, Flag="ESP_HitboxSize", Callback=function(val) FLAGS.ESP_HitboxSize=val end})

-- Misc Tab
local MiscTab = Window:CreateTab("Misc")
MiscTab:Toggle({Name="Fast Reload", Flag="FastReload", Callback=function(state) FLAGS.FastReload=state end})

-- Settings Tab (example)
local SettingsTab = Window:CreateTab("Settings")
SettingsTab:Button({Name="Unload Script", Callback=function()
    -- destroy everything, clean up
    for _, conn in pairs(getconnections or {}) do
        if typeof(conn.Disconnect) == "function" then conn:Disconnect() end
    end
    for _, v in pairs(LocalPlayer.Character:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
    end
    Library:Unload()
end})

