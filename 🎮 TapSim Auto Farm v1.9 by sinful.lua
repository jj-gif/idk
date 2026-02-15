--[[
    TapSim Auto Farm v1.9 ULTIMATE
    by sinful
    
    🎮 COMPLETE AUTOMATION SUITE 🎮
    
    Features:
    - Auto-Clicking with rate control
    - Auto-Rebirth system
    - Auto-Egg Hatching (ultra-fast!)
    - Auto-Claim Block Essence
    - Auto-Buy Upgrades (gem shop)
    - Auto-Redeem Codes (on load)
    - Auto-Wheelspin (Festive & Void)
    - Critical Hit spam
    - Server Hop & Rejoin with auto-reload
    - Zone Teleport Dropdown (all 16 zones!)
    - Real-time statistics
    - Modern Fluent UI
    
    New in v1.7:
    - Zone teleport is now a full dropdown
    - Shows all 16 zones with their multipliers
    - Uses actual TeleportZone remote
    - Locked zones show notification
    
    New in v1.6:
    - Auto-Buy Gem Shop Upgrades
    - Auto-Redeem Codes
    - Auto-Wheelspin (Festive & Void wheels)
    
    New in v1.5:
    - Auto-Claim Block Essence
    
    New in v1.4:
    - Auto-reload after Server Hop/Rejoin
    
    Created: 2026-02-09
]]--

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Auto-reload support
-- Note: The script must be stored in _G.TapSimAutoFarm_ScriptSource on first execution
-- This is typically done by wrapping: _G.TapSimAutoFarm_ScriptSource = [[<script>]] loadstring(_G.TapSimAutoFarm_ScriptSource)()

local AUTO_RELOAD_KEY = "TapSim_AutoReload"

-- Check if we should auto-reload after teleport
if _G[AUTO_RELOAD_KEY] then
    _G[AUTO_RELOAD_KEY] = false
    
    print("[TapSim] Auto-reload detected, waiting for game to load...")
    
    task.spawn(function()
        -- Wait for game to be ready
        repeat task.wait(0.5) until game:IsLoaded()
        task.wait(2)
        
        print("[TapSim] Reloading script...")
        
        -- Reload the script
        local success, err = pcall(function()
            if _G.TapSimAutoFarm_ScriptSource then
                loadstring(_G.TapSimAutoFarm_ScriptSource)()
                print("[TapSim] Script reloaded successfully!")
            else
                warn("[TapSim] Auto-reload failed: Script source not found in _G.TapSimAutoFarm_ScriptSource")
                warn("[TapSim] Please re-execute the script manually or use auto-execute")
            end
        end)
        
        if not success then
            warn("[TapSim Auto-Reload Error]", err)
        end
    end)
    
    return -- Exit this instance
end
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Game Modules
local Network = require(ReplicatedStorage.Modules.Network)
local Replication = require(ReplicatedStorage.Game.Replication)
local Eggs = require(ReplicatedStorage.Game.Eggs)
local Rebirths = require(ReplicatedStorage.Game.Rebirths)

local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    AutoClick = false,
    AutoRebirth = false,
    AutoHatch = false,
    CriticalSpam = false,
    AutoClaimEssence = false,
    AutoUpgrades = false,
    AutoWheelspin = false,
    AutoCollectChests = false,
    AutoMinigame = false,
    AutoPetTreats = false,
    
    ClickDelay = 0.05,
    RebirthDelay = 2,
    HatchDelay = 0.5,
    EssenceClaimDelay = 3,  -- Re-scan for blocks every 3s
    UpgradeCheckDelay = 10,
    WheelspinDelay = 5,
    ChestCheckDelay = 30,
    MinigameCheckDelay = 15,  -- Check if minigame available every 15s
    TreatPurchaseDelay = 60,  -- Try to buy treats every 60s
    
    SelectedEgg = "Basic",
    EggAmount = 1,
    RebirthTier = 1,
    
    -- Code list (add codes here)
    CodeList = {
        "russo ",
        "lucky",
        "tacos",
        "enchant",
        "SPEEDYTOTEM",
        "LUCKYTOTEM",
        "TELEPORT",
    },
    
    -- Upgrade priorities (order matters)
    UpgradePriority = {"ClickMultiplier", "AutoClickerSpeed", "CriticalPower"},
}

-- Codes to auto-redeem (user can edit)
local DEFAULT_CODES = {
    -- Add known codes here, script will try to redeem
}

-- Statistics
local Stats = {
    TotalClicks = 0,
    TotalRebirths = 0,
    TotalEggsHatched = 0,
    MinigamesPlayed = 0,
    SessionStartTime = tick(),
    CurrentClicks = 0,
    CurrentRebirths = 0,
}

-- State
local LastClick = 0
local LastRebirth = 0
local LastHatch = 0
local LastEssenceClaim = 0
local LastUpgradeCheck = 0
local LastWheelspin = 0
local LastChestCheck = 0
local IsHatching = false
local HasTeleportedToEgg = false
local CodesRedeemed = false
local Connections = {}

-- Debug mode
local DEBUG = true

local function DebugPrint(...)
    if DEBUG then
        print("[DEBUG]", ...)
    end
end

-- Generate rebirth dropdown options
local function GenerateRebirthOptions()
    local options = {}
    for i = 1, 20 do -- First 20 tiers
        local rebirths = Rebirths:fromIndex(i)
        table.insert(options, string.format("%d Rebirths (Tier %d)", rebirths, i))
    end
    return options
end

-- Parse rebirth option back to tier
local function ParseRebirthOption(option)
    local tier = option:match("Tier (%d+)")
    return tonumber(tier) or 1
end

-- Get list of eggs
local function GetEggList()
    local eggList = {}
    for eggName, eggData in pairs(Eggs) do
        if type(eggData) == "table" and eggData.Price then
            table.insert(eggList, eggName)
        end
    end
    table.sort(eggList, function(a, b)
        local indexA = Eggs[a].Index or 999
        local indexB = Eggs[b].Index or 999
        return indexA < indexB
    end)
    return eggList
end

-- Teleport to egg machine
local function TeleportToEgg(eggName)
    local success, err = pcall(function()
        -- Find the egg machine in workspace
        local eggMachine = workspace.Eggs:FindFirstChild(eggName)
        
        if eggMachine then
            local eggPart = eggMachine:FindFirstChild("Egg") or eggMachine.PrimaryPart
            
            if eggPart and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                -- Teleport character in front of the egg
                local targetPos = eggPart.Position + Vector3.new(0, 0, 5)
                LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(targetPos))
                
                DebugPrint("Teleported to", eggName, "egg machine")
                
                Fluent:Notify({
                    Title = "Auto-Hatch",
                    Content = "Teleported to " .. eggName .. " egg!",
                    Duration = 3
                })
                
                HasTeleportedToEgg = true
                return true
            else
                DebugPrint("Egg machine found but no valid parts")
                return false
            end
        else
            DebugPrint("Egg machine not found:", eggName)
            
            Fluent:Notify({
                Title = "Auto-Hatch Error",
                Content = "Couldn't find " .. eggName .. " egg machine!",
                Duration = 5
            })
            
            return false
        end
    end)
    
    if not success then
        warn("[Teleport Error]", err)
        return false
    end
    
    return success
