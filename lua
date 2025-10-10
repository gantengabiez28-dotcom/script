-- NexusX Hub - Premium Edition v4.0
-- Fixed Version - No CoreGui Errors

-- Load Rayfield safely
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    warn("[NexusX] Failed to load Rayfield UI Library")
    return
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- ========= SAFE UTILS =========
local function alive(i)
    if not i then return false end
    local ok, result = pcall(function() return i.Parent end)
    return ok and result ~= nil
end

local function validPart(p) 
    return p and alive(p) and p:IsA("BasePart") 
end

local function clamp(n,lo,hi) 
    if n<lo then return lo 
    elseif n>hi then return hi 
    else return n end 
end

local function now() 
    return os.clock() 
end

local function dist(a,b) 
    return (a-b).Magnitude 
end

local function firstBasePart(inst)
    if not alive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart and validPart(inst.PrimaryPart) then 
            return inst.PrimaryPart 
        end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        if validPart(p) then return p end
    end
    return nil
end

-- ========= SAFE BILLBOARD =========
local function makeBillboard(text, color3)
    local success, gui = pcall(function()
        local g = Instance.new("BillboardGui")
        g.Name = "NX_Tag"
        g.AlwaysOnTop = true
        g.Size = UDim2.new(0, 200, 0, 40)
        g.StudsOffset = Vector3.new(0, 3.5, 0)
        
        local l = Instance.new("TextLabel")
        l.Name = "Label"
        l.BackgroundTransparency = 0.5
        l.BackgroundColor3 = Color3.new(0, 0, 0)
        l.BorderSizePixel = 0
        l.Size = UDim2.new(1, 0, 1, 0)
        l.Font = Enum.Font.GothamBold
        l.Text = text
        l.TextSize = 15
        l.TextColor3 = color3 or Color3.new(1,1,1)
        l.TextStrokeTransparency = 0
        l.TextStrokeColor3 = Color3.new(0,0,0)
        l.Parent = g
        
        return g
    end)
    
    return success and gui or nil
end

-- ========= SAFE BOX ESP =========
local function ensureBoxESP(part, name, color)
    if not validPart(part) then return end
    
    pcall(function()
        local existing = part:FindFirstChild(name)
        if existing then
            existing.Color3 = color
            existing.Size = part.Size + Vector3.new(0.3,0.3,0.3)
            return
        end
        
        local b = Instance.new("BoxHandleAdornment")
        b.Name = name
        b.Adornee = part
        b.ZIndex = 10
        b.AlwaysOnTop = true
        b.Transparency = 0.4
        b.Size = part.Size + Vector3.new(0.3,0.3,0.3)
        b.Color3 = color
        b.Parent = part
    end)
end

-- ========= SAFE HIGHLIGHT =========
local function ensureHighlight(model, fill)
    if not (model and model:IsA("Model") and alive(model)) then return end
    
    pcall(function()
        local hl = model:FindFirstChild("NX_HL")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "NX_HL"
            hl.Adornee = model
            hl.FillTransparency = 0.4
            hl.OutlineTransparency = 0
            hl.Parent = model
        end
        hl.FillColor = fill
        hl.OutlineColor = fill
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end)
end

local function clearHighlight(model)
    pcall(function()
        if model and model:FindFirstChild("NX_HL") then
            model.NX_HL:Destroy()
        end
    end)
end

local function clearChild(o, n)
    pcall(function()
        if o and alive(o) then
            local c = o:FindFirstChild(n)
            if c then c:Destroy() end
        end
    end)
end

-- ========= CREATE WINDOW =========
local Window = Rayfield:CreateWindow({
    Name="⚡ NexusX Hub ULTRA",
    LoadingTitle="NexusX Premium",
    LoadingSubtitle="v4.0 Fixed Edition",
    ConfigurationSaving={
        Enabled=true,
        FolderName="NexusX_Premium",
        FileName="nx_config_v4"
    },
    KeySystem=false
})

