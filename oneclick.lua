-- RIBOUTAID One-Click Mode
-- No UI, uses executor variables

-- Show loading screen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RIBOUTAIDOneClick"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.Position = UDim2.new(0, 0, 0, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "RIBOUTAID OneClick\nBy Numass"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- Get settings from executor variables
local webhookUrl = getgenv().WebhookURL or ""
local discordUserId = getgenv().DiscordUserID or ""
local autoFarmEnabled = getgenv().AutoFarm or false
local selectedArea = getgenv().FarmArea or "All Areas"
local petsPerCoin = getgenv().PetsPerCoin or 1
local autoHatchEnabled = getgenv().AutoHatch or false
local selectedEgg = getgenv().EggType or "Metal Egg"
local goldenEggEnabled = getgenv().GoldenEgg or false
local numberOfEggs = getgenv().EggQuantity or 1
local autoUnlockAreas = getgenv().AutoUnlock or false
local autoCollectOrb = getgenv().AutoCollectOrbs or false
local autoClaimGifts = getgenv().AutoClaimGifts or false
local autoBuyDiamonds = getgenv().AutoBuyDiamonds or false

-- Auto features variables
local diamondButtonUsed = false
local diamondThreshold = 250000000000 -- 250b

-- Currency parser function
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

-- Core functions (same as main script)
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

-- Auto Unlock Areas
if autoUnlockAreas then
    spawn(function()
        while autoUnlockAreas do
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
                end
            end
            for _, area in ipairs(areas) do
                local args = {{ area }}
                workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("buy area"):InvokeServer(unpack(args))
            end
            task.wait(5)
        end
    end)
end

-- Auto Collect Orbs
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

-- Auto Farm
if autoFarmEnabled then
    spawn(function()
        local lastCoinIndex = 0
        local lastCheckTime = 0
        local coins = {}
        local petGroups = {}
        
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

-- Auto Hatch Eggs
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

-- Auto Claim Free Gifts
if autoClaimGifts then
    spawn(function()
        while autoClaimGifts do
            local success, result = pcall(function()
                local player = game:GetService("Players").LocalPlayer
                local freeGiftsTop = player.PlayerGui:FindFirstChild("FreeGiftsTop")
                
                if freeGiftsTop and freeGiftsTop:FindFirstChild("Button") and freeGiftsTop.Button:FindFirstChild("Timer") then
                    local timerText = freeGiftsTop.Button.Timer.Text
                    
                    if timerText == "Ready!" then
                        -- Click all gift buttons (continue even if some fail)
                        local freeGifts = player.PlayerGui:FindFirstChild("FreeGifts")
                        if freeGifts and freeGifts:FindFirstChild("Frame") and freeGifts.Frame:FindFirstChild("Container") and freeGifts.Frame.Container:FindFirstChild("Gifts") then
                            for _, giftButton in ipairs(freeGifts.Frame.Container.Gifts:GetChildren()) do
                                if giftButton:IsA("TextButton") then
                                    pcall(function()
                                        giftButton:Activate()
                                    end)
                                end
                            end
                        end
                        
                        -- Keep spamming remote calls until timer is no longer "Ready!"
                        local attempts = 0
                        local maxAttempts = 50
                        
                        while attempts < maxAttempts do
                            -- Check if timer is still "Ready!"
                            local currentTimerText = "Ready!"
                            if freeGiftsTop and freeGiftsTop:FindFirstChild("Button") and freeGiftsTop.Button:FindFirstChild("Timer") then
                                currentTimerText = freeGiftsTop.Button.Timer.Text
                            end
                            
                            if currentTimerText ~= "Ready!" then
                                break
                            end
                            
                            -- Use remote calls for gifts 1-12
                            for i = 1, 12 do
                                local args = {{i}}
                                pcall(function()
                                    workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("redeem free gift"):InvokeServer(unpack(args))
                                end)
                                task.wait(0.05)
                            end
                            
                            attempts = attempts + 1
                            task.wait(0.2)
                        end
                    end
                end
            end)
            
            task.wait(10) -- Check every 10 seconds
        end
    end)
end

-- Auto Buy Diamonds
if autoBuyDiamonds then
    spawn(function()
        while autoBuyDiamonds do
            local success, result = pcall(function()
                local player = game:GetService("Players").LocalPlayer
                local techCoinsGui = player.PlayerGui:FindFirstChild("Main")
                
                if techCoinsGui and techCoinsGui:FindFirstChild("Right") and techCoinsGui.Right:FindFirstChild("Tech Coins") and techCoinsGui.Right["Tech Coins"]:FindFirstChild("Amount") then
                    local amountText = techCoinsGui.Right["Tech Coins"].Amount.Text
                    local currentAmount = parseCurrency(amountText)
                    
                    if currentAmount >= diamondThreshold then
                        -- Click BestCurrency button once per execution
                        if not diamondButtonUsed then
                            local exclusiveShop = player.PlayerGui:FindFirstChild("ExclusiveShop")
                            if exclusiveShop and exclusiveShop:FindFirstChild("Frame") and exclusiveShop.Frame:FindFirstChild("Container") and exclusiveShop.Frame.Container:FindFirstChild("Diamonds") and exclusiveShop.Frame.Container.Diamonds:FindFirstChild("BestCurrency") then
                                local button = exclusiveShop.Frame.Container.Diamonds.BestCurrency
                                
                                -- Try multiple activation methods
                                pcall(function()
                                    if button:FindFirstChild("MouseButton1Click") then
                                        button.MouseButton1Click:Fire()
                                    elseif game:GetService("GuiService") then
                                        game:GetService("GuiService"):FireEvent(button, "MouseButton1Click")
                                    else
                                        button:Activate()
                                    end
                                end)
                                
                                diamondButtonUsed = true
                                task.wait(1)
                            else
                                diamondButtonUsed = true
                            end
                        end
                        
                        -- Continuously buy diamond packs until under threshold
                        local attempts = 0
                        local maxAttempts = 100
                        while autoBuyDiamonds and currentAmount >= diamondThreshold and attempts < maxAttempts do
                            attempts = attempts + 1
                            
                            local args = {{4}}
                            pcall(function()
                                workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("buy diamond pack"):InvokeServer(unpack(args))
                            end)
                            
                            -- Check current amount again
                            task.wait(0.1)
                            if techCoinsGui and techCoinsGui:FindFirstChild("Right") and techCoinsGui.Right:FindFirstChild("Tech Coins") and techCoinsGui.Right["Tech Coins"]:FindFirstChild("Amount") then
                                local newAmountText = techCoinsGui.Right["Tech Coins"].Amount.Text
                                currentAmount = parseCurrency(newAmountText)
                                
                                if currentAmount < diamondThreshold then
                                    break
                                end
                            end
                            
                            task.wait(0.2)
                        end
                    end
                end
            end)
            
            task.wait(5) -- Check every 5 seconds
        end
    end)
end

-- Anti AFK
spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    while true do
        wait(60)
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Remove loading screen after 3 seconds
spawn(function()
    task.wait(3)
    screenGui:Destroy()
end)

-- OneClick mode loaded silently
