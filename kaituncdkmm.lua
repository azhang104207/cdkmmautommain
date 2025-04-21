-- Check if player is in Third Sea
if game.PlaceId ~= 7449423635 then -- Third Sea PlaceId
    warn("sea 3 mới chạy được")
    return
end

-- Cache services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Generic server hop function to reduce code duplication
local function ServerHop(port)
    local success, foundServers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet('http://localhost:' .. port .. '/api/messages'))
    end)
    
    if success and foundServers and #foundServers > 0 then
        table.sort(foundServers, function(a,b) 
            return (a.playing or 0) < (b.playing or 0)
        end)
        
        for _, server in ipairs(foundServers) do
            if server.jobId ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.jobId, game.Players.LocalPlayer)
                break
            end
        end
    end
end

-- Define specific hop functions using the generic one
getgenv().IndraHop = function() ServerHop(5000) end
getgenv().DoughKingHop = function() ServerHop(5001) end
getgenv().SoulReaperHop = function() ServerHop(5002) end

-- Boss tracking variables
local cakeQueenDied = false
local cakeQueenDeathTime = 0
local targetBosses = {
    "rip_indra True Form",
    "Dough King",
    "Soul Reaper",
    "Cake Queen"
}

-- Helper function to check if a name is in our target boss list
local function IsTargetBoss(name)
    for _, bossName in ipairs(targetBosses) do
        if name == bossName then
            return true
        end
    end
    return false
end

function DetectingPart(v1)
    return v1 and v1:FindFirstChild("HumanoidRootPart") and v1:FindFirstChild("Humanoid")
end

function CheckBossAttack()
    -- Check workspace first for active bosses
    for _, Boss in pairs(game.Workspace.Enemies:GetChildren()) do
        if IsTargetBoss(Boss.Name) and DetectingPart(Boss) and Boss.Humanoid.Health > 0 then
            -- Set up Cake Queen death tracking
            if Boss.Name == "Cake Queen" and not Boss:FindFirstChild("DeathTracked") then
                local tracker = Instance.new("BoolValue")
                tracker.Name = "DeathTracked"
                tracker.Parent = Boss
                
                Boss.Humanoid.Died:Connect(function()
                    cakeQueenDied = true
                    cakeQueenDeathTime = os.time()
                end)
            end
            return Boss
        end
    end
    
    -- Check ReplicatedStorage for bosses that haven't spawned yet
    for _, Boss in pairs(ReplicatedStorage:GetChildren()) do
        if IsTargetBoss(Boss.Name) then
            return Boss
        end
    end
    
    return nil
end

-- Cache remote
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- Item checking with optimized command selection and caching
local lastCheckTime = 0
local cachedItems = nil
local cachedLevel = 0
local checkCooldown = 2 -- seconds between inventory checks

function CheckItems()
    local plr = game.Players.LocalPlayer
    local currentTime = os.time()
    
    -- Return cached results if within cooldown period
    if cachedItems and currentTime - lastCheckTime < checkCooldown then
        return cachedItems, cachedLevel
    end
    
    local items = {
        hasValkyrie = false,
        hasMirror = false,
        hasTushita = false,
        alucardCount = 0
    }
    
    -- Try the most reliable command first
    local success, materials = pcall(function()
        return CommF:InvokeServer("CheckMaterial")
    end)
    
    -- If first attempt fails, try alternatives
    if not success or not materials then
        local remoteCommands = {"GetMaterial", "getInventory", "LoadInventory", "CheckInventory", "GetInventory"}
        
        for _, cmd in ipairs(remoteCommands) do
            success, materials = pcall(function()
                return CommF:InvokeServer(cmd)
            end)
            if success and materials then break end
            task.wait(0.5) -- Reduced wait time
        end
    end
    
    -- Process inventory data if available
    if success and materials then
        for _, material in pairs(materials) do
            if material and material.Name then
                if material.Name == "Valkyrie Helm" then
                    items.hasValkyrie = true
                elseif material.Name == "Mirror Fractal" then
                    items.hasMirror = true
                elseif material.Name == "Tushita" then
                    items.hasTushita = true
                elseif material.Name == "Alucard Fragment" then
                    items.alucardCount = material.Count or 0
                end
            end
        end
    end
    
    -- Update cache
    cachedItems = items
    cachedLevel = plr.Data.Level.Value
    lastCheckTime = currentTime
    
    return items, cachedLevel
end