-- Create Tabs
local TabPlayer = Window:CreateTab("🎮 Movement", 4483362458)
local TabESP = Window:CreateTab("👁️ ESP Pro", 4483362458)
local TabWorld = Window:CreateTab("🌍 World", 4483362458)
local TabVisual = Window:CreateTab("✨ Visual", 4483362458)
local TabMisc = Window:CreateTab("⚙️ Settings", 4483362458)

-- ========= ROLE DETECTION =========
local function getRole(p)
    local success, team = pcall(function()
        return p.Team
    end)
    
    if not success or not team then return "Survivor" end
    
    local tn = tostring(team.Name):lower()
    if tn:find("killer") then return "Killer" end
    return "Survivor"
end

-- ========= PLAYER ESP =========
local survivorColor = Color3.fromRGB(0,255,150)
local killerColor = Color3.fromRGB(255,50,50)
local playerESPEnabled = false
local nametagsEnabled = false
local playerConns = {}

local function applyPlayerESP(p)
    if p == LP then return end
    
    pcall(function()
        local c = p.Character
        if not (c and alive(c)) then return end
        
        local col = (getRole(p)=="Killer") and killerColor or survivorColor
        
        if playerESPEnabled then
            if c:IsDescendantOf(Workspace) then
                ensureHighlight(c, col)
            end
            
            local head = c:FindFirstChild("Head")
            if nametagsEnabled and validPart(head) then
                local tag = head:FindFirstChild("NX_Tag")
                if not tag then
                    tag = makeBillboard(p.Name, col)
                    if tag then
                        tag.Parent = head
                    end
                else
                    local l = tag:FindFirstChild("Label")
                    if l then
                        l.Text = (getRole(p)=="Killer" and "⚠️ " or "✅ ")..p.Name
                        l.TextColor3 = col
                    end
                end
            else
                clearChild(head, "NX_Tag")
            end
        else
            clearHighlight(c)
            local head = c:FindFirstChild("Head")
            clearChild(head, "NX_Tag")
        end
    end)
end

local function watchPlayer(p)
    pcall(function()
        if playerConns[p] then
            for _,cn in ipairs(playerConns[p]) do
                cn:Disconnect()
            end
        end
        playerConns[p] = {}
        
        local conn1 = p.CharacterAdded:Connect(function()
            task.delay(0.3, function() applyPlayerESP(p) end)
        end)
        table.insert(playerConns[p], conn1)
        
        if p.Character then
            applyPlayerESP(p)
        end
    end)
end

-- ESP Tab
TabESP:CreateSection("🎯 Player Detection")

TabESP:CreateToggle({
    Name="ESP Chams (Ultra)",
    CurrentValue=false,
    Flag="PlayerESP",
    Callback=function(s)
        playerESPEnabled = s
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then applyPlayerESP(pl) end
        end
        Rayfield:Notify({
            Title="ESP System",
            Content=s and "✅ Activated" or "❌ Deactivated",
            Duration=3
        })
    end
})

TabESP:CreateToggle({
    Name="Premium Nametags",
    CurrentValue=false,
    Flag="Nametags",
    Callback=function(s)
        nametagsEnabled = s
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then applyPlayerESP(pl) end
        end
    end
})

TabESP:CreateColorPicker({
    Name="Survivor Color",
    Color=survivorColor,
    Flag="SurvivorCol",
    Callback=function(c)
        survivorColor = c
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then applyPlayerESP(pl) end
        end
    end
})

TabESP:CreateColorPicker({
    Name="Killer Color",
    Color=killerColor,
    Flag="KillerCol",
    Callback=function(c)
        killerColor = c
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then applyPlayerESP(pl) end
        end
    end
})

-- Initialize ESP
for _,p in ipairs(Players:GetPlayers()) do
    if p ~= LP then watchPlayer(p) end
end

Players.PlayerAdded:Connect(watchPlayer)

