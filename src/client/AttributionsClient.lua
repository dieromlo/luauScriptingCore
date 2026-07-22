-- ============================================================
--  AttributionsClient.client.lua
--  LocalScript | src/client (StarterPlayerScripts)
-- ============================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

-- Aseguramos que el jugador y su interfaz estén completamente cargados
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end
local playerGui = player:WaitForChild("PlayerGui", 10)

if not playerGui then
    warn("[Attributions] No se pudo encontrar PlayerGui a tiempo.")
    return
end

-- ─── Sistema de Audio UI (Clonado de OutfitClient) ───
local uiSounds = SoundService:FindFirstChild("InfectedMemories_UISounds")
if not uiSounds then
    uiSounds = Instance.new("Folder")
    uiSounds.Name = "InfectedMemories_UISounds"
    uiSounds.Parent = SoundService
end

local function getOrCreateSound(name, id, vol, pitch)
    local s = uiSounds:FindFirstChild(name)
    if not s then
        s = Instance.new("Sound")
        s.Name = name
        s.SoundId = "rbxassetid://" .. id
        s.Volume = vol or 0.5
        s.PlaybackSpeed = pitch or 1
        s.Parent = uiSounds
    end
    return s
end

local sndHover = getOrCreateSound("Hover", "6895079853", 0.5, 1.2)
local sndClick = getOrCreateSound("Click", "6895079853", 0.5, 1.0)

local function playHover()
    if sndHover.IsLoaded then sndHover:Play() end
end

local function playClick()
    if sndClick.IsLoaded then sndClick:Play() end
end

-- ─── Tokens de Diseño ───
local C = {
    bgBase     = Color3.fromRGB(10, 10, 10),
    bgCard     = Color3.fromRGB(22, 22, 22),
    bgBtn      = Color3.fromRGB(32, 32, 32),
    bgBtnHover = Color3.fromRGB(48, 48, 48),
    txtMain    = Color3.fromRGB(255, 255, 255),
    txtSub     = Color3.fromRGB(150, 150, 150),
    border     = Color3.fromRGB(38, 38, 38),
    borderHot  = Color3.fromRGB(255, 255, 255),
    accent     = Color3.fromRGB(255, 255, 255),
}

local F_BOLD   = Enum.Font.GothamBold
local F_NORMAL = Enum.Font.Gotham
local T_FAST   = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local T_MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_MENU   = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ─── Helpers ───
local function uiCorner(p, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 12)
    c.Parent = p
end

local function uiStroke(p, col, px)
    local s = Instance.new("UIStroke")
    s.Color = col or C.border
    s.Thickness = px or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

-- ─── Root GUI ───
local GUI = Instance.new("ScreenGui")
GUI.Name = "CreativeAttributions"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.IgnoreGuiInset = true
GUI.Parent = playerGui

-- ─── Control de Desfoque y Fondo Opaco ───
local blurEffect = Lighting:FindFirstChild("UIBlurEffect") or Instance.new("BlurEffect")
blurEffect.Name = "UIBlurEffect"
blurEffect.Size = 0
blurEffect.Parent = Lighting

local Backdrop = Instance.new("TextButton")
Backdrop.Name                   = "AttributionsBackdrop"
Backdrop.Size                   = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3       = Color3.fromRGB(5, 5, 5)
Backdrop.BackgroundTransparency = 1
Backdrop.Text                   = ""
Backdrop.ZIndex                 = 9
Backdrop.Visible                = false
Backdrop.Parent                 = GUI

-- ─── Botón Flotante "i" (Alineado perfectamente en la esquina inferior) ───
local containerBtn = Instance.new("Frame")
containerBtn.Name = "Slot_Attributions"
containerBtn.Size = UDim2.new(0, 44, 0, 44)
containerBtn.Position = UDim2.new(1, -60, 1, -44) -- Alineado con la base del dock inferior
containerBtn.AnchorPoint = Vector2.new(0, 1)
containerBtn.BackgroundTransparency = 1
containerBtn.Parent = GUI

