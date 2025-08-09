local Fluent, LibraryUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
end)

if not Fluent then
    warn("Failed to load Fluent UI", LibraryUI)
    return
end

-- Debug system - initialize Debug to false by default
if not getgenv then
    getfenv().getgenv = function() return _G end
end

if getgenv().Debug == nil then
    getgenv().Debug = false
end

local function debugPrint(...)
    if getgenv().Debug == true then
        print("[DEBUG]", ...)
    end
end

local Window = LibraryUI:CreateWindow({
    Title = "RIBOUTAID",
    SubTitle = "v1.1.0 By Numass",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Theme = "Tomorrow Night Blue",
    MinimizeKey = Enum.KeyCode.RightControl
})

local MainTab = Window:AddTab({
    Title = "Main",
    Icon = "rbxassetid://7733960981"
})

local autoUnlockToggle = MainTab:AddToggle("AutoUnlockToggle", {
    Title = "Auto Unlock Areas",
    Default = false,
    Callback = function(enabled)
        if enabled then
            spawn(function()
                while autoUnlockToggle do
                    local areas = {}
                    local map = workspace:FindFirstChild("__MAP")
                    if map then
                        local areasFolder = map:FindFirstChild("Areas")
                        if areasFolder then
                            for _, folder in ipairs(areasFolder:GetChildren()) do
                                if folder:IsA("Folder") then
                                    table.insert(areas, folder.Name)
                                end
                            end
                        else
                            warn("Areas folder not found in __MAP")
                        end
                    else
                        warn("__MAP not found in workspace")
                    end
                    for _, area in ipairs(areas) do
                        local args = {
                            {
                                area
                            }
                        }
                        workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("buy area"):InvokeServer(unpack(args))
                         -- Add delay to prevent spamming
                    end
                end
            end)
        end
    end
})

-- Auto Claim Free Gifts variables
local autoClaimGifts = false

-- Auto Buy Diamonds variables
local autoBuyDiamonds = false
local diamondButtonUsed = false
local diamondThreshold = 250000000000 -- 250b

local function parseCurrency(text)
    if not text then return 0 end
    text = text:gsub(",", "") -- Remove commas
    local number = tonumber(text:match("%d+%.?%d*"))
    if not number then return 0 end
    
    if text:find("[Tt]") then
        return number * 1e12
    elseif text:find("[Bb]") then
        return number * 1e9
    elseif text:find("[Mm]") then
        return number * 1e6
    elseif text:find("[Kk]") then
        return number * 1e3
    end
    return number
end

MainTab:AddToggle("AutoClaimGiftsToggle", {
    Title = "Auto Claim Free Gifts",
    Default = false,
    Callback = function(value)
        autoClaimGifts = value
        if value then
            debugPrint("✅ Auto Claim Free Gifts enabled")
            print("Auto Claim Free Gifts started! (Enable debug with getgenv().Debug = true)")
            spawn(function()
                while autoClaimGifts do
                    local success, result = pcall(function()
                        local player = game:GetService("Players").LocalPlayer
                        debugPrint("🔍 Checking for FreeGiftsTop GUI...")
                        local freeGiftsTop = player.PlayerGui:FindFirstChild("FreeGiftsTop")
                        
                        if freeGiftsTop then
                            debugPrint("✅ Found FreeGiftsTop")
                            if freeGiftsTop:FindFirstChild("Button") then
                                debugPrint("✅ Found Button in FreeGiftsTop")
                                if freeGiftsTop.Button:FindFirstChild("Timer") then
                                    local timerText = freeGiftsTop.Button.Timer.Text
                                    debugPrint("🎁 Free gifts timer:", timerText)
                                    
                                    if timerText == "Ready!" then
                                        debugPrint("🎁 Free gifts ready, claiming...")
                                        
                                        -- Click all gift buttons (continue even if some fail)
                                        local freeGifts = player.PlayerGui:FindFirstChild("FreeGifts")
                                        if freeGifts and freeGifts:FindFirstChild("Frame") and freeGifts.Frame:FindFirstChild("Container") and freeGifts.Frame.Container:FindFirstChild("Gifts") then
                                            for _, giftButton in ipairs(freeGifts.Frame.Container.Gifts:GetChildren()) do
                                                if giftButton:IsA("TextButton") then
                                                    local buttonSuccess, buttonResult = pcall(function()
                                                        giftButton:Activate()
                                                    end)
                                                    if buttonSuccess then
                                                        debugPrint("🎁 Clicked gift button:", giftButton.Name)
                                                    else
                                                        debugPrint("⚠️ Failed to click gift button", giftButton.Name, "(might be already activated):", buttonResult)
                                                    end
                                                end
                                            end
                                        end
                                        
                                        -- Keep spamming remote calls until timer is no longer "Ready!"
                                        local attempts = 0
                                        local maxAttempts = 50 -- Prevent infinite loop
                                        
                                        while attempts < maxAttempts do
                                            -- Check if timer is still "Ready!"
                                            local currentTimerText = "Ready!"
                                            if freeGiftsTop and freeGiftsTop:FindFirstChild("Button") and freeGiftsTop.Button:FindFirstChild("Timer") then
                                                currentTimerText = freeGiftsTop.Button.Timer.Text
                                            end
                                            
                                            if currentTimerText ~= "Ready!" then
                                                debugPrint("🎁 Timer changed to:", currentTimerText, "- stopping gift claiming")
                                                break
                                            end
                                            
                                            -- Use remote calls for gifts 1-12
                                            for i = 1, 12 do
                                                local args = {{i}}
                                                local success, result = pcall(function()
                                                    workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("redeem free gift"):InvokeServer(unpack(args))
                                                end)
                                                if success then
                                                    debugPrint("🎁 Claimed gift", i, "(attempt", attempts + 1, ")")
                                                else
                                                    debugPrint("❌ Failed to claim gift", i, ":", result)
                                                end
                                                task.wait(0.05) -- Shorter wait for faster claiming
                                            end
                                            
                                            attempts = attempts + 1
                                            task.wait(0.2) -- Small delay between attempts
                                        end
                                        
                                        if attempts >= maxAttempts then
                                            debugPrint("⚠️ Reached maximum attempts for gift claiming")
                                        end
                                        
                                        print("✅ Free gifts claiming completed!")
                                    end
                                else
                                    debugPrint("❌ Timer not found in Button")
                                end
                            else
                                debugPrint("❌ Button not found in FreeGiftsTop")
                            end
                        else
                            debugPrint("❌ FreeGiftsTop GUI not found")
                        end
                    end)
                    
                    if not success then
                        debugPrint("❌ Auto claim gifts error:", result)
                    end
                    
                    task.wait(10) -- Check every 10 seconds
                end
            end)
        else
            debugPrint("❌ Auto Claim Free Gifts disabled")
        end
    end
})

