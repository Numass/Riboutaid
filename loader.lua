-- RIBOUTAID Loader Script with Animation
-- Checks for OneClick variable and loads appropriate script

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create loading screen GUI
local function createLoadingScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RIBOUTAIDLoader"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Background frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(2, 2, 2, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 45)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 55))
    })
    gradient.Rotation = 45
    gradient.Parent = background
    
    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 400, 0, 300)
    container.Position = UDim2.new(0.5, -200, 0.5, -150)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    container.BorderSizePixel = 0
    container.Parent = background
    
    -- Container corner
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 20)
    containerCorner.Parent = container
    
    -- Container stroke
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(100, 150, 255)
    containerStroke.Thickness = 2
    containerStroke.Transparency = 0.3
    containerStroke.Parent = container
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "RIBOUTAID"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = container
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0, 80)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "By Numa"
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = container
    
    -- Loading text
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(1, 0, 0, 30)
    loadingText.Position = UDim2.new(0, 0, 0, 130)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "Initializing..."
    loadingText.TextColor3 = Color3.fromRGB(100, 150, 255)
    loadingText.TextScaled = true
    loadingText.Font = Enum.Font.Gotham
    loadingText.Parent = container
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Size = UDim2.new(0.8, 0, 0, 8)
    progressBg.Position = UDim2.new(0.1, 0, 0, 180)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = container
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 4)
    progressBgCorner.Parent = progressBg
    
    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 4)
    progressFillCorner.Parent = progressFill
    
    -- Spinning loader
    local spinner = Instance.new("Frame")
    spinner.Name = "Spinner"
    spinner.Size = UDim2.new(0, 40, 0, 40)
    spinner.Position = UDim2.new(0.5, -20, 0, 220)
    spinner.BackgroundTransparency = 1
    spinner.Parent = container
    
    local spinnerStroke = Instance.new("UIStroke")
    spinnerStroke.Color = Color3.fromRGB(100, 150, 255)
    spinnerStroke.Thickness = 4
    spinnerStroke.Parent = spinner
    
    local spinnerCorner = Instance.new("UICorner")
    spinnerCorner.CornerRadius = UDim.new(0.5, 0)
    spinnerCorner.Parent = spinner
    
    -- Animate spinner
    local spinTween = TweenService:Create(spinner, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        Rotation = 360
    })
    spinTween:Play()
    
    return screenGui, loadingText, progressFill, container
end

-- Animate loading progress
local function animateProgress(progressFill, loadingText, progress, text)
    loadingText.Text = text
    local tween = TweenService:Create(progressFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(progress, 0, 1, 0)
    })
    tween:Play()
    return tween
end

-- Main loading function
local function loadScript()
    local screenGui, loadingText, progressFill, container = createLoadingScreen()
    
    -- Animate container entrance
    container.Position = UDim2.new(0.5, -200, 1.5, 0)
    local entranceTween = TweenService:Create(container, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -200, 0.5, -150)
    })
    entranceTween:Play()
    
    wait(1)
    
    -- Loading stages
    local stages = {
        {0.2, "Checking configuration..."},
        {0.4, "Getting last update... "},
        {0.6, "Loading modules..."},
        {0.8, "Preparing interface..."},
        {3.0, "Almost ready..."}
    }
    
    for _, stage in ipairs(stages) do
        local tween = animateProgress(progressFill, loadingText, stage[1], stage[2])
        tween.Completed:Wait()
        wait(0.3)
    end
    
    -- Determine which script to load
    local scriptUrl
    local mode
    if getgenv().OneClick == true then
        mode = "OneClick Mode"
        scriptUrl = "https://raw.githubusercontent.com/Numass/Riboutaid/refs/heads/main/oneclick.lua"
    else
        mode = "Default Mode"
        scriptUrl = "https://raw.githubusercontent.com/Numass/Riboutaid/refs/heads/main/RIBOUTAID.lua"
    end
    
    loadingText.Text = "Loading " .. mode .. "..."
    wait(0.5)
    
    -- Load the actual script
    local success, result = pcall(function()
        loadstring(game:HttpGet(scriptUrl))()
    end)
    
    if success then
        loadingText.Text = "✅ Loaded successfully!"
        loadingText.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        loadingText.Text = "❌ Failed to load"
        loadingText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    wait(1)
    
    -- Animate exit
    local exitTween = TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -200, -1.5, 0)
    })
    exitTween:Play()
    
    exitTween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- Execute the loader
loadScript()