Players.PlayerRemoving:Connect(function(p)
    pcall(function()
        if playerConns[p] then
            for _,cn in ipairs(playerConns[p]) do
                cn:Disconnect()
            end
            playerConns[p] = nil
        end
    end)
end)

-- ========= WORLD ESP =========
local worldColors = {
    Generator = Color3.fromRGB(0,200,255),
    Hook = Color3.fromRGB(255,50,50),
    Gate = Color3.fromRGB(255,225,0),
}

local worldEnabled = {Generator=false, Hook=false, Gate=false}
local worldReg = {Generator={}, Hook={}, Gate={}}
local validCats = {Generator=true, Hook=true, Gate=true}

local function pickRep(model, cat)
    if not (model and alive(model)) then return nil end
    if cat == "Generator" then
        local hb = model:FindFirstChild("HitBox", true)
        if validPart(hb) then return hb end
    end
    return firstBasePart(model)
end

local function genProgress(model)
    local success, pct = pcall(function()
        return tonumber(model:GetAttribute("RepairProgress")) or 0
    end)
    
    if not success then return 0 end
    if pct >= 0 and pct <= 1.001 then pct = pct * 100 end
    return clamp(pct, 0, 100)
end

local function ensureWorldEntry(cat, model)
    pcall(function()
        if not alive(model) or worldReg[cat][model] then return end
        local rep = pickRep(model, cat)
        if not validPart(rep) then return end
        worldReg[cat][model] = {part = rep}
    end)
end

local function removeWorldEntry(cat, model)
    pcall(function()
        local e = worldReg[cat][model]
        if not e then return end
        clearChild(e.part, "NX_"..cat)
        clearChild(e.part, "NX_Text_"..cat)
        worldReg[cat][model] = nil
    end)
end

local worldLoopThread = nil

local function startWorldLoop()
    if worldLoopThread then return end
    
    worldLoopThread = task.spawn(function()
        while true do
            local hasEnabled = false
            for _,v in pairs(worldEnabled) do
                if v then hasEnabled = true break end
            end
            
            if not hasEnabled then
                task.wait(1)
            else
                pcall(function()
                    for cat, models in pairs(worldReg) do
                        if worldEnabled[cat] then
                            local col = worldColors[cat]
                            local tagName = "NX_"..cat
                            local textName = "NX_Text_"..cat
                            
                            for model, entry in pairs(models) do
                                if alive(model) and entry.part then
                                    ensureBoxESP(entry.part, tagName, col)
                                    
                                    local bb = entry.part:FindFirstChild(textName)
                                    if not bb then
                                        bb = makeBillboard("⚡ "..cat, col)
                                        if bb then
                                            bb.Name = textName
                                            bb.Parent = entry.part
                                        end
                                    end
                                    
                                    if bb then
                                        local lbl = bb:FindFirstChild("Label")
                                        if lbl and cat == "Generator" then
                                            local prog = genProgress(model)
                                            lbl.Text = "⚡ Gen "..tostring(math.floor(prog)).."%"
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.3)
            end
        end
    end)
end

local function setWorldToggle(cat, state)
    worldEnabled[cat] = state
    if state then
        startWorldLoop()
    else
        pcall(function()
            for _, entry in pairs(worldReg[cat]) do
                if entry and entry.part then
                    clearChild(entry.part, "NX_"..cat)
                    clearChild(entry.part, "NX_Text_"..cat)
                end
            end
        end)
    end
end

-- Scan for world objects
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local map = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Map1")
            if not map then return end
            
            for _, d in ipairs(map:GetDescendants()) do
                if d:IsA("Model") and validCats[d.Name] then
                    ensureWorldEntry(d.Name, d)
                end
            end
        end)
    end
end)

