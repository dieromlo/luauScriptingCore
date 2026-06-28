-- ============================================================
--  OutfitClient.client.lua
--  LocalScript | StarterPlayerScripts
--  UI completa: HUD + Outfit Panel + Settings
--  Estética: Infected Memories
-- ============================================================

print("[OutfitClient] 🔵 Script iniciado")

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

local TryOnOutfit = remoteFolder:WaitForChild("TryOnOutfit", 15)
local ResetAvatar = remoteFolder:WaitForChild("ResetAvatar",  15)
local BuyOutfit   = remoteFolder:WaitForChild("BuyOutfit",    15)

if not TryOnOutfit then error("[OutfitClient] ❌ TryOnOutfit no encontrado") end
if not ResetAvatar then error("[OutfitClient] ❌ ResetAvatar no encontrado") end

-- ══════════════════════════════════════════════════════════════
--  TOKENS DE DISEÑO
-- ══════════════════════════════════════════════════════════════
local C = {
    bgBase      = Color3.fromRGB(8,   8,  12),
    bgCard      = Color3.fromRGB(18,  18, 26),
    bgBtn       = Color3.fromRGB(28,  28, 40),
    bgBtnHover  = Color3.fromRGB(38,  38, 54),
    accent      = Color3.fromRGB(196, 22, 42),
    accentHover = Color3.fromRGB(220, 38, 58),
    accentDim   = Color3.fromRGB(80,  10, 18),
    success     = Color3.fromRGB(40,  185, 90),
    txtMain     = Color3.fromRGB(255, 255, 255),
    txtSub      = Color3.fromRGB(140, 140, 160),
    txtMuted    = Color3.fromRGB(80,  80,  100),
    border      = Color3.fromRGB(40,  40,  58),
    borderHot   = Color3.fromRGB(196, 22,  42),
}

local F_BOLD   = Enum.Font.GothamBold
local F_NORMAL = Enum.Font.Gotham

local T_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local T_MED  = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_SLOW = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function uiCorner(p, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 8)
    c.Parent = p
    return c
end

local function uiStroke(p, col, px)
    local s = Instance.new("UIStroke")
    s.Color    = col or C.border
    s.Thickness = px or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent   = p
    return s
end

local function uiPad(p, top, bot, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, top    or 0)
    pad.PaddingBottom = UDim.new(0, bot    or 0)
    pad.PaddingLeft   = UDim.new(0, left   or 0)
    pad.PaddingRight  = UDim.new(0, right  or 0)
    pad.Parent = p
end

-- ══════════════════════════════════════════════════════════════
--  ROOT GUI
-- ══════════════════════════════════════════════════════════════
local GUI = Instance.new("ScreenGui")
GUI.Name           = "InfectedMemoriesUI"
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.IgnoreGuiInset = false
GUI.Parent         = playerGui

-- ══════════════════════════════════════════════════════════════
--  BACKDROP (overlay para cerrar paneles)
-- ══════════════════════════════════════════════════════════════
local Backdrop = Instance.new("TextButton")
Backdrop.Name                   = "Backdrop"
Backdrop.Size                   = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3       = Color3.new(0, 0, 0)
Backdrop.BackgroundTransparency = 1
Backdrop.Text                   = ""
Backdrop.ZIndex                 = 9
Backdrop.Visible                = false
Backdrop.Parent                 = GUI

-- ══════════════════════════════════════════════════════════════
--  [1] HUD — botones verticales, esquina inferior izquierda
--      Diseño: píldoras anchas con icono + texto
-- ══════════════════════════════════════════════════════════════
local HUD = Instance.new("Frame")
HUD.Name                   = "HUD"
HUD.Size                   = UDim2.new(0, 158, 0, 0)  -- alto automático
HUD.Position               = UDim2.new(0, 16, 1, -16)
HUD.AnchorPoint            = Vector2.new(0, 1)         -- ancla desde abajo-izquierda
HUD.BackgroundTransparency = 1
HUD.ZIndex                 = 30
HUD.Parent                 = GUI

local hudLayout = Instance.new("UIListLayout")
hudLayout.FillDirection  = Enum.FillDirection.Vertical
hudLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
hudLayout.SortOrder      = Enum.SortOrder.LayoutOrder
hudLayout.Padding        = UDim.new(0, 6)
hudLayout.Parent         = HUD

-- Auto-ajustar alto del HUD al contenido
hudLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    HUD.Size = UDim2.new(0, 158, 0, hudLayout.AbsoluteContentSize.Y)
end)

