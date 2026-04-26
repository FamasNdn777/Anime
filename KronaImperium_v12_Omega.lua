--[[
    ╔══════════════════════════════════════════════════════════╗
    ║   KRONA IMPERIUM v12 OMEGA — Blox Fruits Edition        ║
    ║   Delta Mobile Optimized · ESP Real · Aimbot Funcional  ║
    ║   Anti-Detection Layer · Ícones UI · Mobile Compact     ║
    ╚══════════════════════════════════════════════════════════╝
    Executor: Delta Mobile (Roblox)
]]

local LOGO_URL =
      "https://raw.githubusercontent.com/FamasNdn777/Anime/refs/heads/main/1000
      182145-photoaidcom-cropped.jpg"
    6 local FILE_NAME = "KronaLogo.jpg"
    7
    8 -- Função para baixar a imagem (Necessário para o Delta)
    9 local function GetImage()
   10     if not isfile(FILE_NAME) then
   11         local success, response = pcall(function()
   12             return game:HttpGet(LOGO_URL)
   13         end)
   14         if success then
   15             writefile(FILE_NAME, response)
   16         else
   17             warn("Erro ao baixar a imagem!")
   18             return nil
   19         end
   20     end
   21     -- Transforma o arquivo salvo em um ID que o Roblox aceita
   22     return getcustomasset(FILE_NAME)
   23 end
   24
   25 local FinalLogo = GetImage()
-- ========== ANTI-DETECTION LAYER ==========
-- Hooks namecall para esconder Kick e proteger GUI. Tudo envolvido em pcall pra
-- não quebrar a execução se o executor não suportar (Delta varia).
local AntiDetect = {}
do
    local ok, err = pcall(function()
        local hookmetamethod = rawget(getfenv(), "hookmetamethod")
        local checkcaller    = rawget(getfenv(), "checkcaller")
        local newcclosure    = rawget(getfenv(), "newcclosure") or function(f) return f end
        local getnamecallmethod = rawget(getfenv(), "getnamecallmethod")

        if hookmetamethod and checkcaller and getnamecallmethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                -- Só bloqueia Kick proveniente do servidor (não nosso script)
                if not checkcaller() and method == "Kick" then
                    return nil
                end
                return oldNamecall(self, ...)
            end))
            AntiDetect.namecall = true
        end
    end)
    if not ok then warn("[Krona] AntiDetect falhou: "..tostring(err)) end

    -- Esconder GUI do GetChildren do CoreGui (alguns anti-cheats varrem)
    AntiDetect.protectGui = function(gui)
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        pcall(function() if gethui then gui.Parent = gethui() end end)
        pcall(function() if protectgui then protectgui(gui) end end)
    end
end

-- ========== SERVICES ==========
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera or Camera
end)

-- ========== CONFIG ==========
_G.Krona = _G.Krona or {}
local CFG = _G.Krona

CFG.EspEnabled       = true
CFG.EspBox           = true
CFG.EspName          = true
CFG.EspHealth        = true
CFG.EspDistance      = true
CFG.EspTracer        = false
CFG.EspChams         = false
CFG.EspFruit         = true
CFG.EspLevel         = true
CFG.EspTeamCheck     = true
CFG.EspMaxDistance   = 2500

CFG.AimbotEnabled    = false
CFG.AimbotKey        = "Q"
CFG.AimbotFOV        = 200
CFG.AimbotPart       = "Head"
CFG.AimbotTeamCheck  = true
CFG.AimbotPrediction = 0.165
CFG.AimbotSmoothness = 0.25
CFG.AimbotMobileBtn  = true
CFG.AimMode          = "Closest" -- "Closest" | "Mouse" | "Specific" | "All" | "Locked"
CFG.AimTargetName    = ""        -- nome (ou parte) do player no modo Specific
CFG.AimSticky        = false     -- 100% grudado (não solta enquanto vivo)
CFG.AimSnap          = 0         -- puxada extra/snap inicial (0-100), aplica boost no primeiro frame
CFG.AimToggleMode    = true      -- true: botão flutuante alterna ON/OFF | false: segurar p/ mirar
CFG.AimLockedName    = ""        -- nome do player travado pela lista (modo Locked)

CFG.KillAura         = false
CFG.KillAuraRange    = 25
CFG.SpamM1           = false
CFG.HitboxExpander   = false
CFG.HitboxSize       = 6
CFG.AutoCounter      = false
CFG.AutoBlock        = false
CFG.AntiStun         = false
CFG.AutoDodge        = false
CFG.LowHpWarning     = true
CFG.LowHpThreshold   = 35

CFG.SpeedEnabled     = false
CFG.WalkSpeed        = 24
CFG.JumpEnabled      = false
CFG.JumpPower        = 60
CFG.InfJump          = false
CFG.NoClip           = false
CFG.Fly              = false
CFG.FlySpeed         = 60
CFG.NoFallDamage     = false
CFG.AntiAFK          = true

-- ========== UTILS ==========
local function safe(fn, ...) local ok, e = pcall(fn, ...); return ok, e end

local function getCharacter(plr)
    plr = plr or LP
    local c = plr.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil end
    return c, hrp, hum
end
local function isAlive(plr)
    local c, hrp, hum = getCharacter(plr)
    return c and hrp and hum and hum.Health > 0
end
local function distFromMe(pos)
    local _, hrp = getCharacter(LP)
    if not hrp then return math.huge end
    return (hrp.Position - pos).Magnitude
end
-- Lista de frutas conhecidas do Blox Fruits (cobre as principais)
local BLOX_FRUITS = {
    Rocket=1,Spin=1,Chop=1,Spring=1,Bomb=1,Smoke=1,Spike=1,Flame=1,Falcon=1,
    Ice=1,Sand=1,Dark=1,Diamond=1,Light=1,Rubber=1,Barrier=1,Magma=1,Door=1,
    Quake=1,Buddha=1,Love=1,Spider=1,Sound=1,Phoenix=1,Portal=1,Rumble=1,Paw=1,
    Gravity=1,Dough=1,Shadow=1,Venom=1,Control=1,Soul=1,Dragon=1,Leopard=1,Kitsune=1,
    Mammoth=1,Gas=1,Blizzard=1,T_Rex=1,Yeti=1,Creation=1,Eagle=1,Spirit=1
}
local function getEquippedFruit(plr)
    local function scan(container)
        if not container then return nil end
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") then
                local n = tostring(t.Name)
                local clean = n:gsub("%-Fruit",""):gsub(" Fruit","")
                if BLOX_FRUITS[clean] then return clean end
                if n:lower():find("fruit") then return clean end
            end
        end
        return nil
    end
    local f = scan(plr.Character)
    if f then return f end
    f = scan(plr:FindFirstChildOfClass("Backpack"))
    return f
end
local function getLevel(plr)
    local d = plr:FindFirstChild("Data")
    if d and d:FindFirstChild("Level") then return d.Level.Value end
    local ls = plr:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Level") then return ls.Level.Value end
    return nil
