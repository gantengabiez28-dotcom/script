--[[
    M20 Project - Violence District Suite
    Version: 5.0 Complete Rewrite
    Made by: M20 Development Team
    
    Complete rewrite with proper error handling
]]

-- ========================================
-- INITIALIZATION & SAFETY CHECKS
-- ========================================

local function safeRequire(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    return success and result or nil
end

-- Load UI Library
local Rayfield = safeRequire("https://sirius.menu/rayfield")
if not Rayfield then
    warn("[M20 Project] Failed to load UI library")
    return
end

-- ========================================
-- SERVICES
-- ========================================

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualUser = game:GetService("VirtualUser")
}

local Player = Services.Players.LocalPlayer

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

local Utils = {}

function Utils.isAlive(instance)
    if not instance then return false end
    local success, parent = pcall(function() 
        return instance.Parent 
    end)
    return success and parent ~= nil
end

function Utils.isValidPart(part)
    return part and Utils.isAlive(part) and part:IsA("BasePart")
end

function Utils.getDistance(pos1, pos2)
    local success, distance = pcall(function()
        return (pos1 - pos2).Magnitude
    end)
    return success and distance or math.huge
end

function Utils.safeDestroy(instance)
    pcall(function()
        if instance and instance.Parent then
            instance:Destroy()
        end
    end)
end

function Utils.safeDisconnect(connection)
    pcall(function()
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end)
end

-- ========================================
-- CREATE WINDOW
-- ========================================

local Window = Rayfield:CreateWindow({
    Name = "M20 Project - VD Suite",
    LoadingTitle = "M20 Project Loading",
    LoadingSubtitle = "Violence District Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "M20_Project",
        FileName = "m20_config"
    },
    KeySystem = false
})

-- Create tabs
local Tabs = {
    Player = Window:CreateTab("Player", 4483362458),
    Combat = Window:CreateTab("Combat", 4483362458),
    ESP = Window:CreateTab("ESP", 4483362458),
    World = Window:CreateTab("World", 4483362458),
    Visual = Window:CreateTab("Visual", 4483362458),
    Misc = Window:CreateTab("Misc", 4483362458)
}

-- ========================================
-- ROLE DETECTION
-- ========================================

local RoleSystem = {
    cache = {}
}

function RoleSystem:getRole(player)
    if not player then return "Survivor" end
    
    local success, team = pcall(function()
        return player.Team
    end)
    
    if not success or not team then return "Survivor" end
    
    local teamName = tostring(team.Name):lower()
    if teamName:find("killer") or teamName:find("murder") then
        return "Killer"
    end
    
    return "Survivor"
end

function RoleSystem:isKiller(player)
    return self:getRole(player or Player) == "Killer"
end

-- ========================================
-- ESP SYSTEM
-- ========================================

local ESPSystem = {
    enabled = false,
    nametags = false,
    colors = {
        survivor = Color3.fromRGB(0, 255, 100),
        killer = Color3.fromRGB(255, 50, 50)
    },
    connections = {},
    highlights = {}
}

function ESPSystem:createHighlight(model, color)
    if not model or not Utils.isAlive(model) then return end
    
    pcall(function()
        -- Remove old highlight
        local old = model:FindFirstChild("M20_Highlight")
        if old then old:Destroy() end
        
        -- Create new highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "M20_Highlight"
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        
        self.highlights[model] = highlight
    end)
end

function ESPSystem:removeHighlight(model)
    if not model then return end
    
    pcall(function()
        local highlight = model:FindFirstChild("M20_Highlight")
        if highlight then
            highlight:Destroy()
        end
        self.highlights[model] = nil
    end)
end

function ESPSystem:createNametag(head, text, color)
    if not Utils.isValidPart(head) then return end
    
    pcall(function()
        -- Remove old nametag
        local old = head:FindFirstChild("M20_Nametag")
        if old then old:Destroy() end
        
        -- Create billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "M20_Nametag"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        
        -- Create label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.Parent = billboard
        
        billboard.Parent = head
    end)
end

