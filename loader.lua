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
    screenGui.DisplayOrder = 999999999  -- Ensure it's on top of everything
    screenGui.Parent = playerGui
    
    -- Background frame (covers entire screen including top bar)
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 300)  -- Extra height to cover top bar
    background.Position = UDim2.new(0, 0, 0, -36)  -- Start above screen
    background.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    background.BorderSizePixel = 0
    background.ZIndex = 999999999
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
    container.ZIndex = 999999999
    container.Parent = background
    
    -- Glow effect for container
    local glowEffect = Instance.new("ImageLabel")
    glowEffect.Name = "GlowEffect"
    glowEffect.Size = UDim2.new(1, 60, 1, 60)
    glowEffect.Position = UDim2.new(0, -30, 0, -30)
    glowEffect.BackgroundTransparency = 1
    glowEffect.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    glowEffect.ImageColor3 = Color3.fromRGB(100, 150, 255)
    glowEffect.ImageTransparency = 0.8
    glowEffect.ZIndex = container.ZIndex - 1
    glowEffect.Parent = container
    
    -- Container corner
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 20)
    containerCorner.Parent = container
    
    -- Container stroke with animated glow
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(100, 150, 255)
    containerStroke.Thickness = 2
    containerStroke.Transparency = 0.3
    containerStroke.Parent = container
    
    -- Animate stroke glow
    local strokeGlowTween = TweenService:Create(containerStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Transparency = 0.1
    })
    strokeGlowTween:Play()
    
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
    
    return screenGui, loadingText, progressFill, container, background
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
    local screenGui, loadingText, progressFill, container, background = createLoadingScreen()
    
    -- Animate background and container entrance together
    background.Position = UDim2.new(0, 0, -1, 0)  -- Start above screen
    container.Position = UDim2.new(0.5, -200, 1.5, 0)  -- Start below screen
    
    -- Animate background sliding down
    local backgroundTween = TweenService:Create(background, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, -36)
    })
    
    -- Animate container sliding up
    local entranceTween = TweenService:Create(container, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -200, 0.5, -150)
    })
    
    -- Start both animations simultaneously
    backgroundTween:Play()
    entranceTween:Play()
    
    wait(1)
    
    -- Loading stages with extended final step
    local stages = {
        {0.2, "Checking configuration..."},
        {0.4, "Getting last update... "},
        {0.6, "Loading modules..."},
        {0.8, "Preparing interface..."},
        {1.0, "Almost ready..."}
    }
    
    -- Add floating particles effect
    local function createParticle()
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
        particle.Position = UDim2.new(math.random(0, 100) / 100, 0, 1, 0)
        particle.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        particle.BorderSizePixel = 0
        particle.ZIndex = container.ZIndex + 1
        particle.Parent = background
        
        local particleCorner = Instance.new("UICorner")
        particleCorner.CornerRadius = UDim.new(0.5, 0)
        particleCorner.Parent = particle
        
        -- Animate particle floating up
        local floatTween = TweenService:Create(particle, TweenInfo.new(math.random(3, 6), Enum.EasingStyle.Linear), {
            Position = UDim2.new(particle.Position.X.Scale, 0, -0.1, 0),
            BackgroundTransparency = 1
        })
        floatTween:Play()
        
        floatTween.Completed:Connect(function()
            particle:Destroy()
        end)
    end
    
    -- Spawn particles periodically
    spawn(function()
        for i = 1, 20 do
            createParticle()
            wait(0.2)
        end
    end)
    
    for i, stage in ipairs(stages) do
        local tween = animateProgress(progressFill, loadingText, stage[1], stage[2])
        tween.Completed:Wait()
        
        -- Extended wait for final stage
        if i == #stages then
            wait(1.3)  -- Extended by 1 second as requested
        else
            wait(0.3)
        end
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
    
    -- Animate exit with both background and container
    local containerExitTween = TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -200, -1.5, 0)
    })
    
    local backgroundExitTween = TweenService:Create(background, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0, 0, 1, 0)
    })
    
    containerExitTween:Play()
    backgroundExitTween:Play()
    
    containerExitTween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- Execute the loader
loadScript()
