-- NexusX Hub - Premium Edition
-- Advanced Test Suite for Violence District
-- Version 4.0 ULTRA

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- ========= UTILS =========
local function alive(i)
    if not i then return false end
    local ok = pcall(function() return i.Parent end)
    return ok and i.Parent ~= nil
end
local function validPart(p) return p and alive(p) and p:IsA("BasePart") end
local function clamp(n,lo,hi) if n<lo then return lo elseif n>hi then return hi else return n end end
local function now() return os.clock() end
local function dist(a,b) return (a-b).Magnitude end

local function firstBasePart(inst)
    if not alive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") and alive(inst.PrimaryPart) then return inst.PrimaryPart end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        if validPart(p) then return p end
    end
    if inst:IsA("Tool") then
        local h = inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart")
        if validPart(h) then return h end
    end
    return nil
end

local function makeBillboard(text, color3)
    local g = Instance.new("BillboardGui")
    g.Name = "NX_Tag"
    g.AlwaysOnTop = true
    g.Size = UDim2.new(0, 200, 0, 40)
    g.StudsOffset = Vector3.new(0, 3.5, 0)
    
    local l = Instance.new("TextLabel")
    l.Name = "Label"
    l.BackgroundTransparency = 0.3
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
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = l
    
    return g
end

local function ensureBoxESP(part, name, color)
    if not validPart(part) then return end
    local a = part:FindFirstChild(name)
    if not a then
        local ok, obj = pcall(function()
            local b = Instance.new("BoxHandleAdornment")
            b.Name = name
            b.Adornee = part
            b.ZIndex = 10
            b.AlwaysOnTop = true
            b.Transparency = 0.4
            b.Size = part.Size + Vector3.new(0.3,0.3,0.3)
            b.Color3 = color
            b.Parent = part
            return b
        end)
        if ok then a = obj end
    else
        a.Color3 = color
        a.Size = part.Size + Vector3.new(0.3,0.3,0.3)
    end
end

local function clearChild(o, n)
    if o and alive(o) then
        local c = o:FindFirstChild(n)
        if c then pcall(function() c:Destroy() end) end
    end
end

local function ensureHighlight(model, fill)
    if not (model and model:IsA("Model") and alive(model)) then return end
    local hl = model:FindFirstChild("NX_HL")
    if not hl then
        local ok, obj = pcall(function()
            local h = Instance.new("Highlight")
            h.Name = "NX_HL"
            h.Adornee = model
            h.FillTransparency = 0.4
            h.OutlineTransparency = 0
            h.Parent = model
            return h
        end)
        if ok then hl = obj else return end
    end
    hl.FillColor = fill
    hl.OutlineColor = fill
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function clearHighlight(model)
    if model and model:FindFirstChild("NX_HL") then
        pcall(function() model.NX_HL:Destroy() end)
    end
end

-- ========= UI WINDOW =========
local Window = Rayfield:CreateWindow({
    Name="⚡ NexusX Hub ULTRA",
    LoadingTitle="NexusX Hub Premium",
    LoadingSubtitle="by NexusX Team - v4.0",
    ConfigurationSaving={
        Enabled=true,
        FolderName="NexusX_Premium",
        FileName="nx_config_v4"
    },
    KeySystem=false
})

local TabPlayer= Window:CreateTab("🎮 Movement", 4483362458)
local TabKiller= Window:CreateTab("🔪 Killer", 4483362458)
local TabESP   = Window:CreateTab("👁️ ESP Pro", 4483362458)
local TabWorld = Window:CreateTab("🌍 World", 4483362458)
local TabVisual= Window:CreateTab("✨ Visual FX", 4483362458)
local TabMisc  = Window:CreateTab("⚙️ Premium", 4483362458)

-- ========= ROLE DETECTION =========
local function getRole(p)
    local tn = p.Team and p.Team.Name and p.Team.Name:lower() or ""
    if tn:find("killer") then return "Killer" end
    if tn:find("survivor") then return "Survivor" end
    return "Survivor"