function ESPSystem:removeNametag(head)
    if not head then return end
    
    pcall(function()
        local nametag = head:FindFirstChild("M20_Nametag")
        if nametag then
            nametag:Destroy()
        end
    end)
end

function ESPSystem:updatePlayer(player)
    if player == Player then return end
    if not player or not player.Character then return end
    
    pcall(function()
        local character = player.Character
        if not Utils.isAlive(character) then return end
        
        local role = RoleSystem:getRole(player)
        local color = (role == "Killer") and self.colors.killer or self.colors.survivor
        
        -- Handle ESP
        if self.enabled then
            self:createHighlight(character, color)
        else
            self:removeHighlight(character)
        end
        
        -- Handle nametags
        local head = character:FindFirstChild("Head")
        if head then
            if self.nametags and self.enabled then
                local prefix = (role == "Killer") and "[KILLER] " or ""
                self:createNametag(head, prefix .. player.Name, color)
            else
                self:removeNametag(head)
            end
        end
    end)
end

function ESPSystem:watchPlayer(player)
    if player == Player then return end
    
    pcall(function()
        -- Disconnect old connections
        if self.connections[player] then
            for _, conn in ipairs(self.connections[player]) do
                Utils.safeDisconnect(conn)
            end
        end
        
        self.connections[player] = {}
        
        -- Character added
        local charConn = player.CharacterAdded:Connect(function()
            task.wait(0.5)
            self:updatePlayer(player)
        end)
        table.insert(self.connections[player], charConn)
        
        -- Update current character
        if player.Character then
            self:updatePlayer(player)
        end
    end)
end

function ESPSystem:cleanup(player)
    pcall(function()
        if player.Character then
            self:removeHighlight(player.Character)
            local head = player.Character:FindFirstChild("Head")
            if head then
                self:removeNametag(head)
            end
        end
        
        if self.connections[player] then
            for _, conn in ipairs(self.connections[player]) do
                Utils.safeDisconnect(conn)
            end
            self.connections[player] = nil
        end
    end)
end

function ESPSystem:initialize()
    -- Watch all current players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        self:watchPlayer(player)
    end
    
    -- Watch new players
    Services.Players.PlayerAdded:Connect(function(player)
        self:watchPlayer(player)
    end)
    
    -- Cleanup leaving players
    Services.Players.PlayerRemoving:Connect(function(player)
        self:cleanup(player)
    end)
end

-- ========================================
-- SPEED SYSTEM
-- ========================================

local SpeedSystem = {
    enabled = false,
    speed = 16,
    humanoid = nil,
    connection = nil
}

function SpeedSystem:setSpeed(value)
    self.speed = value
    if self.enabled and self.humanoid then
        pcall(function()
            if self.humanoid.Parent and self.humanoid.Health > 0 then
                self.humanoid.WalkSpeed = value
            end
        end)
    end
end

function SpeedSystem:enable()
    self.enabled = true
    
    if self.connection then
        Utils.safeDisconnect(self.connection)
    end
    
    self.connection = Services.RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        if not self.humanoid or not self.humanoid.Parent then return end
        
        pcall(function()
            if self.humanoid.Health > 0 and self.humanoid.WalkSpeed ~= self.speed then
                self.humanoid.WalkSpeed = self.speed
            end
        end)
    end)
    
    if self.humanoid then
        self:setSpeed(self.speed)
    end
end

function SpeedSystem:disable()
    self.enabled = false
    
    if self.connection then
        Utils.safeDisconnect(self.connection)
        self.connection = nil
    end
    
    if self.humanoid then
        pcall(function()
            if self.humanoid.Parent then
                self.humanoid.WalkSpeed = 16
            end
        end)
    end
end

function SpeedSystem:bindHumanoid(humanoid)
    self.humanoid = humanoid
    if self.enabled then
        self:setSpeed(self.speed)
    end
end

-- ========================================
-- NOCLIP SYSTEM
-- ========================================

local NoclipSystem = {
    enabled = false,
    connection = nil
}

