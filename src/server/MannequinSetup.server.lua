-- ============================================================
--  OutfitClient.client.lua
--  LocalScript | StarterPlayerScripts
--  UI completa: HUD + Outfit Panel + Settings
--  Estética: dark / cyberpunk / infected memories
-- ============================================================

--> SERVICIOS
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

--> REMOTE EVENTS
local remoteFolder = ReplicatedStorage
    :WaitForChild("OutfitSystem")
    :WaitForChild("RemoteEvents")

local TryOnOutfit = remoteFolder:WaitForChild("TryOnOutfit")
local ResetAvatar = remoteFolder:WaitForChild("ResetAvatar")
local BuyOutfit   = remoteFolder:WaitForChild("BuyOutfit", 10)

if not BuyOutfit then
    warn("[OutfitClient] ❌ BuyOutfit no encontrado. ¿Actualizaste RemoteEventInit?")
end

-- ──────────────────────────────────────────────────────────────
--  TOKENS DE DISEÑO
--  Cambia estos valores para ajustar toda la paleta del juego
-- ──────────────────────────────────────────────────────────────
local C = {
    bgBase      = Color3.fromRGB(8,   8,  12),   -- negro base
    bgCard      = Color3.fromRGB(14,  14, 20),   -- tarjetas
    bgBtn       = Color3.fromRGB(24,  24, 34),   -- botones secundarios
    accent      = Color3.fromRGB(196, 22, 42),   -- rojo profundo (marca)
    accentHover = Color3.fromRGB(220, 38, 58),   -- rojo hover
    success     = Color3.fromRGB(40, 185, 90),   -- verde confirmación
    txtMain     = Color3.fromRGB(255, 255, 255),
    txtSub      = Color3.fromRGB(148, 148, 165),
    border      = Color3.fromRGB(36,  36,  50),
}

local F_BOLD   = Enum.Font.GothamBold
local F_NORMAL = Enum.Font.Gotham

local T_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local T_MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ──────────────────────────────────────────────────────────────
--  HELPERS
-- ──────────────────────────────────────────────────────────────
local function uiCorner(parent, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 8)
    c.Parent = parent
end

local function uiStroke(parent, color, px)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.border
    s.Thickness = px or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
end

-- Flash de color al presionar un botón (feedback táctil)
local function clickFlash(btn, flashCol, restoreCol)
    TweenService:Create(btn, T_FAST, {BackgroundColor3 = flashCol}):Play()
    task.delay(0.35, function()
        if btn and btn.Parent then
            TweenService:Create(btn, T_MED, {BackgroundColor3 = restoreCol}):Play()
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
--  ROOT SCREENGUI
-- ──────────────────────────────────────────────────────────────
local GUI = Instance.new("ScreenGui")
GUI.Name           = "InfectedMemoriesUI"
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent         = playerGui

-- ══════════════════════════════════════════════════════════════
--  [1] BACKDROP — overlay oscuro detrás del panel
--      TextButton para poder capturar clicks y cerrar el panel
-- ══════════════════════════════════════════════════════════════
local Backdrop = Instance.new("TextButton")
Backdrop.Name                 = "Backdrop"
Backdrop.Size                 = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3     = Color3.new(0, 0, 0)
Backdrop.BackgroundTransparency = 1   -- empieza invisible
Backdrop.Text                 = ""
Backdrop.ZIndex               = 9
Backdrop.Visible              = false
Backdrop.Parent               = GUI

-- ══════════════════════════════════════════════════════════════
--  [2] HUD — botones laterales fijos
--      ZIndex 30 → siempre encima de backdrop y paneles
-- ══════════════════════════════════════════════════════════════
local HUD = Instance.new("Frame")
HUD.Name                   = "HUD"
HUD.Size                   = UDim2.new(0, 48, 0, 172)
HUD.Position               = UDim2.new(0, 16, 0.5, -86)
HUD.BackgroundTransparency = 1
HUD.ZIndex                 = 30
HUD.Parent                 = GUI

local hudLayout = Instance.new("UIListLayout")
hudLayout.FillDirection = Enum.FillDirection.Vertical
hudLayout.SortOrder     = Enum.SortOrder.LayoutOrder
hudLayout.Padding       = UDim.new(0, 8)
hudLayout.Parent        = HUD

-- Fábrica de botón HUD (solo hover de color, sin size tween por UIListLayout)
local function makeHudBtn(icon, order)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 48, 0, 48)
    btn.BackgroundColor3 = C.bgCard
    btn.Text             = icon
    btn.TextColor3       = C.txtMain
    btn.TextSize         = 20
    btn.Font             = F_NORMAL
    btn.LayoutOrder      = order
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 31
    btn.Parent           = HUD
    uiCorner(btn, 12)
    uiStroke(btn, C.border)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, T_FAST, {BackgroundColor3 = C.bgBtn}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, T_FAST, {BackgroundColor3 = C.bgCard}):Play()
    end)
    return btn