end
local function isSameTeam(plr)
    if not CFG.EspTeamCheck then return false end
    if plr.Team and LP.Team and plr.Team == LP.Team then return true end
    return false
end

-- ========== CLEANUP ==========
pcall(function()
    local old = CoreGui:FindFirstChild("KronaImperium")
    if old then old:Destroy() end
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g.Name == "KronaEspContainer" then g:Destroy() end
    end
end)

-- ========== MAIN GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KronaImperium"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
AntiDetect.protectGui(ScreenGui)
if not ScreenGui.Parent then
    pcall(function() ScreenGui.Parent = CoreGui end)
end
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

-- Container separado para ESP (BillboardGuis) - mais limpo
local EspContainer = Instance.new("Folder")
EspContainer.Name = "KronaEspContainer"
EspContainer.Parent = ScreenGui

local C = {
    bg=Color3.fromRGB(15,17,26), bg2=Color3.fromRGB(22,25,37), bg3=Color3.fromRGB(30,34,50),
    accent=Color3.fromRGB(120,90,255), accent2=Color3.fromRGB(180,100,255),
    text=Color3.fromRGB(235,238,250), sub=Color3.fromRGB(150,155,175),
    on=Color3.fromRGB(120,90,255), off=Color3.fromRGB(60,65,85),
    danger=Color3.fromRGB(255,80,110), success=Color3.fromRGB(80,220,140),
}

-- Ícones Roblox (asset IDs oficiais — equivalentes a Lucide/Material)
local ICONS = {
    eye      = "rbxassetid://7733715400", -- olho (ESP)
    crosshair= "rbxassetid://7733964640", -- mira (Aimbot/PVP)
    run      = "rbxassetid://7733717447", -- corrida (Player)
    settings = "rbxassetid://7734053495", -- engrenagem (Config)
    crown    = "rbxassetid://7733911828", -- coroa (logo)
    close    = "rbxassetid://7743878857", -- X
    minus    = "rbxassetid://7743878538", -- –
    shield   = "rbxassetid://7733769889", -- escudo
    trash    = "rbxassetid://7734122606", -- lixeira
    target   = "rbxassetid://7733964640",
    bolt     = "rbxassetid://7733799986", -- raio
    heart    = "rbxassetid://7734066883",
}

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c end
local function stroke(p, col, t) local s = Instance.new("UIStroke"); s.Color = col or C.bg3; s.Thickness = t or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s end
local function pad(p, v) local u = Instance.new("UIPadding"); u.PaddingLeft = UDim.new(0,v); u.PaddingRight = UDim.new(0,v); u.PaddingTop = UDim.new(0,v); u.PaddingBottom = UDim.new(0,v); u.Parent = p; return u end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 440, 0, 300)
Main.Position = UDim2.new(0.5, -220, 0.5, -150)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
corner(Main, 14)
stroke(Main, Color3.fromRGB(45,50,75), 1)

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,C.bg), ColorSequenceKeypoint.new(1,Color3.fromRGB(20,22,35))}
grad.Rotation = 135
grad.Parent = Main

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1,0,0,38)
TopBar.BackgroundColor3 = C.bg2
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
corner(TopBar, 14)
local topFix = Instance.new("Frame"); topFix.Size = UDim2.new(1,0,0,14); topFix.Position = UDim2.new(0,0,1,-14); topFix.BackgroundColor3 = C.bg2; topFix.BorderSizePixel = 0; topFix.Parent = TopBar

-- Logo com ícone
local LogoIcon = Instance.new("ImageLabel")
LogoIcon.Size = UDim2.new(0,20,0,20)
LogoIcon.Position = UDim2.new(0,12,0.5,-10)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Image = ICONS.crown
LogoIcon.ImageColor3 = C.accent2
LogoIcon.Parent = TopBar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 180, 1, 0)
Logo.Position = UDim2.new(0, 38, 0, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "KRONA"
Logo.TextColor3 = C.text
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 14
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = TopBar

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(0,100,1,0)
Sub.Position = UDim2.new(0,90,0,0)
Sub.BackgroundTransparency = 1
Sub.Text = "v12.1 OMEGA"
Sub.TextColor3 = C.accent
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 10
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Parent = TopBar

local function makeIconBtn(iconAsset, x, color)
    local b = Instance.new("ImageButton")
    b.Size = UDim2.new(0,28,0,28)
    b.Position = UDim2.new(1, x, 0, 5)
    b.BackgroundColor3 = C.bg3
    b.BorderSizePixel = 0
    b.Image = iconAsset
    b.ImageColor3 = color or C.text
    b.ImageRectSize = Vector2.new(0,0)
    b.AutoButtonColor = false
    b.Parent = TopBar
    corner(b, 6)
    pad(b, 5)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color or C.accent}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.bg3}):Play() end)
    return b
end
local MinBtn   = makeIconBtn(ICONS.minus, -68)
local CloseBtn = makeIconBtn(ICONS.close, -34, C.danger)

-- Sidebar
local Side = Instance.new("Frame")
Side.Size = UDim2.new(0, 96, 1, -46)
Side.Position = UDim2.new(0, 6, 0, 42)
Side.BackgroundColor3 = C.bg2
Side.BorderSizePixel = 0
Side.Parent = Main
corner(Side, 8)
local SideList = Instance.new("UIListLayout"); SideList.Padding = UDim.new(0,4); SideList.SortOrder = Enum.SortOrder.LayoutOrder; SideList.Parent = Side
pad(Side, 6)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -114, 1, -46)
Content.Position = UDim2.new(0, 106, 0, 42)
Content.BackgroundColor3 = C.bg2
Content.BorderSizePixel = 0
Content.Parent = Main
corner(Content, 8)

local tabs, activeTab = {}, nil
local function makeTab(name, iconAsset, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,36)
    btn.BackgroundColor3 = C.bg3
    btn.BackgroundTransparency = 0.4
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = Side
    corner(btn, 6)

    local ic = Instance.new("ImageLabel")
    ic.Size = UDim2.new(0,18,0,18)
    ic.Position = UDim2.new(0,8,0.5,-9)
    ic.BackgroundTransparency = 1
    ic.Image = iconAsset
    ic.ImageColor3 = C.sub
    ic.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-32,1,0)
    lbl.Position = UDim2.new(0,32,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.sub
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0,3,0.6,0)
    indicator.Position = UDim2.new(0,0,0.2,0)
    indicator.BackgroundColor3 = C.accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = btn
    corner(indicator,2)

    local panel = Instance.new("ScrollingFrame")
    panel.Size = UDim2.new(1,-8,1,-8)
    panel.Position = UDim2.new(0,4,0,4)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = C.accent
    panel.CanvasSize = UDim2.new(0,0,0,0)
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.Visible = false
    panel.Parent = Content
    local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0,6); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = panel

    local function activate()
        for _, t in pairs(tabs) do
            t.panel.Visible = false; t.indicator.Visible = false
            TweenService:Create(t.ic, TweenInfo.new(0.2), {ImageColor3 = C.sub}):Play()
            TweenService:Create(t.lbl, TweenInfo.new(0.2), {TextColor3 = C.sub}):Play()
            TweenService:Create(t.btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
        end
        panel.Visible = true; indicator.Visible = true
        TweenService:Create(ic, TweenInfo.new(0.2), {ImageColor3 = C.accent}):Play()
        TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = C.text}):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        activeTab = name
    end
    btn.MouseButton1Click:Connect(activate)
    local entry = {btn=btn, panel=panel, ic=ic, lbl=lbl, indicator=indicator, activate=activate}
    tabs[name] = entry
    return entry, panel