function NoclipSystem:enable()
    self.enabled = true
    
    if self.connection then
        Utils.safeDisconnect(self.connection)
    end
    
    self.connection = Services.RunService.Stepped:Connect(function()
        if not self.enabled then return end
        
        pcall(function()
            local character = Player.Character
            if not character then return end
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

function NoclipSystem:disable()
    self.enabled = false
    
    if self.connection then
        Utils.safeDisconnect(self.connection)
        self.connection = nil
    end
    
    pcall(function()
        local character = Player.Character
        if not character then return end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end)
end

-- ========================================
-- TELEPORT SYSTEM
-- ========================================

local TeleportSystem = {}

function TeleportSystem:teleport(cframe)
    pcall(function()
        local character = Player.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- Enable noclip temporarily
        local wasEnabled = NoclipSystem.enabled
        if not wasEnabled then
            NoclipSystem:enable()
        end
        
        hrp.CFrame = cframe
        
        -- Restore noclip state
        task.delay(0.5, function()
            if not wasEnabled then
                NoclipSystem:disable()
            end
        end)
    end)
end

function TeleportSystem:teleportToPlayer(targetRole)
    pcall(function()
        local myHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Character not found",
                Duration = 3
            })
            return
        end
        
        local closest = nil
        local closestDist = math.huge
        
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= Player and RoleSystem:getRole(player) == targetRole then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local dist = Utils.getDistance(myHRP.Position, hrp.Position)
                    if dist < closestDist then
                        closestDist = dist
                        closest = {player = player, hrp = hrp}
                    end
                end
            end
        end
        
        if closest then
            local offset = closest.hrp.CFrame * CFrame.new(0, 0, -5) + Vector3.new(0, 2, 0)
            self:teleport(offset)
            
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Teleported to " .. closest.player.Name,
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Teleport",
                Content = "No " .. targetRole .. " found",
                Duration = 3
            })
        end
    end)
end

-- ========================================
-- VISUAL SYSTEM
-- ========================================

local VisualSystem = {
    fullbright = false,
    fullbrightLoop = nil,
    originalLighting = {}
}

function VisualSystem:saveOriginalLighting()
    pcall(function()
        self.originalLighting = {
            Brightness = Services.Lighting.Brightness,
            ClockTime = Services.Lighting.ClockTime,
            FogEnd = Services.Lighting.FogEnd,
            GlobalShadows = Services.Lighting.GlobalShadows
        }
    end)
end

function VisualSystem:enableFullbright()
    self.fullbright = true
    
    if self.fullbrightLoop then
        task.cancel(self.fullbrightLoop)
    end
    
    self.fullbrightLoop = task.spawn(function()
        while self.fullbright do
            pcall(function()
                Services.Lighting.Brightness = 2
                Services.Lighting.ClockTime = 14
                Services.Lighting.FogEnd = 100000
                Services.Lighting.GlobalShadows = false
            end)
            task.wait(0.5)
        end
    end)
end

function VisualSystem:disableFullbright()
    self.fullbright = false
    
    if self.fullbrightLoop then
        task.cancel(self.fullbrightLoop)
        self.fullbrightLoop = nil
    end
    
    pcall(function()
        for key, value in pairs(self.originalLighting) do
            Services.Lighting[key] = value
        end
    end)
end

-- ========================================
-- WORLD ESP SYSTEM
-- ========================================

local WorldESP = {
    enabled = {
        Generator = false,
        Hook = false,
        Gate = false
    },
    colors = {
        Generator = Color3.fromRGB(0, 200, 255),
        Hook = Color3.fromRGB(255, 50, 50),
        Gate = Color3.fromRGB(255, 225, 0)
    },
    objects = {
        Generator = {},
        Hook = {},
        Gate = {}
    },
    updateLoop = nil
}

function WorldESP:findObjects()
    pcall(function()
        local map = Services.Workspace:FindFirstChild("Map") or Services.Workspace:FindFirstChild("Map1")
        if not map then return end
        
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") then
                local name = obj.Name
                if name == "Generator" or name == "Hook" or name == "Gate" then
                    if not self.objects[name][obj] then
                        local part = obj:FindFirstChild("HitBox", true) or obj.PrimaryPart
                        if Utils.isValidPart(part) then
                            self.objects[name][obj] = part
                        end
                    end
                end
            end
        end
    end)