-- ─── Fábrica de botón HUD ──────────────────────────────────────
-- Retorna el botón y el stroke (para animarlo cuando está activo)
local function makeHudButton(icon, label, order, accentOnActive)
    local btn = Instance.new("TextButton")
    btn.Name             = "HudBtn_" .. label
    btn.Size             = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = C.bgCard
    btn.Text             = ""
    btn.LayoutOrder      = order
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 31
    btn.Parent           = HUD
    uiCorner(btn, 12)
    local stroke = uiStroke(btn, C.border, 1)

    -- Ícono (izquierda)
    local ico = Instance.new("TextLabel")
    ico.Size             = UDim2.new(0, 38, 1, 0)
    ico.Position         = UDim2.new(0, 0, 0, 0)
    ico.BackgroundTransparency = 1
    ico.Text             = icon
    ico.TextColor3       = C.txtSub
    ico.TextSize         = 18
    ico.Font             = F_NORMAL
    ico.ZIndex           = 32
    ico.Parent           = btn

    -- Separador vertical
    local sep = Instance.new("Frame")
    sep.Size             = UDim2.new(0, 1, 0, 24)
    sep.Position         = UDim2.new(0, 38, 0.5, -12)
    sep.BackgroundColor3 = C.border
    sep.BorderSizePixel  = 0
    sep.ZIndex           = 32
    sep.Parent           = btn

    -- Texto (derecha)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -46, 1, 0)
    lbl.Position         = UDim2.new(0, 46, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextColor3       = C.txtMain
    lbl.TextSize         = 12
    lbl.Font             = F_BOLD
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 32
    lbl.Parent           = btn

    -- Hover: fondo más claro + borde iluminado
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,    T_FAST, {BackgroundColor3 = C.bgBtnHover}):Play()
        TweenService:Create(stroke, T_FAST, {Color = C.borderHot}):Play()
        TweenService:Create(ico,    T_FAST, {TextColor3 = C.txtMain}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if not btn:GetAttribute("Active") then
            TweenService:Create(btn,    T_FAST, {BackgroundColor3 = C.bgCard}):Play()
            TweenService:Create(stroke, T_FAST, {Color = C.border}):Play()
            TweenService:Create(ico,    T_FAST, {TextColor3 = C.txtSub}):Play()
        end
    end)

    -- Función para marcar el botón como activo/inactivo
    local function setActive(active)
        btn:SetAttribute("Active", active)
        local bg  = active and (accentOnActive and C.accent or C.bgBtnHover) or C.bgCard
        local bdr = active and C.borderHot or C.border
        local ic  = active and C.txtMain   or C.txtSub
        TweenService:Create(btn,    T_FAST, {BackgroundColor3 = bg}):Play()
        TweenService:Create(stroke, T_FAST, {Color = bdr}):Play()
        TweenService:Create(ico,    T_FAST, {TextColor3 = ic}):Play()
    end

    return btn, lbl, setActive
end

-- ─── Instanciar botones ────────────────────────────────────────
local btnReset,    _,          _           = makeHudButton("↺",  "Resetear",    3, false)
local btnSprint,   lblSprint,  setSprintActive = makeHudButton("▷",  "Correr",   2, true)
local btnSettings, _,          _           = makeHudButton("⚙",  "Ajustes",     1, false)

-- ─── SPRINT ────────────────────────────────────────────────────
local isSprinting = false
local SPD_WALK    = 16
local SPD_SPRINT  = 32

local function applySprint(active)
    isSprinting = active
    local char  = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = active and SPD_SPRINT or SPD_WALK end
    end
    lblSprint.Text = active and "Caminando" or "Correr"
    setSprintActive(active)
end

-- Click en el botón (funciona en móvil y PC)
btnSprint.MouseButton1Click:Connect(function()
    applySprint(not isSprinting)
end)

-- Shift como atajo de teclado (bonus PC)
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.LeftShift then applySprint(true) end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.LeftShift then applySprint(false) end
end)

player.CharacterAdded:Connect(function() applySprint(false) end)

-- ─── RESET ─────────────────────────────────────────────────────
btnReset.MouseButton1Click:Connect(function()
    ResetAvatar:FireServer()
    -- Flash de confirmación
    TweenService:Create(btnReset, T_FAST, {BackgroundColor3 = C.success}):Play()
    task.delay(0.6, function()
        TweenService:Create(btnReset, T_MED, {BackgroundColor3 = C.bgCard}):Play()
    end)
end)