end

local killerTypeName = "Killer"
local killerColors = {
    Jason = Color3.fromRGB(255, 60, 60),
    Stalker = Color3.fromRGB(255, 120, 60),
    Masked = Color3.fromRGB(255, 160, 60),
    Hidden = Color3.fromRGB(255, 60, 160),
    Abysswalker = Color3.fromRGB(120, 60, 255),
    Killer = Color3.fromRGB(255, 0, 0),
}

local function currentKillerColor()
    return killerColors[killerTypeName] or killerColors.Killer
end

local knownKillers = {Jason=true, Stalker=true, Masked=true, Hidden=true, Abysswalker=true}
do
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if r then
        local k = r:FindFirstChild("Killers")
        if k then
            for _,ch in ipairs(k:GetChildren()) do
                if ch:IsA("Folder") then knownKillers[ch.Name] = true end
            end
        end
    end
end

local function refreshKillerESPLabels()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and getRole(pl)=="Killer" then
            if pl.Character then
                local head = pl.Character:FindFirstChild("Head")
                if head then
                    local tag = head:FindFirstChild("NX_Tag")
                    if tag then
                        local l = tag:FindFirstChild("Label")
                        if l then l.Text = "⚠️ "..pl.Name.." ["..tostring(killerTypeName).."]" end
                    end
                end
            end
        end
    end
end

local function setKillerType(name)
    if name and knownKillers[name] and killerTypeName ~= name then
        killerTypeName = name
        refreshKillerESPLabels()
    end
end

-- ========= PLAYER ESP =========
local survivorColor = Color3.fromRGB(0,255,150)
local killerBaseColor = killerColors.Killer
local nametagsEnabled, playerESPEnabled = false, false
local playerConns = {}

local function applyPlayerESP(p)
    if p == LP then return end
    local c = p.Character
    if not (c and alive(c)) then return end
    local col = (getRole(p)=="Killer") and currentKillerColor() or survivorColor

    if playerESPEnabled then
        if c:IsDescendantOf(Workspace) then ensureHighlight(c, col) end
        local head = c:FindFirstChild("Head")
        if nametagsEnabled and validPart(head) then
            local tag = head:FindFirstChild("NX_Tag") or makeBillboard(p.Name, col)
            tag.Name = "NX_Tag"
            tag.Parent = head
            local l = tag:FindFirstChild("Label")
            if l then
                if getRole(p)=="Killer" then 
                    l.Text = "⚠️ "..p.Name.." ["..tostring(killerTypeName).."]" 
                else 
                    l.Text = "✅ "..p.Name
                end
                l.TextColor3 = col
            end
        else
            local t = head and head:FindFirstChild("NX_Tag")
            if t then pcall(function() t:Destroy() end) end
        end
    else
        clearHighlight(c)
        local head = c:FindFirstChild("Head")
        local t = head and head:FindFirstChild("NX_Tag")
        if t then pcall(function() t:Destroy() end) end
    end
end

local function watchPlayer(p)
    if playerConns[p] then for _,cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = {}
    table.insert(playerConns[p], p.CharacterAdded:Connect(function()
        task.delay(0.15, function() applyPlayerESP(p) end)
    end))
    table.insert(playerConns[p], p:GetPropertyChangedSignal("Team"):Connect(function() applyPlayerESP(p) end))
    if p.Character then applyPlayerESP(p) end
end

local function unwatchPlayer(p)
    if p.Character then
        clearHighlight(p.Character)
        local head = p.Character:FindFirstChild("Head")
        if head and head:FindFirstChild("NX_Tag") then pcall(function() head.NX_Tag:Destroy() end) end
    end
    if playerConns[p] then for _,cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = nil
end