end

local btnReset    = makeHudBtn("↺", 1)
local btnSprint   = makeHudBtn("▶", 2)
local btnSettings = makeHudBtn("⚙", 3)

-- ─── SPRINT ────────────────────────────────────────────────────
local isSprinting  = false
local SPD_WALK     = 16
local SPD_SPRINT   = 30

local function applySprint(active)
    isSprinting = active
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = active and SPD_SPRINT or SPD_WALK end
    end
    -- El botón se ilumina en rojo cuando está activo
    TweenService:Create(btnSprint, T_FAST, {
        BackgroundColor3 = active and C.accent or C.bgCard,
    }):Play()
end

btnSprint.MouseButton1Click:Connect(function() applySprint(not isSprinting) end)

-- Shift como atajo de teclado para sprint
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then applySprint(true) end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then applySprint(false) end
end)

-- Resetear velocidad al respawnear
player.CharacterAdded:Connect(function() applySprint(false) end)

-- ─── RESET ─────────────────────────────────────────────────────
btnReset.MouseButton1Click:Connect(function()
    ResetAvatar:FireServer()
    clickFlash(btnReset, C.accent, C.bgCard)
end)

-- ══════════════════════════════════════════════════════════════
--  [3] OUTFIT PANEL — se abre al presionar E en un maniquí
-- ══════════════════════════════════════════════════════════════
local PW, PH   = 500, 415
local POS_HIDE = UDim2.new(0.5, -PW/2, 1.25, 0)
local POS_SHOW = UDim2.new(0.5, -PW/2, 0.5, -PH/2)

local Panel = Instance.new("Frame")
Panel.Name             = "OutfitPanel"
Panel.Size             = UDim2.new(0, PW, 0, PH)
Panel.Position         = POS_HIDE
Panel.BackgroundColor3 = C.bgBase
Panel.BorderSizePixel  = 0
Panel.ZIndex           = 10
uiCorner(Panel, 16)
uiStroke(Panel, C.accent, 1.5)
Panel.Parent = GUI

-- Barra roja de acento (arriba del panel)
local topBar = Instance.new("Frame")
topBar.Size             = UDim2.new(1, 0, 0, 3)
topBar.BackgroundColor3 = C.accent
topBar.BorderSizePixel  = 0
topBar.ZIndex           = 11
uiCorner(topBar, 2)
topBar.Parent = Panel

-- Nombre del outfit
local lblName = Instance.new("TextLabel")
lblName.Size             = UDim2.new(1, -80, 0, 38)
lblName.Position         = UDim2.new(0, 20, 0, 14)
lblName.BackgroundTransparency = 1
lblName.TextColor3       = C.txtMain
lblName.TextSize         = 22
lblName.Font             = F_BOLD
lblName.TextXAlignment   = Enum.TextXAlignment.Left
lblName.TextTruncate     = Enum.TextTruncate.AtEnd
lblName.Text             = "—"
lblName.ZIndex           = 11
lblName.Parent           = Panel