local triggerBtn = Instance.new("TextButton")
triggerBtn.Size = UDim2.new(1, 0, 1, 0)
triggerBtn.Position = UDim2.new(0.5, 0, 1, 0)
triggerBtn.AnchorPoint = Vector2.new(0.5, 1)
triggerBtn.BackgroundColor3 = C.bgCard
triggerBtn.Text = "i"
triggerBtn.TextColor3 = C.txtSub
triggerBtn.Font = F_NORMAL
triggerBtn.TextSize = 22
triggerBtn.BorderSizePixel = 0
triggerBtn.ZIndex = 10
uiCorner(triggerBtn, 22)
local triggerStroke = uiStroke(triggerBtn, C.border, 1.5)
triggerBtn.Parent = containerBtn

-- ─── Panel Principal ───
local PANEL_W, PANEL_H = 380, 400
local POS_HIDE = UDim2.new(0.5, -PANEL_W/2, 1.5, 0)
local POS_SHOW = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
Panel.Position = POS_HIDE
Panel.BackgroundColor3 = C.bgBase
Panel.BorderSizePixel = 0
Panel.ZIndex = 20
uiCorner(Panel, 16)
uiStroke(Panel, C.border, 1.5)
Panel.Parent = GUI

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 30)
title.Position = UDim2.new(0, 24, 0, 24) -- Movido levemente a la izquierda tras remover sideBar
title.BackgroundTransparency = 1
title.Text = "Atribuciones Creativas"
title.TextColor3 = C.txtMain
title.Font = F_BOLD
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 21
title.Parent = Panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -70, 0, 20)
subtitle.Position = UDim2.new(0, 24, 0, 50) -- Ajustado en concordancia con el título
subtitle.BackgroundTransparency = 1
subtitle.Text = "Créditos de desarrollo y diseño"
subtitle.TextColor3 = C.txtSub
subtitle.Font = F_NORMAL
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 21
subtitle.Parent = Panel

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 30, 0, 30)
btnClose.Position = UDim2.new(1, -46, 0, 24)
btnClose.BackgroundColor3 = C.bgBtn
btnClose.Text = "✕"
btnClose.TextColor3 = C.txtSub
btnClose.Font = F_BOLD
btnClose.TextSize = 12
btnClose.BorderSizePixel = 0
btnClose.ZIndex = 22
uiCorner(btnClose, 8)
btnClose.Parent = Panel

-- ─── Lista Desplegable e Inteligente (Autohide Navigation Bar) ───
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -48, 1, -110)
list.Position = UDim2.new(0, 24, 0, 90)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = C.txtSub
-- Desaparece por completo cuando no se interactúa con ella
list.ScrollBarImageTransparency = 1 
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ZIndex = 21
list.Parent = Panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

-- Muestra u oculta la barra de desplazamiento suavemente al scrollear
list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    TweenService:Create(list, T_FAST, {ScrollBarImageTransparency = 0.3}):Play()
    task.delay(0.8, function()
        if list then TweenService:Create(list, T_FAST, {ScrollBarImageTransparency = 1}):Play() end
    end)
end)

local function addCredit(role, name, iconId)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 48)
    row.BackgroundColor3 = C.bgCard
    row.BorderSizePixel = 0
    uiCorner(row, 10)
    uiStroke(row, C.border, 1)
    row.Parent = list

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 14, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. iconId
    icon.ImageColor3 = C.txtSub
    icon.Parent = row

    local lblRole = Instance.new("TextLabel")
    lblRole.Size = UDim2.new(1, -50, 0, 16)
    lblRole.Position = UDim2.new(0, 44, 0, 8)
    lblRole.BackgroundTransparency = 1
    lblRole.Text = role
    lblRole.TextColor3 = C.txtSub
    lblRole.Font = F_NORMAL
    lblRole.TextSize = 11
    lblRole.TextXAlignment = Enum.TextXAlignment.Left
    lblRole.Parent = row

    local lblName = Instance.new("TextLabel")
    lblName.Size = UDim2.new(1, -50, 0, 18)
    lblName.Position = UDim2.new(0, 44, 0, 24)
    lblName.BackgroundTransparency = 1
    lblName.Text = name
    lblName.TextColor3 = C.txtMain
    lblName.Font = F_BOLD
    lblName.TextSize = 13
    lblName.TextXAlignment = Enum.TextXAlignment.Left
    lblName.Parent = row
