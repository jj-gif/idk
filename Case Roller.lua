--[[
    ═══════════════════════════════════════════════════════════════════
    🎲 CASE ROLLER BY SINFUL v4.0
    ═══════════════════════════════════════════════════════════════════
    NOW USES ACTUAL GAME GUI PATHS FOR ACCURATE STATS
]]

-- Wait for game
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer.Character

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

print("🎲 Starting Case Roller By Sinful...")

-- Load Network
local Network
local success = pcall(function()
    Network = ReplicatedStorage:WaitForChild("RojoShared", 10):WaitForChild("Network", 10)
end)

if not success or not Network then
    warn("❌ Failed to load Network module!")
    player:Kick("Network module not found!")
    return
end

print("✅ Network loaded")

-- Load Fluent UI
local Fluent
local success2 = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not success2 or not Fluent then
    warn("❌ Failed to load UI Library!")
    player:Kick("UI Library failed to load!")
    return
end

print("✅ UI Library loaded")

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "Case Roller By Sinful",
    SubTitle = "v4.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

print("✅ Window created")

-- ═══════════════════════════════════════════════════════════════════
-- CREATE ALL TABS
-- ═══════════════════════════════════════════════════════════════════

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Roll", Icon = "box" }),
    Bank = Window:AddTab({ Title = "Bank", Icon = "dollar-sign" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "bell" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

print("✅ Tabs created")
task.wait(0.5)

-- ═══════════════════════════════════════════════════════════════════
-- SETTINGS & STATS
-- ═══════════════════════════════════════════════════════════════════

local Settings = {
    AutoRoll = false,
    CaseName = "",
    Quantity = 1,
    RollDelay = 2,
    BypassCooldown = false,
    AutoSell = false,
    SellThreshold = 500,
    BankFarmer = false,
    BankInterval = 5,
    NotifyPink = true,
    NotifyRed = true,
    NotifyGold = true,
    WebhookURL = "",
    WebhookAutoSend = false,
    WebhookInterval = 300
}

local Stats = {
    TotalOpened = 0,
    TotalSpent = 0,
    TotalValue = 0,
    Blues = 0,
    Purples = 0,
    Pinks = 0,
    Reds = 0,
    Golds = 0,
    BankCollections = 0,
    StartTime = os.time(),
    CurrentCash = 0,
    CurrentInventoryValue = 0,
    CurrentInventoryCount = 0,
    LastReportCash = 0,
    LastReportValue = 0
}

local Running = {
    AutoRoll = false,
    BankFarmer = false,
    WebhookTimer = false
}

-- ═══════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

local function formatCurrency(amount)
    return "$" .. string.format("%.2f", amount or 0)
end

local function formatPercent(value, total)
    if total == 0 then return "0.0%" end
    return string.format("%.1f%%", (value / total) * 100)
end

local function formatChange(current, previous)
    if previous == 0 then return "+0.0%" end
    local change = ((current - previous) / previous) * 100
    return (change >= 0 and "+" or "") .. string.format("%.1f%%", change)
end

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    elseif minutes > 0 then
        return string.format("%dm", minutes)
    else
        return string.format("%ds", seconds)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- GAME-SPECIFIC FUNCTIONS (USES ACTUAL GUI PATHS)
-- ═══════════════════════════════════════════════════════════════════

local function getCasePrice(caseName)
    -- Get the case price from the GUI
    local success, price = pcall(function()
        local casesGui = player.PlayerGui:FindFirstChild("CasesScreenGui")
        if not casesGui then return 0 end
        
        local caseView = casesGui:FindFirstChild("caseView")
        if not caseView then return 0 end
        
        local scrollContainer = caseView:FindFirstChild("scrollingContainer")
        if not scrollContainer then return 0 end
        
        local scrollFrame = scrollContainer:FindFirstChild("scrollingFrame")
        if not scrollFrame then return 0 end
        
        -- Loop through all ItemCards to find matching case name
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child.Name == "ItemCard" and child:IsA("Frame") then
                local bottomFrame = child:FindFirstChild("bottomFrame")
                if bottomFrame then
                    local line1 = bottomFrame:FindFirstChild("line1")
                    local priceLabel = bottomFrame:FindFirstChild("price")
                    
                    if line1 and priceLabel and line1.Text == caseName then
                        -- Parse price (remove $ and convert to number)
                        local priceText = priceLabel.Text:gsub("$", ""):gsub(",", "")
                        return tonumber(priceText) or 0
                    end
                end
            end
        end
        return 0
    end)
    
    return success and price or 0
end

local function updateCurrentValues()
    -- Get cash from leaderstats
    pcall(function()
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local cash = leaderstats:FindFirstChild("Cash")
            if cash then
                -- Convert to number in case it's a string
                local cashValue = cash.Value
                if type(cashValue) == "string" then
                    cashValue = tonumber(cashValue:gsub("[$,]", "")) or 0
                end
                Stats.CurrentCash = cashValue or 0
            end
        end
    end)
    
    -- Get inventory value from leaderstats
    pcall(function()
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local value = leaderstats:FindFirstChild("Value")
            if value then
                -- Convert to number in case it's a string
                local valueNum = value.Value
                if type(valueNum) == "string" then
                    valueNum = tonumber(valueNum:gsub("[$,]", "")) or 0
                end
                Stats.CurrentInventoryValue = valueNum or 0
            end
        end
    end)
    
    -- Count inventory items from GUI
    pcall(function()
        local inventoryGui = player.PlayerGui:FindFirstChild("InventoryScreenGui")
        if inventoryGui then
            local inventory = inventoryGui:FindFirstChild("Inventory")
            if inventory then
                local inventoryList = inventory:FindFirstChild("InventoryList")
                if inventoryList then
                    local scrollFrame = inventoryList:FindFirstChild("scrollingFrame")
                    if scrollFrame then
                        local count = 0
                        for _, child in ipairs(scrollFrame:GetChildren()) do
                            if child.Name == "ItemCard" and child:IsA("Frame") then
                                count = count + 1
                            end
                        end
                        Stats.CurrentInventoryCount = count
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- CORE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

local function openCase(caseName, quantity)
    if not caseName or caseName == "" then
        Fluent:Notify({
            Title = "Error",
            Content = "Enter case name!",
            Duration = 3
        })
        return false
    end
    
    -- Get the case price and add to total spent
    local casePrice = getCasePrice(caseName)
    if casePrice > 0 then
        Stats.TotalSpent = Stats.TotalSpent + (casePrice * quantity)
    end
    
    local success = pcall(function()
        Network.PurchaseCase:InvokeServer(caseName, quantity or 1, false)
    end)
    
    if success then
        Stats.TotalOpened = Stats.TotalOpened + quantity
    end
    
    return success
end

local function collectBankPayout()
    local success, result = pcall(function()
        local bankItems = Network.GetBankItems:InvokeServer()
        if not bankItems or #bankItems == 0 then
            return {success = false, count = 0}
        end
        
        local uuids = {}
        for _, item in ipairs(bankItems) do
            if item.item and item.item._uuid then
                table.insert(uuids, item.item._uuid)
            end
        end
        
        if #uuids > 0 then
            local collected = Network.CollectPayout:InvokeServer(uuids)
            if collected then
                Stats.BankCollections = Stats.BankCollections + 1
                return {success = true, count = #uuids}
            end
        end
        return {success = false, count = 0}
    end)
    
    if success and result.success then
        return true, result.count
    end
    return false, 0
end

local function sellItems(items)
    if not items or #items == 0 then return false end
    
    -- The game uses SellItem (singular) not SellItems (plural)
    local success = true
    for _, item in ipairs(items) do
        local itemSuccess = pcall(function()
            Network.SellItem:InvokeServer({{item}})
        end)
        if not itemSuccess then
            success = false
        end
    end
    
    return success
end

local function sendWebhook()
    if not Settings.WebhookURL or Settings.WebhookURL == "" then
        Fluent:Notify({
            Title = "Error",
            Content = "Set webhook URL first!",
            Duration = 3
        })
        return false
    end
    
    print("📤 Sending webhook...")
    -- Don't call updateCurrentValues here - use cached values from the update loop
    
    local cashChange = formatChange(Stats.CurrentCash, Stats.LastReportCash)
    local valueChange = formatChange(Stats.CurrentInventoryValue, Stats.LastReportValue)
    local profit = Stats.TotalValue - Stats.TotalSpent
    local profitPercent = Stats.TotalSpent > 0 and (profit / Stats.TotalSpent * 100) or 0
    local sessionTime = os.time() - Stats.StartTime
    local totalItems = Stats.Blues + Stats.Purples + Stats.Pinks + Stats.Reds + Stats.Golds
    
    local message = "```"
    message = message .. "\n🎲 CASE UNBOXING REPORT"
    message = message .. "\n================================"
    message = message .. "\n"
    message = message .. "\n💰 Current Cash: " .. formatCurrency(Stats.CurrentCash) .. " (" .. cashChange .. ")"
    message = message .. "\n📦 Inventory Value: " .. formatCurrency(Stats.CurrentInventoryValue) .. " (" .. valueChange .. ")"
    message = message .. "\n📊 Inventory Items: " .. tostring(Stats.CurrentInventoryCount)
    message = message .. "\n"
    message = message .. "\n🎲 Cases Opened: " .. tostring(Stats.TotalOpened)
    message = message .. "\n💵 Total Spent: " .. formatCurrency(Stats.TotalSpent)
    message = message .. "\n💎 Total Won: " .. formatCurrency(Stats.TotalValue)
    message = message .. "\n📈 Net Profit/Loss: " .. formatCurrency(profit) .. " (" .. string.format("%.1f%%", profitPercent) .. ")"
    message = message .. "\n⏱️ Session Time: " .. formatTime(sessionTime)
    message = message .. "\n🏦 Bank Collections: " .. tostring(Stats.BankCollections)
    message = message .. "\n"
    message = message .. "\n🎨 RARITY BREAKDOWN"
    message = message .. "\n--------------------------------"
    
    if totalItems > 0 then
        message = message .. "\n🔵 Blue: " .. Stats.Blues .. " (" .. string.format("%.1f%%", Stats.Blues/totalItems*100) .. ")"
        message = message .. "\n🟣 Purple: " .. Stats.Purples .. " (" .. string.format("%.1f%%", Stats.Purples/totalItems*100) .. ")"
        message = message .. "\n🌸 Pink: " .. Stats.Pinks .. " (" .. string.format("%.1f%%", Stats.Pinks/totalItems*100) .. ")"
        message = message .. "\n🔴 Red: " .. Stats.Reds .. " (" .. string.format("%.1f%%", Stats.Reds/totalItems*100) .. ")"
        message = message .. "\n🟡 Gold: " .. Stats.Golds .. " (" .. string.format("%.1f%%", Stats.Golds/totalItems*100) .. ")"
    else
        message = message .. "\nNo items opened yet"
    end
    
    message = message .. "\n"
    message = message .. "\n================================"
    message = message .. "\nCase Roller By Sinful | " .. tostring(player.Name)
    message = message .. "\n```"
    
    print("📝 Message built, length:", #message)
    
    local data = {
        username = "Case Roller By Sinful",
        content = message
    }
    
    local jsonData
    local encodeSuccess, encodeError = pcall(function()
        jsonData = HttpService:JSONEncode(data)
    end)
    
    if not encodeSuccess then
        Fluent:Notify({Title = "❌ Error", Content = "Encode failed", Duration = 3})
        warn("JSON Encode Error:", encodeError)
        return false
    end
    
    print("✅ JSON encoded successfully")
    
    local success, response = pcall(function()
        if syn and syn.request then
            return syn.request({
                Url = Settings.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        elseif http_request then
            return http_request({
                Url = Settings.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        elseif request then
            return request({
                Url = Settings.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        else
            error("No HTTP request function available")
        end
    end)
    
    if success and response and (response.StatusCode == 204 or response.StatusCode == 200) then
        Stats.LastReportCash = Stats.CurrentCash
        Stats.LastReportValue = Stats.CurrentInventoryValue
        Fluent:Notify({Title = "✅ Success", Content = "Full report sent!", Duration = 3})
        print("✅ Webhook sent successfully!")
        return true
    else
        local errorMsg = "Failed to send"
        if success and response then
            errorMsg = "Status: " .. tostring(response.StatusCode)
            print("❌ Webhook failed - Status Code:", response.StatusCode)
            if response.Body then
                print("Response Body:", response.Body)
            end
        else
            errorMsg = "Request error"
            print("❌ Webhook request failed:", tostring(response))
        end
        Fluent:Notify({Title = "❌ Failed", Content = errorMsg, Duration = 5})
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO SYSTEMS
-- ═══════════════════════════════════════════════════════════════════

local function startAutoRoll()
    if Running.AutoRoll then return end
    Running.AutoRoll = true
    
    task.spawn(function()
        while Settings.AutoRoll and Running.AutoRoll do
            if openCase(Settings.CaseName, Settings.Quantity) then
                task.wait(Settings.BypassCooldown and 0.1 or Settings.RollDelay)
            else
                task.wait(5)
            end
        end
        Running.AutoRoll = false
    end)
end

local function startBankFarmer()
    if Running.BankFarmer then return end
    Running.BankFarmer = true
    
    task.spawn(function()
        while Settings.BankFarmer and Running.BankFarmer do
            local success, count = collectBankPayout()
            if success and count > 0 then
                Fluent:Notify({Title = "Bank", Content = "Collected " .. count .. " items", Duration = 2})
            end
            task.wait(Settings.BankInterval)
        end
        Running.BankFarmer = false
    end)
end

local function startWebhookTimer()
    if Running.WebhookTimer then return end
    Running.WebhookTimer = true
    
    task.spawn(function()
        while Settings.WebhookAutoSend and Running.WebhookTimer do
            task.wait(Settings.WebhookInterval)
            if Settings.WebhookAutoSend then
                sendWebhook()
            end
        end
        Running.WebhookTimer = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- BUILD UI - MAIN TAB
-- ═══════════════════════════════════════════════════════════════════

print("Building Main Tab...")

Tabs.Main:AddParagraph({
    Title = "🎲 Auto Roll",
    Content = "Automatically open cases"
})

local AutoRollToggle = Tabs.Main:AddToggle("MainAutoRoll", {
    Title = "Enable Auto Roll",
    Default = false
})

AutoRollToggle:OnChanged(function(value)
    Settings.AutoRoll = value
    if value then
        startAutoRoll()
    else
        Running.AutoRoll = false
    end
end)

Tabs.Main:AddInput("MainCaseName", {
    Title = "Case Name",
    Default = "",
    Placeholder = "e.g., Basic Case",
    Callback = function(value)
        Settings.CaseName = value
    end
})

Tabs.Main:AddSlider("MainQuantity", {
    Title = "Cases Per Open",
    Min = 1,
    Max = 10,
    Default = 1,
    Rounding = 0,
    Callback = function(value)
        Settings.Quantity = value
    end
})

Tabs.Main:AddSlider("MainDelay", {
    Title = "Delay (seconds)",
    Min = 0.1,
    Max = 10,
    Default = 2,
    Rounding = 1,
    Callback = function(value)
        Settings.RollDelay = value
    end
})

Tabs.Main:AddButton({
    Title = "Open Case Now",
    Callback = function()
        openCase(Settings.CaseName, Settings.Quantity)
    end
})

Tabs.Main:AddParagraph({
    Title = "💰 Auto Sell",
    Content = "Automatically sell low value items"
})

local AutoSellToggle = Tabs.Main:AddToggle("MainAutoSell", {
    Title = "Enable Auto Sell",
    Default = false
})

AutoSellToggle:OnChanged(function(value)
    Settings.AutoSell = value
end)

Tabs.Main:AddSlider("MainSellThreshold", {
    Title = "Sell Below ($)",
    Min = 0,
    Max = 50,
    Default = 5,
    Rounding = 0,
    Callback = function(value)
        Settings.SellThreshold = value -- Store as dollars, not cents
    end
})

local BypassToggle = Tabs.Main:AddToggle("MainBypass", {
    Title = "Cooldown Bypass",
    Default = false
})

BypassToggle:OnChanged(function(value)
    Settings.BypassCooldown = value
end)

print("✅ Main Tab built")

-- ═══════════════════════════════════════════════════════════════════
-- BUILD UI - BANK TAB
-- ═══════════════════════════════════════════════════════════════════

print("Building Bank Tab...")

Tabs.Bank:AddParagraph({
    Title = "🏦 Bank Payout Farmer",
    Content = "Auto-collect passive income"
})

local BankToggle = Tabs.Bank:AddToggle("BankFarmer", {
    Title = "Enable Bank Farmer",
    Default = false
})

BankToggle:OnChanged(function(value)
    Settings.BankFarmer = value
    if value then
        startBankFarmer()
    else
        Running.BankFarmer = false
    end
end)

Tabs.Bank:AddSlider("BankInterval", {
    Title = "Interval (seconds)",
    Min = 1,
    Max = 60,
    Default = 5,
    Rounding = 0,
    Callback = function(value)
        Settings.BankInterval = value
    end
})

Tabs.Bank:AddButton({
    Title = "Collect Now",
    Callback = function()
        local success, count = collectBankPayout()
        Fluent:Notify({
            Title = success and "Success" or "Failed",
            Content = success and ("Collected " .. count .. " items") or "No items",
            Duration = 3
        })
    end
})

local BankStats = Tabs.Bank:AddParagraph({
    Title = "Bank Collections",
    Content = "0"
})

print("✅ Bank Tab built")

-- ═══════════════════════════════════════════════════════════════════
-- BUILD UI - WEBHOOK TAB
-- ═══════════════════════════════════════════════════════════════════

print("Building Webhook Tab...")

Tabs.Webhook:AddParagraph({
    Title = "🔔 Discord Webhook",
    Content = "Send reports to Discord"
})

Tabs.Webhook:AddInput("WebhookURL", {
    Title = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        Settings.WebhookURL = value
    end
})

Tabs.Webhook:AddButton({
    Title = "Test Webhook (Simple)",
    Callback = function()
        if not Settings.WebhookURL or Settings.WebhookURL == "" then
            Fluent:Notify({Title = "Error", Content = "Enter webhook URL first!", Duration = 3})
            return
        end
        
        local testData = {
            username = "Case Roller By Sinful",
            content = "🎲 **Test Message** - Webhook is working! ✅"
        }
        
        local success, response = pcall(function()
            if syn and syn.request then
                return syn.request({
                    Url = Settings.WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(testData)
                })
            elseif http_request then
                return http_request({
                    Url = Settings.WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(testData)
                })
            elseif request then
                return request({
                    Url = Settings.WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(testData)
                })
            else
                error("No HTTP function available")
            end
        end)
        
        if success and response and (response.StatusCode == 204 or response.StatusCode == 200) then
            Fluent:Notify({Title = "✅ Success", Content = "Test message sent!", Duration = 3})
        else
            Fluent:Notify({Title = "❌ Failed", Content = success and ("Code: " .. tostring(response.StatusCode)) or "HTTP not supported", Duration = 5})
        end
    end
})

Tabs.Webhook:AddButton({
    Title = "Send Full Report",
    Callback = function()
        sendWebhook()
    end
})

Tabs.Webhook:AddParagraph({
    Title = "⚙️ Auto Reports",
    Content = "Automatically send reports"
})

local WebhookAutoToggle = Tabs.Webhook:AddToggle("WebhookAuto", {
    Title = "Enable Auto Reports",
    Default = false
})

WebhookAutoToggle:OnChanged(function(value)
    Settings.WebhookAutoSend = value
    if value then
        startWebhookTimer()
    else
        Running.WebhookTimer = false
    end
end)

Tabs.Webhook:AddSlider("WebhookInterval", {
    Title = "Interval (minutes)",
    Min = 1,
    Max = 60,
    Default = 5,
    Rounding = 0,
    Callback = function(value)
        Settings.WebhookInterval = value * 60
    end
})

Tabs.Webhook:AddParagraph({
    Title = "📊 Report Includes",
    Content = "• Cash & Change %\n• Inventory Value & Change %\n• Cases Opened\n• Profit/Loss\n• Session Time\n• Rarity Breakdown"
})

print("✅ Webhook Tab built")

-- ═══════════════════════════════════════════════════════════════════
-- BUILD UI - STATS TAB
-- ═══════════════════════════════════════════════════════════════════

print("Building Stats Tab...")

Tabs.Stats:AddParagraph({
    Title = "📊 Session Statistics",
    Content = "Live stats tracking"
})

local StatsLabels = {
    Opened = Tabs.Stats:AddParagraph({Title = "Cases Opened", Content = "0"}),
    Spent = Tabs.Stats:AddParagraph({Title = "Total Spent", Content = "$0.00"}),
    Won = Tabs.Stats:AddParagraph({Title = "Total Won", Content = "$0.00"}),
    Profit = Tabs.Stats:AddParagraph({Title = "Profit/Loss", Content = "$0.00"}),
    Time = Tabs.Stats:AddParagraph({Title = "Session Time", Content = "0s"})
}

local RarityLabels = {
    Blue = Tabs.Stats:AddParagraph({Title = "🔵 Blue", Content = "0 (0%)"}),
    Purple = Tabs.Stats:AddParagraph({Title = "🟣 Purple", Content = "0 (0%)"}),
    Pink = Tabs.Stats:AddParagraph({Title = "🌸 Pink", Content = "0 (0%)"}),
    Red = Tabs.Stats:AddParagraph({Title = "🔴 Red", Content = "0 (0%)"}),
    Gold = Tabs.Stats:AddParagraph({Title = "🟡 Gold", Content = "0 (0%)"})
}

Tabs.Stats:AddButton({
    Title = "Reset Statistics",
    Callback = function()
        Stats = {
            TotalOpened = 0,
            TotalSpent = 0,
            TotalValue = 0,
            Blues = 0,
            Purples = 0,
            Pinks = 0,
            Reds = 0,
            Golds = 0,
            BankCollections = 0,
            StartTime = os.time(),
            CurrentCash = 0,
            CurrentInventoryValue = 0,
            CurrentInventoryCount = 0,
            LastReportCash = 0,
            LastReportValue = 0
        }
        Fluent:Notify({Title = "Reset", Content = "Stats cleared", Duration = 2})
    end
})

print("✅ Stats Tab built")

-- ═══════════════════════════════════════════════════════════════════
-- BUILD UI - SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════════

print("Building Settings Tab...")

Tabs.Settings:AddParagraph({
    Title = "🔔 Notifications",
    Content = "Toggle drop notifications"
})

local NotifyPink = Tabs.Settings:AddToggle("NotifyPink", {Title = "Pink Drops", Default = true})
NotifyPink:OnChanged(function(v) Settings.NotifyPink = v end)

local NotifyRed = Tabs.Settings:AddToggle("NotifyRed", {Title = "Red Drops", Default = true})
NotifyRed:OnChanged(function(v) Settings.NotifyRed = v end)

local NotifyGold = Tabs.Settings:AddToggle("NotifyGold", {Title = "Gold Drops", Default = true})
NotifyGold:OnChanged(function(v) Settings.NotifyGold = v end)

Tabs.Settings:AddButton({
    Title = "Get Current Cash",
    Callback = function()
        updateCurrentValues()
        Fluent:Notify({Title = "Cash", Content = formatCurrency(Stats.CurrentCash), Duration = 3})
    end
})

Tabs.Settings:AddButton({
    Title = "Get Inventory Value",
    Callback = function()
        updateCurrentValues()
        Fluent:Notify({Title = "Inventory", Content = formatCurrency(Stats.CurrentInventoryValue), Duration = 3})
    end
})

print("✅ Settings Tab built")

-- ═══════════════════════════════════════════════════════════════════
-- UI UPDATE LOOP
-- ═══════════════════════════════════════════════════════════════════

local function updateUI()
    StatsLabels.Opened:SetDesc(tostring(Stats.TotalOpened))
    StatsLabels.Spent:SetDesc(formatCurrency(Stats.TotalSpent))
    StatsLabels.Won:SetDesc(formatCurrency(Stats.TotalValue))
    
    local profit = Stats.TotalValue - Stats.TotalSpent
    StatsLabels.Profit:SetDesc((profit >= 0 and "✅ " or "❌ ") .. formatCurrency(profit))
    
    local sessionTime = os.time() - Stats.StartTime
    StatsLabels.Time:SetDesc(formatTime(sessionTime))
    
    local total = Stats.Blues + Stats.Purples + Stats.Pinks + Stats.Reds + Stats.Golds
    if total > 0 then
        RarityLabels.Blue:SetDesc(Stats.Blues .. " (" .. formatPercent(Stats.Blues, total) .. ")")
        RarityLabels.Purple:SetDesc(Stats.Purples .. " (" .. formatPercent(Stats.Purples, total) .. ")")
        RarityLabels.Pink:SetDesc(Stats.Pinks .. " (" .. formatPercent(Stats.Pinks, total) .. ")")
        RarityLabels.Red:SetDesc(Stats.Reds .. " (" .. formatPercent(Stats.Reds, total) .. ")")
        RarityLabels.Gold:SetDesc(Stats.Golds .. " (" .. formatPercent(Stats.Golds, total) .. ")")
    end
    
    BankStats:SetDesc(tostring(Stats.BankCollections))
    updateCurrentValues()
end

task.spawn(function()
    while task.wait(2) do
        pcall(updateUI)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- EVENT LISTENERS
-- ═══════════════════════════════════════════════════════════════════

Network.RollResult.OnClientEvent:Connect(function(results, crate)
    local itemsToSell = {}
    
    for _, item in ipairs(results) do
        if item.price then
            Stats.TotalValue = Stats.TotalValue + item.price
        end
        
        local hex = item.hex or ""
        
        if hex == "#4b69ff" then
            Stats.Blues = Stats.Blues + 1
        elseif hex == "#8847ff" then
            Stats.Purples = Stats.Purples + 1
        elseif hex == "#d32ce6" then
            Stats.Pinks = Stats.Pinks + 1
            if Settings.NotifyPink then
                Fluent:Notify({Title = "🌸 PINK!", Content = item.market_hash_name or "Exotic", Duration = 5})
            end
        elseif hex == "#eb4b4b" then
            Stats.Reds = Stats.Reds + 1
            if Settings.NotifyRed then
                Fluent:Notify({Title = "🔴 RED!", Content = item.market_hash_name or "Covert", Duration = 8})
            end
        elseif hex == "#e4ae39" then
            Stats.Golds = Stats.Golds + 1
            if Settings.NotifyGold then
                Fluent:Notify({Title = "🟡🟡 GOLD! 🟡🟡", Content = item.market_hash_name or "RARE!", Duration = 15})
            end
        end
        
        -- Check if we should auto-sell (price is in dollars)
        if Settings.AutoSell and item.price and item.price <= Settings.SellThreshold then
            table.insert(itemsToSell, item)
        end
    end
    
    if #itemsToSell > 0 then
        print("🤖 Auto-selling", #itemsToSell, "items below $" .. Settings.SellThreshold)
        task.delay(0.5, function()
            sellItems(itemsToSell)
        end)
    end
    
    pcall(updateUI)
end)

-- ═══════════════════════════════════════════════════════════════════
-- INITIALIZATION COMPLETE
-- ═══════════════════════════════════════════════════════════════════

Fluent:Notify({
    Title = "✅ Ready!",
    Content = "Case Roller By Sinful v4.0 loaded!",
    Duration = 5
})

print("═══════════════════════════════════════════════════════════")
print("✅ CASE ROLLER BY SINFUL v4.0 LOADED")
print("✅ NOW USING ACTUAL GAME VALUES:")
print("   • Cash from leaderstats.Cash")
print("   • Value from leaderstats.Value")
print("   • Inventory count from GUI")
print("   • Case prices from GUI")
print("═══════════════════════════════════════════════════════════")

return {
    Settings = Settings,
    Stats = Stats,
    SendWebhook = sendWebhook
}