end

function WorldESP:createESP(part, name, color)
    pcall(function()
        -- Remove old ESP
        local oldBox = part:FindFirstChild("M20_Box")
        if oldBox then oldBox:Destroy() end
        
        local oldBillboard = part:FindFirstChild("M20_Billboard")
        if oldBillboard then oldBillboard:Destroy() end
        
        -- Create box
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "M20_Box"
        box.Adornee = part
        box.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
        box.Color3 = color
        box.AlwaysOnTop = true
        box.Transparency = 0.5
        box.ZIndex = 10
        box.Parent = part
        
        -- Create billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "M20_Billboard"
        billboard.Adornee = part
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.Parent = billboard
        
        billboard.Parent = part
    end)
end

function WorldESP:removeESP(part)
    pcall(function()
        local box = part:FindFirstChild("M20_Box")
        if box then box:Destroy() end
        
        local billboard = part:FindFirstChild("M20_Billboard")
        if billboard then billboard:Destroy() end
    end)
end

function WorldESP:startUpdateLoop()
    if self.updateLoop then return end
    
    self.updateLoop = task.spawn(function()
        while true do
            -- Find new objects
            self:findObjects()
            
            -- Update ESP
            for category, enabled in pairs(self.enabled) do
                if enabled then
                    for obj, part in pairs(self.objects[category]) do
                        if Utils.isAlive(obj) and Utils.isValidPart(part) then
                            self:createESP(part, category, self.colors[category])
                        else
                            self.objects[category][obj] = nil
                        end
                    end
                else
                    -- Remove ESP when disabled
                    for obj, part in pairs(self.objects[category]) do
                        if Utils.isValidPart(part) then
                            self:removeESP(part)
                        end
                        self.objects[category][obj] = nil
                    end
                end
            end
            
            task.wait(1)
        end
    end)
end

-- ========================================
-- UI SETUP - PLAYER TAB
-- ========================================

Tabs.Player:CreateSection("Movement")

Tabs.Player:CreateToggle({
    Name = "Speed Lock",
    CurrentValue = false,
    Flag = "SpeedLock",
    Callback = function(value)
        if value then
            SpeedSystem:enable()
            Rayfield:Notify({
                Title = "Speed Lock",
                Content = "Enabled at " .. SpeedSystem.speed,
                Duration = 3
            })
        else
            SpeedSystem:disable()
            Rayfield:Notify({
                Title = "Speed Lock",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

Tabs.Player:CreateSlider({
    Name = "Walk Speed",
    Range = {0, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(value)
        SpeedSystem:setSpeed(value)
    end
})

Tabs.Player:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(value)
        if value then
            NoclipSystem:enable()
        else
            NoclipSystem:disable()
        end
    end
})

Tabs.Player:CreateSection("Teleport")

Tabs.Player:CreateButton({
    Name = "Teleport to Killer",
    Callback = function()
        TeleportSystem:teleportToPlayer("Killer")
    end
})

Tabs.Player:CreateButton({
    Name = "Teleport to Survivor",
    Callback = function()
        TeleportSystem:teleportToPlayer("Survivor")
    end
})

Tabs.Player:CreateSection("Protection")

Tabs.Player:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(value)
        if value then
            Player.Idled:Connect(function()
                Services.VirtualUser:CaptureController()
                Services.VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end
})

-- ========================================
-- UI SETUP - ESP TAB
-- ========================================

Tabs.ESP:CreateSection("Player ESP")

Tabs.ESP:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(value)
        ESPSystem.enabled = value
        for _, player in ipairs(Services.Players:GetPlayers()) do
            ESPSystem:updatePlayer(player)
        end
        
        Rayfield:Notify({
            Title = "Player ESP",
            Content = value and "Enabled" or "Disabled",
            Duration = 3
        })
    end
})

Tabs.ESP:CreateToggle({
    Name = "Show Nametags",
    CurrentValue = false,
    Flag = "Nametags",
    Callback = function(value)
        ESPSystem.nametags = value
        for _, player in ipairs(Services.Players:GetPlayers()) do
            ESPSystem:updatePlayer(player)
        end
    end
})