MainTab:AddToggle("AutoBuyDiamondsToggle", {
    Title = "Auto Buy Diamonds",
    Default = false,
    Callback = function(value)
        autoBuyDiamonds = value
        if value then
            debugPrint("✅ Auto Buy Diamonds enabled")
            print("Auto Buy Diamonds started! (Enable debug with getgenv().Debug = true)")
            spawn(function()
                while autoBuyDiamonds do
                    local success, result = pcall(function()
                        local player = game:GetService("Players").LocalPlayer
                        debugPrint("🔍 Checking for Main GUI...")
                        local techCoinsGui = player.PlayerGui:FindFirstChild("Main")
                        
                        if techCoinsGui then
                            debugPrint("✅ Found Main GUI")
                            if techCoinsGui:FindFirstChild("Right") then
                                debugPrint("✅ Found Right section")
                                if techCoinsGui.Right:FindFirstChild("Tech Coins") then
                                    debugPrint("✅ Found Tech Coins section")
                                    if techCoinsGui.Right["Tech Coins"]:FindFirstChild("Amount") then
                                        debugPrint("✅ Found Amount label")
                                    else
                                        debugPrint("❌ Amount label not found")
                                    end
                                else
                                    debugPrint("❌ Tech Coins section not found")
                                end
                            else
                                debugPrint("❌ Right section not found")
                            end
                        else
                            debugPrint("❌ Main GUI not found")
                        end
                        
                        if techCoinsGui and techCoinsGui:FindFirstChild("Right") and techCoinsGui.Right:FindFirstChild("Tech Coins") and techCoinsGui.Right["Tech Coins"]:FindFirstChild("Amount") then
                            local amountText = techCoinsGui.Right["Tech Coins"].Amount.Text
                            local currentAmount = parseCurrency(amountText)
                            
                            debugPrint("💎 Current Tech Coins:", amountText, "(parsed:", currentAmount, ")")
                            
                            if currentAmount >= diamondThreshold then
                                debugPrint("💎 Tech Coins above threshold, buying diamonds...")
                                
                                -- Click BestCurrency button once per execution
                                if not diamondButtonUsed then
                                    local exclusiveShop = player.PlayerGui:FindFirstChild("ExclusiveShop")
                                    if exclusiveShop and exclusiveShop:FindFirstChild("Frame") and exclusiveShop.Frame:FindFirstChild("Container") and exclusiveShop.Frame.Container:FindFirstChild("Diamonds") and exclusiveShop.Frame.Container.Diamonds:FindFirstChild("BestCurrency") then
                                        debugPrint("💎 Clicking BestCurrency button")
                                        exclusiveShop.Frame.Container.Diamonds.BestCurrency:Activate()
                                        diamondButtonUsed = true
                                        task.wait(1)
                                    end
                                end
                                
                                -- Buy diamond pack
                                local args = {{4}}
                                local buySuccess, buyResult = pcall(function()
                                    workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("buy diamond pack"):InvokeServer(unpack(args))
                                end)
                                
                                if buySuccess then
                                    debugPrint("💎 Diamond pack purchased")
                                    print("💎 Bought diamond pack!")
                                else
                                    debugPrint("❌ Failed to buy diamond pack:", buyResult)
                                end
                            end
                        end
                    end)
                    
                    if not success then
                        debugPrint("❌ Auto buy diamonds error:", result)
                    end
                    
                    task.wait(5) -- Check every 5 seconds
                end
            end)
        else
            debugPrint("❌ Auto Buy Diamonds disabled")
            diamondButtonUsed = false -- Reset for next execution
        end
    end
})