end

local function section(parent, text)
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1,0,0,18)
    s.BackgroundTransparency = 1
    s.Text = "  " .. text
    s.TextColor3 = C.accent
    s.Font = Enum.Font.GothamBold
    s.TextSize = 10
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Parent = parent
end

local function toggle(parent, name, key, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,30)
    f.BackgroundColor3 = C.bg3
    f.BackgroundTransparency = 0.3
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = C.text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0,32,0,16); sw.Position = UDim2.new(1,-40,0.5,-8)
    sw.BackgroundColor3 = CFG[key] and C.on or C.off; sw.BorderSizePixel = 0
    sw.Text = ""; sw.AutoButtonColor = false; sw.Parent = f
    corner(sw,8)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,12,0,12)
    dot.Position = CFG[key] and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BorderSizePixel = 0
    dot.Parent = sw; corner(dot,6)
    local function set(v)
        CFG[key] = v
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = v and C.on or C.off}):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {Position = v and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}):Play()
        if callback then callback(v) end
    end
    sw.MouseButton1Click:Connect(function() set(not CFG[key]) end)
end

local function slider(parent, name, key, min, max, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,42)
    f.BackgroundColor3 = C.bg3; f.BackgroundTransparency = 0.3
    f.BorderSizePixel = 0; f.Parent = parent
    corner(f,6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,0,16); lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = C.text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0,40,0,16); val.Position = UDim2.new(1,-45,0,4)
    val.BackgroundTransparency = 1; val.Text = tostring(CFG[key])
    val.TextColor3 = C.accent; val.Font = Enum.Font.GothamBold; val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right; val.Parent = f
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-20,0,5); bar.Position = UDim2.new(0,10,0,28)
    bar.BackgroundColor3 = C.off; bar.BorderSizePixel = 0; bar.Parent = f
    corner(bar,3)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((CFG[key]-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = C.accent; fill.BorderSizePixel = 0
    fill.Parent = bar; corner(fill,3)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,12,0,12)
    knob.Position = UDim2.new((CFG[key]-min)/(max-min),-6,0.5,-6)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0
    knob.Parent = bar; corner(knob,6)
    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local v = math.floor(min + (max-min)*rel + 0.5)
        CFG[key] = v; val.Text = tostring(v)
        fill.Size = UDim2.new(rel,0,1,0)
        knob.Position = UDim2.new(rel,-6,0.5,-6)
        if callback then callback(v) end
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; update(i) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
end


local function dropdown(parent, name, key, options, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,30)
    f.BackgroundColor3 = C.bg3; f.BackgroundTransparency = 0.3
    f.BorderSizePixel = 0; f.Parent = parent
    corner(f,6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45,-10,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = C.text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5,-10,0,22); btn.Position = UDim2.new(0.5,0,0.5,-11)
    btn.BackgroundColor3 = C.bg2; btn.BorderSizePixel = 0
    btn.Text = CFG[key]; btn.TextColor3 = C.accent
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    btn.AutoButtonColor = false; btn.Parent = f
    corner(btn,6)
    local idx = 1
    for i,v in ipairs(options) do if v == CFG[key] then idx = i; break end end
    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        CFG[key] = options[idx]; btn.Text = options[idx]
        if callback then callback(options[idx]) end
    end)
end

local function textbox(parent, name, key, placeholder, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,30)
    f.BackgroundColor3 = C.bg3; f.BackgroundTransparency = 0.3
    f.BorderSizePixel = 0; f.Parent = parent
    corner(f,6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4,-10,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = name
    lbl.TextColor3 = C.text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0.55,-10,0,22); tb.Position = UDim2.new(0.45,0,0.5,-11)
    tb.BackgroundColor3 = C.bg2; tb.BorderSizePixel = 0
    tb.Text = CFG[key] or ""; tb.PlaceholderText = placeholder or ""
    tb.TextColor3 = C.text; tb.PlaceholderColor3 = C.sub
    tb.Font = Enum.Font.Gotham; tb.TextSize = 11
    tb.ClearTextOnFocus = false; tb.Parent = f
    corner(tb,6); pad(tb,4)
    tb.FocusLost:Connect(function()
        CFG[key] = tb.Text
        if callback then callback(tb.Text) end
    end)
end

-- ========== TABS ==========
local _, espPanel    = makeTab("ESP",    ICONS.eye,       1)
local _, pvpPanel    = makeTab("PVP",    ICONS.crosshair, 2)
local _, playerPanel = makeTab("Player", ICONS.run,       3)
local _, settingsPanel=makeTab("Config", ICONS.settings,  4)

-- ESP TAB
section(espPanel, "VISUAL")
toggle(espPanel, "ESP Habilitado", "EspEnabled")
toggle(espPanel, "Box (Caixa)", "EspBox")
toggle(espPanel, "Nome", "EspName")
toggle(espPanel, "Barra de Vida", "EspHealth")
toggle(espPanel, "Distância", "EspDistance")
toggle(espPanel, "Tracer", "EspTracer")
toggle(espPanel, "Chams (Brilho)", "EspChams")
section(espPanel, "INFO PVP")
toggle(espPanel, "Mostrar Fruta", "EspFruit")
toggle(espPanel, "Mostrar Level", "EspLevel")
section(espPanel, "FILTROS")
toggle(espPanel, "Ignorar Time", "EspTeamCheck")
slider(espPanel, "Distância Máxima", "EspMaxDistance", 500, 5000)

-- PVP TAB
section(pvpPanel, "AIMBOT")
toggle(pvpPanel, "Aimbot Habilitado", "AimbotEnabled")
toggle(pvpPanel, "Botão Aimbot Mobile", "AimbotMobileBtn")
toggle(pvpPanel, "Ignorar Time (Aim)", "AimbotTeamCheck")
dropdown(pvpPanel, "Modo de Alvo", "AimMode", {"Closest","Mouse","Specific","All","Locked"})
textbox(pvpPanel, "Player Específico", "AimTargetName", "ex: NoobMaster")
toggle(pvpPanel, "Sticky (100% grudado)", "AimSticky")
toggle(pvpPanel, "Botão Mobile = Toggle", "AimToggleMode")
slider(pvpPanel, "FOV", "AimbotFOV", 50, 600)
slider(pvpPanel, "Suavidade %", "AimbotSmoothness", 5, 100)
slider(pvpPanel, "Puxada (Snap) %", "AimSnap", 0, 100)