TabWorld:CreateSection("🔍 Object Detection")
TabWorld:CreateToggle({Name="⚡ Generators", CurrentValue=false, Flag="Gen", Callback=function(s) setWorldToggle("Generator", s) end})
TabWorld:CreateToggle({Name="🪝 Hooks", CurrentValue=false, Flag="Hook", Callback=function(s) setWorldToggle("Hook", s) end})
TabWorld:CreateToggle({Name="🚪 Gates", CurrentValue=false, Flag="Gate", Callback=function(s) setWorldToggle("Gate", s) end})

-- ========= SPEED SYSTEM =========
local speedCurrent = 16
local speedHumanoid = nil
local speedEnforced = false
local speedTickConn = nil

local function setWalkSpeed(h, v)
    pcall(function()
        if h and h.Parent and h.Health > 0 then
            h.WalkSpeed = v
        end
    end)
end

local function canEnforce()
    if not speedEnforced then return false end
    if not speedHumanoid or not speedHumanoid.Parent then return false end
    if speedHumanoid.Health <= 0 then return false end
    return true
end

local function heartbeat()
    if not canEnforce() then return end
    if speedHumanoid.WalkSpeed ~= speedCurrent then
        setWalkSpeed(speedHumanoid, speedCurrent)
    end
end

local function bindHumanoid(h)
    speedHumanoid = h
    if speedEnforced and canEnforce() then
        if not speedTickConn then
            speedTickConn = RunService.Heartbeat:Connect(heartbeat)
        end
        setWalkSpeed(h, speedCurrent)
    end
end

TabPlayer:CreateSection("⚡ Movement Control")

TabPlayer:CreateToggle({
    Name="Speed Lock",
    CurrentValue=false,
    Flag="SpeedLock",
    Callback=function(state)
        speedEnforced = state
        
        if state then
            if speedHumanoid and speedHumanoid.Parent then
                if not speedTickConn then
                    speedTickConn = RunService.Heartbeat:Connect(heartbeat)
                end
                if canEnforce() then
                    setWalkSpeed(speedHumanoid, speedCurrent)
                end
            end
            Rayfield:Notify({
                Title="Speed Lock",
                Content="✅ Enabled: "..speedCurrent,
                Duration=3
            })
        else
            if speedTickConn then
                speedTickConn:Disconnect()
                speedTickConn = nil
            end
            if speedHumanoid and speedHumanoid.Parent then
                setWalkSpeed(speedHumanoid, 16)
            end
            Rayfield:Notify({
                Title="Speed Lock",
                Content="❌ Disabled",
                Duration=3
            })
        end
    end
})

TabPlayer:CreateSlider({
    Name="Walk Speed",
    Range={0, 200},
    Increment=1,
    CurrentValue=16,
    Flag="WalkSpeed",
    Callback=function(v)
        speedCurrent = v
        if speedEnforced and canEnforce() then
            setWalkSpeed(speedHumanoid, speedCurrent)
        end
    end
})

-- ========= NOCLIP =========
local noclipEnabled = false
local noclipConn = nil