-- ══════════════════════════════════════════════════════════════
--  [2] SETTINGS PANEL — modal centrado
-- ══════════════════════════════════════════════════════════════
local SET_W, SET_H = 360, 310
local SET_HIDE = UDim2.new(0.5, -SET_W/2, 1.4,  0)
local SET_SHOW = UDim2.new(0.5, -SET_W/2, 0.5, -SET_H/2)

local SetPanel = Instance.new("Frame")
SetPanel.Name             = "SettingsPanel"
SetPanel.Size             = UDim2.new(0, SET_W, 0, SET_H)
SetPanel.Position         = SET_HIDE
SetPanel.BackgroundColor3 = C.bgBase
SetPanel.BorderSizePixel  = 0
SetPanel.ZIndex           = 20
uiCorner(SetPanel, 18)
uiStroke(SetPanel, C.border, 1.5)
SetPanel.Parent = GUI

-- Barra de acento rojo arriba
local setAccentBar = Instance.new("Frame")
setAccentBar.Size             = UDim2.new(1, 0, 0, 3)
setAccentBar.BackgroundColor3 = C.accent
setAccentBar.BorderSizePixel  = 0
setAccentBar.ZIndex           = 21
uiCorner(setAccentBar, 2)
setAccentBar.Parent = SetPanel

-- Header del panel
local setHeader = Instance.new("Frame")
setHeader.Size             = UDim2.new(1, 0, 0, 56)
setHeader.BackgroundTransparency = 1
setHeader.ZIndex           = 21
setHeader.Parent           = SetPanel

local setTitle = Instance.new("TextLabel")
setTitle.Size             = UDim2.new(1, -60, 1, 0)
setTitle.Position         = UDim2.new(0, 20, 0, 0)
setTitle.BackgroundTransparency = 1
setTitle.TextColor3       = C.txtMain
setTitle.TextSize         = 18
setTitle.Font             = F_BOLD
setTitle.TextXAlignment   = Enum.TextXAlignment.Left
setTitle.Text             = "⚙  Ajustes"
setTitle.ZIndex           = 22
setTitle.Parent           = setHeader

local btnSetClose = Instance.new("TextButton")
btnSetClose.Size             = UDim2.new(0, 32, 0, 32)
btnSetClose.Position         = UDim2.new(1, -44, 0.5, -16)
btnSetClose.BackgroundColor3 = C.bgBtn
btnSetClose.Text             = "✕"
btnSetClose.TextColor3       = C.txtSub
btnSetClose.TextSize         = 13
btnSetClose.Font             = F_BOLD
btnSetClose.ZIndex           = 22
btnSetClose.BorderSizePixel  = 0
uiCorner(btnSetClose, 8)
btnSetClose.Parent = setHeader
btnSetClose.MouseEnter:Connect(function()
    TweenService:Create(btnSetClose, T_FAST,
        {BackgroundColor3 = C.accent, TextColor3 = C.txtMain}):Play()
end)
btnSetClose.MouseLeave:Connect(function()
    TweenService:Create(btnSetClose, T_FAST,
        {BackgroundColor3 = C.bgBtn, TextColor3 = C.txtSub}):Play()
end)

-- Divisor
local setDiv = Instance.new("Frame")
setDiv.Size             = UDim2.new(1, -32, 0, 1)
setDiv.Position         = UDim2.new(0, 16, 0, 56)
setDiv.BackgroundColor3 = C.border
setDiv.BorderSizePixel  = 0
setDiv.ZIndex           = 21
setDiv.Parent           = SetPanel

-- Contenedor scrollable de filas
local setContent = Instance.new("Frame")
setContent.Size             = UDim2.new(1, -32, 1, -72)
setContent.Position         = UDim2.new(0, 16, 0, 64)
setContent.BackgroundTransparency = 1
setContent.ZIndex           = 21
setContent.Parent           = SetPanel

local setContentLayout = Instance.new("UIListLayout")
setContentLayout.FillDirection = Enum.FillDirection.Vertical
setContentLayout.SortOrder     = Enum.SortOrder.LayoutOrder
setContentLayout.Padding       = UDim.new(0, 8)
setContentLayout.Parent        = setContent