-- Descripción
local lblDesc = Instance.new("TextLabel")
lblDesc.Size             = UDim2.new(1, -80, 0, 26)
lblDesc.Position         = UDim2.new(0, 20, 0, 54)
lblDesc.BackgroundTransparency = 1
lblDesc.TextColor3       = C.txtSub
lblDesc.TextSize         = 12
lblDesc.Font             = F_NORMAL
lblDesc.TextXAlignment   = Enum.TextXAlignment.Left
lblDesc.TextWrapped      = true
lblDesc.Text             = ""
lblDesc.ZIndex           = 11
lblDesc.Parent           = Panel

-- Divisor horizontal
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -40, 0, 1)
divider.Position         = UDim2.new(0, 20, 0, 88)
divider.BackgroundColor3 = C.border
divider.BorderSizePixel  = 0
divider.ZIndex           = 11
divider.Parent           = Panel

-- Etiqueta de sección
local secLabel = Instance.new("TextLabel")
secLabel.Size             = UDim2.new(1, -40, 0, 18)
secLabel.Position         = UDim2.new(0, 20, 0, 98)
secLabel.BackgroundTransparency = 1
secLabel.TextColor3       = C.accent
secLabel.TextSize         = 10
secLabel.Font             = F_BOLD
secLabel.TextXAlignment   = Enum.TextXAlignment.Left
secLabel.Text             = "ITEMS DEL LOOK"
secLabel.ZIndex           = 11
secLabel.Parent           = Panel

-- ─── TARJETAS DE ÍTEM ──────────────────────────────────────────
-- Construye una tarjeta con imagen thumbnail y etiqueta de tipo
local function makeItemCard(xOffset, typeText)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0, 148, 0, 178)
    card.Position         = UDim2.new(0, xOffset, 0, 124)
    card.BackgroundColor3 = C.bgCard
    card.BorderSizePixel  = 0
    card.ZIndex           = 11
    uiCorner(card, 10)
    uiStroke(card, C.border)
    card.Parent = Panel

    -- Imagen miniatura del ítem
    local img = Instance.new("ImageLabel")
    img.Size             = UDim2.new(1, -16, 0, 118)
    img.Position         = UDim2.new(0, 8, 0, 8)
    img.BackgroundColor3 = C.bgBase
    img.Image            = ""
    img.ScaleType        = Enum.ScaleType.Fit
    img.ZIndex           = 12
    uiCorner(img, 6)
    img.Parent = card

    -- Etiqueta de tipo (CAMISA / PANTALÓN)
    local lType = Instance.new("TextLabel")
    lType.Size            = UDim2.new(1, -8, 0, 16)
    lType.Position        = UDim2.new(0, 4, 0, 130)
    lType.BackgroundTransparency = 1
    lType.TextColor3      = C.accent
    lType.TextSize        = 9
    lType.Font            = F_BOLD
    lType.Text            = typeText
    lType.ZIndex          = 12
    lType.Parent          = card

    -- Asset ID (info secundaria)
    local lId = Instance.new("TextLabel")
    lId.Size            = UDim2.new(1, -8, 0, 22)
    lId.Position        = UDim2.new(0, 4, 0, 148)
    lId.BackgroundTransparency = 1
    lId.TextColor3      = C.txtSub
    lId.TextSize        = 10
    lId.Font            = F_NORMAL
    lId.TextWrapped     = true
    lId.Text            = "—"
    lId.ZIndex          = 12
    lId.Parent          = card

    return img, lId
end

local shirtImg, shirtIdLbl = makeItemCard(20,  "CAMISA")
local pantsImg, pantsIdLbl = makeItemCard(182, "PANTALÓN")

-- ─── BOTÓN CERRAR ──────────────────────────────────────────────
local btnClose = Instance.new("TextButton")
btnClose.Size             = UDim2.new(0, 32, 0, 32)
btnClose.Position         = UDim2.new(1, -44, 0, 12)
btnClose.BackgroundColor3 = C.bgBtn
btnClose.Text             = "✕"
btnClose.TextColor3       = C.txtSub
btnClose.TextSize         = 13
btnClose.Font             = F_BOLD
btnClose.ZIndex           = 12
btnClose.BorderSizePixel  = 0
uiCorner(btnClose, 8)
btnClose.Parent = Panel
btnClose.MouseEnter:Connect(function()
    TweenService:Create(btnClose, T_FAST,
        {BackgroundColor3 = C.accent, TextColor3 = C.txtMain}):Play()
end)
btnClose.MouseLeave:Connect(function()
    TweenService:Create(btnClose, T_FAST,
        {BackgroundColor3 = C.bgBtn, TextColor3 = C.txtSub}):Play()
end)