TabESP:CreateSection("🎯 Player Detection")
TabESP:CreateToggle({
    Name="ESP Chams (Ultra)",
    CurrentValue=false,
    Flag="PlayerESP",
    Callback=function(s) 
        playerESPEnabled=s 
        for _,pl in ipairs(Players:GetPlayers()) do 
            if pl~=LP then applyPlayerESP(pl) end 
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
        nametagsEnabled=s 
        for _,pl in ipairs(Players:GetPlayers()) do 
            if pl~=LP then applyPlayerESP(pl) end 
        end
    end
})

TabESP:CreateColorPicker({
    Name="Survivor Color",
    Color=survivorColor,
    Flag="SurvivorCol",
    Callback=function(c) 
        survivorColor=c 
        for _,pl in ipairs(Players:GetPlayers()) do 
            if pl~=LP then applyPlayerESP(pl) end 
        end 
    end
})

TabESP:CreateColorPicker({
    Name="Killer Color",
    Color=killerBaseColor,
    Flag="KillerCol",
    Callback=function(c) 
        killerBaseColor=c 
        killerColors.Killer=c 
        for _,pl in ipairs(Players:GetPlayers()) do 
            if pl~=LP then applyPlayerESP(pl) end 
        end 
    end
})

for _,p in ipairs(Players:GetPlayers()) do if p~=LP then watchPlayer(p) end end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(unwatchPlayer)

-- ========= WORLD ESP =========
local worldColors = {
    Generator = Color3.fromRGB(0,200,255),
    Hook = Color3.fromRGB(255,50,50),
    Gate = Color3.fromRGB(255,225,0),
    Window = Color3.fromRGB(255,255,255),
    Palletwrong = Color3.fromRGB(255,160,0)
}
local worldEnabled = {Generator=false,Hook=false,Gate=false,Window=false,Palletwrong=false}
local validCats = {Generator=true,Hook=true,Gate=true,Window=true,Palletwrong=true}
local worldReg = {Generator={},Hook={},Gate={},Window={},Palletwrong={}}
local mapAdd, mapRem = {}, {}

local palletState = setmetatable({}, {__mode="k"})
local windowState = setmetatable({}, {__mode="k"})

local function labelForPallet(model)
    local st=palletState[model] or "UP"
    if st=="DOWN" then return "🔻 Pallet (Down)" end
    if st=="DEST" then return "❌ Pallet (Broken)" end
    if st=="SLIDE" then return "⚡ Pallet (Slide)" end
    return "🟢 Pallet (Ready)"
end

local function labelForWindow(model)
    local st=windowState[model] or "READY"
    return st=="BUSY" and "🔴 Window (Busy)" or "🟢 Window (Ready)"
end

local function pickRep(model, cat)
    if not (model and alive(model)) then return nil end
    if cat == "Generator" then
        local hb = model:FindFirstChild("HitBox", true)
        if validPart(hb) then return hb end
    elseif cat == "Palletwrong" then
        local a = model:FindFirstChild("HumanoidRootPart", true); if validPart(a) then return a end
        local b = model:FindFirstChild("PrimaryPartPallet", true); if validPart(b) then return b end
        local c = model:FindFirstChild("Primary1", true); if validPart(c) then return c end
        local d = model:FindFirstChild("Primary2", true); if validPart(d) then return d end
    end
    return firstBasePart(model)
end