MainTab:AddSection("Information")

MainTab:AddParagraph("WelcomeParagraph", {
    Title = "Welcome",
    Content = "Made By Numa"
})

MainTab:AddParagraph("AutoFeatureInfo", {
    Title = "Auto Features Info",
    Content = "Auto Claim Free Gifts: Checks every 10s for 'Ready!' timer\nAuto Buy Diamonds: Activates when Tech Coins > 250b\nUse getgenv().Debug = true for detailed logs"
})

local openCrackedEgg = false
local autoCollectOrb = false
local optimizeEgg = false
local autoFarmEnabled = false
local selectedArea = "All Areas"
local petsPerCoin = 1

local function GetAreaNames()
    local areas = {"All Areas"}
    local areasFolder = workspace:WaitForChild("__MAP"):WaitForChild("Areas")
    for _, area in ipairs(areasFolder:GetChildren()) do
        if area.Name ~= "Shop" then
            table.insert(areas, area.Name)
        end
    end
    return areas
end

local function GetEquippedPetIDs()
    local ids = {}
    local petsFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Pets")
    for _, pet in ipairs(petsFolder:GetChildren()) do
        local owner = pet:GetAttribute("Owner")
        if owner == game.Players.LocalPlayer.UserId or owner == game.Players.LocalPlayer.Name then
            local petId = pet:GetAttribute("ID")
            if petId then
                table.insert(ids, petId)
            end
        end
    end
    return ids
end

local function FarmCoin(coinId, petIds)
    local remotes = workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES")
    remotes["join coin"]:InvokeServer({ [1] = coinId, [2] = petIds })
    remotes["farm coin"]:FireServer({ [1] = coinId, [2] = petIds[1] })
end