end

-- Update statistics
local function UpdateStats()
    if Replication.Loaded and Replication.Data then
        Stats.CurrentClicks = Replication.Data.Statistics.Clicks or 0
        Stats.CurrentRebirths = Replication.Data.Statistics.Rebirths or 0
    end
end

-- Auto-Click Function
local function AutoClick()
    if not Config.AutoClick then return end
    
    local currentTime = tick()
    if currentTime - LastClick >= Config.ClickDelay then
        LastClick = currentTime
        
        local success, err = pcall(function()
            Network:FireServer("Tap", true, true, Config.CriticalSpam)
            Stats.TotalClicks = Stats.TotalClicks + 1
        end)
        
        if not success then
            DebugPrint("Auto-Click Error:", err)
        end
    end
end

-- Auto-Rebirth Function (FIXED)
local function AutoRebirth()
    if not Config.AutoRebirth then return end
    if not Replication.Loaded then return end
    
    local currentTime = tick()
    if currentTime - LastRebirth >= Config.RebirthDelay then
        LastRebirth = currentTime
        
        local success, result = pcall(function()
            local data = Replication.Data
            if not data then 
                DebugPrint("No replication data")
                return false
            end
            
            local tier = Config.RebirthTier
            local basePrice = Rebirths:fromIndex(tier)
            local currentRebirths = data.Statistics.Rebirths or 0
            local price = Rebirths:ClicksPrice(basePrice, currentRebirths)
            local currentClicks = data.Statistics.Clicks or 0
            
            DebugPrint("Rebirth Check:", "Tier", tier, "Need", price, "Have", currentClicks)
            
            if currentClicks >= price then
                DebugPrint("Attempting rebirth...")
                
                -- FIXED: Call with just tier number, second param should be nil for manual mode
                local rebirthSuccess = Network:InvokeServer("Rebirth", tier)
                
                DebugPrint("Rebirth result:", rebirthSuccess)
                
                if rebirthSuccess then
                    Stats.TotalRebirths = Stats.TotalRebirths + 1
                    
                    Fluent:Notify({
                        Title = "Auto-Rebirth",
                        Content = "Successfully rebirthed to tier " .. tier .. "!",
                        Duration = 3
                    })
                    
                    return true
                else
                    DebugPrint("Rebirth failed - server returned false")
                end
            else
                local needed = price - currentClicks
                DebugPrint("Not enough clicks, need", needed, "more")
            end
            
            return false
        end)
        
        if not success then
            warn("[Auto-Rebirth Error]", result)
            Fluent:Notify({
                Title = "Auto-Rebirth Error",
                Content = tostring(result),
                Duration = 5
            })
        end
    end
end