-- ===== SELECIONAR PLAYER (lista do servidor) =====
section(pvpPanel, "SELECIONAR PLAYER")

-- label do alvo travado
local lockedLbl = Instance.new("TextLabel")
lockedLbl.Size = UDim2.new(1,0,0,24)
lockedLbl.BackgroundColor3 = C.bg3; lockedLbl.BackgroundTransparency = 0.3
lockedLbl.BorderSizePixel = 0
lockedLbl.Text = "Alvo: nenhum"
lockedLbl.TextColor3 = C.accent
lockedLbl.Font = Enum.Font.GothamBold; lockedLbl.TextSize = 11
lockedLbl.Parent = pvpPanel
corner(lockedLbl, 6)

-- container scrollável para a lista
local plrList = Instance.new("ScrollingFrame")
plrList.Size = UDim2.new(1,0,0,140)
plrList.BackgroundColor3 = C.bg3; plrList.BackgroundTransparency = 0.4
plrList.BorderSizePixel = 0
plrList.ScrollBarThickness = 3
plrList.ScrollBarImageColor3 = C.accent
plrList.CanvasSize = UDim2.new(0,0,0,0)
plrList.AutomaticCanvasSize = Enum.AutomaticSize.Y
plrList.Parent = pvpPanel
corner(plrList, 6)
local plrLayout = Instance.new("UIListLayout")
plrLayout.Padding = UDim.new(0,3)
plrLayout.SortOrder = Enum.SortOrder.LayoutOrder
plrLayout.Parent = plrList
local plrPad = Instance.new("UIPadding")
plrPad.PaddingTop = UDim.new(0,4); plrPad.PaddingLeft = UDim.new(0,4)
plrPad.PaddingRight = UDim.new(0,4); plrPad.PaddingBottom = UDim.new(0,4)
plrPad.Parent = plrList

local function updateLockedLabel()
    if CFG.AimLockedName ~= "" then
        lockedLbl.Text = "🎯 Travado em: " .. CFG.AimLockedName
        lockedLbl.TextColor3 = C.danger
    else
        lockedLbl.Text = "Alvo: nenhum"
        lockedLbl.TextColor3 = C.accent
    end
end

local function refreshPlayerList()
    for _, c in ipairs(plrList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1,-4,0,26)
            b.BackgroundColor3 = (CFG.AimLockedName == plr.Name) and C.danger or C.bg2
            b.BorderSizePixel = 0
            b.Text = "  " .. plr.DisplayName .. "  (@" .. plr.Name .. ")"
            b.TextColor3 = C.text
            b.Font = Enum.Font.GothamMedium; b.TextSize = 11
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.AutoButtonColor = false
            b.Parent = plrList
            corner(b, 5)
            b.MouseButton1Click:Connect(function()
                if CFG.AimLockedName == plr.Name then
                    -- desselecionar
                    CFG.AimLockedName = ""
                    if CFG.AimMode == "Locked" then CFG.AimMode = "Closest" end
                else
                    CFG.AimLockedName = plr.Name
                    CFG.AimMode = "Locked"
                end
                updateLockedLabel()
                refreshPlayerList()
            end)
        end
    end
end

-- botões controle da lista
local ctrlRow = Instance.new("Frame")
ctrlRow.Size = UDim2.new(1,0,0,28)
ctrlRow.BackgroundTransparency = 1
ctrlRow.Parent = pvpPanel
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.5,-3,1,0); refreshBtn.Position = UDim2.new(0,0,0,0)
refreshBtn.BackgroundColor3 = C.accent; refreshBtn.BorderSizePixel = 0
refreshBtn.Text = "🔄 Atualizar Lista"; refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
refreshBtn.Font = Enum.Font.GothamBold; refreshBtn.TextSize = 11
refreshBtn.AutoButtonColor = false
refreshBtn.Parent = ctrlRow
corner(refreshBtn, 6)
refreshBtn.MouseButton1Click:Connect(refreshPlayerList)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.5,-3,1,0); clearBtn.Position = UDim2.new(0.5,3,0,0)
clearBtn.BackgroundColor3 = C.danger; clearBtn.BorderSizePixel = 0
clearBtn.Text = "✖ Limpar Alvo"; clearBtn.TextColor3 = Color3.fromRGB(255,255,255)
clearBtn.Font = Enum.Font.GothamBold; clearBtn.TextSize = 11
clearBtn.AutoButtonColor = false
clearBtn.Parent = ctrlRow
corner(clearBtn, 6)
clearBtn.MouseButton1Click:Connect(function()
    CFG.AimLockedName = ""
    if CFG.AimMode == "Locked" then CFG.AimMode = "Closest" end
    updateLockedLabel()
    refreshPlayerList()
end)

-- popular inicialmente e manter atualizado quando players entram/saem
refreshPlayerList()
Players.PlayerAdded:Connect(function() task.wait(0.5); pcall(refreshPlayerList) end)
Players.PlayerRemoving:Connect(function(p)
    if p and CFG.AimLockedName == p.Name then
        CFG.AimLockedName = ""
        if CFG.AimMode == "Locked" then CFG.AimMode = "Closest" end
        updateLockedLabel()
    end
    task.wait(0.3); pcall(refreshPlayerList)
end)
section(pvpPanel, "COMBATE")
toggle(pvpPanel, "Kill Aura (M1)", "KillAura")
slider(pvpPanel, "Alcance Aura", "KillAuraRange", 5, 60)
toggle(pvpPanel, "Spam M1", "SpamM1")
toggle(pvpPanel, "Hitbox Expandida", "HitboxExpander")
slider(pvpPanel, "Tamanho Hitbox", "HitboxSize", 3, 20)
section(pvpPanel, "DEFENSIVO")
toggle(pvpPanel, "Auto Counter (F)", "AutoCounter")
toggle(pvpPanel, "Auto Block", "AutoBlock")
toggle(pvpPanel, "Anti Stun Alert", "AntiStun")
toggle(pvpPanel, "Auto Dodge", "AutoDodge")
toggle(pvpPanel, "Aviso HP Baixo", "LowHpWarning")
slider(pvpPanel, "HP Limite %", "LowHpThreshold", 10, 80)

-- PLAYER TAB
section(playerPanel, "MOVIMENTO")
toggle(playerPanel, "Speed", "SpeedEnabled")
slider(playerPanel, "Velocidade", "WalkSpeed", 16, 80)
toggle(playerPanel, "Pulo Alto", "JumpEnabled")
slider(playerPanel, "Força Pulo", "JumpPower", 50, 200)
toggle(playerPanel, "Pulo Infinito", "InfJump")
toggle(playerPanel, "NoClip", "NoClip")
section(playerPanel, "VOO")
toggle(playerPanel, "Fly", "Fly")
slider(playerPanel, "Velocidade Voo", "FlySpeed", 30, 200)
section(playerPanel, "PROTEÇÃO")
toggle(playerPanel, "No Fall Damage", "NoFallDamage")
toggle(playerPanel, "Anti AFK", "AntiAFK")