-- ─── FÁBRICA DE TOGGLE ROW ─────────────────────────────────────
local function makeToggleRow(label, sublabel, order, startOn, onChange)
    local row = Instance.new("Frame")
    row.Name             = "Toggle_" .. label
    row.Size             = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3 = C.bgCard
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.ZIndex           = 22
    uiCorner(row, 10)
    uiStroke(row, C.border)
    row.Parent = setContent

    -- Texto principal
    local lMain = Instance.new("TextLabel")
    lMain.Size           = UDim2.new(0.65, 0, 0, 22)
    lMain.Position       = UDim2.new(0, 14, 0, 8)
    lMain.BackgroundTransparency = 1
    lMain.TextColor3     = C.txtMain
    lMain.TextSize       = 13
    lMain.Font           = F_BOLD
    lMain.TextXAlignment = Enum.TextXAlignment.Left
    lMain.Text           = label
    lMain.ZIndex         = 23
    lMain.Parent         = row

    -- Subtexto
    local lSub = Instance.new("TextLabel")
    lSub.Size           = UDim2.new(0.65, 0, 0, 16)
    lSub.Position       = UDim2.new(0, 14, 0, 30)
    lSub.BackgroundTransparency = 1
    lSub.TextColor3     = C.txtMuted
    lSub.TextSize       = 10
    lSub.Font           = F_NORMAL
    lSub.TextXAlignment = Enum.TextXAlignment.Left
    lSub.Text           = sublabel
    lSub.ZIndex         = 23
    lSub.Parent         = row

    -- Toggle background
    local tBg = Instance.new("Frame")
    tBg.Size             = UDim2.new(0, 46, 0, 24)
    tBg.Position         = UDim2.new(1, -58, 0.5, -12)
    tBg.BackgroundColor3 = startOn and C.accent or C.border
    tBg.BorderSizePixel  = 0
    tBg.ZIndex           = 23
    uiCorner(tBg, 12)
    tBg.Parent = row

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 18, 0, 18)
    knob.Position         = startOn
        and UDim2.new(1, -21, 0.5, -9)
        or  UDim2.new(0,   3, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 24
    uiCorner(knob, 9)
    knob.Parent = tBg

    -- Hitbox
    local hit = Instance.new("TextButton")
    hit.Size                   = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text                   = ""
    hit.ZIndex                 = 25
    hit.Parent                 = tBg

    local state = startOn
    hit.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(tBg, T_FAST,
            {BackgroundColor3 = state and C.accent or C.border}):Play()
        TweenService:Create(knob, T_FAST, {
            Position = state
                and UDim2.new(1, -21, 0.5, -9)
                or  UDim2.new(0,   3, 0.5, -9)
        }):Play()
        if onChange then task.defer(onChange, state) end
    end)

    return function() return state end
end

-- ─── Toggles del panel ────────────────────────────────────────
makeToggleRow(
    "Ocultar jugadores",
    "Hace invisibles a otros jugadores",
    1, false,
    function(active)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = active and 1 or 0
                    end
                end
            end
        end
    end
)

makeToggleRow(
    "Efectos de sonido",
    "Activa o silencia los sonidos del juego",
    2, true,
    function(_active)
        -- Implementado en el paso de audio
    end
)

makeToggleRow(
    "Ocultar nombre del jugador",
    "Oculta el tag de nombre sobre tu personaje",
    3, false,
    function(_active)
        -- Implementado con BillboardGui
    end
)

-- Settings open/close
local settingsOpen = false
local function openSettings()
    settingsOpen = true
    Backdrop.Visible = true
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 0.55}):Play()
    TweenService:Create(SetPanel, T_MED, {Position = SET_SHOW}):Play()
end
local function closeSettings()
    settingsOpen = false
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 1}):Play()
    TweenService:Create(SetPanel, T_SLOW, {Position = SET_HIDE}):Play()
    task.delay(0.5, function() Backdrop.Visible = false end)
end

btnSettings.MouseButton1Click:Connect(function()
    if settingsOpen then closeSettings() else openSettings() end
end)
btnSetClose.MouseButton1Click:Connect(closeSettings)

-- ══════════════════════════════════════════════════════════════
--  [3] OUTFIT PANEL — sube desde abajo al presionar E
-- ══════════════════════════════════════════════════════════════
local PW, PH   = 520, 420
local POS_HIDE = UDim2.new(0.5, -PW/2, 1.3,   0)
local POS_SHOW = UDim2.new(0.5, -PW/2, 0.5, -PH/2)

local Panel = Instance.new("Frame")
Panel.Name             = "OutfitPanel"
Panel.Size             = UDim2.new(0, PW, 0, PH)
Panel.Position         = POS_HIDE
Panel.BackgroundColor3 = C.bgBase
Panel.BorderSizePixel  = 0
Panel.ZIndex           = 10
uiCorner(Panel, 18)
uiStroke(Panel, C.accent, 1.5)
Panel.Parent = GUI