local function genLabelData(model)
    local pct = tonumber(model:GetAttribute("RepairProgress")) or 0
    if pct>=0 and pct<=1.001 then pct = pct*100 end
    pct = clamp(pct,0,100)
    local repairers = tonumber(model:GetAttribute("PlayersRepairingCount")) or 0
    local paused = (model:GetAttribute("ProgressPaused")==true)
    
    local parts = {"⚡ Gen "..tostring(math.floor(pct+0.5)).."%" }
    if repairers>0 then parts[#parts+1]="👥"..repairers end
    if paused then parts[#parts+1]="⏸️" end
    
    local text = table.concat(parts," ")
    local hue = clamp((pct/100)*0.33,0,0.33)
    local labelColor = Color3.fromHSV(hue,1,1)
    return text, labelColor
end

local function hasAnyBasePart(m)
    if not (m and alive(m)) then return false end
    local bp = m:FindFirstChildWhichIsA("BasePart", true)
    return bp ~= nil
end

local function isPalletGone(m)
    if not alive(m) then return true end
    if not m:IsDescendantOf(Workspace) then return true end
    if palletState[m]=="DEST" then return true end
    local ok, val = pcall(function() return m:GetAttribute("Destroyed") end)
    if ok and val == true then return true end
    if not hasAnyBasePart(m) then return true end
    return false
end

local function ensureWorldEntry(cat, model)
    if not alive(model) or worldReg[cat][model] then return end
    if cat=="Palletwrong" and isPalletGone(model) then return end
    local rep = pickRep(model, cat)
    if not validPart(rep) then return end
    worldReg[cat][model] = {part = rep}
end

local function removeWorldEntry(cat, model)
    local e = worldReg[cat][model]
    if not e then return end
    clearChild(e.part, "NX_"..cat)
    clearChild(e.part, "NX_Text_"..cat)
    worldReg[cat][model] = nil
end

local function registerFromDescendant(obj)
    if not alive(obj) then return end
    if obj:IsA("Model") and validCats[obj.Name] then
        ensureWorldEntry(obj.Name, obj)
        return
    end
    if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and validCats[obj.Parent.Name] then
        ensureWorldEntry(obj.Parent.Name, obj.Parent)
    end
end

local function unregisterFromDescendant(obj)
    if not obj then return end
    if obj:IsA("Model") and validCats[obj.Name] then
        removeWorldEntry(obj.Name, obj)
        return
    end
    if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and validCats[obj.Parent.Name] then
        local e = worldReg[obj.Parent.Name][obj.Parent]
        if e and e.part == obj then removeWorldEntry(obj.Parent.Name, obj.Parent) end
    end
end

local function attachRoot(root)
    if not root or mapAdd[root] then return end
    mapAdd[root] = root.DescendantAdded:Connect(registerFromDescendant)
    mapRem[root] = root.DescendantRemoving:Connect(unregisterFromDescendant)
    for _,d in ipairs(root:GetDescendants()) do registerFromDescendant(d) end
end

local function refreshRoots()
    for _,cn in pairs(mapAdd) do if cn then cn:Disconnect() end end
    for _,cn in pairs(mapRem) do if cn then cn:Disconnect() end end
    mapAdd, mapRem = {}, {}
    local r1 = Workspace:FindFirstChild("Map")
    local r2 = Workspace:FindFirstChild("Map1")
    if r1 then attachRoot(r1) end
    if r2 then attachRoot(r2) end
end
refreshRoots()
Workspace.ChildAdded:Connect(function(ch) if ch.Name=="Map" or ch.Name=="Map1" then attachRoot(ch) end end)

local worldLoopThread=nil
local function anyWorldEnabled() for _,v in pairs(worldEnabled) do if v then return true end end return false end

local function startWorldLoop()
    if worldLoopThread then return end
    worldLoopThread = task.spawn(function()
        while anyWorldEnabled() do
            for cat,models in pairs(worldReg) do
                if worldEnabled[cat] then
                    local col, tagName, textName = worldColors[cat], "NX_"..cat, "NX_Text_"..cat
                    local n = 0
                    for model,entry in pairs(models) do
                        if cat=="Palletwrong" and isPalletGone(model) then
                            removeWorldEntry(cat, model)
                        else
                            local part = entry.part
                            if model and alive(model) then
                                if not validPart(part) or (model:IsA("Model") and not part:IsDescendantOf(model)) then
                                    entry.part = pickRep(model, cat); part = entry.part
                                end
                                if validPart(part) then
                                    ensureBoxESP(part, tagName, col)
                                    local bb = part:FindFirstChild(textName)
                                    if not bb then
                                        local newbb = makeBillboard((cat=="Palletwrong" and "🟢 Pallet") or ("⚡ "..cat), col)
                                        newbb.Name = textName
                                        newbb.Parent = part
                                        bb = newbb
                                    end
                                    local lbl = bb:FindFirstChild("Label")
                                    if lbl then
                                        if cat=="Generator" then 
                                            local txt,lblCol=genLabelData(model) 
                                            lbl.Text=txt 
                                            lbl.TextColor3=lblCol
                                        elseif cat=="Palletwrong" then 
                                            lbl.Text=labelForPallet(model) 
                                            lbl.TextColor3=col
                                        elseif cat=="Window" then 
                                            lbl.Text=labelForWindow(model) 
                                            lbl.TextColor3=col
                                        else 
                                            lbl.Text="⚡ "..cat 
                                            lbl.TextColor3=col 
                                        end
                                    end
                                end
                            else
                                removeWorldEntry(cat, model)
                            end
                        end
                        n = n + 1
                        if n % 60 == 0 then task.wait() end
                    end
                end
            end
            task.wait(0.25)
        end
        worldLoopThread=nil
    end)
end

local function setWorldToggle(cat, state)
    worldEnabled[cat] = state
    if state then
        if not worldLoopThread then startWorldLoop() end
    else
        for _,entry in pairs(worldReg[cat]) do
            if entry and entry.part then
                clearChild(entry.part,"NX_"..cat); clearChild(entry.part,"NX_Text_"..cat)
            end
        end
    end
end

TabWorld:CreateSection("🔍 Object Detection")
TabWorld:CreateToggle({Name="⚡ Generators",CurrentValue=false,Flag="Gen",Callback=function(s) setWorldToggle("Generator", s) end})
TabWorld:CreateToggle({Name="🪝 Hooks",CurrentValue=false,Flag="Hook",Callback=function(s) setWorldToggle("Hook", s) end})
TabWorld:CreateToggle({Name="🚪 Exit Gates",CurrentValue=false,Flag="Gate",Callback=function(s) setWorldToggle("Gate", s) end})
TabWorld:CreateToggle({Name="🪟 Windows (Smart)",CurrentValue=false,Flag="Window",Callback=function(s) setWorldToggle("Window", s) end})
TabWorld:CreateToggle({Name="🔻 Pallets (Smart)",CurrentValue=false,Flag="Pallet",Callback=function(s) setWorldToggle("Palletwrong", s) end})

TabWorld:CreateSection("🎨 Customize Colors")
TabWorld:CreateColorPicker({Name="Generator",Color=worldColors.Generator,Flag="GenCol",Callback=function(c) worldColors.Generator=c end})
TabWorld:CreateColorPicker({Name="Hooks",Color=worldColors.Hook,Flag="HookCol",Callback=function(c) worldColors.Hook=c end})
TabWorld:CreateColorPicker({Name="Gates",Color=worldColors.Gate,Flag="GateCol",Callback=function(c) worldColors.Gate=c end})

-- ========= LIGHTING & VISUAL FX =========
local initLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local fullbrightEnabled = false
local fbLoop

TabVisual:CreateSection("💡 Advanced Lighting")
TabVisual:CreateToggle({
    Name="Fullbright ULTRA",
    CurrentValue=false,
    Flag="Fullbright",
    Callback=function(s)
        fullbrightEnabled = s
        if fbLoop then task.cancel(fbLoop) fbLoop=nil end
        if s then
            fbLoop = task.spawn(function()
                while fullbrightEnabled do
                    Lighting.Brightness = 3
                    Lighting.ClockTime = 14
                    Lighting.FogStart = 0
                    Lighting.FogEnd = 1e9
                    Lighting.GlobalShadows = false
                    Lighting.OutdoorAmbient = Color3.fromRGB(150,150,150)
                    task.wait(0.5)
                end
            end)
            Rayfield:Notify({
                Title="Visual FX",
                Content="✅ Fullbright Activated",
                Duration=3
            })
        else
            for k,v in pairs(initLighting) do 
                pcall(function() if v~=nil then Lighting[k]=v end end) 
            end
        end
    end
})

TabVisual:CreateToggle({
    Name="No Fog (Clear)",
    CurrentValue=false,
    Flag="NoFog",
    Callback=function(s)
        pcall(function()
            Lighting.FogEnd = s and 1e9 or initLighting.FogEnd
        end)
    end
})

TabVisual:CreateToggle({
    Name="No Shadows (FPS+)",
    CurrentValue=false,
    Flag="NoShadows",
    Callback=function(s)
        pcall(function()
            Lighting.GlobalShadows = not s
        end)
    end
})

-- ========= SPEED SYSTEM =========
local speedCurrent, speedHumanoid = 16, nil
local speedEnforced = false
local speedTickConn = nil

local function setWalkSpeed(h,v) 
    if h and h.Parent then 
        pcall(function() h.WalkSpeed=v end) 
    end 
end

local function canEnforce()
    if not speedEnforced then return false end
    if not speedHumanoid or not speedHumanoid.Parent then return false end
    if speedHumanoid.Health<=0 then return false end
    return true
end

local function heartbeat()
    if not speedHumanoid then return end
    if not canEnforce() then return end
    if speedHumanoid.WalkSpeed ~= speedCurrent then
        setWalkSpeed(speedHumanoid, speedCurrent)
    end
end

local function bindHumanoid(h)
    speedHumanoid = h
    if speedEnforced then
        if not speedTickConn then
            speedTickConn = RunService.Heartbeat:Connect(heartbeat)
        end
        if canEnforce() then
            setWalkSpeed(h, speedCurrent)
        end
    end
end

TabPlayer:CreateSection("⚡ Movement Control")
TabPlayer:CreateToggle({
    Name="Speed Lock (Stable)",
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
                Title="Movement",
                Content="✅ Speed Lock: "..speedCurrent,
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
                Title="Movement",
                Content="❌ Speed Normalized",
                Duration=3
            })
        end
    end
})