-- CONFIG TAB
section(settingsPanel, "ANTI-DETECÇÃO")
local infoAd = Instance.new("TextLabel")
infoAd.Size = UDim2.new(1,0,0,60)
infoAd.BackgroundColor3 = C.bg3
infoAd.BackgroundTransparency = 0.3
infoAd.BorderSizePixel = 0
infoAd.Text = (AntiDetect.namecall and "  ✓ Hook namecall ativo\n  ✓ GUI protegida (CoreGui)\n  ✓ Bloqueio de Kick remoto\n  ✓ Filtro AntiCheat FireServer"
                                   or "  ⚠ Hook indisponível neste executor\n  ✓ GUI protegida\n  Use Delta Mobile atualizado")
infoAd.TextColor3 = AntiDetect.namecall and C.success or C.danger
infoAd.Font = Enum.Font.GothamMedium
infoAd.TextSize = 11
infoAd.TextXAlignment = Enum.TextXAlignment.Left
infoAd.TextYAlignment = Enum.TextYAlignment.Top
infoAd.Parent = settingsPanel
corner(infoAd,6); pad(infoAd,6)

section(settingsPanel, "INFO")
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,0,0,80)
info.BackgroundColor3 = C.bg3; info.BackgroundTransparency = 0.3
info.BorderSizePixel = 0
info.Text = "  KRONA IMPERIUM v12 OMEGA\n  Blox Fruits · Delta Mobile\n  ESP via BillboardGui (100% mobile)\n\n  Toggle: RightShift / Botão flutuante"
info.TextColor3 = C.text
info.Font = Enum.Font.GothamMedium; info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = settingsPanel
corner(info,6); pad(info,6)

local destroyBtn = Instance.new("TextButton")
destroyBtn.Size = UDim2.new(1,0,0,32)
destroyBtn.BackgroundColor3 = C.danger
destroyBtn.BorderSizePixel = 0
destroyBtn.Text = "  Destruir Script"
destroyBtn.TextColor3 = Color3.fromRGB(255,255,255)
destroyBtn.Font = Enum.Font.GothamBold
destroyBtn.TextSize = 12
destroyBtn.AutoButtonColor = false
destroyBtn.Parent = settingsPanel
corner(destroyBtn,6)
local trashIc = Instance.new("ImageLabel")
trashIc.Size = UDim2.new(0,16,0,16); trashIc.Position = UDim2.new(0,12,0.5,-8)
trashIc.BackgroundTransparency = 1; trashIc.Image = ICONS.trash
trashIc.ImageColor3 = Color3.fromRGB(255,255,255); trashIc.Parent = destroyBtn

tabs["ESP"].activate()

-- ========== FLOATING BUTTONS (mobile) ==========
local function makeFloat(iconAsset, posY, color, size)
    local b = Instance.new("ImageButton")
    b.Size = UDim2.new(0, size or 46, 0, size or 46)
    b.Position = UDim2.new(0, 12, 0.5, posY)
    b.BackgroundColor3 = color or C.accent
    b.BorderSizePixel = 0
    b.Image = iconAsset
    b.ImageColor3 = Color3.fromRGB(255,255,255)
    b.AutoButtonColor = false
    b.Active = true
    b.Draggable = true
    b.Parent = ScreenGui
    corner(b, (size or 46)/2)
    stroke(b, Color3.fromRGB(255,255,255), 2)
    pad(b, 10)
    return b
end

local FloatBtn = makeFloat(ICONS.crown, -22, C.accent, 48)
if LOGO_URL ~= "" then
    FloatBtn.Image = LOGO_URL
    FloatBtn.ImageColor3 = Color3.fromRGB(255,255,255)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(15,15,22)
    -- também aplica no ícone do topo do menu
    LogoIcon.Image = LOGO_URL
    LogoIcon.ImageColor3 = Color3.fromRGB(255,255,255)
end
local AimFloat = makeFloat(ICONS.crosshair, 38, C.danger, 44)
AimFloat.Visible = CFG.AimbotMobileBtn

local function toggleMain() Main.Visible = not Main.Visible end
FloatBtn.MouseButton1Click:Connect(toggleMain)
MinBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then toggleMain() end
end)

-- ========== ESP SYSTEM (BillboardGui — funciona 100% no Delta Mobile) ==========
local espCache = {}

local function clearEsp(plr)
    local d = espCache[plr]
    if not d then return end
    if d.bb then pcall(function() d.bb:Destroy() end) end
    if d.cham then pcall(function() d.cham:Destroy() end) end
    if d.tracer then pcall(function() d.tracer:Remove() end) end
    espCache[plr] = nil
end
local function clearAllEsp()
    for plr,_ in pairs(espCache) do clearEsp(plr) end
    espCache = {}
end

