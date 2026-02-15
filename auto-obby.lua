-- Obby Auto-Complete Script
-- Fluent UI

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Settings
local Settings = {
    AutoComplete = false,
    FireSpeed = 0.1,
    SavedPosition = nil,
    TeleportDelay = 0.2
}

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "Obby Auto-Complete",
    SubTitle = "v1.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tab
local MainTab = Window:AddTab({ Title = "Main", Icon = "flag" })

-- Get the obby win part
local function GetWinPart()
    local success, part = pcall(function()
        return workspace["Studio Workspace"].ZoneSystem.Zones.Zone0.Obby.obbyparts.ObbyWinPart
    end)
    
    if success and part then
        return part
    else
        return nil
    end
end

-- Add status
local StatusParagraph = MainTab:AddParagraph({
    Title = "Status",
    Content = "Checking obby part..."
})

-- Check if part exists
local winPart = GetWinPart()
if winPart then
    StatusParagraph:SetDesc("✅ Obby win part found!")
else
    StatusParagraph:SetDesc("❌ Obby win part not found!")
end

-- Add Toggle
local AutoCompleteToggle = MainTab:AddToggle("AutoComplete", {
    Title = "Auto-Complete Obby",
    Default = false,
    Callback = function(Value)
        Settings.AutoComplete = Value
        print("Auto-Complete:", Value and "ON" or "OFF")
        
        if Value then
            Fluent:Notify({
                Title = "Auto-Complete",
                Content = "Obby auto-complete enabled!",
                Duration = 2
            })
        end
    end
})

-- Add Speed Slider
local SpeedSlider = MainTab:AddSlider("Speed", {
    Title = "Fire Speed",
    Description = "How fast to trigger (lower = faster)",
    Default = 0.1,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Settings.FireSpeed = Value
    end
})

-- Add Teleport Delay Slider
local DelaySlider = MainTab:AddSlider("TeleportDelay", {
    Title = "Teleport Back Delay",
    Description = "Wait time before teleporting back",
    Default = 0.2,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        Settings.TeleportDelay = Value
    end
})

MainTab:AddParagraph({
    Title = "━━━━━━━━━━━━━━━━━━━━━",
    Content = ""
})

-- Add Set Location Button
MainTab:AddButton({
    Title = "📍 Set My Location",
    Description = "Save current position to return to",
    Callback = function()
        if LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                Settings.SavedPosition = hrp.CFrame
                
                Fluent:Notify({
                    Title = "Location Saved",
                    Content = "You'll teleport back to this spot!",
                    Duration = 3
                })
                
                StatusParagraph:SetDesc("✅ Location saved! Toggle on to start")
                
                print("📍 Saved location:", hrp.Position)
            end
        else
            Fluent:Notify({
                Title = "Error",
                Content = "Character not found!",
                Duration = 2
            })
        end
    end
})

-- Add Clear Location Button
MainTab:AddButton({
    Title = "🗑️ Clear Location",
    Description = "Remove saved position",
    Callback = function()
        Settings.SavedPosition = nil
        
        Fluent:Notify({
            Title = "Location Cleared",
            Content = "Saved position removed",
            Duration = 2
        })
        
        StatusParagraph:SetDesc("Idle - Set a new location")
        
        print("🗑️ Location cleared")
    end
})

-- Add manual trigger button
MainTab:AddButton({
    Title = "⚡ Complete Now",
    Description = "Manually trigger obby completion",
    Callback = function()
        if not Settings.SavedPosition then
            Fluent:Notify({
                Title = "Error",
                Content = "Set your location first!",
                Duration = 2
            })
            return
        end
        
        local part = GetWinPart()
        if part and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                pcall(function()
                    firetouchinterest(hrp, part, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, part, 1)
                end)
                
                -- Wait for teleport
                task.wait(Settings.TeleportDelay)
                
                -- Restore to saved position
                if hrp and Settings.SavedPosition then
                    hrp.CFrame = Settings.SavedPosition
                end
                
                Fluent:Notify({
                    Title = "Success",
                    Content = "Completed obby and returned to saved spot!",
                    Duration = 2
                })
            end
        else
            Fluent:Notify({
                Title = "Error",
                Content = "Obby part not found!",
                Duration = 2
            })
        end
    end
})

-- Add info section
MainTab:AddParagraph({
    Title = "ℹ️ How to Use",
    Content = "1. Stand where you want to stay\n2. Click 'Set My Location'\n3. Toggle on to auto-complete\n4. You'll return to your saved spot each time!"
})

-- Auto-fire loop
task.spawn(function()
    while task.wait(Settings.FireSpeed) do
        if Settings.AutoComplete then
            local part = GetWinPart()
            
            if part and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    -- Check if location is saved
                    if not Settings.SavedPosition then
                        StatusParagraph:SetDesc("⚠️ Click 'Set My Location' first!")
                        task.wait(1)
                        continue
                    end
                    
                    pcall(function()
                        -- Fire touch to complete obby
                        firetouchinterest(hrp, part, 0)
                        task.wait(0.05)
                        firetouchinterest(hrp, part, 1)
                    end)
                    
                    -- Wait for game to register completion and teleport
                    task.wait(Settings.TeleportDelay)
                    
                    -- Teleport back to saved position
                    if hrp and Settings.SavedPosition then
                        hrp.CFrame = Settings.SavedPosition
                    end
                    
                    StatusParagraph:SetDesc("🔥 Auto-completing + returning to saved spot...")
                end
            else
                StatusParagraph:SetDesc("⚠️ Obby part or character not found")
            end
        else
            if Settings.SavedPosition then
                StatusParagraph:SetDesc("Idle - Location saved, ready to go!")
            else
                StatusParagraph:SetDesc("Idle - Set location then toggle on")
            end
        end
    end
end)

print("✅ Obby Auto-Complete loaded!")
print("🎯 Target: ObbyWinPart")
print("⚡ Ready to complete!")