TabPlayer:CreateSlider({
    Name="Walk Speed",
    Range={0,200},
    Increment=1,
    CurrentValue=16,
    Flag="WalkSpeed",
    Callback=function(v) 
        speedCurrent=v 
        if speedEnforced and canEnforce() then 
            setWalkSpeed(speedHumanoid,speedCurrent) 
        end 
    end
})

-- ========= NOCLIP =========
local noclipEnabled, noclipConn = false, nil

local function setNoclip(state)
    if state and not noclipConn then
        noclipEnabled = true
        noclipConn = RunService.Stepped:Connect(function()
            local c = LP.Character
            if not c then return end
            for _,part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    elseif not state and noclipConn then
        noclipEnabled=false
        noclipConn:Disconnect()
        noclipConn=nil
    end
end

TabPlayer:CreateToggle({
    Name="Noclip (Phase)",
    CurrentValue=false,
    Flag="Noclip",
    Callback=function(s) 
        setNoclip(s)
        Rayfield:Notify({
            Title="Movement",
            Content=s and "✅ Noclip Active" or "❌ Noclip Off",
            Duration=2
        })
    end
})

-- ========= TELEPORTS =========
TabPlayer:CreateSection("🚀 Teleportation")

local function tpCFrame(cf)
    local char=LP.Character
    if not (char and char.Parent) then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local was=noclipEnabled
    setNoclip(true)
    hrp.CFrame = cf
    task.delay(0.5,function() 
        if not was then setNoclip(false) end 
    end)
end

local function teleportToNearest(role)
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local best,bp,bd=nil,nil,1e9
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=LP and getRole(pl)==role then
            local ch=pl.Character
            local h=ch and ch:FindFirstChild("HumanoidRootPart")
            if h then 
                local d=dist(h.Position,hrp.Position) 
                if d<bd then 
                    bd=d 
                    best=pl 
                    bp=h 
                end 
            end
        end
    end
    
    if best and bp then
        local cf = bp.CFrame * CFrame.new(0,0,-5)
        cf = cf + Vector3.new(0,2,0)
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
end

TabPlayer:CreateButton({
    Name="⚠️ Teleport to Killer",
    Callback=function() 
        teleportToNearest("Killer") 
    end
})

TabPlayer:CreateButton({
    Name="✅ Teleport to Teammate",
    Callback=function() 
        teleportToNearest("Survivor") 
    end
})

-- ========= AUTO REPAIR GENS =========
do
    local autoRepairEnabled = false
    local SCAN_INTERVAL = 1.0
    local REPAIR_TICK = 0.25
    local AVOID_RADIUS = 80
    local MOVE_DIST = 35
    
    local gens = {}
    local current = nil
    local lastScan = 0

    local function findRemotes()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        if not r then return nil,nil end
        local g = r:FindFirstChild("Generator")
        if not g then return nil,nil end
        return g:FindFirstChild("RepairEvent"), g:FindFirstChild("RepairAnim")
    end
    
    local RepairEvent, RepairAnim = findRemotes()

    local function getGenPartFromModel(m)
        if not (m and alive(m)) then return nil end
        local hb = m:FindFirstChild("HitBox", true)
        if validPart(hb) then return hb end
        return firstBasePart(m)
    end

    local function genProgress(m)
        local p = tonumber(m:GetAttribute("RepairProgress")) or 0
        if p <= 1.001 then p = p * 100 end
        return clamp(p,0,100)
    end

    local function rescanGenerators()
        gens = {}
        local function scanRoot(root)
            if not root then return end
            for _,d in ipairs(root:GetDescendants()) do
                if d:IsA("Model") and d.Name=="Generator" then
                    local part = getGenPartFromModel(d)
                    if validPart(part) then
                        table.insert(gens, {model=d, part=part})
                    end
                end
            end
        end
        scanRoot(Workspace:FindFirstChild("Map"))
        scanRoot(Workspace:FindFirstChild("Map1"))
    end

    local function nearestKillerDistanceTo(pos)
        local bd = 1e9
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP and getRole(pl)=="Killer" then
                local ch = pl.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - pos).Magnitude
                    if d < bd then bd = d end
                end
            end
        end
        return bd
    end

    local function chooseTarget()
        local best = nil
        local bestScore = -1
        for _,g in ipairs(gens) do
            local m = g.model
            if alive(m) then
                local prog = genProgress(m)
                if prog < 100 then
                    local pos = g.part.Position
                    local kd = nearestKillerDistanceTo(pos)
                    local score = (kd >= AVOID_RADIUS and 1000 or 0) + prog
                    if score > bestScore then
                        bestScore = score
                        best = g
                    end
                end
            end
        end
        return best
    end

    local function safeFromKiller(target)
        if not target or not target.part then return false end
        local kd = nearestKillerDistanceTo(target.part.Position)
        return kd >= AVOID_RADIUS
    end

    local function doRepair(target)
        if RepairAnim and RepairAnim.FireServer then 
            pcall(function() RepairAnim:FireServer(target.model) end) 
        end
        if RepairEvent and RepairEvent.FireServer then 
            pcall(function() RepairEvent:FireServer(target.model) end) 
        end
    end

    task.spawn(function()
        while true do
            local t = now()
            if t - lastScan >= SCAN_INTERVAL then
                lastScan = t
                rescanGenerators()
            end
            task.wait(0.2)
        end
    end)

    task.spawn(function()
        while true do
            if autoRepairEnabled then
                if (not current) or (not alive(current.model)) or genProgress(current.model) >= 100 or (not safeFromKiller(current)) then
                    current = chooseTarget()
                end

                if current and alive(current.model) and genProgress(current.model) < 100 then
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - current.part.Position).Magnitude
                        if d > MOVE_DIST then
                            local cf = current.part.CFrame * CFrame.new(0,0,-3) + Vector3.new(0,2,0)
                            tpCFrame(cf)
                        end
                    end
                    doRepair(current)
                end
            end
            task.wait(REPAIR_TICK)
        end
    end)

    TabWorld:CreateSection("🤖 Automation")
    TabWorld:CreateToggle({
        Name="Auto-Repair (AI)",
        CurrentValue=false,
        Flag="AutoRepairGens",
        Callback=function(state)
            autoRepairEnabled = state
            Rayfield:Notify({
                Title="Auto-Repair",
                Content=state and "✅ AI Activated" or "❌ Deactivated",
                Duration=4
            })
        end
    })