-- ─── BOTÓN VESTIR ──────────────────────────────────────────────
local btnTryOn = Instance.new("TextButton")
btnTryOn.Size             = UDim2.new(0, 168, 0, 44)
btnTryOn.Position         = UDim2.new(0, 20, 1, -60)
btnTryOn.BackgroundColor3 = C.accent
btnTryOn.Text             = "VESTIR"
btnTryOn.TextColor3       = C.txtMain
btnTryOn.TextSize         = 14
btnTryOn.Font             = F_BOLD
btnTryOn.ZIndex           = 12
btnTryOn.BorderSizePixel  = 0
uiCorner(btnTryOn, 10)
btnTryOn.Parent = Panel
btnTryOn.MouseEnter:Connect(function()
    TweenService:Create(btnTryOn, T_FAST, {BackgroundColor3 = C.accentHover}):Play()
end)
btnTryOn.MouseLeave:Connect(function()
    TweenService:Create(btnTryOn, T_FAST, {BackgroundColor3 = C.accent}):Play()
end)

-- ─── BOTÓN COMPRAR ─────────────────────────────────────────────
local btnBuy = Instance.new("TextButton")
btnBuy.Size             = UDim2.new(0, 168, 0, 44)
btnBuy.Position         = UDim2.new(0, 200, 1, -60)
btnBuy.BackgroundColor3 = C.bgBtn
btnBuy.Text             = "COMPRAR"
btnBuy.TextColor3       = C.txtMain
btnBuy.TextSize         = 14
btnBuy.Font             = F_BOLD
btnBuy.ZIndex           = 12
btnBuy.BorderSizePixel  = 0
uiCorner(btnBuy, 10)
uiStroke(btnBuy, C.border)
btnBuy.Parent = Panel
btnBuy.MouseEnter:Connect(function()
    TweenService:Create(btnBuy, T_FAST,
        {BackgroundColor3 = Color3.fromRGB(34, 34, 48)}):Play()
end)
btnBuy.MouseLeave:Connect(function()
    TweenService:Create(btnBuy, T_FAST, {BackgroundColor3 = C.bgBtn}):Play()
end)

-- ─── LÓGICA DEL PANEL ──────────────────────────────────────────
local panelOpen    = false
local activeOutfit = nil  -- datos del outfit actual

local function openPanel(data)
    if panelOpen then return end
    panelOpen    = true
    activeOutfit = data

    -- Llenar datos en la UI
    lblName.Text = data.name        or "—"
    lblDesc.Text = data.description or ""

    local sid = data.shirt or 0
    local pid = data.pants or 0

    -- rbxthumb genera automáticamente la imagen del ítem por su ID
    shirtImg.Image   = sid ~= 0
        and ("rbxthumb://type=Asset&id=" .. sid .. "&w=150&h=150") or ""
    shirtIdLbl.Text  = sid ~= 0 and ("ID: " .. sid) or "—"

    pantsImg.Image   = pid ~= 0
        and ("rbxthumb://type=Asset&id=" .. pid .. "&w=150&h=150") or ""
    pantsIdLbl.Text  = pid ~= 0 and ("ID: " .. pid) or "—"

    -- Mostrar backdrop + animar panel hacia arriba
    Backdrop.Visible = true
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(Panel,    T_MED, {Position = POS_SHOW}):Play()
end

local function closePanel()
    if not panelOpen then return end
    panelOpen    = false
    activeOutfit = nil

    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 1}):Play()
    TweenService:Create(Panel,    T_MED, {Position = POS_HIDE}):Play()
    -- Ocultar backdrop después de la animación
    task.delay(0.35, function() Backdrop.Visible = false end)
end

-- Formas de cerrar el panel
Backdrop.MouseButton1Click:Connect(closePanel)
btnClose.MouseButton1Click:Connect(closePanel)
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Escape then closePanel() end
end)