local function createEsp(plr)
    if espCache[plr] then return espCache[plr] end
    local d = {}

    local bb = Instance.new("BillboardGui")
    bb.Name = "KronaEsp_"..plr.Name
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 140, 0, 80)
    bb.StudsOffset = Vector3.new(0, 1.5, 0)
    bb.LightInfluence = 0
    bb.Parent = EspContainer

    -- Box (frame com borda)
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.Size = UDim2.new(0, 70, 0, 90)
    box.Position = UDim2.new(0.5, -35, 0.5, -25)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = bb
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = C.accent
    boxStroke.Thickness = 1.5
    boxStroke.Parent = box
    -- Cantos do box
    local function cornerLine(parent, anchor, sx, sy)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = C.accent
        f.BorderSizePixel = 0
        f.Size = UDim2.new(0, sx, 0, sy)
        f.AnchorPoint = anchor
        f.Parent = parent
        return f
    end

    -- Nome
    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.new(1, 0, 0, 14)
    name.Position = UDim2.new(0, 0, 0, 0)
    name.BackgroundTransparency = 1
    name.Text = plr.Name
    name.TextColor3 = Color3.fromRGB(255,255,255)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextStrokeTransparency = 0
    name.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    name.Parent = bb

    -- Info (Lv + Fruta)
    local info = Instance.new("TextLabel")
    info.Name = "Info"
    info.Size = UDim2.new(1, 0, 0, 12)
    info.Position = UDim2.new(0, 0, 0, 14)
    info.BackgroundTransparency = 1
    info.Text = ""
    info.TextColor3 = Color3.fromRGB(180,180,255)
    info.Font = Enum.Font.GothamMedium
    info.TextSize = 11
    info.TextStrokeTransparency = 0
    info.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    info.Parent = bb

    -- Distância
    local dist = Instance.new("TextLabel")
    dist.Name = "Dist"
    dist.Size = UDim2.new(1, 0, 0, 12)
    dist.Position = UDim2.new(0, 0, 1, -12)
    dist.BackgroundTransparency = 1
    dist.Text = ""
    dist.TextColor3 = Color3.fromRGB(200,200,200)
    dist.Font = Enum.Font.GothamMedium
    dist.TextSize = 11
    dist.TextStrokeTransparency = 0
    dist.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    dist.Parent = bb

    -- HP bar (dentro do bb, lateral esquerda do box)
    local hpBg = Instance.new("Frame")
    hpBg.Name = "HpBg"
    hpBg.Size = UDim2.new(0, 4, 0, 90)
    hpBg.Position = UDim2.new(0.5, -42, 0.5, -25)
    hpBg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    hpBg.BackgroundTransparency = 0.4
    hpBg.BorderSizePixel = 0
    hpBg.Parent = bb
    corner(hpBg, 2)
    local hp = Instance.new("Frame")
    hp.Name = "Hp"
    hp.Size = UDim2.new(1, 0, 1, 0)
    hp.BackgroundColor3 = C.success
    hp.BorderSizePixel = 0
    hp.AnchorPoint = Vector2.new(0,1)
    hp.Position = UDim2.new(0,0,1,0)
    hp.Parent = hpBg
    corner(hp, 2)

    -- Chams
    local cham = Instance.new("Highlight")
    cham.FillColor = C.accent
    cham.OutlineColor = Color3.fromRGB(255,255,255)
    cham.FillTransparency = 0.7
    cham.OutlineTransparency = 0
    cham.Enabled = false
    cham.Parent = EspContainer

    -- Tracer (Drawing fallback se disponível)
    local tracer = nil
    if Drawing and Drawing.new then
        local ok, t = pcall(function()
            local l = Drawing.new("Line")
            l.Thickness = 1.2
            l.Color = Color3.fromRGB(120,90,255)
            l.Visible = false
            return l
        end)
        if ok then tracer = t end
    end

    d.bb = bb; d.box = box; d.boxStroke = boxStroke
    d.name = name; d.info = info; d.dist = dist
    d.hp = hp; d.hpBg = hpBg; d.cham = cham; d.tracer = tracer
    espCache[plr] = d
    return d
end

local function hideEsp(d)
    if d.bb then d.bb.Enabled = false end
    if d.cham then d.cham.Enabled = false end
    if d.tracer then pcall(function() d.tracer.Visible = false end) end
end

local function updateEsp()
    if not CFG.EspEnabled then
        for _, d in pairs(espCache) do hideEsp(d) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        repeat
            if plr == LP then break end
            if isSameTeam(plr) then if espCache[plr] then hideEsp(espCache[plr]) end; break end
            if not isAlive(plr) then if espCache[plr] then hideEsp(espCache[plr]) end; break end
            local char, hrp, hum = getCharacter(plr)
            if not hrp then if espCache[plr] then hideEsp(espCache[plr]) end; break end
            local d = distFromMe(hrp.Position)
            if d > CFG.EspMaxDistance then if espCache[plr] then hideEsp(espCache[plr]) end; break end

        local data = createEsp(plr)
        local head = char:FindFirstChild("Head") or hrp
        data.bb.Adornee = head
        data.bb.Enabled = true

        -- Cor por HP
        local hpPct = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
        local col = Color3.fromRGB(math.floor(255*(1-hpPct)+80*hpPct), math.floor(80*(1-hpPct)+220*hpPct), 90)

        -- Box
        data.boxStroke.Enabled = CFG.EspBox
        data.boxStroke.Color = CFG.EspBox and C.accent or col

        -- Nome
        data.name.Visible = CFG.EspName

        -- Info (level + fruta)
        if CFG.EspFruit or CFG.EspLevel then
            local parts = {}
            if CFG.EspLevel then local lv = getLevel(plr); if lv then table.insert(parts,"Lv."..lv) end end
            if CFG.EspFruit then local fr = getEquippedFruit(plr); if fr then table.insert(parts,fr) end end
            data.info.Text = table.concat(parts," | ")
            data.info.Visible = #parts > 0
        else data.info.Visible = false end

        -- Distância
        if CFG.EspDistance then
            data.dist.Text = string.format("[%dm]", math.floor(d))
            data.dist.Visible = true
        else data.dist.Visible = false end

        -- HP
        if CFG.EspHealth then
            data.hpBg.Visible = true
            data.hp.Visible = true
            data.hp.Size = UDim2.new(1, 0, hpPct, 0)
            data.hp.BackgroundColor3 = col
        else
            data.hpBg.Visible = false; data.hp.Visible = false
        end

        -- Chams
        if CFG.EspChams then
            data.cham.Adornee = char
            data.cham.FillColor = col
            data.cham.Enabled = true
        else data.cham.Enabled = false end

        -- Tracer (Drawing)
        if CFG.EspTracer and data.tracer then
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            if vis then
                pcall(function()
                    data.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    data.tracer.To = Vector2.new(pos.X, pos.Y)
                    data.tracer.Color = col
                    data.tracer.Visible = true
                end)
            else pcall(function() data.tracer.Visible = false end) end
        elseif data.tracer then pcall(function() data.tracer.Visible = false end) end
        until true
    end
end

Players.PlayerRemoving:Connect(clearEsp)

-- Recriar ESP quando personagem respawnar
local function hookCharacter(plr)
    if plr == LP then return end
    plr.CharacterAdded:Connect(function()
        clearEsp(plr)
        task.wait(0.5)
    end)
end
for _, plr in ipairs(Players:GetPlayers()) do hookCharacter(plr) end
Players.PlayerAdded:Connect(hookCharacter)

-- ========== AIMBOT ==========
local aimbotActive = false

-- PC: hold Q
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Q and CFG.AimbotEnabled then aimbotActive = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Q then aimbotActive = false end
end)

-- Mobile: botão flutuante (suporta TOGGLE on/off ou HOLD para mirar)
local function setAimFloatVisual(active)
    pcall(function()
        AimFloat.BackgroundColor3 = active and C.on or C.danger
    end)
end

local function aimToggle()
    if not CFG.AimbotEnabled then
        -- mesmo sem o master, ativa pra facilitar uso pelo botão externo
        CFG.AimbotEnabled = true
    end
    aimbotActive = not aimbotActive
    setAimFloatVisual(aimbotActive)
end

AimFloat.MouseButton1Click:Connect(function()
    if CFG.AimToggleMode then
        aimToggle()
    end
end)
AimFloat.MouseButton1Down:Connect(function()
    if not CFG.AimToggleMode and CFG.AimbotEnabled then
        aimbotActive = true; setAimFloatVisual(true)
    end
end)
AimFloat.MouseButton1Up:Connect(function()
    if not CFG.AimToggleMode then
        aimbotActive = false; setAimFloatVisual(false)
    end
end)
AimFloat.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch and not CFG.AimToggleMode and CFG.AimbotEnabled then
        aimbotActive = true; setAimFloatVisual(true)
    end