MainTab:AddToggle("AutoCollectOrbToggle", {
    Title = "Auto collect orb",
    Default = false,
    Callback = function(value)
        autoCollectOrb = value
        if autoCollectOrb then
            spawn(function()
                local remotes = workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES")
                local claimOrbsRemote = remotes:WaitForChild("claim orbs")
                while autoCollectOrb do
                    local orbsFolder = workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Orbs")
                    if orbsFolder then
                        for _, orb in pairs(orbsFolder:GetChildren()) do
                            if orb.Name then
                                local args = {{{orb.Name}}}
                                pcall(function()
                                    claimOrbsRemote:FireServer(unpack(args))
                                end)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

local FarmTab = Window:AddTab({
    Title = "Farm",
    Icon = "rbxassetid://7733960981"
})

local areaDropdown = FarmTab:AddDropdown("AreaDropdown", {
    Title = "Select Area",
    Values = GetAreaNames(),
    Default = "All Areas",
    Callback = function(value)
        selectedArea = value
    end
})

spawn(function()
    while true do
        areaDropdown:SetValues(GetAreaNames())
        task.wait(10)
    end
end)

FarmTab:AddDropdown("PetsPerCoinDropdown", {
    Title = "Pets Per Coin",
    Values = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
    Default = 1,
    Callback = function(value)
        petsPerCoin = value
    end
})

local upgradeOptions = {
    "Chest Damage",
    "Chest Coins",
    "Egg Luck",
    "Egg Quantity",
    "Egg Rainbow Luck",
    "Egg Golden Luck"
}

local selectedUpgrades = {}

FarmTab:AddDropdown("UpgradeDropdown", {
    Title = "Tech Chest Upgrades",
    Values = upgradeOptions,
    Multi = true,
    Default = {"Chest Coins"},

    Callback = function(values)
        selectedUpgrades = values
    end
})

spawn(function()
    while true do
        if #selectedUpgrades > 0 then
            for _, upgrade in ipairs(upgradeOptions) do
                if table.find(selectedUpgrades, upgrade) then
                    local args = {{upgrade}}
                    for i = 1, 2 do
                        workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("buy upgrade"):InvokeServer(unpack(args))
                    end
                end
            end
        end
        task.wait(60)
    end
end)

local lastCoinIndex = 0
local lastCheckTime = 0
local coins = {}
local petGroups = {}

FarmTab:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm Area",
    Default = false,
    Callback = function(value)
        autoFarmEnabled = value
        if autoFarmEnabled then
            spawn(function()
                while autoFarmEnabled do
                    local currentTime = os.clock()
                    if currentTime - lastCheckTime >= 10 then
                        lastCheckTime = currentTime

                        local petIds = {}
                        repeat
                            petIds = GetEquippedPetIDs()
                            if #petIds == 0 then
                                warn("No equipped pets found – retrying.")
                                task.wait(1)
                            end
                        until #petIds > 0

                        coins = {}
                        local coinsFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Coins")
                        for _, coinFolder in ipairs(coinsFolder:GetChildren()) do
                            local coinArea = coinFolder:GetAttribute("Area")
                            local coinId = tonumber(coinFolder.Name)
                            if coinId and (selectedArea == "All Areas" or coinArea == selectedArea) then
                                table.insert(coins, coinId)
                            end
                        end

                        petGroups = {}
                        for i = 1, #petIds, petsPerCoin do
                            local group = {}
                            for j = i, math.min(i + petsPerCoin - 1, #petIds) do
                                table.insert(group, petIds[j])
                            end
                            table.insert(petGroups, group)
                        end
                    end

                    if #coins > 0 and #petGroups > 0 then
                        for coinIndex = 1, #coins do
                            local coinId = coins[coinIndex]
                            local petGroup = petGroups[(coinIndex - 1) % #petGroups + 1]
                            FarmCoin(coinId, petGroup)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
})

local Egg = Window:AddTab({
    Title = "Egg",
    Icon = "rbxassetid://7733960981"
})

Egg:AddToggle("EggAnimationOptiToggle", {
    Title = "In dev Animation Optimization",
    Default = false,
    Callback = function(value)
        eggAnimationOptiEnabled = value
        if eggAnimationOptiEnabled then
            -- Make Pet UI invisible
            game:GetService("ReplicatedStorage").Assets.UI.Eggs.Opening.Pet.Visible = false

            -- Make all egg meshes transparent
            for _, eggFolder in ipairs(game:GetService("ReplicatedStorage").__DIRECTORY.Eggs:GetChildren()) do
                if eggFolder:IsA("Folder") then
                    for _, eggSubFolder in ipairs(eggFolder:GetChildren()) do
                        if eggSubFolder:IsA("Folder") then
                            local eggMesh = eggSubFolder:FindFirstChild("Egg")
                            if eggMesh and eggMesh:IsA("MeshPart") then
                                eggMesh.Transparency = 1
                            end
                        end
                    end
                end
            end

            -- Make Egg Open Info GUI invisible
            local eggOpenInfo = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Egg Open Info")
            if eggOpenInfo then
                eggOpenInfo.Enabled = false
            end

            -- Make FFlags EggOpening invisible
            local eggOpeningFrame = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("FFlags")
            if eggOpeningFrame and eggOpeningFrame:FindFirstChild("Frame") and eggOpeningFrame.Frame:FindFirstChild("Flags") then
                local eggOpeningFlag = eggOpeningFrame.Frame.Flags:FindFirstChild("EggOpening")
                if eggOpeningFlag then
                    eggOpeningFlag.Visible = false
                end
            end

            -- Make EggOpenPetInfo transparent
            local eggOpenPetInfo = game:GetService("ReplicatedStorage").Assets.Other:FindFirstChild("EggOpenPetInfo")
            if eggOpenPetInfo then
                eggOpenPetInfo.Transparency = 1
            end

            -- Make Egg Open Particles transparent
            local eggOpenParticles = game:GetService("ReplicatedStorage").Assets.Particles:FindFirstChild("Egg Open")
            if eggOpenParticles and eggOpenParticles:IsA("ParticleEmitter") then
                eggOpenParticles.Transparency = NumberSequence.new(1)
            end
        end
    end
})

local WebhookTab = Window:AddTab({
    Title = "Webhook",
    Icon = "rbxassetid://7733960981"
})


local webhookUrl = ""
local autoSendGlobal = false
local autoSendUseful = false
local autoSendInventory = false
local lastPetInventory = {}
local webhookInterval = 1
local forceSendWebhook = false
local discordUserId = ""
local player = game.Players.LocalPlayer

WebhookTab:AddInput("WebhookUrlInput", {
    Title = "Discord Webhook URL",
    Default = "",
    Placeholder = "Paste your Discord webhook URL here",
    Callback = function(value)
        webhookUrl = value
        if value ~= "" then
            print("✅ Webhook URL set:", string.sub(value, 1, 50) .. "...")
            debugPrint("✅ Webhook URL set to:", value)
        else
            print("❌ Webhook URL cleared")
            debugPrint("❌ Webhook URL cleared from input")
        end
    end
})

WebhookTab:AddInput("DiscordUserIdInput", {
    Title = "Discord User ID (for ping)",
    Default = "",
    Placeholder = "Enter your Discord user ID",
    Callback = function(value)
        discordUserId = value
    end
})
WebhookTab:AddDropdown("WebhookIntervalDropdown", {
    Title = "Send Interval (minutes)",
    Values = {1,2,3,5,10,15,30,60},
    Default = 1,
    Callback = function(value)
        webhookInterval = tonumber(value)
    end
})

WebhookTab:AddToggle("AutoSendGlobalToggle", {
    Title = "Auto Send Global Stats",
    Default = false,
    Callback = function(value)
        autoSendGlobal = value
        if value then
            print("✅ Global stats webhook enabled")
            debugPrint("✅ Global stats webhook toggle: ENABLED")
        else
            print("❌ Global stats webhook disabled")
            debugPrint("❌ Global stats webhook toggle: DISABLED")
        end
    end
})

WebhookTab:AddToggle("AutoSendUsefulToggle", {
    Title = "Auto Send Useful Stats",
    Default = false,
    Callback = function(value)
        autoSendUseful = value
        if value then
            print("✅ Useful stats webhook enabled")
            debugPrint("✅ Useful stats webhook toggle: ENABLED")
        else
            print("❌ Useful stats webhook disabled")
            debugPrint("❌ Useful stats webhook toggle: DISABLED")
        end
    end
})

WebhookTab:AddToggle("AutoSendInventoryToggle", {
    Title = "Auto Send Inventory (All Pets)",
    Default = false,
    Callback = function(value)
        autoSendInventory = value
        if value then
            print("✅ Inventory webhook enabled")
            debugPrint("✅ Inventory webhook toggle: ENABLED")
        else
            print("❌ Inventory webhook disabled")
            debugPrint("❌ Inventory webhook toggle: DISABLED")
        end
    end
})

WebhookTab:AddButton({
    Title = "Force Send Webhook",
    Callback = function()
        forceSendWebhook = true
        print("🚀 Force sending webhook...")
        debugPrint("🚀 Force send webhook button pressed, forceSendWebhook flag set to true")
    end
})

-- Enhanced Webhook System with proper pet tracking
-- Note: webhookUrl and other variables are already declared above, no need to redeclare

-- Enhanced pet tracking functions
local function getPetCounts(pets)
    local petCount = {}
    for _, pet in ipairs(pets) do
        local id = pet.id or "Unknown"
        petCount[id] = (petCount[id] or 0) + 1
    end
    return petCount
end

local function formatCurrency(amount)
    if amount >= 1e12 then
        return string.format("%.2fT", amount / 1e12)
    elseif amount >= 1e9 then
        return string.format("%.2fB", amount / 1e9)
    elseif amount >= 1e6 then
        return string.format("%.2fM", amount / 1e6)
    elseif amount >= 1e3 then
        return string.format("%.2fK", amount / 1e3)
    else
        return tostring(amount)
    end
end

local function getCoinStats(stats)
    local coins = {}
    for k, v in pairs(stats) do
        if type(v) == "number" and (k:find("Coin") or k:find("Gingerbread") or k:find("Candy") or k:find("Diamonds")) then
            coins[k] = v
        end
    end
    return coins
end

-- File-based pet inventory tracking
local function saveLastInventory(userId, inventory)
    local filePath = "last_inventory_" .. tostring(userId) .. ".json"
    local HttpService = game:GetService("HttpService")
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, inventory)
    if success then
        writefile(filePath, encoded)
    end
end

local function loadLastInventory(userId)
    local filePath = "last_inventory_" .. tostring(userId) .. ".json"
    if isfile(filePath) then
        local content = readfile(filePath)
        local HttpService = game:GetService("HttpService")
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        if success then
            return decoded
        end
    end
    return {}
end

local function compareInventories(oldInventory, newInventory)
    local changes = {
        newPets = {},
        increasedCounts = {}
    }
    
    for petType, newCount in pairs(newInventory) do
        local oldCount = oldInventory[petType] or 0
        if oldCount == 0 then
            -- Completely new pet type
            table.insert(changes.newPets, {type = petType, count = newCount})
        elseif newCount > oldCount then
            -- Increased count of existing pet type
            local difference = newCount - oldCount
            table.insert(changes.increasedCounts, {type = petType, difference = difference, total = newCount})
        end
    end
    
    return changes
end

local function formatPetInventory(petCounts)
    local petLines = {}
    for petType, count in pairs(petCounts) do
        local emoji = "🐾"
        local line = emoji .. " " .. petType .. (count > 1 and (" x" .. count) or "")
        table.insert(petLines, line)
    end
    return petLines
end

local function formatCoinList(coinStats)
    local coinLines = {}
    for coinType, amount in pairs(coinStats) do
        local emoji = "🪙"
        local line = emoji .. " " .. coinType .. ": " .. formatCurrency(amount)
        table.insert(coinLines, line)
    end
    return coinLines
end

-- Enhanced webhook loop with proper pet detection and Discord pings
spawn(function()
    local lastSent = os.clock()
    print("🔄 Webhook system started")
    debugPrint("🔄 Webhook system initialized with debug mode enabled")
    while true do
        local now = os.clock()
        if webhookUrl ~= "" and ((now - lastSent) >= webhookInterval * 60 or forceSendWebhook) then
            debugPrint("📡 Attempting to send webhook...")
            print("📡 Sending webhook...")
            lastSent = now
            forceSendWebhook = false
            
            local success, statsResult = pcall(function()
                local statsRemote = workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("get stats")
                return statsRemote:InvokeServer({player})[1]
            end)
            
            if not success then
                warn("❌ Failed to get player stats:", statsResult)
                task.wait(1)
            end
            
            local stats = statsResult
            local embeds = {}
            
            -- Global Stats
            if autoSendGlobal then
                local coinStats = getCoinStats(stats)
                local coinList = formatCoinList(coinStats)
                
                table.insert(embeds, {
                    title = "🌍 Global Stats for " .. player.Name,
                    color = 3447003,
                    fields = {
                        {name = "🏆 Rank", value = stats.Rank or "N/A", inline = true},
                        {name = "💎 Diamonds", value = formatCurrency(stats.Diamonds or 0), inline = true},
                        {name = "🌍 World", value = stats.World or "Unknown", inline = true},
                        {name = "🔓 Areas Unlocked", value = tostring((stats.AreasUnlocked and #stats.AreasUnlocked) or 0), inline = true},
                        {name = "🥚 Total Eggs Opened", value = tostring(stats.EggOpenCount or 0), inline = true},
                        {name = "🪙 Currencies", value = table.concat(coinList, "\n"), inline = false}
                    },
                    footer = {text = "📢 Generated via Enhanced Stats Reporter | " .. os.date("%Y-%m-%d %H:%M:%S")}
                })
            end
            
            -- Useful Stats with improved coin display
            if autoSendUseful then
                local coinStats = getCoinStats(stats)
                local coinList = formatCoinList(coinStats)
                
                table.insert(embeds, {
                    title = "✨ Useful Stats for " .. player.Name,
                    color = 15844367,
                    fields = {
                        {name = "🥚 Total Eggs Opened", value = tostring(stats.EggOpenCount or 0), inline = true},
                        {name = "🪙 All Currencies", value = table.concat(coinList, "\n"), inline = false}
                    },
                    footer = {text = "✨ Useful Stats | " .. os.date("%Y-%m-%d %H:%M:%S")}
                })
            end
            
            -- Enhanced Pet Inventory with change detection and Discord pings
            if autoSendInventory then
                local pets = stats.Pets or {}
                local currentPetCounts = getPetCounts(pets)
                local lastInventory = loadLastInventory(stats.UserId)
                local changes = compareInventories(lastInventory, currentPetCounts)
                
                local petLines = formatPetInventory(currentPetCounts)
                local inventoryFields = {
                    {name = "All Pets", value = #petLines > 0 and table.concat(petLines, "\n") or "No pets", inline = false}
                }
                
                local shouldPing = false
                local pingMessage = ""
                
                -- Add new pets information
                if #changes.newPets > 0 then
                    local newPetLines = {}
                    for _, newPet in ipairs(changes.newPets) do
                        table.insert(newPetLines, "🆕 " .. newPet.type .. " x" .. newPet.count)
                    end
                    table.insert(inventoryFields, {name = "🆕 New Pet Types", value = table.concat(newPetLines, "\n"), inline = false})
                    shouldPing = true
                    pingMessage = "New pet type(s) discovered!"
                end
                
                -- Add increased counts information
                if #changes.increasedCounts > 0 then
                    local increasedLines = {}
                    for _, increased in ipairs(changes.increasedCounts) do
                        table.insert(increasedLines, "📈 " .. increased.type .. " +" .. increased.difference .. " (Total: " .. increased.total .. ")")
                    end
                    table.insert(inventoryFields, {name = "📈 Pet Count Increases", value = table.concat(increasedLines, "\n"), inline = false})
                    if not shouldPing then
                        shouldPing = true
                        pingMessage = "Pet count increased!"
                    end
                end
                
                if #changes.newPets == 0 and #changes.increasedCounts == 0 then
                    table.insert(inventoryFields, {name = "📊 Status", value = "No new pets since last check", inline = false})
                end
                
                table.insert(embeds, {
                    title = "🐾 Pet Inventory for " .. player.Name,
                    color = 3066993,
                    fields = inventoryFields,
                    footer = {text = "🐾 Pet Inventory | " .. os.date("%Y-%m-%d %H:%M:%S")}
                })
                
                -- Save current inventory for next comparison
                saveLastInventory(stats.UserId, currentPetCounts)
            end
            
            -- Send webhook if any embeds were created
            if #embeds > 0 then
                debugPrint("📦 Creating webhook payload with", #embeds, "embeds")
                local payload = {
                    username = game.Players.LocalPlayer.Name .. "'s Enhanced Stats",
                    embeds = embeds
                }
                
                -- Add Discord ping if new pets were found
                if shouldPing and discordUserId ~= "" then
                    payload.content = "<@" .. discordUserId .. "> " .. pingMessage
                    debugPrint("🔔 Adding Discord ping:", pingMessage)
                end
                
                local HttpService = game:GetService("HttpService")
                local success, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
                if success then
                    debugPrint("✅ Payload encoded successfully")
                    
                    -- Enhanced HTTP request function detection with debug info
                    -- Simplified HTTP function detection (matching working version)
                    local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or krnl and krnl.request or request
                    local executorName = "HTTP Request Function"
                    
                    if requestFunc then
                        debugPrint("🌐 Sending webhook to:", string.sub(webhookUrl, 1, 50) .. "...")
                        print("🌐 Sending webhook...")
                        
                        local response = requestFunc({
                            Url = webhookUrl,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = encoded
                        })
                        
                        if response.StatusCode == 204 then
                            print("✅ Webhook sent successfully!")
                            if shouldPing then
                                print("🔔 Discord ping sent:", pingMessage)
                            end
                        else
                            warn("❌ Webhook error (Code " .. response.StatusCode .. "): " .. response.Body)
                        end
                    else
                        warn("❌ No HTTP request function available")
                        warn("❌ Available functions: syn.request=", syn and syn.request and "YES" or "NO")
                        warn("❌ Available functions: http.request=", http and http.request and "YES" or "NO")
                        warn("❌ Available functions: http_request=", http_request and "YES" or "NO")
                        warn("❌ Available functions: request=", request and "YES" or "NO")
                    end
                else
                    warn("❌ Failed to encode webhook payload:", encoded)
                end
            else
                debugPrint("⚠️ No embeds to send (check if webhook toggles are enabled)")
            end
        elseif webhookUrl == "" then
            -- Only show this message once every 60 seconds to avoid spam
            if now - lastSent >= 60 then
                debugPrint("⚠️ Webhook URL not set")
                lastSent = now
            end
        end
        task.wait(1)
    end
end)

local MiscTab = Window:AddTab({
    Title = "Misc",
    Icon = "rbxassetid://7733960981"
})

local OptimizationTab = Window:AddTab({
    Title = "Optimization",
    Icon = "rbxassetid://7733960981"
})

OptimizationTab:AddToggle("DeleteLootbagsToggle", {
    Title = "Delete Lootbags",
    Default = false,
    Callback = function(value)
        deleteLootbagsEnabled = value
        if deleteLootbagsEnabled then
            spawn(function()
                while deleteLootbagsEnabled do
                    for _, lootbag in ipairs(workspace.__THINGS.Lootbags:GetChildren()) do
                        lootbag:Destroy()
                    end
                    task.wait(10)
                end
            end)
        end
    end
})

OptimizationTab:AddToggle("DisableLightingSkyToggle", {
    Title = "Disable Lightning / Sky",
    Default = false,
    Callback = function(value)
        disableLightingSkyEnabled = value
        local lightingFolder = Instance.new("Folder")
        lightingFolder.Name = "LightingBackup"
        if disableLightingSkyEnabled then
            for _, item in ipairs(game:GetService("Lighting"):GetChildren()) do
                item.Parent = lightingFolder
            end
            lightingFolder.Parent = game
        else
            for _, item in ipairs(lightingFolder:GetChildren()) do
                item.Parent = game:GetService("Lighting")
            end
            lightingFolder:Destroy()
        end
    end
})

OptimizationTab:AddParagraph("WarningParagraph", {
    Title = "⚠️ Warning: Some features may break game mechanics",
    Default = false,
    Callback = function(value)
        warningEnabled = value
    end
})

OptimizationTab:AddToggle("DisableMapToggle", {
    Title = "⚠️ Disable Map",
    Default = false,
    Callback = function(value)
        disableMapEnabled = value
        if disableMapEnabled then
            for _, area in ipairs(workspace.__MAP.Areas:GetChildren()) do
                if area.Name ~= "Spawn" and area.Name ~= "Shop" then
                    for _, item in ipairs(area:GetChildren()) do
                        if item.Name ~= "Ground" then
                            item:Destroy()
                        end
                    end
                end
            end
        end
    end
})

OptimizationTab:AddToggle("BetaOptiToggle", {
    Title = "⚠️ BETA OPTI",
    Default = false,
    Callback = function(value)
        betaOptiEnabled = value
        if betaOptiEnabled then
            game:GetService("ReplicatedStorage").Assets.Particles:Destroy()
        end
    end
})

MiscTab:AddButton({
    Title = "Redeem Codes",
    Callback = function()
        local codesUrl = "https://github.com/Numass/Riboutaid/raw/refs/heads/main/codes.txt"
        local success, codes = pcall(function()
            return loadstring(game:HttpGet(codesUrl))()
        end)

        if success and codes then
            for code in string.gmatch(codes, "[^]+") do
                local args = {{code}}
                workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("redeem twitter code"):InvokeServer(unpack(args))
            end
        else
            local fallbackCodes = {
                "300ccu",
                "700favorites",
                "600likes",
                "200kvisits"
            }
            for _, code in ipairs(fallbackCodes) do
                local args = {{code}}
                workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("redeem twitter code"):InvokeServer(unpack(args))
            end
            -- Use fallbackCodes as needed
        end
    end
})

local antiAFKEnabled = true

MainTab:AddToggle("AntiAFKToggle", {
    Title = "Anti AFK",
    Default = true,
    Callback = function(value)
        antiAFKEnabled = value
        if antiAFKEnabled then
            spawn(function()
                local VirtualUser = game:GetService("VirtualUser")
                while antiAFKEnabled do
                    wait(60)
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end
            end)
        end
    end
})

local selectedEgg = "Metal Egg"
local goldenEggEnabled = false
local numberOfEggs = 1

local eggsDirModule = game:GetService("ReplicatedStorage").__DIRECTORY.Eggs["Grab All Eggs"]

local allEggs = require(eggsDirModule)  -- { ["Egg Name"] = eggData, ... }

-- 2) Extract, sort, and filter out golden eggs
local eggNames = {}
for name, data in pairs(allEggs) do
    if data.hatchable and not data.isGolden then
        table.insert(eggNames, name)
    end
end
table.sort(eggNames)

Egg:AddDropdown("EggDropdown", {
    Title = "Select Egg",
    Values = eggNames,
    Default = "Metal Egg",
    Search = true,
    Callback = function(value)
        selectedEgg = value
    end
})

Egg:AddToggle("GoldenEggToggle", {
    Title = "Golden Egg",
    Default = false,
    Callback = function(value)
        goldenEggEnabled = value
    end
})

Egg:AddDropdown("NumberOfEggsDropdown", {
    Title = "Number of Eggs",
    Values = {1, 3},
    Default = 1,
    Callback = function(value)
        numberOfEggs = value
    end
})

Egg:AddToggle("AutoHatchToggle", {
    Title = "Auto Hatch Egg",
    Default = false,
    Callback = function(value)
        autoHatchEnabled = value
        if autoHatchEnabled then
            spawn(function()
                while autoHatchEnabled do
                    local eggName = selectedEgg
                    if goldenEggEnabled then
                        eggName = "Golden " .. eggName
                    end

                    local args = {
                        {
                            eggName,
                            numberOfEggs == 3
                        }
                    }
                    workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("buy egg"):InvokeServer(unpack(args))

                    task.wait(0.15)
                end
            end)
        end
    end
})

local SaveSettingsTab = Window:AddTab({
    Title = "Save Settings",
    Icon = "rbxassetid://7733960981"
})

local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Numass/SaveManagerFluentReworked/refs/heads/main/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Numass/SaveManagerFluentReworked/refs/heads/main/InterfaceManager.luau"))()

SaveManager:SetLibrary(LibraryUI)
InterfaceManager:SetLibrary(LibraryUI)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("PSXRebooted")
SaveManager:SetFolder("PSXRebooted/Settings")
InterfaceManager:BuildInterfaceSection(SaveSettingsTab)
SaveManager:BuildConfigSection(SaveSettingsTab)
SaveManager:LoadAutoloadConfig()
