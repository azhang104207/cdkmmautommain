-- Check if player is in Third Sea
if game.PlaceId ~= 7449423635 then -- Third Sea PlaceId
    warn("This script only works in Third Sea!")
    return
end

getgenv().IndraHop = function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    local success, foundServers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet('http://localhost:5000/api/messages'))
    end)
    
    if success and #foundServers > 0 then
        table.sort(foundServers, function(a,b) 
            return (a.playing or 0) < (b.playing or 0)
        end)
        
        for _, server in ipairs(foundServers) do
            if server.jobId ~= game.JobId then
                game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", server.jobId)
                break
            end
        end
    end
end

getgenv().DoughKingHop = function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    local success, foundServers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet('http://localhost:5001/api/messages'))
    end)
    
    if success and #foundServers > 0 then
        table.sort(foundServers, function(a,b) 
            return (a.playing or 0) < (b.playing or 0)
        end)
        
        for _, server in ipairs(foundServers) do
            if server.jobId ~= game.JobId then
                game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", server.jobId)
                break
            end
        end
    end
end

getgenv().SoulReaperHop = function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    local success, foundServers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet('http://localhost:5002/api/messages'))
    end)
    
    if success and #foundServers > 0 then
        table.sort(foundServers, function(a,b) 
            return (a.playing or 0) < (b.playing or 0)
        end)
        
        for _, server in ipairs(foundServers) do
            if server.jobId ~= game.JobId then
                game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", server.jobId)
                break
            end
        end
    end
end

local cakeQueenDied = false
local cakeQueenDeathTime = 0

function CheckBossAttack()
    for _,Boss in pairs(game.Workspace.Enemies:GetChildren()) do
        if Boss.Name == "rip_indra True Form" or Boss.Name == "Dough King" or Boss.Name == "Soul Reaper" or Boss.Name == "Cake Queen" and DetectingPart(Boss) and Boss.Humanoid.Health > 0 then
            if Boss.Name == "Cake Queen" then
                Boss.Humanoid.Died:Connect(function()
                    cakeQueenDied = true
                    cakeQueenDeathTime = os.time()
                end)
            end
            return Boss
        end
    end
    for _,Boss in pairs(game.ReplicatedStorage:GetChildren()) do
        if Boss.Name == "rip_indra True Form" or Boss.Name == "Dough King" or Boss.Name == "Soul Reaper" or Boss.Name == "Cake Queen" then
            return Boss
        end
    end
end

function DetectingPart(v1)
    return v1 and v1:FindFirstChild("HumanoidRootPart") and v1:FindFirstChild("Humanoid")
end

function CheckItems()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    local plr = game.Players.LocalPlayer
    
    local success, materials
    local remoteCommands = {"CheckMaterial", "GetMaterial", "getInventory", "LoadInventory", "CheckInventory", "GetInventory"}
    
    local items = {
        hasValkyrie = false,
        hasMirror = false,
        hasTushita = false,
        alucardCount = 0
    }
    
    for _, cmd in ipairs(remoteCommands) do
        success, materials = pcall(function()
            return CommF:InvokeServer(cmd)
        end)
        if success and materials then break end
        task.wait(1)
    end
    
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
    return items, plr.Data.Level.Value
end

-- Create main menu GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ItemStatusGUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

-- Create main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 250)  -- Back to original size
mainFrame.Position = UDim2.new(1, -420, 0, 10)  -- Positioned at top right
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Add corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Create title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Text = "Item Status"
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 24  -- Increased text size
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar

-- Create content frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -40)
contentFrame.Position = UDim2.new(0, 10, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local itemLabels = {}
local items = {"Valkyrie", "Mirror", "Tushita", "Alucard"}  -- Remove quest items
local yOffset = 0

for _, item in ipairs(items) do
    local itemFrame = Instance.new("Frame")
    itemFrame.Size = UDim2.new(1, 0, 0, 40)  -- Made taller
    itemFrame.Position = UDim2.new(0, 0, 0, yOffset)
    itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = contentFrame
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 6)
    itemCorner.Parent = itemFrame
    
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Name = item
    itemLabel.Size = UDim2.new(1, -10, 1, 0)
    itemLabel.Position = UDim2.new(0, 10, 0, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemLabel.TextSize = 20  -- Increased text size
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.TextXAlignment = Enum.TextXAlignment.Left
    itemLabel.Parent = itemFrame
    
    itemLabels[item:lower()] = itemLabel
    yOffset = yOffset + 45  -- Increased spacing
end

-- Update the UpdateItemStatus function
function UpdateItemStatus(items)
    pcall(function()
        itemLabels.valkyrie.Text = "Valkyrie Helm: " .. (items.hasValkyrie and "✓" or "✗")
        itemLabels.mirror.Text = "Mirror Fractal: " .. (items.hasMirror and "✓" or "✗")
        itemLabels.tushita.Text = "Tushita: " .. (items.hasTushita and "✓" or "✗")
        itemLabels.alucard.Text = "Alucard Fragment: " .. items.alucardCount
        
        -- Update colors based on status
        itemLabels.valkyrie.Parent.BackgroundColor3 = items.hasValkyrie and Color3.fromRGB(45, 85, 45) or Color3.fromRGB(40, 40, 40)
        itemLabels.mirror.Parent.BackgroundColor3 = items.hasMirror and Color3.fromRGB(45, 85, 45) or Color3.fromRGB(40, 40, 40)
        itemLabels.tushita.Parent.BackgroundColor3 = items.hasTushita and Color3.fromRGB(45, 85, 45) or Color3.fromRGB(40, 40, 40)
        itemLabels.alucard.Parent.BackgroundColor3 = items.alucardCount >= 5 and Color3.fromRGB(45, 85, 45) or Color3.fromRGB(40, 40, 40)
    end)
end

spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local items, playerLevel = CheckItems()
            local boss = CheckBossAttack()
            
            UpdateItemStatus(items)
            
            -- Check if Cake Queen died recently (within 1 minute 30 seconds)
            if cakeQueenDied and os.time() - cakeQueenDeathTime < 90 then
                return
            end
            
            -- Reset Cake Queen death status after 1 minute 30 seconds
            if cakeQueenDied and os.time() - cakeQueenDeathTime >= 90 then
                cakeQueenDied = false
            end
            
            -- Check if Cake Queen is present
            if boss and boss.Name == "Cake Queen" then
                return
            end
            
            if not items.hasValkyrie or (playerLevel >= 2000 and not items.hasTushita) then
                if not boss or boss.Name ~= "rip_indra True Form" then
                    return IndraHop()
                end
            elseif not items.hasMirror then
                if not boss or boss.Name ~= "Dough King" then
                    return DoughKingHop()
                end
            elseif items.alucardCount == 5 then -- Changed from >= to ==
                if not boss or boss.Name ~= "Soul Reaper" then
                    return SoulReaperHop()
                end
            end
        end)
    end
end)