end)
AimFloat.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch and not CFG.AimToggleMode then
        aimbotActive = false; setAimFloatVisual(false)
    end
end)

local StickyTarget = nil -- Player atualmente travado no modo Sticky

local function getTargetPart(plr)
    local char = plr.Character
    return char and (char:FindFirstChild(CFG.AimbotPart) or char:FindFirstChild("HumanoidRootPart"))
end

local function pickTargetByMode()
    local mode = CFG.AimMode or "Closest"

    -- Modo Locked: usa player travado pela lista
    if mode == "Locked" and CFG.AimLockedName and CFG.AimLockedName ~= "" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Name == CFG.AimLockedName and isAlive(plr) then
                return plr
            end
        end
        return nil
    end

    -- Modo Specific: procura player pelo nome digitado
    if mode == "Specific" and CFG.AimTargetName and CFG.AimTargetName ~= "" then
        local query = CFG.AimTargetName:lower()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isAlive(plr) then
                local n = (plr.Name .. " " .. (plr.DisplayName or "")):lower()
                if n:find(query) then return plr end
            end
        end
        return nil
    end

    -- Modo All: primeiro vivo (com filtro de time)
    if mode == "All" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and isAlive(plr) then
                if not (CFG.AimbotTeamCheck and isSameTeam(plr)) then
                    return plr
                end
            end
        end
        return nil
    end

    -- Modo Mouse: mais próximo do cursor/centro dentro do FOV
    -- Modo Closest: mais próximo em distância 3D
    local best, bestVal
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local _, myHrp = getCharacter(LP)
    for _, plr in ipairs(Players:GetPlayers()) do
        repeat
            if plr == LP then break end
            if CFG.AimbotTeamCheck and isSameTeam(plr) then break end
            if not isAlive(plr) then break end
            local part = getTargetPart(plr)
            if not part then break end
            if mode == "Mouse" then
                local pos, vis = Camera:WorldToViewportPoint(part.Position)
                if not vis then break end
                local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if d <= CFG.AimbotFOV and (not bestVal or d < bestVal) then
                    bestVal = d; best = plr
                end
            else -- Closest
                if myHrp then
                    local d = (myHrp.Position - part.Position).Magnitude
                    if not bestVal or d < bestVal then bestVal = d; best = plr end
                end
            end
        until true
    end
    return best
end

local function getClosestTarget()
    -- Sticky: mantém o mesmo alvo enquanto vivo
    if CFG.AimSticky and StickyTarget and isAlive(StickyTarget) then
        return getTargetPart(StickyTarget)
    end
    local plr = pickTargetByMode()
    if plr then
        StickyTarget = plr
        return getTargetPart(plr)
    end
    StickyTarget = nil
    return nil
end

-- ========== KILL AURA / SPAM M1 ==========
local lastM1 = 0
local function fireM1()
    pcall(function()
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        if VIM then
            VIM:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
            task.wait(0.04)
            VIM:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
        else
            VirtualUser:Button1Down(center)
            task.wait(0.04)
            VirtualUser:Button1Up(center)
        end
    end)
end

local function pressKey(key)
    pcall(function()
        if VIM then
            VIM:SendKeyEvent(true, key, false, game)
            task.wait(0.04)
            VIM:SendKeyEvent(false, key, false, game)
        end
    end)
end

-- ========== BADGES ==========
local StunBadge = Instance.new("TextLabel")
StunBadge.Size = UDim2.new(0,140,0,28); StunBadge.Position = UDim2.new(0.5,-70,0.15,0)
StunBadge.BackgroundColor3 = C.danger; StunBadge.BorderSizePixel = 0
StunBadge.Text = "⚠ STUN INCOMING"
StunBadge.TextColor3 = Color3.fromRGB(255,255,255)
StunBadge.Font = Enum.Font.GothamBold; StunBadge.TextSize = 12
StunBadge.Visible = false; StunBadge.Parent = ScreenGui
corner(StunBadge,6)

local HpBadge = Instance.new("TextLabel")
HpBadge.Size = UDim2.new(0,110,0,24); HpBadge.Position = UDim2.new(0.5,-55,0.85,0)
HpBadge.BackgroundColor3 = C.danger; HpBadge.BorderSizePixel = 0
HpBadge.Text = "❤ HP BAIXO"
HpBadge.TextColor3 = Color3.fromRGB(255,255,255)
HpBadge.Font = Enum.Font.GothamBold; HpBadge.TextSize = 11
HpBadge.Visible = false; HpBadge.Parent = ScreenGui
corner(HpBadge,6)

-- ========== ANTI AFK ==========
LP.Idled:Connect(function()
    if CFG.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ========== MOVIMENTO ==========
local function applyMovement()
    local _, hrp, hum = getCharacter(LP)
    if not hum then return end
    if CFG.SpeedEnabled then hum.WalkSpeed = CFG.WalkSpeed end
    if CFG.JumpEnabled then
        pcall(function() hum.JumpPower = CFG.JumpPower end)
        pcall(function() hum.UseJumpPower = true end)
    end
    if CFG.NoFallDamage and hrp then
        local v = hrp.Velocity
        if v.Y < -50 then hrp.Velocity = Vector3.new(v.X,-10,v.Z) end
    end
end

UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump then
        local _,_,hum = getCharacter(LP)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if CFG.NoClip then
        pcall(function()
            local c = LP.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end)

-- ========== FLY ==========
local flyBV, flyBG
local flyKeys = {W=false,A=false,S=false,D=false,Space=false,LeftControl=false}
local function startFly()
    local _, hrp = getCharacter(LP)
    if not hrp or flyBV then return end
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(9e9,9e9,9e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9); flyBG.P = 1000; flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
end
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
end
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    local k = i.KeyCode.Name
    if flyKeys[k] ~= nil then flyKeys[k] = true end
end)
UserInputService.InputEnded:Connect(function(i)
    local k = i.KeyCode.Name
    if flyKeys[k] ~= nil then flyKeys[k] = false end
end)

-- ========== HITBOX ==========
RunService.Heartbeat:Connect(function()
    if not CFG.HitboxExpander then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and not (CFG.AimbotTeamCheck and isSameTeam(plr)) then
            local _, hrp = getCharacter(plr)
            if hrp then
                pcall(function()
                    hrp.Size = Vector3.new(CFG.HitboxSize, CFG.HitboxSize, CFG.HitboxSize)
                    hrp.Massless = true
                    -- NÃO mexemos em CanCollide nem Transparency em outros players
                    -- pois Blox Fruits anti-cheat detecta e dá kick.
                end)
            end
        end
    end
end)

