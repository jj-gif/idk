warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
warn("                                                                  ")
warn("            ██████╗ ██╗   ██╗████████╗███████╗██████╗           ")
warn("            ██╔══██╗██║   ██║╚══██╔══╝██╔════╝██╔══██╗          ")
warn("            ██████╔╝██║   ██║   ██║   █████╗  ██████╔╝          ")
warn("            ██╔══██╗██║   ██║   ██║   ██╔══╝  ██╔══██╗          ")
warn("            ██████╔╝╚██████╔╝   ██║   ███████╗██║  ██║          ")
warn("            ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝          ")
warn("                                                                  ")
warn("              🧈 BUTER HUB v1.24 - WORKING 🧈                   ")
warn("          Fixed: Magic Bullet, Instant Hit, No Recoil            ")
warn("                                                                  ")
warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

task.wait(0.3)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local HubSettings = {
    FovCircleVisible = true,
    FovCircleRadius = 150,
    SilentAimActive = false,
    VisibleTargetsOnly = true,
    TeamCheck = false,
    PlayerBoxEsp = false,
    BoxFillEnabled = false,
    NameTagsEnabled = false,
    ShowDistances = false,
    ThemeColor = Color3.fromRGB(255, 200, 0),
    RainbowEffect = false,
    SnapLinesEnabled = false,
    BrightMode = false,
    WorldFOV = 70,
    VelHopEnabled = false,
    VelHopMultiplier = 2.0,
    MagicBulletActive = false,
    InstantHitEnabled = false,
    TriggerbotActive = false,
    TriggerbotDelay = 0.1,
    ThirdPersonEnabled = false,
    ThirdPersonDistance = 10,
    ThirdPersonShoulder = 2,
    ThirdPersonRotationSpeed = 0.15,
    SpinbotEnabled = false,
    SpinbotSpeed = 360,
    ChamsEnabled = false,
    ChamsColor = Color3.fromRGB(255, 0, 255),
    ChamsRainbow = false,
    SkeletonEnabled = false,
    LocalChamsEnabled = false,
    LocalChamsColor = Color3.fromRGB(0, 255, 255),
    LocalChamsTransparency = 0.3,
    LocalChamsRainbow = false,
    PredictionEnabled = true,
    PredictionAmount = 0.1,
    KillSound = false,
    KillSoundId = "rbxassetid://6518811702",
    NoRecoil = false
}

local TriggerbotCooldown = false
local KillCount = 0

local function clampMul(v)
    v = tonumber(v) or 2.0
    if v < 1.0 then v = 1.0 end
    if v > 2.5 then v = 2.5 end
    return v
end

HubSettings.VelHopMultiplier = clampMul(HubSettings.VelHopMultiplier)

do
    local old = CoreGui:FindFirstChild("BUTER_OVERLAY")
    if old then old:Destroy() end
end

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "BUTER_OVERLAY"
OverlayGui.Parent = CoreGui
OverlayGui.IgnoreGuiInset = true
OverlayGui.ResetOnSpawn = false

local LineContainer = Instance.new("Folder")
LineContainer.Name = "Lines"
LineContainer.Parent = OverlayGui

local BoxContainer = Instance.new("Folder")
BoxContainer.Name = "Boxes"
BoxContainer.Parent = OverlayGui

local SkeletonContainer = Instance.new("Folder")
SkeletonContainer.Name = "Skeletons"
SkeletonContainer.Parent = OverlayGui

local BoxEspCache = {}
local ChamsCache = {}
local SkeletonCache = {}

local SnapLine = Instance.new("Frame")
SnapLine.Name = "SnapLineSingle"
SnapLine.Parent = LineContainer
SnapLine.BorderSizePixel = 0
SnapLine.AnchorPoint = Vector2.new(0.5, 0.5)
SnapLine.Visible = false

local VisualFovCircle = Instance.new("Frame")
VisualFovCircle.Name = "FOVCircle"
VisualFovCircle.Parent = OverlayGui
VisualFovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
VisualFovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
VisualFovCircle.BackgroundTransparency = 1

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Parent = VisualFovCircle
CircleStroke.Thickness = 1

local CircleCorner = Instance.new("UICorner")
CircleCorner.Parent = VisualFovCircle
CircleCorner.CornerRadius = UDim.new(1, 0)

local BrightRestore = {
    Has = false,
    Brightness = nil,
    ClockTime = nil,
    GlobalShadows = nil,
    Ambient = nil,
    OutdoorAmbient = nil,
    FogEnd = nil,
    FogStart = nil,
    FogColor = nil
}