end

-- ========= ANTI AFK =========
TabPlayer:CreateSection("🛡️ Protection")

local antiAFKConn=nil
TabPlayer:CreateToggle({
    Name="Anti-AFK (Safe)",
    CurrentValue=false,
    Flag="AntiAFK",
    Callback=function(s)
        if s and not antiAFKConn then
            antiAFKConn = LP.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
        elseif not s and antiAFKConn then
            antiAFKConn:Disconnect()
            antiAFKConn=nil
        end
    end
})

-- ========= KILLER FEATURES =========
TabKiller:CreateSection("🔪 Advanced Killer Tools")
TabKiller:CreateParagraph({
    Title="Coming Soon",
    Content="Advanced killer features will be added in future updates"
})

-- ========= MISC / PREMIUM =========
TabMisc:CreateSection("ℹ️ About NexusX")
TabMisc:CreateParagraph({
    Title="⚡ NexusX Hub ULTRA",
    Content="Premium Edition v4.0\nMade by NexusX Team\n\nFeatures:\n• Advanced ESP System\n• Smart World Detection\n• AI Auto-Repair\n• Premium Visual FX\n• Stable Speed Lock"
})

TabMisc:CreateButton({
    Name="🔄 Reload Configuration",
    Callback=function()
        Rayfield:LoadConfiguration()
        Rayfield:Notify({
            Title="Config",
            Content="✅ Configuration Reloaded",
            Duration=3
        })
    end
})