-- ========== AUTO COUNTER detect ==========
local function detectIncomingAttack()
    local _, myHrp = getCharacter(LP)
    if not myHrp then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        repeat
            if plr == LP then break end
            local _, hrp = getCharacter(plr)
            if not hrp then break end
            local d = (myHrp.Position - hrp.Position).Magnitude
            if d > 25 then break end
            local toMe = (myHrp.Position - hrp.Position).Unit
            local dot = toMe:Dot(hrp.CFrame.LookVector)
            if dot > 0.85 then return true, plr end
        until true
    end
    return false
end

-- ========== MAIN LOOP ==========
RunService.RenderStepped:Connect(function()
    local ok, err = pcall(function()
        safe(updateEsp)
        safe(applyMovement)

        -- Aimbot mobile button visibility (em modo toggle, sempre visível p/ ativar de fora do menu)
        AimFloat.Visible = CFG.AimbotMobileBtn and (CFG.AimbotEnabled or CFG.AimToggleMode)

        -- Fly (mobile-friendly: voa pra onde a câmera olha quando ativo)
        if CFG.Fly then
            if not flyBV then startFly() end
            local _, hrp = getCharacter(LP)
            if hrp and flyBV and flyBG then
                local cf = Camera.CFrame
                local dir = Vector3.zero
                -- Suporte PC (WASD)
                if flyKeys.W then dir = dir + cf.LookVector end
                if flyKeys.S then dir = dir - cf.LookVector end
                if flyKeys.A then dir = dir - cf.RightVector end
                if flyKeys.D then dir = dir + cf.RightVector end
                if flyKeys.Space then dir = dir + Vector3.new(0,1,0) end
                if flyKeys.LeftControl then dir = dir - Vector3.new(0,1,0) end
                -- Mobile: se nenhuma tecla pressionada, segue a câmera (look forward)
                if dir.Magnitude < 0.1 and UserInputService.TouchEnabled then
                    dir = cf.LookVector
                end
                flyBV.Velocity = dir * CFG.FlySpeed
                flyBG.CFrame = cf
            end
        else
            if flyBV then stopFly() end
        end

        -- Aimbot
        if CFG.AimbotEnabled and aimbotActive then
            if CFG.AimLockedName ~= "" and CFG.AimMode ~= "Locked" then
                CFG.AimMode = "Locked"
            end
            local target = getClosestTarget()
            if target then
                pcall(function()
                    local predicted = target.Position + target.Velocity * CFG.AimbotPrediction
                    local cur = Camera.CFrame
                    local goal = CFrame.new(cur.Position, predicted)
                    local smooth = 1 - math.clamp(CFG.AimbotSmoothness/100, 0.05, 1)
                    local snap = math.clamp((CFG.AimSnap or 0)/100, 0, 1)
                    local finalAlpha = math.clamp(smooth + snap*(1-smooth), 0.05, 1)
                    Camera.CFrame = cur:Lerp(goal, finalAlpha)
                end)
            end
        else
            if not aimbotActive then StickyTarget = nil end
        end

        -- Kill Aura / Spam M1
        if CFG.KillAura or CFG.SpamM1 then
            local now = tick()
            if now - lastM1 > 0.25 then
                local _, myHrp = getCharacter(LP)
                local doIt = CFG.SpamM1
                if CFG.KillAura and myHrp then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        repeat
                            if plr == LP then break end
                            if CFG.AimbotTeamCheck and isSameTeam(plr) then break end
                            local _, hrp = getCharacter(plr)
                            if hrp and (myHrp.Position - hrp.Position).Magnitude < CFG.KillAuraRange then
                                doIt = true
                            end
                        until true
                        if doIt then break end
                    end
                end
                if doIt then lastM1 = now; safe(fireM1) end
            end
        end

        -- Auto Counter / Anti-Stun / Auto Dodge
        if CFG.AutoCounter or CFG.AntiStun or CFG.AutoDodge then
            local incoming = detectIncomingAttack()
            StunBadge.Visible = CFG.AntiStun and incoming
            if incoming then
                if CFG.AutoCounter then safe(pressKey, Enum.KeyCode.F) end
                if CFG.AutoDodge then
                    local _,_,hum = getCharacter(LP)
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end
        else StunBadge.Visible = false end

        -- Auto Block
        if CFG.AutoBlock and VIM then
            pcall(function()
                local _, myHrp = getCharacter(LP)
                if not myHrp then return end
                local near = false
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP then
                        local _, hrp = getCharacter(plr)
                        if hrp and (myHrp.Position - hrp.Position).Magnitude < 30 then near = true; break end
                    end
                end
                VIM:SendKeyEvent(near, Enum.KeyCode.F, false, game)
            end)
        end

        -- Low HP
        if CFG.LowHpWarning then
            local _,_,hum = getCharacter(LP)
            if hum and hum.MaxHealth > 0 then
                local pct = hum.Health/hum.MaxHealth * 100
                HpBadge.Visible = pct < CFG.LowHpThreshold
            end
        else HpBadge.Visible = false end
    end)
    if not ok then warn("[Krona Loop] "..tostring(err)) end
end)

-- ========== DESTROY ==========
_G.KronaDestroy = function()
    pcall(function() ScreenGui:Destroy() end)
    pcall(function() EspContainer:Destroy() end)
    clearAllEsp()
    stopFly()
    _G.KronaLoaded = false
end
destroyBtn.MouseButton1Click:Connect(_G.KronaDestroy)

-- ========== BANNER ==========
local Banner = Instance.new("TextLabel")
Banner.Size = UDim2.new(0,260,0,36)
Banner.Position = UDim2.new(0.5,-130,0,20)
Banner.BackgroundColor3 = C.accent
Banner.BorderSizePixel = 0
Banner.Text = "KRONA v12.2 OMEGA carregado!"
Banner.TextColor3 = Color3.fromRGB(255,255,255)
Banner.Font = Enum.Font.GothamBold
Banner.TextSize = 12
Banner.Parent = ScreenGui
corner(Banner,8)
TweenService:Create(Banner, TweenInfo.new(2.5, Enum.EasingStyle.Quad), {BackgroundTransparency=1, TextTransparency=1}):Play()
task.delay(3, function() Banner:Destroy() end)

-- ========== DIAGNÓSTICO ==========
pcall(function()
    print("============================================")
    print("[KRONA v12.2] Carregado com sucesso!")
    print("[KRONA] Players no servidor:", #Players:GetPlayers())
    print("[KRONA] Executor:", identifyexecutor and identifyexecutor() or "Desconhecido")
    print("[KRONA] AntiDetect ativo:", AntiDetect.namecall and "SIM" or "NAO")
    print("[KRONA] VirtualInputManager:", VIM and "OK" or "INDISPONIVEL (KillAura/AutoBlock vão usar fallback)")
    print("[KRONA] Mobile (touch):", UserInputService.TouchEnabled and "SIM" or "NAO")
    print("[KRONA] Parent do GUI:", ScreenGui.Parent and ScreenGui.Parent.Name or "NIL")
    print("============================================")
end)