-- VESTIR: aplica ropa en el personaje del jugador
btnTryOn.MouseButton1Click:Connect(function()
    if not activeOutfit then return end
    TryOnOutfit:FireServer(activeOutfit.id)
    -- Feedback visual de confirmación
    local originalText = btnTryOn.Text
    btnTryOn.Text = "✓ EQUIPADO"
    TweenService:Create(btnTryOn, T_FAST, {BackgroundColor3 = C.success}):Play()
    task.delay(2, function()
        if btnTryOn and btnTryOn.Parent then
            btnTryOn.Text = originalText
            TweenService:Create(btnTryOn, T_MED, {BackgroundColor3 = C.accent}):Play()
        end
    end)
end)

-- COMPRAR: el servidor abre el diálogo oficial de Roblox
-- Se abren dos prompts separados: uno por camisa, otro por pantalón
btnBuy.MouseButton1Click:Connect(function()
    if not activeOutfit or not BuyOutfit then return end
    local sid = activeOutfit.shirt or 0
    local pid = activeOutfit.pants or 0
    if sid ~= 0 then BuyOutfit:FireServer(sid) end
    if pid ~= 0 then
        task.delay(0.6, function()
            if BuyOutfit then BuyOutfit:FireServer(pid) end
        end)
    end
    clickFlash(btnBuy, C.success, C.bgBtn)
end)

-- ══════════════════════════════════════════════════════════════
--  [4] SETTINGS PANEL — desliza desde la izquierda
-- ══════════════════════════════════════════════════════════════
local SW, SH    = 292, 224
local SET_HIDE  = UDim2.new(-0.35, 0, 0.5, -SH/2)
local SET_SHOW  = UDim2.new(0, 76,  0.5, -SH/2)

local SetPanel = Instance.new("Frame")
SetPanel.Name             = "SettingsPanel"
SetPanel.Size             = UDim2.new(0, SW, 0, SH)
SetPanel.Position         = SET_HIDE
SetPanel.BackgroundColor3 = C.bgBase
SetPanel.BorderSizePixel  = 0
SetPanel.ZIndex           = 20
uiCorner(SetPanel, 16)
uiStroke(SetPanel, C.border)
SetPanel.Parent = GUI

-- Barra roja settings
local setBar = Instance.new("Frame")
setBar.Size             = UDim2.new(1, 0, 0, 3)
setBar.BackgroundColor3 = C.accent
setBar.BorderSizePixel  = 0
setBar.ZIndex           = 21
uiCorner(setBar, 2)
setBar.Parent = SetPanel

-- Título settings
local setTitle = Instance.new("TextLabel")
setTitle.Size             = UDim2.new(1, -50, 0, 48)
setTitle.Position         = UDim2.new(0, 18, 0, 0)
setTitle.BackgroundTransparency = 1
setTitle.TextColor3       = C.txtMain
setTitle.TextSize         = 17
setTitle.Font             = F_BOLD
setTitle.TextXAlignment   = Enum.TextXAlignment.Left
setTitle.Text             = "Settings"
setTitle.ZIndex           = 21
setTitle.Parent           = SetPanel

-- Botón cerrar settings
local btnSetClose = Instance.new("TextButton")
btnSetClose.Size             = UDim2.new(0, 28, 0, 28)
btnSetClose.Position         = UDim2.new(1, -38, 0, 10)
btnSetClose.BackgroundColor3 = C.bgBtn
btnSetClose.Text             = "✕"
btnSetClose.TextColor3       = C.txtSub
btnSetClose.TextSize         = 12
btnSetClose.Font             = F_BOLD
btnSetClose.ZIndex           = 21
btnSetClose.BorderSizePixel  = 0
uiCorner(btnSetClose, 7)
btnSetClose.Parent = SetPanel

