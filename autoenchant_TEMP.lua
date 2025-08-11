-- Auto Enchant Script by RIBOUTAID (owned by Numass)
-- Fluent UI Auto Enchant System

-- Safe service loading with error handling
local RunService, Players, player, m_Library
local serviceSuccess = true
RunService = game:GetService("RunService")
Players = game:GetService("Players")
player = Players.LocalPlayer

local replicatedStorage = game:GetService("ReplicatedStorage")
local framework = replicatedStorage:WaitForChild("Framework", 10)
if not framework then
    error("Framework not found in ReplicatedStorage")
end

local library = framework:WaitForChild("Library", 10)
if not library then
    error("Library not found in Framework")
end

m_Library = require(library)


if not serviceSuccess then
    warn("[Auto Enchant] Failed to load game services or library")
    warn("[Auto Enchant] Please ensure the game is fully loaded")
    return
end

-- Wait for library to load with timeout
local loadTimeout = 0
while not m_Library.Loaded and loadTimeout < 30 do 
    RunService.Heartbeat:Wait()
    loadTimeout = loadTimeout + 0.1
end

if not m_Library.Loaded then
    warn("[Auto Enchant] Library failed to load within 30 seconds")
    warn("[Auto Enchant] Please try again when the game is fully loaded")
    return
end

print("[Auto Enchant] Library loaded successfully!")

-- Auto Enchant Variables
local autoEnchantEnabled = false
local selectedPetNames = {}
local selectedEnchants = {}
local selectedLevels = {}
local enchantQueue = {}
local currentBatch = {}
local isEnchanting = false

-- Pet Names Cache
local petNamesCache = {}
local petNamesCacheFile = "pet_names_cache.json"
local petNamesDropdownRef -- optional reference to UI dropdown for live updates

-- Helper Functions from provided scripts
local function trim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end
local function lower(s) return tostring(s):lower() end

local function getSave()
    if m_Library.Save and m_Library.Save.Get then
        return m_Library.Save.Get()
    end
    return nil
end

local function getPetEntry(uid)
    if not uid then return nil end
    if m_Library.PetCmds and m_Library.PetCmds.Get then
        local ok, entry = pcall(m_Library.PetCmds.Get, uid)
        if ok and type(entry) == "table" then
            return entry
        end
    end
    local save = getSave()
    if save and save.Pets then
        for _, p in ipairs(save.Pets) do
            if p.uid == uid then
                return p
            end
        end
    end
    return nil
end

local function translatePower(powerTuple)
    if not powerTuple or type(powerTuple) ~= "table" then return nil end
    local id = powerTuple[1]
    local lvl = powerTuple[2]
    if not id then return nil end

    local readable = nil
    if m_Library.Shared and m_Library.Shared.GetPowerDir then
        local ok, res = pcall(m_Library.Shared.GetPowerDir, id, lvl)
        if ok and type(res) == "table" then
            readable = {
                id = id,
                level = lvl,
                title = res.title or res.name or tostring(id),
                meta = res
            }
        end
    end

    if not readable then
        readable = {
            id = id,
            level = lvl,
            title = tostring(id)
        }
    end

    return readable
end

local function getPetEnchants(uid)
    local pet = getPetEntry(uid)
    if not pet then return {} end

    local powers = pet.powers or pet.pwr or pet.enchants
    if not powers or type(powers) ~= "table" then
        return {}
    end

    local out = {}
    for _, tuple in ipairs(powers) do
        local r = translatePower(tuple)
        if r then table.insert(out, r) end
    end
    return out
end