local function setNoclip(state)
    pcall(function()
        if state and not noclipConn then
            noclipEnabled = true
            noclipConn = RunService.Stepped:Connect(function()
                local c = LP.Character
                if not c then return end
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        elseif not state and noclipConn then
            noclipEnabled = false
            noclipConn:Disconnect()
            noclipConn = nil
        end
    end)
end

TabPlayer:CreateToggle({
    Name="Noclip",
    CurrentValue=false,
    Flag="Noclip",
    Callback=function(s)
        setNoclip(s)
        Rayfield:Notify({
            Title="Noclip",
            Content=s and "✅ Active" or "❌ Off",
            Duration=2
        })
    end
})

-- ========= TELEPORTS =========
TabPlayer:CreateSection("🚀 Teleportation")

local function tpCFrame(cf)
    pcall(function()
        local char = LP.Character
        if not (char and char.Parent) then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local was = noclipEnabled
        setNoclip(true)
        hrp.CFrame = cf
        task.delay(0.5, function()
            if not was then setNoclip(false) end
        end)
    end)
end

local function teleportToNearest(role)
    pcall(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local best, bp, bd = nil, nil, math.huge
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP and getRole(pl) == role then
                local ch = pl.Character
                local h = ch and ch:FindFirstChild("HumanoidRootPart")
                if h then
                    local d = dist(h.Position, hrp.Position)
                    if d < bd then
                        bd = d
                        best = pl
                        bp = h
                    end
                end
            end
        end
        
        if best and bp then
            local cf = bp.CFrame * CFrame.new(0, 0, -5) + Vector3.new(0, 2, 0)
            tpCFrame(cf)
            Rayfield:Notify({
                Title="Teleport",
                Content="✅ To "..role..": "..best.Name,
                Duration=4
            })
        else
            Rayfield:Notify({
                Title="Teleport",
                Content="❌ No "..role.." found",
                Duration=4
            })
        end
    end)
end

TabPlayer:CreateButton({
    Name="⚠️ TP to Killer",
    Callback=function()
        teleportToNearest("Killer")
    end
})

TabPlayer:CreateButton({
    Name="✅ TP to Survivor",
    Callback=function()
        teleportToNearest("Survivor")
    end
})

-- ========= VISUAL FX =========
local fullbrightEnabled = false
local fbLoop = nil

TabVisual:CreateSection("💡 Lighting")

TabVisual:CreateToggle({
    Name="Fullbright",
    CurrentValue=false,
    Flag="Fullbright",
    Callback=function(s)
        fullbrightEnabled = s
        if fbLoop then task.cancel(fbLoop) fbLoop = nil end
        
        if s then
            fbLoop = task.spawn(function()
                while fullbrightEnabled do
                    pcall(function()
                        Lighting.Brightness = 3
                        Lighting.ClockTime = 14
                        Lighting.FogEnd = 1e9
                        Lighting.GlobalShadows = false
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

TabVisual:CreateToggle({
    Name="No Fog",
    CurrentValue=false,
    Flag="NoFog",
    Callback=function(s)
        pcall(function()
            Lighting.FogEnd = s and 1e9 or 100000
        end)
    end
})

-- ========= ANTI AFK =========
TabPlayer:CreateSection("🛡️ Protection")

local antiAFKConn = nil

TabPlayer:CreateToggle({
    Name="Anti-AFK",
    CurrentValue=false,
    Flag="AntiAFK",
    Callback=function(s)
        pcall(function()
            if s and not antiAFKConn then
                antiAFKConn = LP.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            elseif not s and antiAFKConn then
                antiAFKConn:Disconnect()
                antiAFKConn = nil
            end
        end)
    end
})

-- ========= MISC =========
TabMisc:CreateSection("ℹ️ About")

TabMisc:CreateParagraph({
    Title="⚡ NexusX Hub ULTRA",
    Content="Premium Edition v4.0 Fixed\n\nAll errors resolved!\n\nFeatures:\n• Advanced ESP\n• Smart Detection\n• Visual Effects\n• Stable Movement"
})

-- ========= CHARACTER SETUP =========
local function onCharacterAdded(char)
    task.wait(0.5)
    pcall(function()
        local h = char:FindFirstChildWhichIsA("Humanoid")
        if h then bindHumanoid(h) end
        if noclipEnabled then setNoclip(true) end
    end)
end

if LP.Character then
    onCharacterAdded(LP.Character)
end

LP.CharacterAdded:Connect(onCharacterAdded)

-- ========= FINALIZE =========
pcall(function()
    Rayfield:LoadConfiguration()
end)

Rayfield:Notify({
    Title="⚡ NexusX Hub",
    Content="✅ Loaded Successfully!\nv4.0 Fixed Edition",
    Duration=6
})

print("=====================================")
print("⚡ NexusX Hub - Premium Edition")
print("Version: 4.0 FIXED")
print("Status: ✅ NO ERRORS")
print("=====================================")