-- Barra de acento
local pAccent = Instance.new("Frame")
pAccent.Size             = UDim2.new(1, 0, 0, 3)
pAccent.BackgroundColor3 = C.accent
pAccent.BorderSizePixel  = 0
pAccent.ZIndex           = 11
uiCorner(pAccent, 2)
pAccent.Parent = Panel

-- Nombre del outfit
local lblName = Instance.new("TextLabel")
lblName.Size             = UDim2.new(1, -90, 0, 40)
lblName.Position         = UDim2.new(0, 22, 0, 16)
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
lblDesc.Size             = UDim2.new(1, -90, 0, 24)
lblDesc.Position         = UDim2.new(0, 22, 0, 58)
lblDesc.BackgroundTransparency = 1
lblDesc.TextColor3       = C.txtSub
lblDesc.TextSize         = 11
lblDesc.Font             = F_NORMAL
lblDesc.TextXAlignment   = Enum.TextXAlignment.Left
lblDesc.TextWrapped      = true
lblDesc.Text             = ""
lblDesc.ZIndex           = 11
lblDesc.Parent           = Panel

-- Botón cerrar
local btnClose = Instance.new("TextButton")
btnClose.Size             = UDim2.new(0, 34, 0, 34)
btnClose.Position         = UDim2.new(1, -46, 0, 14)
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

-- Divisor
local pDiv = Instance.new("Frame")
pDiv.Size             = UDim2.new(1, -44, 0, 1)
pDiv.Position         = UDim2.new(0, 22, 0, 90)
pDiv.BackgroundColor3 = C.border
pDiv.BorderSizePixel  = 0
pDiv.ZIndex           = 11
pDiv.Parent           = Panel

-- Label de sección
local secLbl = Instance.new("TextLabel")
secLbl.Size             = UDim2.new(1, -44, 0, 20)
secLbl.Position         = UDim2.new(0, 22, 0, 100)
secLbl.BackgroundTransparency = 1
secLbl.TextColor3       = C.accent
secLbl.TextSize         = 10
secLbl.Font             = F_BOLD
secLbl.TextXAlignment   = Enum.TextXAlignment.Left
secLbl.Text             = "ITEMS DEL LOOK"
secLbl.ZIndex           = 11
secLbl.Parent           = Panel

-- ─── Tarjetas de ítem ──────────────────────────────────────────
local function makeItemCard(xOffset, typeLabel)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0, 152, 0, 182)
    card.Position         = UDim2.new(0, xOffset, 0, 128)
    card.BackgroundColor3 = C.bgCard
    card.BorderSizePixel  = 0
    card.ZIndex           = 11
    uiCorner(card, 10)
    uiStroke(card, C.border)
    card.Parent = Panel

    local img = Instance.new("ImageLabel")
    img.Size             = UDim2.new(1, -12, 0, 122)
    img.Position         = UDim2.new(0, 6, 0, 6)
    img.BackgroundColor3 = C.bgBase
    img.Image            = ""
    img.ScaleType        = Enum.ScaleType.Fit
    img.ZIndex           = 12
    uiCorner(img, 7)
    img.Parent = card

    local lType = Instance.new("TextLabel")
    lType.Size            = UDim2.new(1, -8, 0, 16)
    lType.Position        = UDim2.new(0, 4, 0, 132)
    lType.BackgroundTransparency = 1
    lType.TextColor3      = C.accent
    lType.TextSize        = 9
    lType.Font            = F_BOLD
    lType.Text            = typeLabel
    lType.ZIndex          = 12
    lType.Parent          = card

    local lId = Instance.new("TextLabel")
    lId.Size            = UDim2.new(1, -8, 0, 28)
    lId.Position        = UDim2.new(0, 4, 0, 150)
    lId.BackgroundTransparency = 1
    lId.TextColor3      = C.txtMuted
    lId.TextSize        = 9
    lId.Font            = F_NORMAL
    lId.TextWrapped     = true
    lId.Text            = "—"
    lId.ZIndex          = 12
    lId.Parent          = card

    return img, lId
end

local shirtImg, shirtIdLbl = makeItemCard(22,  "CAMISA")
local pantsImg, pantsIdLbl = makeItemCard(186, "PANTALÓN")