-- ========= CHARACTER SETUP =========
local function onCharacterAdded(char)
    local h = char:WaitForChild("Humanoid", 10) or char:FindFirstChildOfClass("Humanoid")
    if h then bindHumanoid(h) end
    if noclipEnabled then
        task.wait(0.2)
        setNoclip(true)
    end
end

if LP.Character then onCharacterAdded(LP.Character) end
LP.CharacterAdded:Connect(onCharacterAdded)

-- ========= REMOTE HOOKS =========
local remoteHooks=setmetatable({},{__mode="k"})
local function connectRemote(inst)
    if remoteHooks[inst] then return end
    local isRE = inst:IsA("RemoteEvent")
    if not isRE then return end
    
    local full = inst:GetFullName()
    if full:find("Killers",1,true) then
        local seg = string.split(full,".")
        for i=#seg,1,-1 do
            if seg[i]=="Killers" then
                local kn = seg[i+1]
                if kn and knownKillers[kn] then
                    local conn = inst.OnClientEvent:Connect(function()
                        setKillerType(kn)
                    end)
                    remoteHooks[inst]=conn
                end
                break
            end
        end
    end
end

for _,d in ipairs(ReplicatedStorage:GetDescendants()) do 
    if d:IsA("RemoteEvent") then connectRemote(d) end 
end
ReplicatedStorage.DescendantAdded:Connect(function(d) 
    if d:IsA("RemoteEvent") then connectRemote(d) end 
end)

-- ========= FINALIZE =========
Rayfield:LoadConfiguration()
Rayfield:Notify({
    Title="⚡ NexusX Hub",
    Content="✅ Loaded Successfully!\nVersion 4.0 ULTRA",
    Duration=6
})

print("=====================================")
print("⚡ NexusX Hub - Premium Edition")
print("Version: 4.0 ULTRA")
print("Status: ✅ ALL SYSTEMS OPERATIONAL")
print("=====================================")
print("Features Active:")
print("• Advanced ESP System")
print("• Smart World Detection")  
print("• AI-Powered Auto-Repair")
print("• Premium Visual Effects")
print("• Stable Movement System")
print("=====================================")
