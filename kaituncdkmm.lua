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

function CheckBossAttack()
    for _,Boss in pairs(game.Workspace.Enemies:GetChildren()) do
        if Boss.Name == "rip_indra True Form" or Boss.Name == "Dough King" or Boss.Name == "Soul Reaper" and DetectingPart(Boss) and Boss.Humanoid.Health > 0 then
            return Boss
        end
    end
    for _,Boss in pairs(game.ReplicatedStorage:GetChildren()) do
        if Boss.Name == "rip_indra True Form" or Boss.Name == "Dough King" or Boss.Name == "Soul Reaper" then
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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ItemStatusGUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local function CreateStatusLabel(name, position)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = name
    textLabel.Size = UDim2.new(0, 450, 0, 60) -- Tăng kích thước gấp 3
    textLabel.Position = position
    textLabel.BackgroundTransparency = 0.5
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 42 -- Tăng font size
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = screenGui
    return textLabel
end

local viewportSize = workspace.CurrentCamera.ViewportSize
local centerX = (viewportSize.X / 2) - 225 -- Căn giữa theo chiều ngang
local centerY = (viewportSize.Y / 2) - 90 -- Căn giữa theo chiều dọc

local itemLabels = {
    valk = CreateStatusLabel("Valkyrie", UDim2.new(0, centerX, 0, centerY)),
    mirror = CreateStatusLabel("Mirror", UDim2.new(0, centerX, 0, centerY + 65)),
    tushita = CreateStatusLabel("Tushita", UDim2.new(0, centerX, 0, centerY + 130)),
    alucard = CreateStatusLabel("Alucard", UDim2.new(0, centerX, 0, centerY + 195))
}

function UpdateItemStatus(items)
    pcall(function()
        itemLabels.valk.Text = "Valkyrie: " .. (items.hasValkyrie and "✓" or "✗")
        itemLabels.mirror.Text = "Mirror: " .. (items.hasMirror and "✓" or "✗")
        itemLabels.tushita.Text = "Tushita: " .. (items.hasTushita and "✓" or "✗")
        itemLabels.alucard.Text = "Alucard Fragment: " .. items.alucardCount
    end)
end

spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local items, playerLevel = CheckItems()
            local boss = CheckBossAttack()
            
            UpdateItemStatus(items)
            
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
