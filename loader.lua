-- RIBOUTAID Loader Script
-- Checks for OneClick variable and loads appropriate script

local function loadScript()
    -- Check if OneClick mode is enabled
    if getgenv().OneClick == true then
        print("Loading RIBOUTAID OneClick Mode...")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Numass/Riboutaid/refs/heads/main/oneclick.lua"))()
    else
        print("Loading RIBOUTAID Default Mode...")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Numass/Riboutaid/refs/heads/main/RIBOUTAID.lua"))()
    end
end

-- Execute the loader
loadScript()