end

-- Lista de atribuciones
addCredit("UI/UX Design & Wireframing", "@helafenty", "98202862460239")
addCredit("UI Engineering & Animations", "@helafenty", "136191071460353")
addCredit("Lead Systems Programmer", "@helafenty", "87873470710971")
addCredit("Gameplay & Client Mechanics", "@helafenty", "87873470710971")
addCredit("Level Design & Atmosphere", "@helafenty", "116542655589112")
addCredit("Environment & Lighting Artist", "@helafenty", "116542655589112")
addCredit("Outfit Curation & Asset Management", "@helafenty", "136191071460353")

-- ─── Lógica de Interacción Remasterizada ───
local isOpen = false

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    playClick()
    
    TweenService:Create(triggerBtn, T_FAST, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.bgCard, TextColor3 = C.txtSub}):Play()
    TweenService:Create(triggerStroke, T_FAST, {Color = C.border}):Play()
    TweenService:Create(Panel, T_MENU, {Position = POS_HIDE}):Play()
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 1}):Play()
    TweenService:Create(blurEffect, T_MED, {Size = 0}):Play()
    
    task.delay(0.3, function() Backdrop.Visible = false end)
end

local function openMenu()
    if isOpen then return end
    isOpen = true
    playClick()
    Backdrop.Visible = true
    
    TweenService:Create(triggerBtn, T_FAST, {Size = UDim2.new(1.15, 0, 1.15, 0), BackgroundColor3 = C.bgBtnHover, TextColor3 = C.txtMain}):Play()
    TweenService:Create(Panel, T_MENU, {Position = POS_SHOW}):Play()
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(blurEffect, T_MED, {Size = 16}):Play()
end

local function toggleMenu()
    if isOpen then closeMenu() else openMenu() end
end

-- Animaciones Físicas MouseEnter / MouseLeave de la "i"
triggerBtn.MouseEnter:Connect(function()
    playHover()
    triggerBtn.ZIndex = 15
    TweenService:Create(triggerBtn, T_FAST, {Size = UDim2.new(1.15, 0, 1.15, 0), BackgroundColor3 = C.bgBtnHover}):Play()
    TweenService:Create(triggerStroke, T_FAST, {Color = C.borderHot}):Play()
    TweenService:Create(triggerBtn, T_FAST, {TextColor3 = C.txtMain}):Play()
end)

triggerBtn.MouseLeave:Connect(function()
    if not isOpen then
        triggerBtn.ZIndex = 10
        TweenService:Create(triggerBtn, T_FAST, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.bgCard}):Play()
        TweenService:Create(triggerStroke, T_FAST, {Color = C.border}):Play()
        TweenService:Create(triggerBtn, T_FAST, {TextColor3 = C.txtSub}):Play()
    end
end)

triggerBtn.MouseButton1Down:Connect(function()
    TweenService:Create(triggerBtn, T_FAST, {Size = UDim2.new(0.95, 0, 0.95, 0)}):Play()
end)

triggerBtn.MouseButton1Up:Connect(function()
    if isOpen then
        TweenService:Create(triggerBtn, T_FAST, {Size = UDim2.new(1, 0, 1, 0)}):Play()
    else
        TweenService:Create(triggerBtn, T_FAST, {Size = UDim2.new(1.15, 0, 1.15, 0)}):Play()
    end
end)

-- Triggers
triggerBtn.MouseButton1Click:Connect(toggleMenu)
btnClose.MouseButton1Click:Connect(closeMenu)
Backdrop.MouseButton1Click:Connect(closeMenu)

print("[Attributions] UI cargada y sincronizada exitosamente con OutfitClient.")