local function canEnchantPet(uid)
    if not uid then return false, "invalid_uid" end

    local pet = getPetEntry(uid)
    if not pet then return false, "no_pet" end

    local dir = m_Library.Directory and m_Library.Directory.Pets and m_Library.Directory.Pets[pet.id]
    if not dir then return false, "no_directory_entry" end

    if dir.isPremium then return false, "premium_pet" end
    if dir.isGift then return false, "gift_pet" end

    local rarity = dir.rarity or ""
    if rarity == "Secret" or rarity == "Mythical" or rarity == "Event" or rarity == "Exclusive" then
        return false, "rarity_not_allowed"
    end

    local inBooth = false
    local boothSuccess = pcall(function()
        if m_Library.Signal and m_Library.Signal.Invoke then
            inBooth = m_Library.Signal.Invoke("Is Trading Booth Pet", uid)
        end
    end)
    
    if not boothSuccess then
        warn("[Auto Enchant] Could not check trading booth status for pet " .. tostring(uid))
    end
    
    if inBooth then return false, "in_trading_booth" end

    return true, "ok"
end

local function getAllAvailableEnchants()
    local result = {}
    for powerKey, powerVal in pairs(m_Library.Directory and m_Library.Directory.Powers or {}) do
        if type(powerVal) == "table" and type(powerVal.tiers) == "table" and powerVal.canDrop then
            local baseName = powerVal.name or powerVal.title or powerKey
            result[baseName] = {
                powerKey = powerKey,
                tiers = powerVal.tiers,
                name = baseName
            }
        end
    end
    return result
end

local function getAllPetNames()
    local save = getSave()
    if not save or not save.Pets then return {} end
    
    local petNames = {}
    local nameSet = {}
    
    for _, petEntry in ipairs(save.Pets) do
        local dir = m_Library.Directory and m_Library.Directory.Pets and m_Library.Directory.Pets[petEntry.id]
        if dir then
            local name = dir.name
            if name and not nameSet[name] then
                local canEnchant, _ = canEnchantPet(petEntry.uid)
                if canEnchant then
                    nameSet[name] = true
                    table.insert(petNames, name)
                end
            end
        end
    end
    
    table.sort(petNames)
    return petNames
end

-- Cache helpers (defined after getAllPetNames)
local function readPetNamesCache()
    local ok, result = pcall(function()
        if isfile and isfile(petNamesCacheFile) then
            local raw = readfile(petNamesCacheFile)
            local decoded = game.HttpService:JSONDecode(raw)
            if type(decoded) == "table" then return decoded end
        end
        return nil
    end)
    if ok then return result or nil end
    return nil
end

local function writePetNamesCache(names)
    pcall(function()
        if writefile then
            local encoded = game.HttpService:JSONEncode(names)
            writefile(petNamesCacheFile, encoded)
        end
    end)
end

-- Compute pet names safely and update cache
local function computeAndCachePetNames()
    local names = {}
    local ok, err = pcall(function()
        names = getAllPetNames()
    end)
    if not ok then
        warn("[Auto Enchant] Failed to compute pet names: " .. tostring(err))
        names = {}
    end
    writePetNamesCache(names)
    petNamesCache = names
    -- If UI dropdown exists, update it on the fly (safe)
     if petNamesDropdownRef then
         pcall(function()
             petNamesDropdownRef:SetValues(petNamesCache)
             print("[Auto Enchant] Pet list updated and cached")
         end)
     end
    return names
end