-- GUI Creation with modular functions
local function CreateGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ItemStatusGUI"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 250, 0, 180) -- Giảm kích thước
    mainFrame.Position = UDim2.new(0, 10, 0, 10) -- Thay đổi vị trí sang bên trái
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 25) -- Giảm chiều cao title
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Text = "Item Status"
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 14 -- Giảm font size
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = titleBar
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -16, 1, -35) -- Giảm padding
    contentFrame.Position = UDim2.new(0, 8, 0, 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    local itemLabels = CreateItemLabels(contentFrame)
    
    return screenGui, itemLabels
end

function CreateTitleBar(parent)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = parent
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Text = "Item Status"
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = titleBar
    
    return titleBar
end

function MakeFrameDraggable(frame, dragHandle)
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragInput = nil
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragInput.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

function CreateItemLabels(parent)
    local itemLabels = {}
    local items = {"Valkyrie", "Mirror", "Tushita", "Alucard"}
    local yOffset = 0
    
    for _, item in ipairs(items) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, 0, 0, 32) -- Giảm chiều cao mỗi item
        itemFrame.Position = UDim2.new(0, 0, 0, yOffset)
        itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = parent
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = itemFrame
        
        local itemLabel = Instance.new("TextLabel")
        itemLabel.Name = item
        itemLabel.Size = UDim2.new(1, -12, 1, 0) -- Giảm padding text
        itemLabel.Position = UDim2.new(0, 6, 0, 0)
        itemLabel.BackgroundTransparency = 1
        itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemLabel.TextSize = 14 -- Giảm font size
        itemLabel.Font = Enum.Font.Gotham
        itemLabel.TextXAlignment = Enum.TextXAlignment.Left
        itemLabel.Parent = itemFrame
        
        itemLabels[item:lower()] = itemLabel
        yOffset = yOffset + 35 -- Giảm khoảng cách giữa các items
    end
    
    return itemLabels
end

-- Create the GUI and get item labels
local gui, itemLabels = CreateGui()

-- Optimized update function with color constants
local COLOR_INACTIVE = Color3.fromRGB(40, 40, 40)
local COLOR_ACTIVE = Color3.fromRGB(45, 85, 45)

function UpdateItemStatus(items)
    pcall(function()
        -- Update text
        itemLabels.valkyrie.Text = "Valkyrie Helm: " .. (items.hasValkyrie and "✓" or "✗")
        itemLabels.mirror.Text = "Mirror Fractal: " .. (items.hasMirror and "✓" or "✗")
        itemLabels.tushita.Text = "Tushita: " .. (items.hasTushita and "✓" or "✗")
        itemLabels.alucard.Text = "Alucard Fragment: " .. items.alucardCount
        
        -- Update colors based on status
        itemLabels.valkyrie.Parent.BackgroundColor3 = items.hasValkyrie and COLOR_ACTIVE or COLOR_INACTIVE
        itemLabels.mirror.Parent.BackgroundColor3 = items.hasMirror and COLOR_ACTIVE or COLOR_INACTIVE
        itemLabels.tushita.Parent.BackgroundColor3 = items.hasTushita and COLOR_ACTIVE or COLOR_INACTIVE
        itemLabels.alucard.Parent.BackgroundColor3 = items.alucardCount >= 5 and COLOR_ACTIVE or COLOR_INACTIVE
    end)
end

-- Constants for main loop
local MAIN_LOOP_INTERVAL = 1.0 -- seconds
local CAKE_QUEEN_COOLDOWN = 90 -- seconds

-- Main loop with optimized checks
spawn(function()
    local lastLoopTime = 0
    
    while true do
        -- Use task.wait for more consistent timing
        task.wait(MAIN_LOOP_INTERVAL)
        
        -- Use pcall to prevent script errors from breaking the loop
        pcall(function()
            local currentTime = os.time()
            local items, playerLevel = CheckItems()
            local boss = CheckBossAttack()
            
            -- Update GUI
            UpdateItemStatus(items)
            
            -- Handle Cake Queen cooldown
            if cakeQueenDied then
                local timeElapsed = currentTime - cakeQueenDeathTime
                if timeElapsed < CAKE_QUEEN_COOLDOWN then
                    return -- Skip server hopping during cooldown
                else
                    cakeQueenDied = false -- Reset after cooldown
                end
            end
            
            -- Skip if Cake Queen is present
            if boss and boss.Name == "Cake Queen" then
                return
            end
            
            -- Determine which boss to hop for based on items and level
            local shouldHopForIndra = not items.hasValkyrie or (playerLevel >= 2000 and not items.hasTushita)
            local shouldHopForDoughKing = items.hasValkyrie and not items.hasMirror
            local shouldHopForSoulReaper = items.hasValkyrie and items.hasMirror and items.alucardCount == 5
            
            -- Execute the appropriate hop if needed
            if shouldHopForIndra and (not boss or boss.Name ~= "rip_indra True Form") then
                return IndraHop()
            elseif shouldHopForDoughKing and (not boss or boss.Name ~= "Dough King") then
                return DoughKingHop()
            elseif shouldHopForSoulReaper and (not boss or boss.Name ~= "Soul Reaper") then
                return SoulReaperHop()
            end
        end)
    end
end)