Tabs.ESP:CreateColorPicker({
    Name = "Survivor Color",
    Color = ESPSystem.colors.survivor,
    Flag = "SurvivorColor",
    Callback = function(color)
        ESPSystem.colors.survivor = color
        for _, player in ipairs(Services.Players:GetPlayers()) do
            ESPSystem:updatePlayer(player)
        end
    end
})

Tabs.ESP:CreateColorPicker({
    Name = "Killer Color",
    Color = ESPSystem.colors.killer,
    Flag = "KillerColor",
    Callback = function(color)
        ESPSystem.colors.killer = color
        for _, player in ipairs(Services.Players:GetPlayers()) do
            ESPSystem:updatePlayer(player)
        end
    end
})

-- ========================================
-- UI SETUP - WORLD TAB
-- ========================================

Tabs.World:CreateSection("Object ESP")

Tabs.World:CreateToggle({
    Name = "Generator ESP",
    CurrentValue = false,
    Flag = "GenESP",
    Callback = function(value)
        WorldESP.enabled.Generator = value
    end
})

Tabs.World:CreateToggle({
    Name = "Hook ESP",
    CurrentValue = false,
    Flag = "HookESP",
    Callback = function(value)
        WorldESP.enabled.Hook = value
    end
})

Tabs.World:CreateToggle({
    Name = "Gate ESP",
    CurrentValue = false,
    Flag = "GateESP",
    Callback = function(value)
        WorldESP.enabled.Gate = value
    end
})

-- ========================================
-- UI SETUP - VISUAL TAB
-- ========================================

Tabs.Visual:CreateSection("Lighting")

Tabs.Visual:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(value)
        if value then
            VisualSystem:enableFullbright()
        else
            VisualSystem:disableFullbright()
        end
    end
})

Tabs.Visual:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Flag = "NoFog",
    Callback = function(value)
        pcall(function()
            Services.Lighting.FogEnd = value and 100000 or VisualSystem.originalLighting.FogEnd
        end)
    end
})

-- ========================================
-- UI SETUP - MISC TAB
-- ========================================

Tabs.Misc:CreateSection("Information")

Tabs.Misc:CreateParagraph({
    Title = "M20 Project",
    Content = "Violence District Suite\nVersion 5.0\n\nComplete rewrite with proper error handling\nAll systems operational"
})

Tabs.Misc:CreateButton({
    Name = "Reload Config",
    Callback = function()
        pcall(function()
            Rayfield:LoadConfiguration()
        end)
        Rayfield:Notify({
            Title = "Config",
            Content = "Configuration reloaded",
            Duration = 3
        })
    end
})

-- ========================================
-- CHARACTER SETUP
-- ========================================

local function onCharacterAdded(character)
    task.wait(0.5)
    pcall(function()
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            SpeedSystem:bindHumanoid(humanoid)
        end
        
        if NoclipSystem.enabled then
            NoclipSystem:enable()
        end
    end)
end

if Player.Character then
    onCharacterAdded(Player.Character)
end

Player.CharacterAdded:Connect(onCharacterAdded)

-- ========================================
-- INITIALIZATION
-- ========================================

-- Save original lighting
VisualSystem:saveOriginalLighting()

-- Initialize ESP
ESPSystem:initialize()

-- Start world ESP loop
WorldESP:startUpdateLoop()

-- Load config
pcall(function()
    Rayfield:LoadConfiguration()
end)

-- Show loaded notification
Rayfield:Notify({
    Title = "M20 Project",
    Content = "Loaded successfully!\nVersion 5.0",
    Duration = 6
})

print("================================================")
print("M20 Project - Violence District Suite")
print("Version: 5.0 Complete Rewrite")
print("Status: All Systems Operational")
print("================================================")
print("Features:")
print("• Player ESP with Highlights")
print("• World Object ESP")
print("• Speed Lock System")
print("• Noclip")
print("• Teleportation")
print("• Visual Enhancements")
print("• Anti-AFK")
print("================================================")