local function CaptureLightingIfNeeded()
    if BrightRestore.Has then return end
    BrightRestore.Has = true
    BrightRestore.Brightness = Lighting.Brightness
    BrightRestore.ClockTime = Lighting.ClockTime
    BrightRestore.GlobalShadows = Lighting.GlobalShadows
    BrightRestore.Ambient = Lighting.Ambient
    BrightRestore.OutdoorAmbient = Lighting.OutdoorAmbient
    BrightRestore.FogEnd = Lighting.FogEnd
    BrightRestore.FogStart = Lighting.FogStart
    BrightRestore.FogColor = Lighting.FogColor
end

local function ApplyFullBright(on)
    if on then
        CaptureLightingIfNeeded()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogStart = 0
        Lighting.FogEnd = 1e9
        Lighting.FogColor = Color3.new(1, 1, 1)
    else
        if BrightRestore.Has then
            Lighting.Brightness = BrightRestore.Brightness
            Lighting.ClockTime = BrightRestore.ClockTime
            Lighting.GlobalShadows = BrightRestore.GlobalShadows
            Lighting.Ambient = BrightRestore.Ambient
            Lighting.OutdoorAmbient = BrightRestore.OutdoorAmbient
            Lighting.FogEnd = BrightRestore.FogEnd
            Lighting.FogStart = BrightRestore.FogStart
            Lighting.FogColor = BrightRestore.FogColor
        end
    end
end

-- =========================================================
-- KILL SOUND SYSTEM
-- =========================================================
local function PlayKillSound()
    if not HubSettings.KillSound then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = HubSettings.KillSoundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- =========================================================
-- KILL DETECTION SYSTEM
-- =========================================================
local LastPlayerHealth = {}

local function SetupKillDetection()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    LastPlayerHealth[player] = humanoid.Health
                    
                    humanoid.Died:Connect(function()
                        if LastPlayerHealth[player] and LastPlayerHealth[player] > 0 then
                            KillCount = KillCount + 1
                            PlayKillSound()
                            warn("🧈 [KILL] Elimination #" .. KillCount)
                        end
                        LastPlayerHealth[player] = 0
                    end)
                    
                    humanoid.HealthChanged:Connect(function(health)
                        LastPlayerHealth[player] = health
                    end)
                end
            end)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                LastPlayerHealth[player] = humanoid.Health
                
                humanoid.Died:Connect(function()
                    if LastPlayerHealth[player] and LastPlayerHealth[player] > 0 then
                        KillCount = KillCount + 1
                        PlayKillSound()
                        warn("🧈 [KILL] Elimination #" .. KillCount)
                    end
                    LastPlayerHealth[player] = 0
                end)
                
                humanoid.HealthChanged:Connect(function(health)
                    LastPlayerHealth[player] = health
                end)
            end
        end)
    end)
end

SetupKillDetection()

local function IsOnTeam(player)
    if not HubSettings.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function HasLineOfSightToPart(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
    local hit = workspace:Raycast(origin, direction, params)
    return hit == nil
end

local function FindBestTargetSilent()
    local bestD = math.huge
    local best = nil
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if IsOnTeam(plr) then continue end
            local head = plr.Character.Head
            local vp, ok = Camera:WorldToViewportPoint(head.Position)
            if ok and vp.Z > 0 then
                local d = (Vector2.new(vp.X, vp.Y) - center).Magnitude
                if d <= HubSettings.FovCircleRadius then
                    if HubSettings.VisibleTargetsOnly and not HasLineOfSightToPart(head) then continue end
                    if d < bestD then bestD = d; best = plr end
                end
            end
        end
    end
    return best
end

local function FindBestTargetMagic()
    local bestD = math.huge
    local best = nil
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if IsOnTeam(plr) then continue end
            local head = plr.Character.Head
            local vp, ok = Camera:WorldToViewportPoint(head.Position)
            if ok and vp.Z > 0 then
                local d = (Vector2.new(vp.X, vp.Y) - center).Magnitude
                if d <= HubSettings.FovCircleRadius then
                    if d < bestD then bestD = d; best = plr end
                end
            end
        end
    end
    return best
end

local function GetClosestTargetForSnapline()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestPlayer, bestHead2D, bestDist = nil, nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if IsOnTeam(plr) then continue end
            local head = plr.Character.Head
            local vp, ok = Camera:WorldToViewportPoint(head.Position)
            if ok and vp.Z > 0 then
                local head2D = Vector2.new(vp.X, vp.Y)
                local dist = (head2D - center).Magnitude
                if dist <= HubSettings.FovCircleRadius and dist < bestDist then
                    if HubSettings.VisibleTargetsOnly and not HasLineOfSightToPart(head) then continue end
                    bestDist = dist
                    bestPlayer = plr
                    bestHead2D = head2D
                end
            end
        end
    end
    return bestPlayer, bestHead2D, center
end

-- =========================================================
-- PROJECTILE MODULE HOOK (For Instant Hit)
-- =========================================================
local ProjectileModule = nil
pcall(function() 
    ProjectileModule = require(ReplicatedStorage.ModuleScripts.GunModules.GunFramework.Projectile)
end)

if ProjectileModule and ProjectileModule.Cast then
    local OriginalCast = ProjectileModule.Cast
    
    ProjectileModule.Cast = function(self, bulletId, origin, endpoint, force)
        -- Multiply force for instant hit
        if HubSettings.InstantHitEnabled then
            force = force * 100
            warn("🧈 [Instant Hit] Force multiplied: " .. force)
        end
        
        return OriginalCast(self, bulletId, origin, endpoint, force)
    end
    
    warn("🧈 [Instant Hit] Hooked Projectile.Cast!")
end

-- =========================================================
-- BULLET HANDLER HOOK (For Silent Aim & Magic Bullet)
-- =========================================================
local GunModule = nil
pcall(function() GunModule = require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler) end)