-- Initialize pet names cache from file first so UI can read immediately without touching services
petNamesCache = readPetNamesCache() or {}
-- Recompute and persist fresh names asynchronously (won't block UI init)
spawn(function()
    computeAndCachePetNames()
end)

local function getPetsByName(petName)
    local save = getSave()
    if not save or not save.Pets then return {} end
    
    local pets = {}
    for _, petEntry in ipairs(save.Pets) do
        local dir = m_Library.Directory and m_Library.Directory.Pets and m_Library.Directory.Pets[petEntry.id]
        if dir and dir.name == petName then
            local canEnchant, _ = canEnchantPet(petEntry.uid)
            if canEnchant then
                table.insert(pets, petEntry)
            end
        end
    end
    
    return pets
end

local function petHasTargetEnchant(uid, targetEnchantName, targetLevel)
    local enchants = getPetEnchants(uid)
    for _, enchant in ipairs(enchants) do
        if enchant.title and enchant.title:find(targetEnchantName) and enchant.level >= targetLevel then
            return true
        end
    end
    return false
end

local function petNeedsAnyTargetEnchant(uid)
    -- Check if pet needs any of the selected enchants at the selected levels
    for _, enchantName in ipairs(selectedEnchants) do
        for _, level in ipairs(selectedLevels) do
            if not petHasTargetEnchant(uid, enchantName, level) then
                return true
            end
        end
    end
    return false
end

local function getPetEnchantCount(uid)
    local enchants = getPetEnchants(uid)
    return #enchants
end

local function buildEnchantQueue()
    enchantQueue = {}
    
    for _, petName in ipairs(selectedPetNames) do
        local pets = getPetsByName(petName)
        for _, pet in ipairs(pets) do
            -- Check if pet needs any target enchant and has space for enchants (max 3)
            local currentEnchantCount = getPetEnchantCount(pet.uid)
            local needsEnchant = petNeedsAnyTargetEnchant(pet.uid)
            
            -- Only add to queue if pet needs enchant and has less than 3 enchants
            -- OR if pet has enchants but they're not the target ones (will be replaced)
            if needsEnchant then
                table.insert(enchantQueue, {
                    uid = pet.uid,
                    name = petName,
                    currentEnchants = currentEnchantCount
                })
            end
        end
    end
    
    -- Sort queue: prioritize pets with fewer enchants first
    table.sort(enchantQueue, function(a, b)
        return a.currentEnchants < b.currentEnchants
    end)
end

local function enchantPets(petUids)
    if #petUids == 0 then return false end
    
    local args = { { petUids, false } }
    local success, result = pcall(function()
        local things = workspace:FindFirstChild("__THINGS")
        if not things then
            warn("[Auto Enchant] __THINGS not found in workspace")
            return false
        end
        
        local remotes = things:FindFirstChild("__REMOTES")
        if not remotes then
            warn("[Auto Enchant] __REMOTES not found")
            return false
        end
        
        local enchantRemote = remotes:FindFirstChild("enchant pets")
        if not enchantRemote then
            warn("[Auto Enchant] enchant pets remote not found")
            return false
        end
        
        return enchantRemote:InvokeServer(unpack(args))
    end)
    
    if not success then
        warn("[Auto Enchant] Failed to enchant pets: " .. tostring(result))
        return false
    end
    
    return result
end

local function autoEnchantLoop()
    spawn(function()
        while autoEnchantEnabled do
            if not isEnchanting and #enchantQueue > 0 then
                 isEnchanting = true
                
                -- Take up to 3 pets from queue
                local batchPets = {}
                local batchUids = {}
                for i = 1, math.min(3, #enchantQueue) do
                    local petData = table.remove(enchantQueue, 1)
                    table.insert(batchPets, petData)
                    table.insert(batchUids, petData.uid)
                end
                
                if #batchPets > 0 then
                    print("[Auto Enchant] Enchanting", #batchPets, "pets...")
                    for _, petData in ipairs(batchPets) do
                        print("  - Pet UID:", petData.uid, "(Current enchants:", petData.currentEnchants .. "/3)")
                    end
                    local success = enchantPets(batchUids)
                    
                    if success then
                        print("[Auto Enchant] Enchanting successful, waiting for completion...")
                        wait(0.7) -- Wait for enchanting to complete
                        
                        -- Check if pets got desired enchants, if not, add them back to queue
                        for _, petData in ipairs(batchPets) do
                            local uid = petData.uid
                            local stillNeedsEnchant = petNeedsAnyTargetEnchant(uid)
                            local newEnchantCount = getPetEnchantCount(uid)
                            
                            if stillNeedsEnchant and newEnchantCount < 3 then
                                -- Pet still needs enchant and has space, add back to queue
                                table.insert(enchantQueue, {
                                    uid = uid,
                                    name = petData.name,
                                    currentEnchants = newEnchantCount
                                })
                                print("[Auto Enchant] Pet", uid, "still needs enchanting (", newEnchantCount .. "/3 enchants)")
                            elseif not stillNeedsEnchant then
                                print("[Auto Enchant] Pet", uid, "successfully enchanted! (", newEnchantCount .. "/3 enchants)")
                            else
                                print("[Auto Enchant] Pet", uid, "is full (3/3 enchants) but doesn't have target enchants")
                            end
                        end
                    else
                        print("[Auto Enchant] Enchanting failed, adding pets back to queue")
                        for _, petData in ipairs(batchPets) do
                            table.insert(enchantQueue, petData)
                        end
                    end
                end
                
                isEnchanting = false
            end
            
            -- Rebuild queue periodically to catch new pets
            if #enchantQueue == 0 then
                buildEnchantQueue()
                if #enchantQueue == 0 then
                    print("[Auto Enchant] All selected pets have been enchanted!")
                    wait(5) -- Wait before checking again
                end
            end
            
            wait(1)
        end
    end)
end

-- Console command system for fallback
local function setupConsoleCommands()
    local commands = {
        ["/enchant_start"] = function()
            if #selectedPetNames == 0 or #selectedEnchants == 0 or #selectedLevels == 0 then
                warn("[Auto Enchant] Please configure pets, enchants, and levels first")
                warn("[Auto Enchant] Use /enchant_config to see current settings")
                return
            end
            autoEnchantEnabled = true
            buildEnchantQueue()
            print("[Auto Enchant] Started with", #enchantQueue, "pets in queue")
            autoEnchantLoop()
        end,
        ["/enchant_stop"] = function()
            autoEnchantEnabled = false
            print("[Auto Enchant] Stopped")
        end,
        ["/enchant_status"] = function()
            print("[Auto Enchant] Status:", autoEnchantEnabled and "Running" or "Stopped")
            print("[Auto Enchant] Queue:", #enchantQueue, "pets")
            print("[Auto Enchant] Currently enchanting:", isEnchanting)
        end,
        ["/enchant_config"] = function()
            print("[Auto Enchant] Configuration:")
            print("  Pet Names:", table.concat(selectedPetNames, ", "))
            print("  Enchants:", table.concat(selectedEnchants, ", "))
            print("  Levels:", table.concat(selectedLevels, ", "))
        end
    }
    
    -- Set up default configuration for console mode
    selectedPetNames = {"Astral Axolotl"} -- Target pet
    selectedEnchants = {"Rainbow Coins"} -- Target enchant
    selectedLevels = {5} -- Target level
    
    print("[Auto Enchant] Console commands available:")
    for cmd, _ in pairs(commands) do
        print("  " .. cmd)
    end
    print("[Auto Enchant] Default configuration loaded. Use /enchant_config to view.")
    
    return commands
end

-- Console commands are always available; UI is attached later if possible
local Window, InfoTab, EnchantTab, CreditsTab
local consoleCommands = setupConsoleCommands()
if player and player.Chatted then
    player.Chatted:Connect(function(message)
        local cmd = message:lower()
        if consoleCommands[cmd] then
            consoleCommands[cmd]()
        end
    end)
end

-- UI completely disabled due to Instance capability requirements
-- UI completely disabled to prevent Instance capability errors
warn("[Auto Enchant] Fluent UI disabled - your executor lacks Plugin capability")
warn("[Auto Enchant] Script will run in console mode only")
print("[Auto Enchant] Available commands:")
print("  /enchant_start - Start auto enchanting")
print("  /enchant_stop - Stop auto enchanting")
print("  /enchant_status - Show current status")
print("  /enchant_config - Show current configuration")

-- Simple command input GUI (no remote dependencies)
local function createSimpleCommandGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoEnchantCommands"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 120)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.BorderSizePixel = 0
    title.Text = "Auto Enchant Commands"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -10, 0, 30)
    textBox.Position = UDim2.new(0, 5, 0, 35)
    textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textBox.BorderSizePixel = 1
    textBox.BorderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.Text = ""
    textBox.PlaceholderText = "Enter command (e.g., /enchant_start)"
    textBox.TextColor3 = Color3.fromRGB(0, 0, 0)
    textBox.TextScaled = true
    textBox.Font = Enum.Font.SourceSans
    textBox.Parent = frame
    
    local executeButton = Instance.new("TextButton")
    executeButton.Size = UDim2.new(0, 100, 0, 30)
    executeButton.Position = UDim2.new(0, 5, 0, 75)
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    executeButton.BorderSizePixel = 0
    executeButton.Text = "Execute"
    executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeButton.TextScaled = true
    executeButton.Font = Enum.Font.SourceSansBold
    executeButton.Parent = frame
    
    local helpButton = Instance.new("TextButton")
    helpButton.Size = UDim2.new(0, 100, 0, 30)
    helpButton.Position = UDim2.new(0, 115, 0, 75)
    helpButton.BackgroundColor3 = Color3.fromRGB(0, 0, 120)
    helpButton.BorderSizePixel = 0
    helpButton.Text = "Help"
    helpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    helpButton.TextScaled = true
    helpButton.Font = Enum.Font.SourceSansBold
    helpButton.Parent = frame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 60, 0, 30)
    closeButton.Position = UDim2.new(0, 225, 0, 75)
    closeButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = frame
    
    -- Execute command function
    local function executeCommand()
        local command = textBox.Text:lower():gsub("^%s*(.-)%s*$", "%1")
        if command ~= "" then
            if consoleCommands[command] then
                consoleCommands[command]()
                textBox.Text = ""
            else
                warn("[Auto Enchant] Unknown command: " .. command)
                warn("[Auto Enchant] Available commands: /enchant_start, /enchant_stop, /enchant_status, /enchant_config")
            end
        end
    end
    
    -- Button connections
    executeButton.MouseButton1Click:Connect(executeCommand)
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            executeCommand()
        end
    end)
    
    helpButton.MouseButton1Click:Connect(function()
        print("[Auto Enchant] Available commands:")
        print("  /enchant_start - Start auto enchanting")
        print("  /enchant_stop - Stop auto enchanting")
        print("  /enchant_status - Show current status")
        print("  /enchant_config - Show current configuration")
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    return screenGui
end

-- Create the simple command GUI
local commandGUI = createSimpleCommandGUI()
print("[Auto Enchant] Command GUI created. Use the text box to enter commands.")

-- Cache helpers (defined early so they can be used anywhere)
local function readPetNamesCache()
    local ok, result = pcall(function()
        if isfile and isfile(petNamesCacheFile) then
            local raw = readfile(petNamesCacheFile)
            local decoded = game.HttpService:JSONDecode(raw)
            if type(decoded) == "table" then return decoded end
        end
        return nil
    end)
    if ok then return result or nil end
    return nil
end

local function writePetNamesCache(names)
    pcall(function()
        if writefile then
            local encoded = game.HttpService:JSONEncode(names)
            writefile(petNamesCacheFile, encoded)
        end
    end)
end

-- Compute pet names safely and update cache
local function computeAndCachePetNames()
    local names = {}
    local ok, err = pcall(function()
        names = getAllPetNames()
    end)
    if not ok then
        warn("[Auto Enchant] Failed to compute pet names: " .. tostring(err))
        names = {}
    end
    writePetNamesCache(names)
    petNamesCache = names
    return names
end

print("[RIBOUTAID] Auto Enchant script loaded successfully!")
print("[RIBOUTAID] Script by Numass - https://guns.lol/AI0ne")
