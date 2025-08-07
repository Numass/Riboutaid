local Fluent, LibraryUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
end)

if not Fluent then
    warn("Failed to load Fluent UI", LibraryUI)
    return
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

MainTab:AddParagraph("WelcomeParagraph", {
    Title = "Welcome",
    Content = "Made By Numa"
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

FarmTab:AddSlider("PetsPerCoinSlider", {
    Title = "Pets Per Coin",
    Default = 1,
    Min = 1,
    Max = 10,
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
        task.wait(1)
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

local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

SaveManager:SetLibrary(LibraryUI)
InterfaceManager:SetLibrary(LibraryUI)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("PSXRebooted")
SaveManager:SetFolder("PSXRebooted/Settings")
InterfaceManager:BuildInterfaceSection(SaveSettingsTab)
SaveManager:BuildConfigSection(SaveSettingsTab)
SaveManager:LoadAutoloadConfig()