if GunModule and type(GunModule) == "table" and GunModule.Fire then
    local OriginalFire = GunModule.Fire
    
    GunModule.Fire = function(data)
        local target = nil
        
        if HubSettings.MagicBulletActive then
            target = FindBestTargetMagic()
        elseif HubSettings.SilentAimActive then
            target = FindBestTargetSilent()
        end
        
        if target and data and data.Origin then
            if target.Character and target.Character:FindFirstChild("Head") then
                local targetHead = target.Character.Head
                local targetPos = targetHead.Position
                
                -- Velocity prediction
                if HubSettings.PredictionEnabled then
                    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        local velocity = targetRoot.AssemblyLinearVelocity
                        targetPos = targetPos + (velocity * HubSettings.PredictionAmount)
                    end
                end
                
                -- Modify direction AND endpoint
                local newDirection = (targetPos - data.Origin).Unit
                data.Direction = newDirection
                
                -- Also modify VisualOrigin endpoint (line 22 in BulletHandler)
                data.VisualOrigin = data.Origin
                
                -- Update camera CFrame for server validation
                if data.Misc then
                    data.Misc.CamCFrame = CFrame.new(data.Origin, targetPos)
                end
                
                warn("🧈 [Aimbot] Locked onto: " .. target.Name)
            end
        end
        
        return OriginalFire(data)
    end
    
    warn("🧈 [BUTER] BulletHandler hooked!")
else
    warn("🧈 [BUTER] Warning: BulletHandler not found")
end

-- =========================================================
-- NO RECOIL SYSTEM (Fixed - Clears active effects)
-- =========================================================
local CameraHandler = nil
pcall(function() 
    CameraHandler = require(ReplicatedStorage.ModuleScripts.GunModules.GunFramework.CameraHandler)
end)

if CameraHandler then
    -- Clear recoil effects table
    RunService.RenderStepped:Connect(function()
        if HubSettings.NoRecoil and CameraHandler.activeEffects then
            -- Clear all active recoil effects
            table.clear(CameraHandler.activeEffects)
        end
    end)
    
    warn("🧈 [NO RECOIL] Hooked - Clearing activeEffects!")
end

local SpinbotAngle = 0
local SpinbotConnection = nil
local SpinbotHumanoid = nil
local SpinbotRoot = nil

local function StopSpinbot()
    if SpinbotConnection then
        SpinbotConnection:Disconnect()
        SpinbotConnection = nil
    end
    if SpinbotHumanoid then
        SpinbotHumanoid.AutoRotate = true
    end
    SpinbotAngle = 0
end

local function StartSpinbot(character)
    StopSpinbot()
    
    if not character then return end
    
    SpinbotHumanoid = character:WaitForChild("Humanoid", 3)
    SpinbotRoot = character:WaitForChild("HumanoidRootPart", 3)
    
    if not SpinbotHumanoid or not SpinbotRoot then return end
    
    SpinbotHumanoid.AutoRotate = false
    SpinbotAngle = 0
    
    SpinbotConnection = RunService.RenderStepped:Connect(function(dt)
        if not HubSettings.SpinbotEnabled or not SpinbotRoot or not SpinbotRoot.Parent then 
            return 
        end
        
        SpinbotAngle = SpinbotAngle + (HubSettings.SpinbotSpeed * dt)
        SpinbotRoot.CFrame = CFrame.new(SpinbotRoot.Position) * CFrame.Angles(0, math.rad(SpinbotAngle), 0)
    end)
end

if LocalPlayer.Character then
    StartSpinbot(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if HubSettings.SpinbotEnabled then
        StartSpinbot(char)
    end
end)

LocalPlayer.CharacterRemoving:Connect(StopSpinbot)