-- ─── Botón VESTIR ──────────────────────────────────────────────
local btnTryOn = Instance.new("TextButton")
btnTryOn.Size             = UDim2.new(0, 178, 0, 46)
btnTryOn.Position         = UDim2.new(0, 22,  1, -62)
btnTryOn.BackgroundColor3 = C.accent
btnTryOn.Text             = "VESTIR"
btnTryOn.TextColor3       = C.txtMain
btnTryOn.TextSize         = 13
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

-- ─── Botón COMPRAR ─────────────────────────────────────────────
local btnBuy = Instance.new("TextButton")
btnBuy.Size             = UDim2.new(0, 178, 0, 46)
btnBuy.Position         = UDim2.new(0, 212, 1, -62)
btnBuy.BackgroundColor3 = C.bgBtn
btnBuy.Text             = "COMPRAR"
btnBuy.TextColor3       = C.txtMain
btnBuy.TextSize         = 13
btnBuy.Font             = F_BOLD
btnBuy.ZIndex           = 12
btnBuy.BorderSizePixel  = 0
uiCorner(btnBuy, 10)
uiStroke(btnBuy, C.border)
btnBuy.Parent = Panel
btnBuy.MouseEnter:Connect(function()
    TweenService:Create(btnBuy, T_FAST,
        {BackgroundColor3 = Color3.fromRGB(38, 38, 56)}):Play()
end)
btnBuy.MouseLeave:Connect(function()
    TweenService:Create(btnBuy, T_FAST, {BackgroundColor3 = C.bgBtn}):Play()
end)

-- ─── Lógica del panel ──────────────────────────────────────────
local panelOpen    = false
local activeOutfit = nil

local function openPanel(data)
    if panelOpen then return end
    panelOpen    = true
    activeOutfit = data

    lblName.Text = data.name        or "—"
    lblDesc.Text = data.description or ""

    local sid = data.shirt or 0
    local pid = data.pants or 0

    shirtImg.Image  = sid ~= 0
        and ("rbxthumb://type=Asset&id=" .. sid .. "&w=150&h=150") or ""
    shirtIdLbl.Text = sid ~= 0 and ("ID: " .. sid) or "Sin ítem"

    pantsImg.Image  = pid ~= 0
        and ("rbxthumb://type=Asset&id=" .. pid .. "&w=150&h=150") or ""
    pantsIdLbl.Text = pid ~= 0 and ("ID: " .. pid) or "Sin ítem"

    Backdrop.Visible = true
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(Panel,    T_MED, {Position = POS_SHOW}):Play()
end

local function closePanel()
    if not panelOpen then return end
    panelOpen    = false
    activeOutfit = nil
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 1}):Play()
    TweenService:Create(Panel,    T_SLOW, {Position = POS_HIDE}):Play()
    task.delay(0.5, function() Backdrop.Visible = false end)
end

Backdrop.MouseButton1Click:Connect(function()
    closePanel()
    closeSettings()
end)
btnClose.MouseButton1Click:Connect(closePanel)
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Escape then
        closePanel()
        closeSettings()
    end
end)

-- VESTIR
btnTryOn.MouseButton1Click:Connect(function()
    if not activeOutfit then return end
    TryOnOutfit:FireServer(activeOutfit.id)
    local orig = btnTryOn.Text
    btnTryOn.Text = "✓  EQUIPADO"
    TweenService:Create(btnTryOn, T_FAST, {BackgroundColor3 = C.success}):Play()
    task.delay(2, function()
        if btnTryOn and btnTryOn.Parent then
            btnTryOn.Text = orig
            TweenService:Create(btnTryOn, T_MED, {BackgroundColor3 = C.accent}):Play()
        end
    end)
end)

-- COMPRAR
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
    TweenService:Create(btnBuy, T_FAST, {BackgroundColor3 = C.success}):Play()
    task.delay(0.6, function()
        TweenService:Create(btnBuy, T_MED, {BackgroundColor3 = C.bgBtn}):Play()
    end)
end)

-- ══════════════════════════════════════════════════════════════
--  [4] CONECTAR PROXIMITY PROMPTS
-- ══════════════════════════════════════════════════════════════
local function connectMannequin(mannequin)
    if not mannequin:IsA("Model") then return end
    local root = mannequin.PrimaryPart or mannequin:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local prompt = root:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return end

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
        warn("[OutfitClient] ❌ Carpeta 'Mannequins' no encontrada.")
        return
    end
    for _, m in ipairs(folder:GetChildren()) do connectMannequin(m) end
    folder.ChildAdded:Connect(connectMannequin)
    print("[OutfitClient] ✅ UI lista. " .. #folder:GetChildren() .. " maniquíes conectados.")
end)