-- Auto-Hatch Function (FIXED)
local function AutoHatch()
    if not Config.AutoHatch then return end
    if not Replication.Loaded then return end
    if IsHatching then return end
    
    -- Teleport to egg once when first enabled (if not already teleported)
    if not HasTeleportedToEgg then
        TeleportToEgg(Config.SelectedEgg)
        task.wait(0.5) -- Wait a moment after teleporting
    end
    
    local currentTime = tick()
    if currentTime - LastHatch >= Config.HatchDelay then
        LastHatch = currentTime
        
        local success, result = pcall(function()
            local eggName = Config.SelectedEgg
            local buttonType = Config.EggAmount  -- 1, 2, or 3 (not egg count!)
            local eggData = Eggs[eggName]
            
            if not eggData then 
                DebugPrint("Invalid egg:", eggName)
                return false
            end
            
            local data = Replication.Data
            if not data then 
                DebugPrint("No replication data")
                return false
            end
            
            -- Calculate cost based on button type
            local eggCount = buttonType == 1 and 1 or (buttonType == 2 and 3 or 8)
            local currency = eggData.Currency or "Clicks"
            local price = eggData.Price * eggCount
            local currentAmount = data.Statistics[currency] or 0
            
            DebugPrint("Hatch Check:", eggName, "ButtonType:", buttonType, "Count:", eggCount, "Need:", price, currency, "Have:", currentAmount)
            
            if currentAmount >= price then
                IsHatching = true
                DebugPrint("Attempting to hatch...")
                
                -- FIXED: Pass button type (1, 2, 3) and nil as third parameter
                local hatchResult = Network:InvokeServer("OpenEgg", eggName, buttonType, nil)
                
                DebugPrint("Hatch result type:", typeof(hatchResult))
                
                if typeof(hatchResult) == "table" then
                    Stats.TotalEggsHatched = Stats.TotalEggsHatched + eggCount
                    
                    DebugPrint("Hatched successfully! Got", #hatchResult, "pets")
                    
                    -- Don't wait for animation, hatch next immediately
                    IsHatching = false
                    return true
                    
                elseif typeof(hatchResult) == "string" then
                    -- Server returned an error message
                    DebugPrint("Hatch failed:", hatchResult)
                    
                    if hatchResult == "broke" then
                        local needed = price - currentAmount
                        Fluent:Notify({
                            Title = "Auto-Hatch",
                            Content = "Need " .. needed .. " more " .. currency,
                            Duration = 3
                        })
                    else
                        Fluent:Notify({
                            Title = "Auto-Hatch Error",
                            Content = hatchResult,
                            Duration = 3
                        })
                    end
                    
                    IsHatching = false
                    return false
                else
                    DebugPrint("Unexpected result type:", typeof(hatchResult))
                    IsHatching = false
                    return false
                end
            else
                local needed = price - currentAmount
                DebugPrint("Not enough", currency .. ", need", needed, "more")
            end
            
            IsHatching = false
            return false
        end)
        
        if not success then
            warn("[Auto-Hatch Error]", result)
            IsHatching = false
            Fluent:Notify({
                Title = "Auto-Hatch Error",
                Content = tostring(result),
                Duration = 5
            })
        end
    end
end

-- Auto-Claim Block Essence (teleport to each block and collect)
local IsCollectingEssence = false

local function AutoClaimEssence()
    if not Config.AutoClaimEssence then return end
    if IsCollectingEssence then return end -- Prevent overlap
    
    local currentTime = tick()
    if currentTime - LastEssenceClaim < Config.EssenceClaimDelay then return end
    
    IsCollectingEssence = true
    LastEssenceClaim = currentTime
    
    task.spawn(function()
        pcall(function()
            local CollectionService = game:GetService("CollectionService")
            
            -- Find ALL block essence using the CollectionService tag
            local blocks = CollectionService:GetTagged("BlockEssence")
            
            if #blocks == 0 then
                DebugPrint("No BlockEssence found in workspace")
                IsCollectingEssence = false
                return
            end
            
            DebugPrint("Found", #blocks, "block essence to collect")
            
            local collected = 0
            
            for _, block in ipairs(blocks) do
                -- Skip if block was destroyed while we were collecting others
                if not block or not block.Parent then continue end
                if not Config.AutoClaimEssence then break end -- Stop if toggled off
                
                local blockPart = block.PrimaryPart or block:FindFirstChildWhichIsA("BasePart")
                if not blockPart then continue end
                
                local targetPos = blockPart.Position
                
                -- Teleport character to the block
                if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                    LocalPlayer.Character:SetPrimaryPartCFrame(
                        CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    )
                    
                    task.wait(0.1) -- Brief wait after teleport
                    
                    -- Fire the claim remote directly (we're within range now)
                    local success, result = pcall(function()
                        Network:FireServer("ClaimBlockEssence", block)
                    end)
                    
                    if success then
                        collected = collected + 1
                        DebugPrint("Collected essence block:", block:GetAttribute("EssenceType") or "Normal")
                    end
                    
                    task.wait(0.15) -- Small delay between blocks
                end
            end
            
            if collected > 0 then
                DebugPrint("Collected", collected, "essence blocks!")
            end
        end)
        
        IsCollectingEssence = false
    end)
end

-- Chest Data (from ReplicatedStorage.Game.Chests)
local CHEST_DATA = {
    ["FirstChest"]  = { cooldown = 7200  },  -- 2 hours
    ["ClicksChest"] = { cooldown = 14400 },  -- 4 hours
    ["CryoChest"]   = { cooldown = 14400 },  -- 4 hours
}

-- Auto-Collect Chests (uses ProximityPrompt trigger via CollectionService tag)
local IsCollectingChests = false

local function AutoCollectChests()
    if not Config.AutoCollectChests then return end
    if IsCollectingChests then return end

    local currentTime = tick()
    if currentTime - LastChestCheck < Config.ChestCheckDelay then return end
    LastChestCheck = currentTime

    IsCollectingChests = true

    task.spawn(function()
        pcall(function()
            if not Replication.Loaded then
                IsCollectingChests = false
                return
            end

            local CollectionService = game:GetService("CollectionService")
            local chestParts = CollectionService:GetTagged("ChestInteraction")

            if #chestParts == 0 then
                DebugPrint("No ChestInteraction parts found")
                IsCollectingChests = false
                return
            end

            local collected = 0

            for _, part in ipairs(chestParts) do
                if not part or not part.Parent then continue end
                if not Config.AutoCollectChests then break end

                local chestName = part:GetAttribute("Chest")
                if not chestName then continue end

                local chestConfig = CHEST_DATA[chestName]
                if not chestConfig then continue end

                -- Check cooldown using player data
                local lastClaim = Replication.Data.Chests and Replication.Data.Chests[chestName]
                local isReady = not lastClaim or (os.time() - lastClaim >= chestConfig.cooldown)

                if not isReady then
                    DebugPrint("Chest on cooldown:", chestName)
                    continue
                end

                -- Find the ProximityPrompt on the chest
                local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)

                if prompt then
                    -- Trigger the proximity prompt directly
                    local success = pcall(function()
                        game:GetService("ProximityPromptService"):TriggerPrompt(prompt)
                    end)

                    if success then
                        collected = collected + 1
                        DebugPrint("Triggered chest:", chestName)
                        task.wait(0.5)
                    end
                else
                    -- Fallback: fire the network remote directly
                    local success = pcall(function()
                        Network:InvokeServer("OpenChest", chestName)
                    end)
                    if success then
                        collected = collected + 1
                        DebugPrint("Opened chest via remote:", chestName)
                        task.wait(0.5)
                    end
                end
            end

            if collected > 0 then
                Fluent:Notify({
                    Title = "Chests Collected!",
                    Content = "Collected " .. collected .. " chest(s)!",
                    Duration = 3
                })
            end
        end)

        IsCollectingChests = false
    end)
end

-- ============================================================
-- AUTO-MINIGAME (DigGame)
-- Remotes: StartMinigame("DigGame") -> FinishMinigame("DigGame")
-- Cooldown: MinigameCooldown.Time resets hourly, Counter < Max
-- Must be within 90 studs of workspace.Game.DigParts.DigPart
-- ============================================================

local IsRunningMinigame = false
local LastMinigameCheck = 0

local function GetDigPart()
    local gameFolder = workspace:FindFirstChild("Game")
    if gameFolder then
        local digParts = gameFolder:FindFirstChild("DigParts")
        if digParts then
            return digParts:FindFirstChild("DigPart")
        end
    end
    return nil
end

local function IsMinigameAvailable()
    if not Replication.Loaded then return false end
    local cd = Replication.Data.MinigameCooldown
    if not cd then return false end
    local hourReset = os.time() - cd.Time > 3600
    return cd.Time == 0 or hourReset or cd.Counter < cd.Max
end

local function AutoMinigame()
    if not Config.AutoMinigame then return end
    if IsRunningMinigame then return end

    local currentTime = tick()
    if currentTime - LastMinigameCheck < Config.MinigameCheckDelay then return end
    LastMinigameCheck = currentTime

    if not IsMinigameAvailable() then
        DebugPrint("Minigame on cooldown")
        return
    end

    local digPart = GetDigPart()
    if not digPart then
        DebugPrint("No DigPart found in workspace.Game.DigParts")
        return
    end

    IsRunningMinigame = true

    task.spawn(function()
        pcall(function()
            -- Teleport to dig spot if we're too far
            if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                local dist = (LocalPlayer.Character.PrimaryPart.Position - digPart.Position).Magnitude
                if dist > 80 then
                    LocalPlayer.Character:SetPrimaryPartCFrame(
                        CFrame.new(digPart.Position + Vector3.new(0, 5, 0))
                    )
                    task.wait(0.3)
                end
            end

            -- Start the minigame - server gives us the reward item name
            local itemName = Network:InvokeServer("StartMinigame", "DigGame")
            if not itemName then
                DebugPrint("StartMinigame returned nil - may be on cooldown or unavailable")
                IsRunningMinigame = false
                return
            end

            DebugPrint("Minigame started! Reward:", itemName)
            task.wait(0.5)

            -- Immediately finish to claim the reward
            local reward = Network:InvokeServer("FinishMinigame", "DigGame")
            if reward then
                Stats.MinigamesPlayed = (Stats.MinigamesPlayed or 0) + 1
                Fluent:Notify({
                    Title = "⛏️ Minigame Complete!",
                    Content = "Reward: " .. tostring(itemName) .. " (Play #" .. (Stats.MinigamesPlayed or 1) .. ")",
                    Duration = 4
                })
            else
                DebugPrint("FinishMinigame returned nil/false")
            end
        end)
        IsRunningMinigame = false
    end)
end

-- ============================================================
-- AUTO-PET TREATS SHOP
-- Remote: InvokeServer("PurchasePetTreat", treatName)
-- Returns: true (success), "out_of_stock", false (no currency)
-- Restocks every 24h | Only in Trading Plaza world
-- ============================================================

local PET_TREAT_NAMES = { "RegularTreat", "BagOfTreats" }
local LastTreatPurchase = 0

local function AutoPetTreats()
    if not Config.AutoPetTreats then return end

    local currentTime = tick()
    if currentTime - LastTreatPurchase < Config.TreatPurchaseDelay then return end
    LastTreatPurchase = currentTime

    task.spawn(function()
        pcall(function()
            if not Replication.Loaded then return end

            local purchased = 0
            for _, treatName in ipairs(PET_TREAT_NAMES) do
                local result = Network:InvokeServer("PurchasePetTreat", treatName)
                if result == true then
                    purchased = purchased + 1
                    DebugPrint("Purchased treat:", treatName)
                    task.wait(0.3)
                elseif result == "out_of_stock" then
                    DebugPrint("Out of stock:", treatName)
                else
                    DebugPrint("Cannot afford treat:", treatName)
                    break
                end
            end

            if purchased > 0 then
                Fluent:Notify({
                    Title = "🐾 Pet Treats Bought!",
                    Content = "Purchased " .. purchased .. " treat(s)!",
                    Duration = 3
                })
            end
        end)
    end)
end

local ZONES = {
    { name = "Forest",      multi = 1.1,   order = 1  },
    { name = "Winter",      multi = 1.25,  order = 2  },
    { name = "Desert",      multi = 1.5,   order = 3  },
    { name = "Jungle",      multi = 1.75,  order = 4  },
    { name = "Heaven",      multi = 2.0,   order = 5  },
    { name = "Dojo",        multi = 2.5,   order = 6  },
    { name = "Volcano",     multi = 2.75,  order = 7  },
    { name = "Candy",       multi = 3.0,   order = 8  },
    { name = "Atlantis",    multi = 3.25,  order = 9  },
    { name = "Space",       multi = 4.0,   order = 10 },
    { name = "Kryo",        multi = 5.0,   order = 11 },
    { name = "Magma",       multi = 6.5,   order = 12 },
    { name = "Celestial",   multi = 7.5,   order = 13 },
    { name = "Holographic", multi = 8.5,   order = 14 },
    { name = "Lunar",       multi = 9.5,   order = 15 },
    { name = "Cyberpunk",   multi = 10.5,  order = 16 },
}

-- Build dropdown options list
local function GetZoneOptions()
    local options = {"Spawn"}
    for _, zone in ipairs(ZONES) do
        table.insert(options, zone.name .. " (" .. zone.multi .. "x)")
    end
    return options
end

-- Parse zone name from dropdown option
local function ParseZoneName(option)
    if option == "Spawn" then return "Spawn" end
    return option:match("^(%w+)%s%(")
end

-- Teleport to Zone
local function TeleportToZone(zoneName)
    pcall(function()
        if zoneName == "Spawn" then
            -- Teleport back to spawn point
            local tpPoint = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("TpPoint")
            if tpPoint and LocalPlayer.Character then
                LocalPlayer.Character:SetPrimaryPartCFrame(tpPoint.CFrame)
                Fluent:Notify({ Title = "Teleport", Content = "Teleported to Spawn!", Duration = 3 })
            end
            return
        end
        
        -- Check if player has unlocked this zone
        local unlocked = Replication.Loaded and Replication.Data.Portals and Replication.Data.Portals[zoneName]
        
        if not unlocked then
            Fluent:Notify({
                Title = "Zone Locked",
                Content = zoneName .. " is not unlocked yet!",
                Duration = 3
            })
            return
        end
        
        -- Use the game's teleport remote
        local success, result = pcall(function()
            return Network:InvokeServer("TeleportZone", zoneName)
        end)
        
        if success and result then
            -- Also physically teleport character to zone portal
            local zonesFolder = workspace:FindFirstChild("Zones")
            if zonesFolder then
                local portalsFolder = zonesFolder:FindFirstChild("Portals")
                if portalsFolder then
                    local zoneFolder = portalsFolder:FindFirstChild(zoneName)
                    if zoneFolder then
                        local tp = zoneFolder:FindFirstChild("TP")
                        local portal = zoneFolder:FindFirstChild("Portal")
                        local targetCFrame = nil
                        
                        if tp then
                            targetCFrame = tp.CFrame
                        elseif portal and portal:FindFirstChild("Portal") then
                            targetCFrame = portal.Portal.CFrame + portal.Portal.CFrame.RightVector * 18
                        end
                        
                        if targetCFrame and LocalPlayer.Character then
                            LocalPlayer.Character:SetPrimaryPartCFrame(targetCFrame)
                        end
                    end
                end
            end
            
            Fluent:Notify({
                Title = "Teleported!",
                Content = "Now in " .. zoneName .. " zone!",
                Duration = 3
            })
            DebugPrint("Teleported to zone:", zoneName)
        else
            Fluent:Notify({
                Title = "Teleport Failed",
                Content = "Could not teleport to " .. zoneName,
                Duration = 3
            })
        end
    end)
end

-- Auto-Redeem Codes (One-time on load)
local function RedeemAllCodes()
    if CodesRedeemed then return end
    CodesRedeemed = true
    
    task.spawn(function()
        -- Wait for data to load
        repeat task.wait(0.5) until Replication.Loaded
        
        DebugPrint("Starting code redemption...")
        
        -- Combine default codes and user codes
        local allCodes = {}
        for _, code in ipairs(DEFAULT_CODES) do
            table.insert(allCodes, code)
        end
        for _, code in ipairs(Config.CodeList) do
            table.insert(allCodes, code)
        end
        
        local successCount = 0
        local alreadyClaimedCount = 0
        
        for _, code in ipairs(allCodes) do
            -- Check if already claimed
            local alreadyClaimed = Replication.Data.Codes and Replication.Data.Codes[string.lower(code)]
            
            if not alreadyClaimed then
                local success, result = pcall(function()
                    return Network:InvokeServer("RedeemCode", code)
                end)
                
                if success then
                    if typeof(result) == "table" then
                        successCount = successCount + 1
                        DebugPrint("Redeemed code:", code)
                    elseif result == "ALREADY CLAIMED" then
                        alreadyClaimedCount = alreadyClaimedCount + 1
                    elseif result == "INVALID" then
                        DebugPrint("Invalid code:", code)
                    end
                end
                
                task.wait(1) -- Delay between codes
            else
                alreadyClaimedCount = alreadyClaimedCount + 1
            end
        end
        
        if successCount > 0 then
            Fluent:Notify({
                Title = "Codes Redeemed",
                Content = "Successfully redeemed " .. successCount .. " codes!",
                Duration = 5
            })
        end
        
        DebugPrint("Code redemption complete:", successCount, "new,", alreadyClaimedCount, "already claimed")
    end)
end

-- Auto-Upgrade Purchaser
local function AutoUpgrades()
    if not Config.AutoUpgrades then return end
    
    local currentTime = tick()
    if currentTime - LastUpgradeCheck >= Config.UpgradeCheckDelay then
        LastUpgradeCheck = currentTime
        
        pcall(function()
            if not Replication.Loaded then return end
            
            local currentGems = Replication.Data.Statistics.Gems or 0
            
            -- Try upgrades in priority order
            for _, upgradeName in ipairs(Config.UpgradePriority) do
                -- Try to purchase upgrade
                local success, result = pcall(function()
                    return Network:InvokeServer("UpgradeGemShop", upgradeName, nil)
                end)
                
                if success and result == true then
                    DebugPrint("Purchased upgrade:", upgradeName)
                    
                    Fluent:Notify({
                        Title = "Auto-Upgrade",
                        Content = "Purchased: " .. upgradeName,
                        Duration = 2
                    })
                    
                    -- Only buy one upgrade per check
                    break
                end
            end
        end)
    end
end

-- Auto-Wheelspin
local function AutoWheelspin()
    if not Config.AutoWheelspin then return end
    
    local currentTime = tick()
    if currentTime - LastWheelspin >= Config.WheelspinDelay then
        LastWheelspin = currentTime
        
        pcall(function()
            if not Replication.Loaded then return end
            
            local items = Replication.Data.Items
            if not items then return end
            
            -- Try Festive Wheelspin
            if items.ChristmasSpins and items.ChristmasSpins > 0 then
                local success, result = pcall(function()
                    return Network:InvokeServer("SpinWheel", "FestiveSpinWheel")
                end)
                
                if success and result then
                    DebugPrint("Spun Festive Wheel! Remaining:", result[2])
                    return
                end
            end
            
            -- Try Void Wheelspin
            if items.VoidSpins and items.VoidSpins > 0 then
                local success, result = pcall(function()
                    return Network:InvokeServer("SpinWheel", "VoidSpinWheel")
                end)
                
                if success and result then
                    DebugPrint("Spun Void Wheel! Remaining:", result[2])
                    return
                end
            end
        end)
    end
end

-- Start/Stop Functions
local function StartAutoFarm()
    -- Redeem codes once on start
    RedeemAllCodes()
    
    -- Auto-Click Loop
    Connections.Click = RunService.Heartbeat:Connect(function()
        pcall(AutoClick)
    end)
    
    -- Auto-Rebirth Loop
    Connections.Rebirth = RunService.Heartbeat:Connect(function()
        pcall(AutoRebirth)
    end)
    
    -- Auto-Hatch Loop
    Connections.Hatch = RunService.Heartbeat:Connect(function()
        pcall(AutoHatch)
    end)
    
    -- Auto-Claim Essence Loop
    Connections.Essence = RunService.Heartbeat:Connect(function()
        pcall(AutoClaimEssence)
    end)
    
    -- Auto-Upgrade Loop
    Connections.Upgrades = RunService.Heartbeat:Connect(function()
        pcall(AutoUpgrades)
    end)
    
    -- Auto-Wheelspin Loop
    Connections.Wheelspin = RunService.Heartbeat:Connect(function()
        pcall(AutoWheelspin)
    end)
    
    -- Auto-Collect Chests Loop
    Connections.Chests = RunService.Heartbeat:Connect(function()
        pcall(AutoCollectChests)
    end)

    -- Auto-Minigame Loop
    Connections.Minigame = RunService.Heartbeat:Connect(function()
        pcall(AutoMinigame)
    end)

    -- Auto-Pet Treats Loop
    Connections.PetTreats = RunService.Heartbeat:Connect(function()
        pcall(AutoPetTreats)
    end)
    
    -- Stats Update Loop
    Connections.Stats = RunService.Heartbeat:Connect(function()
        pcall(UpdateStats)
    end)
end

local function StopAutoFarm()
    for _, connection in pairs(Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    Connections = {}
end

-- Create Fluent Window
local Window = Fluent:CreateWindow({
    Title = "TapSim Auto Farm v1.9 ULTIMATE",
    SubTitle = "by sinful",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    AutoFarm = Window:AddTab({ Title = "Auto-Farm", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Stats = Window:AddTab({ Title = "Statistics", Icon = "bar-chart-2" }),
}

-- ═══════════════════════════════════════════════════════════
-- MAIN TAB
-- ═══════════════════════════════════════════════════════════

Tabs.Main:AddParagraph({
    Title = "Welcome to TapSim Auto Farm!",
    Content = "Complete automation for TapSim. Enable features in the Auto-Farm tab, configure settings in Settings tab, and monitor your progress in Statistics. Created by sinful.\n\n✨ NEW: Server Hop & Rejoin will auto-reload the script!"
})

Tabs.Main:AddParagraph({
    Title = "⚠️ Auto-Reload Setup (One-Time)",
    Content = "For auto-reload to work after Server Hop/Rejoin:\n1. Use an auto-execute script manager, OR\n2. Wrap the script like this:\n_G.TapSimAutoFarm_ScriptSource = [[<paste script here>]]\nloadstring(_G.TapSimAutoFarm_ScriptSource)()\n\nThis stores the script for automatic reloading!"
})

local MainSection = Tabs.Main:AddSection("Quick Actions")

MainSection:AddButton({
    Title = "Start All Auto-Farm Features",
    Description = "Enable Auto-Click, Auto-Rebirth, and Auto-Hatch",
    Callback = function()
        Config.AutoClick = true
        Config.AutoRebirth = true
        Config.AutoHatch = true
        
        Fluent:Notify({
            Title = "Auto-Farm",
            Content = "All features enabled!",
            Duration = 3
        })
    end
})

MainSection:AddButton({
    Title = "Stop All Auto-Farm Features",
    Description = "Disable all automation",
    Callback = function()
        Config.AutoClick = false
        Config.AutoRebirth = false
        Config.AutoHatch = false
        
        Fluent:Notify({
            Title = "Auto-Farm",
            Content = "All features disabled!",
            Duration = 3
        })
    end
})

local DebugSection = Tabs.Main:AddSection("Debug & Testing")

DebugSection:AddButton({
    Title = "Test Rebirth (Manual)",
    Description = "Try to rebirth once manually",
    Callback = function()
        local tier = Config.RebirthTier
        DebugPrint("Manual rebirth test, tier:", tier)
        
        local success, result = pcall(function()
            return Network:InvokeServer("Rebirth", tier)
        end)
        
        if success then
            Fluent:Notify({
                Title = "Rebirth Test",
                Content = "Result: " .. tostring(result),
                Duration = 5
            })
        else
            Fluent:Notify({
                Title = "Rebirth Test Failed",
                Content = tostring(result),
                Duration = 5
            })
        end
    end
})

DebugSection:AddButton({
    Title = "Test Egg Hatch (Manual)",
    Description = "Try to hatch egg once manually",
    Callback = function()
        local eggName = Config.SelectedEgg
        local buttonType = Config.EggAmount  -- 1, 2, or 3
        DebugPrint("Manual hatch test:", eggName, "ButtonType:", buttonType)
        
        local success, result = pcall(function()
            return Network:InvokeServer("OpenEgg", eggName, buttonType, nil)
        end)
        
        if success then
            Fluent:Notify({
                Title = "Hatch Test",
                Content = "Result type: " .. typeof(result),
                Duration = 5
            })
            DebugPrint("Hatch test result:", result)
        else
            Fluent:Notify({
                Title = "Hatch Test Failed",
                Content = tostring(result),
                Duration = 5
            })
        end
    end
})

DebugSection:AddButton({
    Title = "Teleport to Selected Egg",
    Description = "Manually teleport to the selected egg machine",
    Callback = function()
        TeleportToEgg(Config.SelectedEgg)
    end
})

DebugSection:AddToggle("DebugMode", {
    Title = "Debug Mode",
    Description = "Show debug messages in console",
    Default = true,
    Callback = function(Value)
        DEBUG = Value
        DebugPrint("Debug mode:", Value)
    end
})

-- ═══════════════════════════════════════════════════════════
-- AUTO-FARM TAB
-- ═══════════════════════════════════════════════════════════

local ClickSection = Tabs.AutoFarm:AddSection("Auto-Clicking")

local AutoClickToggle = ClickSection:AddToggle("AutoClick", {
    Title = "Auto-Click",
    Description = "Automatically click to earn currency",
    Default = false,
    Callback = function(Value)
        Config.AutoClick = Value
        
        Fluent:Notify({
            Title = "Auto-Click",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2
        })
    end
})

local CriticalToggle = ClickSection:AddToggle("CriticalSpam", {
    Title = "Critical Hit Spam",
    Description = "Every click is critical (10x multiplier)",
    Default = false,
    Callback = function(Value)
        Config.CriticalSpam = Value
        
        Fluent:Notify({
            Title = "Critical Spam",
            Content = Value and "Enabled (10x multiplier!)" or "Disabled",
            Duration = 2
        })
    end
})

local RebirthSection = Tabs.AutoFarm:AddSection("Auto-Rebirth")

RebirthSection:AddParagraph({
    Title = "Note",
    Content = "Auto-rebirth will attempt to rebirth when you have enough clicks. Check the Statistics tab to see when the next rebirth is possible."
})

local AutoRebirthToggle = RebirthSection:AddToggle("AutoRebirth", {
    Title = "Auto-Rebirth",
    Description = "Automatically rebirth when possible",
    Default = false,
    Callback = function(Value)
        Config.AutoRebirth = Value
        
        Fluent:Notify({
            Title = "Auto-Rebirth",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2
        })
    end
})

RebirthSection:AddDropdown("RebirthSelect", {
    Title = "Rebirth Amount",
    Description = "Select how many rebirths to automatically purchase",
    Values = GenerateRebirthOptions(),
    Default = "1 Rebirths (Tier 1)",
    Callback = function(Value)
        Config.RebirthTier = ParseRebirthOption(Value)
        local rebirths = Rebirths:fromIndex(Config.RebirthTier)
        DebugPrint("Rebirth selection:", rebirths, "rebirths (Tier", Config.RebirthTier .. ")")
        
        Fluent:Notify({
            Title = "Rebirth Selection",
            Content = "Will rebirth for " .. rebirths .. " rebirths",
            Duration = 2
        })
    end
})

local HatchSection = Tabs.AutoFarm:AddSection("Auto-Egg Hatching")

HatchSection:AddParagraph({
    Title = "Note",
    Content = "Auto-hatch will automatically open eggs when you have enough currency. Make sure you have enough clicks/gems before enabling."
})

local AutoHatchToggle = HatchSection:AddToggle("AutoHatch", {
    Title = "Auto-Hatch Eggs",
    Description = "Automatically open eggs",
    Default = false,
    Callback = function(Value)
        Config.AutoHatch = Value
        
        if not Value then
            -- Reset teleport flag when disabled
            HasTeleportedToEgg = false
        end
        
        Fluent:Notify({
            Title = "Auto-Hatch",
            Content = Value and "Enabled - Will teleport to egg!" or "Disabled",
            Duration = 2
        })
    end
})

HatchSection:AddDropdown("EggSelect", {
    Title = "Select Egg",
    Description = "Choose which egg to hatch",
    Values = GetEggList(),
    Default = "Basic",
    Callback = function(Value)
        Config.SelectedEgg = Value
        HasTeleportedToEgg = false -- Reset teleport flag when egg changes
        
        local eggData = Eggs[Value]
        if eggData then
            local price = eggData.Price
            local currency = eggData.Currency or "Clicks"
            Fluent:Notify({
                Title = "Egg Selected",
                Content = Value .. " (" .. price .. " " .. currency .. ")",
                Duration = 3
            })
        end
    end
})

HatchSection:AddDropdown("EggAmount", {
    Title = "Egg Amount",
    Description = "How many eggs to hatch at once",
    Values = {"1 Egg (Single)", "3 Eggs (Double)", "8 Eggs (Triple)"},
    Default = "1 Egg (Single)",
    Callback = function(Value)
        -- Convert display text to button type (1, 2, 3)
        if Value == "1 Egg (Single)" then
            Config.EggAmount = 1
        elseif Value == "3 Eggs (Double)" then
            Config.EggAmount = 2
        elseif Value == "8 Eggs (Triple)" then
            Config.EggAmount = 3
        end
        DebugPrint("Egg button type set to:", Config.EggAmount)
    end
})

local EssenceSection = Tabs.AutoFarm:AddSection("Auto-Claim Features")

local AutoEssenceToggle = EssenceSection:AddToggle("AutoClaimEssence", {
    Title = "Auto-Claim Block Essence",
    Description = "Automatically claim nearby block essence",
    Default = false,
    Callback = function(Value)
        Config.AutoClaimEssence = Value
        
        Fluent:Notify({
            Title = "Auto-Claim Essence",
            Content = Value and "Enabled - Will claim nearby blocks!" or "Disabled",
            Duration = 2
        })
    end
})

EssenceSection:AddParagraph({
    Title = "How it works",
    Content = "Auto-claim teleports to every block essence on the map and collects it automatically. Scans every 3 seconds for new blocks."
})

local UtilitySection = Tabs.AutoFarm:AddSection("Utility Functions")

UtilitySection:AddToggle("AutoCollectChests", {
    Title = "Auto-Collect Chests",
    Description = "Auto-claim FirstChest, ClicksChest & CryoChest when ready",
    Default = false,
    Callback = function(Value)
        Config.AutoCollectChests = Value
        Fluent:Notify({
            Title = "Auto-Collect Chests",
            Content = Value and "Enabled - Checks every 30 seconds!" or "Disabled",
            Duration = 2
        })
    end
})

UtilitySection:AddToggle("AutoMinigame", {
    Title = "Auto-Minigame (Dig Game)",
    Description = "Auto-teleport to dig spot & complete minigame for treats",
    Default = false,
    Callback = function(Value)
        Config.AutoMinigame = Value
        Fluent:Notify({
            Title = "Auto-Minigame",
            Content = Value and "Enabled - Will play when cooldown resets!" or "Disabled",
            Duration = 2
        })
    end
})

UtilitySection:AddToggle("AutoPetTreats", {
    Title = "Auto-Buy Pet Treats",
    Description = "Auto-purchase RegularTreat & BagOfTreats (Trading Plaza only)",
    Default = false,
    Callback = function(Value)
        Config.AutoPetTreats = Value
        Fluent:Notify({
            Title = "Auto-Pet Treats",
            Content = Value and "Enabled - Must be in Trading Plaza!" or "Disabled",
            Duration = 2
        })
    end
})

UtilitySection:AddToggle("AutoUpgrades", {
    Title = "Auto-Buy Upgrades",
    Description = "Automatically purchase gem shop upgrades",
    Default = false,
    Callback = function(Value)
        Config.AutoUpgrades = Value
        
        Fluent:Notify({
            Title = "Auto-Upgrades",
            Content = Value and "Enabled - Will buy upgrades!" or "Disabled",
            Duration = 2
        })
    end
})

UtilitySection:AddToggle("AutoWheelspin", {
    Title = "Auto-Wheelspin",
    Description = "Automatically spin Festive/Void wheels when available",
    Default = false,
    Callback = function(Value)
        Config.AutoWheelspin = Value
        
        Fluent:Notify({
            Title = "Auto-Wheelspin",
            Content = Value and "Enabled - Will auto-spin!" or "Disabled",
            Duration = 2
        })
    end
})

UtilitySection:AddButton({
    Title = "Redeem Codes Manually",
    Description = "Manually trigger code redemption",
    Callback = function()
        CodesRedeemed = false
        RedeemAllCodes()
    end
})

UtilitySection:AddDropdown("ZoneTeleport", {
    Title = "Teleport to Zone",
    Description = "Select a zone to teleport to",
    Values = GetZoneOptions(),
    Default = "Spawn",
    Callback = function(Value)
        local zoneName = ParseZoneName(Value)
        if zoneName then
            TeleportToZone(zoneName)
        end
    end
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

local ClickSettings = Tabs.Settings:AddSection("Click Settings")

ClickSettings:AddSlider("ClickDelay", {
    Title = "Click Delay",
    Description = "Delay between clicks (lower = faster)",
    Default = 0.05,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Config.ClickDelay = Value
        
        local cps = math.floor(1 / Value)
        Fluent:Notify({
            Title = "Click Delay",
            Content = Value .. "s (" .. cps .. " clicks/sec)",
            Duration = 2
        })
    end
})

ClickSettings:AddParagraph({
    Title = "Recommended Delays",
    Content = "Safe: 0.05s (20 CPS)\nBalanced: 0.03s (33 CPS)\nAggressive: 0.02s (50 CPS)\nMaximum: 0.01s (100 CPS)"
})

local RebirthSettings = Tabs.Settings:AddSection("Rebirth Settings")

RebirthSettings:AddSlider("RebirthDelay", {
    Title = "Rebirth Check Delay",
    Description = "How often to check if rebirth is possible",
    Default = 2,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        Config.RebirthDelay = Value
    end
})

local HatchSettings = Tabs.Settings:AddSection("Hatch Settings")

HatchSettings:AddParagraph({
    Title = "Hatch Speed",
    Content = "Hatch delay is locked at 0.5s (fastest safe speed). This ensures eggs hatch as fast as possible without server issues."
})

HatchSettings:AddSlider("HatchDelay", {
    Title = "Hatch Delay (Advanced)",
    Description = "Only change if experiencing issues",
    Default = 0.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        Config.HatchDelay = Value
        
        Fluent:Notify({
            Title = "Hatch Delay",
            Content = "Set to " .. Value .. "s",
            Duration = 2
        })
    end
})

local MiscSettings = Tabs.Settings:AddSection("Miscellaneous")

MiscSettings:AddButton({
    Title = "Enable Low Quality Mode",
    Description = "Reduce visual effects for better performance",
    Callback = function()
        _G.LOW_QUALITY = true
        
        Fluent:Notify({
            Title = "Performance",
            Content = "Low quality mode enabled",
            Duration = 3
        })
    end
})

MiscSettings:AddButton({
    Title = "Reset Statistics",
    Description = "Reset session statistics to zero",
    Callback = function()
        Stats.TotalClicks = 0
        Stats.TotalRebirths = 0
        Stats.TotalEggsHatched = 0
        Stats.SessionStartTime = tick()
        
        Fluent:Notify({
            Title = "Statistics",
            Content = "Statistics reset!",
            Duration = 2
        })
    end
})

local ServerSection = Tabs.Settings:AddSection("Server Actions")

ServerSection:AddButton({
    Title = "Rejoin Server",
    Description = "Rejoin the current server (auto-reloads script)",
    Callback = function()
        Fluent:Notify({
            Title = "Rejoining",
            Content = "Rejoining server in 2 seconds...",
            Duration = 2
        })
        
        -- Set auto-reload flag
        _G[AUTO_RELOAD_KEY] = true
        
        task.wait(2)
        
        local success, err = pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(
                game.PlaceId,
                game.JobId,
                LocalPlayer
            )
        end)
        
        if not success then
            warn("[Rejoin Error]", err)
            _G[AUTO_RELOAD_KEY] = false -- Clear flag on error
            Fluent:Notify({
                Title = "Rejoin Failed",
                Content = "Error: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

ServerSection:AddButton({
    Title = "Server Hop",
    Description = "Find and join a different server (auto-reloads script)",
    Callback = function()
        Fluent:Notify({
            Title = "Server Hopping",
            Content = "Finding a new server...",
            Duration = 3
        })
        
        -- Set auto-reload flag
        _G[AUTO_RELOAD_KEY] = true
        
        task.wait(1)
        
        local success, err = pcall(function()
            local TeleportService = game:GetService("TeleportService")
            local HttpService = game:GetService("HttpService")
            
            -- Get list of servers
            local servers = {}
            local cursor = ""
            
            repeat
                local url = string.format(
                    "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&cursor=%s",
                    game.PlaceId,
                    cursor
                )
                
                local success2, result = pcall(function()
                    return game:HttpGet(url)
                end)
                
                if success2 then
                    local data = HttpService:JSONDecode(result)
                    
                    for _, server in pairs(data.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            table.insert(servers, server.id)
                        end
                    end
                    
                    cursor = data.nextPageCursor or ""
                else
                    break
                end
            until cursor == "" or #servers >= 10
            
            if #servers > 0 then
                -- Pick a random server
                local randomServer = servers[math.random(1, #servers)]
                
                DebugPrint("Server hopping to:", randomServer)
                
                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    randomServer,
                    LocalPlayer
                )
            else
                _G[AUTO_RELOAD_KEY] = false -- Clear flag on error
                Fluent:Notify({
                    Title = "Server Hop Failed",
                    Content = "No available servers found!",
                    Duration = 5
                })
            end
        end)
        
        if not success then
            warn("[Server Hop Error]", err)
            _G[AUTO_RELOAD_KEY] = false -- Clear flag on error
            Fluent:Notify({
                Title = "Server Hop Failed",
                Content = "Error: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

-- ═══════════════════════════════════════════════════════════
-- STATISTICS TAB
-- ═══════════════════════════════════════════════════════════

local SessionStats = Tabs.Stats:AddSection("Session Statistics")

local ClicksParagraph = SessionStats:AddParagraph({
    Title = "Total Clicks",
    Content = "0 clicks"
})

local RebirthsParagraph = SessionStats:AddParagraph({
    Title = "Total Rebirths",
    Content = "0 rebirths"
})

local EggsParagraph = SessionStats:AddParagraph({
    Title = "Total Eggs Hatched",
    Content = "0 eggs"
})

local SessionTimeParagraph = SessionStats:AddParagraph({
    Title = "Session Time",
    Content = "0 minutes"
})

local GameStats = Tabs.Stats:AddSection("Current Game Stats")

local CurrentClicksParagraph = GameStats:AddParagraph({
    Title = "Current Clicks",
    Content = "Loading..."
})

local CurrentRebirthsParagraph = GameStats:AddParagraph({
    Title = "Current Rebirths",
    Content = "Loading..."
})

local NextRebirthParagraph = GameStats:AddParagraph({
    Title = "Next Rebirth Cost",
    Content = "Calculating..."
})

local RatesSection = Tabs.Stats:AddSection("Rates & Performance")

local ClickRateParagraph = RatesSection:AddParagraph({
    Title = "Click Rate",
    Content = "0 clicks/sec"
})

local RebirthRateParagraph = RatesSection:AddParagraph({
    Title = "Rebirth Rate",
    Content = "0 rebirths/min"
})

-- Update statistics display
local lastStatsUpdate = 0
RunService.Heartbeat:Connect(function()
    if tick() - lastStatsUpdate < 1 then return end
    lastStatsUpdate = tick()
    
    -- Session stats
    local sessionTime = math.floor((tick() - Stats.SessionStartTime) / 60)
    
    ClicksParagraph:SetDesc(string.format("%d clicks", Stats.TotalClicks))
    RebirthsParagraph:SetDesc(string.format("%d rebirths", Stats.TotalRebirths))
    EggsParagraph:SetDesc(string.format("%d eggs", Stats.TotalEggsHatched))
    SessionTimeParagraph:SetDesc(string.format("%d minutes", sessionTime))
    
    -- Game stats
    if Replication.Loaded and Replication.Data then
        local data = Replication.Data
        
        -- Format large numbers
        local function formatNumber(num)
            if num >= 1e12 then
                return string.format("%.2fT", num / 1e12)
            elseif num >= 1e9 then
                return string.format("%.2fB", num / 1e9)
            elseif num >= 1e6 then
                return string.format("%.2fM", num / 1e6)
            elseif num >= 1e3 then
                return string.format("%.2fK", num / 1e3)
            else
                return string.format("%d", num)
            end
        end
        
        CurrentClicksParagraph:SetDesc(formatNumber(data.Statistics.Clicks or 0))
        CurrentRebirthsParagraph:SetDesc(string.format("%d", data.Statistics.Rebirths or 0))
        
        -- Calculate next rebirth cost
        local tier = Config.RebirthTier
        local basePrice = Rebirths:fromIndex(tier)
        local currentRebirths = data.Statistics.Rebirths or 0
        local cost = Rebirths:ClicksPrice(basePrice, currentRebirths)
        
        NextRebirthParagraph:SetDesc(string.format("Tier %d: %s clicks", tier, formatNumber(cost)))
    end
    
    -- Rates
    local sessionTimeSeconds = tick() - Stats.SessionStartTime
    if sessionTimeSeconds > 0 then
        local clickRate = Config.AutoClick and (1 / Config.ClickDelay) or 0
        local rebirthRate = (Stats.TotalRebirths / sessionTimeSeconds) * 60
        
        ClickRateParagraph:SetDesc(string.format("%.1f clicks/sec (%.0f CPS)", clickRate, clickRate))
        RebirthRateParagraph:SetDesc(string.format("%.2f rebirths/min", rebirthRate))
    end
end)

-- ═══════════════════════════════════════════════════════════
-- SAVE MANAGER & INTERFACE MANAGER
-- ═══════════════════════════════════════════════════════════

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("PetClickingAutoFarm")
SaveManager:SetFolder("PetClickingAutoFarm/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Load settings
SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════════════════════════
-- START AUTO-FARM
-- ═══════════════════════════════════════════════════════════

StartAutoFarm()

-- Welcome notification
Fluent:Notify({
    Title = "TapSim Auto Farm v1.9 ULTIMATE",
    Content = "Complete automation loaded! Codes will redeem automatically.",
    Duration = 5
})

-- Handle cleanup on disconnect
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        StopAutoFarm()
    end
end)

print("═══════════════════════════════════════════")
print("🎮 TapSim Auto Farm v1.9 ULTIMATE by sinful")
print("═══════════════════════════════════════════")
print("UI: Press LeftControl to minimize/restore")
print("Features: Click, Rebirth, Hatch, Essence")
print("NEW: Auto-Upgrades + Codes + Wheelspins!")
print("Debug: Check F9 console for debug messages")
print("═══════════════════════════════════════════")