local function CreateChams(character)
    if not character then return end
    task.wait(0.1)
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not part:FindFirstChild("ChamHighlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ChamHighlight"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.FillColor = HubSettings.ChamsColor
                highlight.OutlineColor = HubSettings.ChamsColor
                highlight.Parent = part
            end
        end
    end
    
    character.DescendantAdded:Connect(function(part)
        if HubSettings.ChamsEnabled and part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not part:FindFirstChild("ChamHighlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ChamHighlight"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.FillColor = HubSettings.ChamsColor
                highlight.OutlineColor = HubSettings.ChamsColor
                highlight.Parent = part
            end
        end
    end)
end

local function RemoveChams(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        local highlight = part:FindFirstChild("ChamHighlight")
        if highlight then highlight:Destroy() end
    end
end

local function CreateSkeletonLine(parent, name)
    local line = Instance.new("Frame")
    line.Name = name
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.Parent = parent
    return line
end

local function UpdateSkeletonESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or IsOnTeam(player) then
            if SkeletonCache[player] then
                for _, line in pairs(SkeletonCache[player].Lines) do
                    line.Visible = false
                end
            end
            continue
        end
        
        local char = player.Character
        if not char then
            if SkeletonCache[player] then
                for _, line in pairs(SkeletonCache[player].Lines) do
                    line.Visible = false
                end
            end
            continue
        end
        
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not torso then
            if SkeletonCache[player] then
                for _, line in pairs(SkeletonCache[player].Lines) do
                    line.Visible = false
                end
            end
            continue
        end
        
        if not SkeletonCache[player] then
            local folder = Instance.new("Folder")
            folder.Name = "Skeleton_" .. player.Name
            folder.Parent = SkeletonContainer
            
            SkeletonCache[player] = { Folder = folder, Lines = {} }
            
            local lineNames = {"Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Spine"}
            for _, name in ipairs(lineNames) do
                SkeletonCache[player].Lines[name] = CreateSkeletonLine(folder, name)
            end
        end
        
        local cache = SkeletonCache[player]
        
        if HubSettings.SkeletonEnabled then
            local head = char:FindFirstChild("Head")
            local leftArm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftUpperArm")
            local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
            local leftLeg = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftUpperLeg")
            local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
            
            if head and torso then
                local headPos, headVis = Camera:WorldToViewportPoint(head.Position)
                local torsoPos, torsoVis = Camera:WorldToViewportPoint(torso.Position)
                
                if headVis and torsoVis then
                    local function drawLine(line, pos1, vis1, pos2, vis2, color)
                        if vis1 and vis2 then
                            local midpoint = Vector2.new((pos1.X + pos2.X) / 2, (pos1.Y + pos2.Y) / 2)
                            local distance = (Vector2.new(pos1.X, pos1.Y) - Vector2.new(pos2.X, pos2.Y)).Magnitude
                            local angle = math.deg(math.atan2(pos2.Y - pos1.Y, pos2.X - pos1.X))
                            
                            line.Position = UDim2.fromOffset(midpoint.X, midpoint.Y)
                            line.Size = UDim2.fromOffset(distance, 2)
                            line.Rotation = angle
                            line.BackgroundColor3 = color
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end
                    
                    local rainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
                    local skeletonColor = HubSettings.RainbowEffect and rainbowColor or HubSettings.ThemeColor
                    
                    drawLine(cache.Lines.Spine, headPos, headVis, torsoPos, torsoVis, skeletonColor)
                    
                    if leftArm then
                        local laPos, laVis = Camera:WorldToViewportPoint(leftArm.Position)
                        drawLine(cache.Lines.LeftArm, torsoPos, torsoVis, laPos, laVis, skeletonColor)
                    end
                    
                    if rightArm then
                        local raPos, raVis = Camera:WorldToViewportPoint(rightArm.Position)
                        drawLine(cache.Lines.RightArm, torsoPos, torsoVis, raPos, raVis, skeletonColor)
                    end
                    
                    if leftLeg then
                        local llPos, llVis = Camera:WorldToViewportPoint(leftLeg.Position)
                        drawLine(cache.Lines.LeftLeg, torsoPos, torsoVis, llPos, llVis, skeletonColor)
                    end
                    
                    if rightLeg then
                        local rlPos, rlVis = Camera:WorldToViewportPoint(rightLeg.Position)
                        drawLine(cache.Lines.RightLeg, torsoPos, torsoVis, rlPos, rlVis, skeletonColor)
                    end
                else
                    for _, line in pairs(cache.Lines) do
                        line.Visible = false
                    end
                end
            end
        else
            for _, line in pairs(cache.Lines) do
                line.Visible = false
            end
        end
    end
end

local function ApplyLocalChams()
    local char = LocalPlayer.Character
    if not char then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    for _, obj in ipairs(camera:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            if HubSettings.LocalChamsEnabled then
                obj.Transparency = HubSettings.LocalChamsTransparency
                
                local rainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
                obj.Color = HubSettings.LocalChamsRainbow and rainbowColor or HubSettings.LocalChamsColor
            end
        end
    end
end

local vhopConns = {}
local vhopHum, vhopHrp
local vhopArmed = false
local vhopUsedThisAir = false

local function disconnectVhop()
    for _, c in ipairs(vhopConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(vhopConns)
    vhopHum, vhopHrp = nil, nil
    vhopArmed = false
    vhopUsedThisAir = false
end

local function applyVHop()
    if not HubSettings.VelHopEnabled then return end
    if not vhopHrp or not vhopHum then return end
    local v = vhopHrp.AssemblyLinearVelocity
    local y = v.Y
    local horiz = Vector3.new(v.X, 0, v.Z)
    local speed = horiz.Magnitude
    if speed < 0.05 then return end
    local md = vhopHum.MoveDirection
    md = Vector3.new(md.X, 0, md.Z)
    local dir
    if md.Magnitude > 0.05 then dir = md.Unit else dir = horiz.Unit end
    local mul = clampMul(HubSettings.VelHopMultiplier)
    local newSpeed = speed * mul
    local newHoriz = dir * newSpeed
    vhopHrp.AssemblyLinearVelocity = Vector3.new(newHoriz.X, y, newHoriz.Z)
end

local function hookVelocityHop(char)
    disconnectVhop()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    vhopHum, vhopHrp = hum, hrp
    vhopArmed = false
    vhopUsedThisAir = false
    table.insert(vhopConns, hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Landed then
            vhopArmed = true
            vhopUsedThisAir = false
        elseif newState == Enum.HumanoidStateType.Freefall then
            vhopArmed = false
        elseif newState == Enum.HumanoidStateType.Jumping then
            if not HubSettings.VelHopEnabled then return end
            if not vhopArmed or vhopUsedThisAir then return end
            vhopArmed = false
            vhopUsedThisAir = true
            task.spawn(function()
                RunService.Heartbeat:Wait()
                if not hrp.Parent then return end
                if hum:GetState() == Enum.HumanoidStateType.Dead then return end
                applyVHop()
            end)
        end
    end))
    table.insert(vhopConns, RunService.Heartbeat:Connect(function()
        if not hum.Parent or not hrp.Parent then return end
        if hum:GetState() == Enum.HumanoidStateType.Dead then
            vhopArmed = false
            vhopUsedThisAir = false
            return
        end
        local grounded = hum.FloorMaterial ~= Enum.Material.Air
        if grounded then
            vhopArmed = true
            vhopUsedThisAir = false
        end
    end))
end

if LocalPlayer.Character then hookVelocityHop(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.defer(function() hookVelocityHop(char) end)
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        if hum ~= vhopHum or hrp ~= vhopHrp then
            hookVelocityHop(char)
        end
    end
end)

local function clearPlayerEsp(player)
    local cached = BoxEspCache[player]
    if cached then
        if cached.Frame then cached.Frame:Destroy() end
        BoxEspCache[player] = nil
    end
    
    if SkeletonCache[player] then
        if SkeletonCache[player].Folder then
            SkeletonCache[player].Folder:Destroy()
        end
        SkeletonCache[player] = nil
    end
end

Players.PlayerRemoving:Connect(clearPlayerEsp)

local TPVRenderConnection = nil

local function SetupThirdPerson()
    if TPVRenderConnection then 
        RunService:UnbindFromRenderStep("TPV")
        TPVRenderConnection = nil
    end
    
    if not HubSettings.ThirdPersonEnabled then return end
    
    RunService:BindToRenderStep("TPV", 201, function()
        if not HubSettings.ThirdPersonEnabled or not LocalPlayer.Character then return end

        local character = LocalPlayer.Character
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not root or not humanoid then return end

        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end

        local startCFrame = Camera.CFrame
        Camera.CFrame = startCFrame * CFrame.new(
            HubSettings.ThirdPersonShoulder, 
            1, 
            HubSettings.ThirdPersonDistance
        )

        if not HubSettings.SpinbotEnabled then
            local lookVec = Camera.CFrame.LookVector
            local targetCFrame = CFrame.new(root.Position, root.Position + Vector3.new(lookVec.X, 0, lookVec.Z))
            root.CFrame = root.CFrame:Lerp(targetCFrame, HubSettings.ThirdPersonRotationSpeed)
        end
    end)
    
    TPVRenderConnection = true
end

warn("🧈 Creating UI...")

local Window = Fluent:CreateWindow({
    Title = "BUTER HUB v1.24",
    SubTitle = "Actually Working",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- LEFT CTRL to toggle
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "" }),
    World = Window:AddTab({ Title = "World", Icon = "" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "" })
}

-- COMBAT TAB
Tabs.Combat:AddParagraph({
    Title = "✅ Fixed Features",
    Content = "Silent Aim, Magic Bullet & Instant Hit now work!"
})

Tabs.Combat:AddToggle("SilentAim", { Title = "Silent Aim", Default = false }):OnChanged(function(v)
    HubSettings.SilentAimActive = v
end)

Tabs.Combat:AddToggle("MagicBullet", { Title = "Magic Bullet", Default = false }):OnChanged(function(v)
    HubSettings.MagicBulletActive = v
end)

Tabs.Combat:AddToggle("InstantHit", { Title = "Instant Hit (100x Force)", Default = false }):OnChanged(function(v)
    HubSettings.InstantHitEnabled = v
end)

Tabs.Combat:AddToggle("Prediction", { Title = "Velocity Prediction", Default = true }):OnChanged(function(v)
    HubSettings.PredictionEnabled = v
end)

Tabs.Combat:AddSlider("PredictionAmount", { Title = "Prediction", Min = 0.05, Max = 0.3, Default = 0.1, Rounding = 2 }):OnChanged(function(v)
    HubSettings.PredictionAmount = v
end)

Tabs.Combat:AddToggle("VisibleOnly", { Title = "Visible Only", Default = true }):OnChanged(function(v)
    HubSettings.VisibleTargetsOnly = v
end)

Tabs.Combat:AddSlider("FovRadius", { Title = "FOV Size", Min = 50, Max = 500, Default = 150, Rounding = 0 }):OnChanged(function(v)
    HubSettings.FovCircleRadius = v
end)

Tabs.Combat:AddToggle("ShowFov", { Title = "Show FOV Circle", Default = true }):OnChanged(function(v)
    HubSettings.FovCircleVisible = v
end)

Tabs.Combat:AddToggle("Triggerbot", { Title = "Triggerbot", Default = false }):OnChanged(function(v)
    HubSettings.TriggerbotActive = v
end)

Tabs.Combat:AddSlider("TriggerbotDelay", { Title = "Fire Delay", Min = 0.05, Max = 0.5, Default = 0.1, Rounding = 2 }):OnChanged(function(v)
    HubSettings.TriggerbotDelay = v
end)

-- VISUALS TAB
Tabs.Visuals:AddParagraph({
    Title = "ESP Features",
    Content = "Box, Skeleton, Chams & more"
})

Tabs.Visuals:AddToggle("BoxEsp", { Title = "Box ESP", Default = false }):OnChanged(function(v)
    HubSettings.PlayerBoxEsp = v
end)

Tabs.Visuals:AddToggle("FillBoxes", { Title = "Fill Boxes", Default = false }):OnChanged(function(v)
    HubSettings.BoxFillEnabled = v
end)

Tabs.Visuals:AddToggle("NameTags", { Title = "Name Tags", Default = false }):OnChanged(function(v)
    HubSettings.NameTagsEnabled = v
end)

Tabs.Visuals:AddToggle("Distances", { Title = "Distances", Default = false }):OnChanged(function(v)
    HubSettings.ShowDistances = v
end)

Tabs.Visuals:AddToggle("Snaplines", { Title = "Snaplines", Default = false }):OnChanged(function(v)
    HubSettings.SnapLinesEnabled = v
end)

Tabs.Visuals:AddToggle("SkeletonEsp", { Title = "Skeleton ESP", Default = false }):OnChanged(function(v)
    HubSettings.SkeletonEnabled = v
end)

Tabs.Visuals:AddToggle("PlayerChams", { Title = "Player Chams", Default = false }):OnChanged(function(v)
    HubSettings.ChamsEnabled = v
    if v then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                CreateChams(player.Character)
            end
        end
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                RemoveChams(player.Character)
            end
        end
    end
end)

Tabs.Visuals:AddToggle("ChamsRainbow", { Title = "Chams Rainbow", Default = false }):OnChanged(function(v)
    HubSettings.ChamsRainbow = v
end)

Tabs.Visuals:AddToggle("LocalChams", { Title = "Local Chams", Default = false }):OnChanged(function(v)
    HubSettings.LocalChamsEnabled = v
end)

Tabs.Visuals:AddSlider("LocalChamsTransparency", { Title = "Transparency", Min = 0, Max = 1, Default = 0.3, Rounding = 1 }):OnChanged(function(v)
    HubSettings.LocalChamsTransparency = v
end)

Tabs.Visuals:AddToggle("LocalChamsRainbow", { Title = "Local Rainbow", Default = false }):OnChanged(function(v)
    HubSettings.LocalChamsRainbow = v
end)

Tabs.Visuals:AddToggle("RainbowMode", { Title = "Rainbow Mode", Default = false }):OnChanged(function(v)
    HubSettings.RainbowEffect = v
end)

-- WORLD TAB
Tabs.World:AddParagraph({
    Title = "World & Movement",
    Content = "Full Bright, FOV, Third Person, Spinbot"
})

Tabs.World:AddToggle("FullBright", { Title = "Full Bright", Default = false }):OnChanged(function(v)
    HubSettings.BrightMode = v
    ApplyFullBright(v)
end)

Tabs.World:AddSlider("CameraFOV", { Title = "Camera FOV", Min = 60, Max = 120, Default = 70, Rounding = 0 }):OnChanged(function(v)
    HubSettings.WorldFOV = v
end)

Tabs.World:AddToggle("ThirdPerson", { Title = "Third Person", Default = false }):OnChanged(function(v)
    HubSettings.ThirdPersonEnabled = v
    SetupThirdPerson()
end)

Tabs.World:AddSlider("TPDistance", { Title = "TP Distance", Min = 5, Max = 30, Default = 10, Rounding = 0 }):OnChanged(function(v)
    HubSettings.ThirdPersonDistance = v
end)

Tabs.World:AddSlider("TPShoulder", { Title = "Shoulder Offset", Min = -5, Max = 5, Default = 2, Rounding = 0 }):OnChanged(function(v)
    HubSettings.ThirdPersonShoulder = v
end)

Tabs.World:AddToggle("Spinbot", { Title = "Spinbot", Default = false }):OnChanged(function(v)
    HubSettings.SpinbotEnabled = v
    if v then
        if LocalPlayer.Character then
            StartSpinbot(LocalPlayer.Character)
        end
    else
        StopSpinbot()
    end
end)

Tabs.World:AddSlider("SpinSpeed", { Title = "Spin Speed", Min = 1, Max = 720, Default = 360, Rounding = 0 }):OnChanged(function(v)
    HubSettings.SpinbotSpeed = v
end)

Tabs.World:AddToggle("VelocityHop", { Title = "Velocity Hop", Default = false }):OnChanged(function(v)
    HubSettings.VelHopEnabled = v
    if v then
        hookVelocityHop(LocalPlayer.Character)
    else
        disconnectVhop()
    end
end)

Tabs.World:AddSlider("HopMultiplier", { Title = "Hop Multiplier", Min = 1, Max = 2.5, Default = 2, Rounding = 1 }):OnChanged(function(v)
    HubSettings.VelHopMultiplier = clampMul(v)
end)

-- MISC TAB
Tabs.Misc:AddParagraph({
    Title = "✅ Working Features",
    Content = "Kill Sound & No Recoil"
})

Tabs.Misc:AddToggle("KillSound", { Title = "Kill Sound", Default = false }):OnChanged(function(v)
    HubSettings.KillSound = v
end)

Tabs.Misc:AddToggle("NoRecoil", { Title = "No Recoil (Clears Effects)", Default = false }):OnChanged(function(v)
    HubSettings.NoRecoil = v
end)

Tabs.Misc:AddParagraph({
    Title = "Kill Counter",
    Content = "Kills: 0"
})

-- SETTINGS TAB
Tabs.Settings:AddToggle("TeamCheck", { Title = "Team Check", Default = false }):OnChanged(function(v)
    HubSettings.TeamCheck = v
end)

Tabs.Settings:AddButton({
    Title = "Unload Script",
    Description = "Remove BUTER HUB",
    Callback = function()
        warn("🧈 Unloading...")
        if OverlayGui then OverlayGui:Destroy() end
        StopSpinbot()
        disconnectVhop()
        if TPVRenderConnection then
            RunService:UnbindFromRenderStep("TPV")
        end
        if Window then
            pcall(function() Window:Destroy() end)
        end
    end
})

-- MAIN RENDER LOOP
RunService.RenderStepped:Connect(function()
    local rainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
    local currentEspColor = HubSettings.RainbowEffect and rainbowColor or HubSettings.ThemeColor

    Camera.FieldOfView = HubSettings.WorldFOV

    VisualFovCircle.Visible = HubSettings.FovCircleVisible
    VisualFovCircle.Size = UDim2.new(0, HubSettings.FovCircleRadius * 2, 0, HubSettings.FovCircleRadius * 2)
    CircleStroke.Color = currentEspColor

    if HubSettings.BrightMode then
        ApplyFullBright(true)
    end
    
    if HubSettings.LocalChamsEnabled then
        ApplyLocalChams()
    end
    
    if HubSettings.ChamsEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    local highlight = part:FindFirstChild("ChamHighlight")
                    if highlight then
                        local chamColor = HubSettings.ChamsRainbow and rainbowColor or HubSettings.ChamsColor
                        highlight.FillColor = chamColor
                        highlight.OutlineColor = chamColor
                    end
                end
            end
        end
    end
    
    if HubSettings.SkeletonEnabled then
        UpdateSkeletonESP()
    end
    
    if HubSettings.TriggerbotActive and not TriggerbotCooldown then
        local target = FindBestTargetSilent()
        if target then
            local success = pcall(function()
                local SignalManager = require(ReplicatedStorage:WaitForChild("SignalManager"))
                SignalManager.Fire("FireWeaponMoblie", Enum.UserInputState.End)
                task.delay(0.05, function()
                    SignalManager.Fire("FireWeaponMoblie", Enum.UserInputState.Begin)
                end)
            end)
            
            TriggerbotCooldown = true
            task.delay(HubSettings.TriggerbotDelay, function()
                TriggerbotCooldown = false
            end)
        end
    end

    if HubSettings.SnapLinesEnabled then
        local targetPlayer, head2D, center = GetClosestTargetForSnapline()
        if targetPlayer and head2D then
            local offset = head2D - center
            SnapLine.Visible = true
            SnapLine.BackgroundColor3 = currentEspColor
            SnapLine.Position = UDim2.fromOffset((center.X + head2D.X) / 2, (center.Y + head2D.Y) / 2)
            SnapLine.Size = UDim2.fromOffset(offset.Magnitude, 1)
            SnapLine.Rotation = math.deg(math.atan2(offset.Y, offset.X))
        else
            SnapLine.Visible = false
        end
    else
        SnapLine.Visible = false
    end

    local seen = {}
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not root or not head or IsOnTeam(player) then
            local cached = BoxEspCache[player]
            if cached then cached.Frame.Visible = false end
            continue
        end

        local rootVp, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not (onScreen and rootVp.Z > 0) then
            local cached = BoxEspCache[player]
            if cached then cached.Frame.Visible = false end
            continue
        end

        seen[player] = true

        local cached = BoxEspCache[player]
        if not cached then
            local playerBox = Instance.new("Frame")
            playerBox.Name = "Box_" .. player.Name
            playerBox.Parent = BoxContainer
            playerBox.BorderSizePixel = 0
            playerBox.BackgroundTransparency = 1

            local stroke = Instance.new("UIStroke")
            stroke.Name = "Stroke"
            stroke.Thickness = 1
            stroke.Parent = playerBox

            local nameTag = Instance.new("TextLabel")
            nameTag.Name = "NameTag"
            nameTag.Size = UDim2.new(1, 0, 0, 18)
            nameTag.Position = UDim2.new(0, 0, 0, -22)
            nameTag.BackgroundTransparency = 1
            nameTag.Font = Enum.Font.Code
            nameTag.TextSize = 14
            nameTag.TextXAlignment = Enum.TextXAlignment.Center
            nameTag.Parent = playerBox

            local distTag = Instance.new("TextLabel")
            distTag.Name = "DistTag"
            distTag.Size = UDim2.new(1, 0, 0, 18)
            distTag.Position = UDim2.new(0, 0, 1, 2)
            distTag.BackgroundTransparency = 1
            distTag.Font = Enum.Font.Code
            distTag.TextSize = 14
            distTag.TextXAlignment = Enum.TextXAlignment.Center
            distTag.Parent = playerBox

            cached = { Frame = playerBox, Stroke = stroke, NameTag = nameTag, DistTag = distTag }
            BoxEspCache[player] = cached
        end

        local frame = cached.Frame
        local stroke = cached.Stroke
        local nameTag = cached.NameTag
        local distTag = cached.DistTag

        if HubSettings.PlayerBoxEsp or HubSettings.NameTagsEnabled or HubSettings.ShowDistances then
            local z = math.max(rootVp.Z, 1)
            local boxSize = (Camera.ViewportSize.Y / z) * 2.5

            frame.Visible = true
            frame.Size = UDim2.new(0, boxSize, 0, boxSize * 1.5)
            frame.Position = UDim2.new(0, rootVp.X - (boxSize / 2), 0, rootVp.Y - (boxSize * 0.75))

            stroke.Enabled = HubSettings.PlayerBoxEsp
            stroke.Color = currentEspColor

            if HubSettings.PlayerBoxEsp and HubSettings.BoxFillEnabled then
                frame.BackgroundTransparency = 0.7
                frame.BackgroundColor3 = currentEspColor
            else
                frame.BackgroundTransparency = 1
            end

            nameTag.Visible = HubSettings.NameTagsEnabled
            nameTag.Text = player.Name
            nameTag.TextColor3 = currentEspColor

            distTag.Visible = HubSettings.ShowDistances
            distTag.TextColor3 = currentEspColor
            if HubSettings.ShowDistances and myRoot then
                local studs = (myRoot.Position - root.Position).Magnitude
                distTag.Text = string.format("%.0f studs", studs)
            else
                distTag.Text = ""
            end
        else
            frame.Visible = false
        end
    end

    for plr, cached in pairs(BoxEspCache) do
        if not seen[plr] and cached and cached.Frame then
            cached.Frame.Visible = false
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if HubSettings.ChamsEnabled and player ~= LocalPlayer then
            task.wait(0.5)
            CreateChams(char)
        end
    end)
end)

warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
warn("🧈 BUTER HUB v1.24 - Loaded!")
warn("🧈 ✅ Fixed: Magic Bullet, Instant Hit, No Recoil")
warn("🧈 ✅ Hooked: Projectile.Cast & CameraHandler.activeEffects")
warn("🧈 🎮 Press LEFT CTRL to toggle GUI")
warn("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