-- ─── FÁBRICA DE TOGGLES ────────────────────────────────────────
-- Retorna una función getter para leer el estado actual
local function makeToggle(labelText, yPos, startOn, onChanged)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -24, 0, 42)
    row.Position         = UDim2.new(0, 12, 0, yPos)
    row.BackgroundColor3 = C.bgCard
    row.BorderSizePixel  = 0
    row.ZIndex           = 21
    uiCorner(row, 10)
    row.Parent = SetPanel

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(0.65, 0, 1, 0)
    lbl.Position         = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = C.txtMain
    lbl.TextSize         = 12
    lbl.Font             = F_NORMAL
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = labelText
    lbl.ZIndex           = 22
    lbl.Parent           = row

    -- Fondo del toggle
    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(0, 42, 0, 22)
    bg.Position         = UDim2.new(1, -52, 0.5, -11)
    bg.BackgroundColor3 = startOn and C.accent or C.border
    bg.BorderSizePixel  = 0
    bg.ZIndex           = 22
    uiCorner(bg, 11)
    bg.Parent = row

    -- Knob (bolita blanca)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = startOn
        and UDim2.new(1, -19, 0.5, -8)
        or  UDim2.new(0,   3, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 23
    uiCorner(knob, 8)
    knob.Parent = bg

    -- Área clickeable transparente encima del bg
    local hitbox = Instance.new("TextButton")
    hitbox.Size               = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text               = ""
    hitbox.ZIndex             = 24
    hitbox.Parent             = bg

    local state = startOn
    hitbox.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(bg, T_FAST,
            {BackgroundColor3 = state and C.accent or C.border}):Play()
        TweenService:Create(knob, T_FAST, {
            Position = state
                and UDim2.new(1, -19, 0.5, -8)
                or  UDim2.new(0,   3, 0.5, -8)
        }):Play()
        -- Ejecutar callback con el nuevo estado
        if onChanged then task.defer(onChanged, state) end
    end)

    return function() return state end
end

-- Toggle: Ocultar jugadores (hace transparentes sus personajes localmente)
makeToggle("Ocultar jugadores", 50, false, function(active)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = active and 1 or 0
                end
            end
        end
    end
end)

-- Toggle: Efectos de sonido (placeholder para Paso 5)
makeToggle("Efectos de sonido", 100, true, function(_active)
    -- Se implementa en el paso de audio
end)

-- Toggle: Ocultar player tag (placeholder para Paso 5)
makeToggle("Ocultar player tag", 150, false, function(_active)
    -- Se implementa con BillboardGui en el servidor
end)

-- Lógica open/close settings
local settingsOpen = false
btnSettings.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    TweenService:Create(SetPanel, T_MED, {
        Position = settingsOpen and SET_SHOW or SET_HIDE
    }):Play()
end)
btnSetClose.MouseButton1Click:Connect(function()
    settingsOpen = false
    TweenService:Create(SetPanel, T_MED, {Position = SET_HIDE}):Play()
end)

-- ══════════════════════════════════════════════════════════════
--  [5] CONECTAR PROXIMITY PROMPTS DE LOS MANIQUÍES
-- ══════════════════════════════════════════════════════════════
local function connectMannequin(mannequin)
    if not mannequin:IsA("Model") then return end
    local root = mannequin.PrimaryPart or mannequin:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local prompt = root:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return end

    -- Al presionar E, leer atributos del maniquí y abrir panel
    prompt.Triggered:Connect(function()
        openPanel({
            id          = mannequin:GetAttribute("OutfitId"),
            name        = mannequin:GetAttribute("OutfitName"),
            description = mannequin:GetAttribute("OutfitDescription"),
            shirt       = mannequin:GetAttribute("ShirtId"),
            pants       = mannequin:GetAttribute("PantsId"),
        })
    end)
end

task.spawn(function()
    local folder = workspace:WaitForChild("Mannequins", 15)
    if not folder then
        warn("[OutfitClient] ❌ Carpeta 'Mannequins' no encontrada en Workspace.")
        return
    end
    for _, m in ipairs(folder:GetChildren()) do
        connectMannequin(m)
    end
    -- Conectar maniquíes que se añadan dinámicamente
    folder.ChildAdded:Connect(connectMannequin)
    print("[OutfitClient] ✅ UI lista. "
        .. #folder:GetChildren() .. " maniquíes conectados.")
end)