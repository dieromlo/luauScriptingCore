-- ============================================================
--  OutfitClient.client.lua
--  LocalScript | StarterPlayerScripts
--  UI Premium: Horizontal Dock HUD + Adaptive Menus
--  Estética: Minimalist Dark Glass (Upscaled +40%)
-- ============================================================

print("[OutfitClient] 🔵 Script Pro-Grade iniciado")

--> SERVICIOS
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local SoundService      = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

--> REMOTE EVENTS (Preservados con validaciones estrictas)
local remoteFolder = ReplicatedStorage
    :WaitForChild("OutfitSystem")
    :WaitForChild("RemoteEvents")

local TryOnOutfit = remoteFolder:WaitForChild("TryOnOutfit", 15)
local ResetAvatar = remoteFolder:WaitForChild("ResetAvatar",  15)
local BuyOutfit   = remoteFolder:WaitForChild("BuyOutfit",    15)

if not TryOnOutfit then error("[OutfitClient] ❌ TryOnOutfit no encontrado") end
if not ResetAvatar then error("[OutfitClient] ❌ ResetAvatar no encontrado") end

-- ══════════════════════════════════════════════════════════════
--  SISTEMA DE AUDIO UI (Sutil y Premium)
-- ══════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════
--  TOGGLE DE SONIDOS DE LA UI
-- ══════════════════════════════════════════════════════════════
local sndHover = getOrCreateSound("Hover", "6895079853", 0.5, 1.2)
local sndClick = getOrCreateSound("Click", "6895079853", 0.5, 1.0)

local sonidosActivos = true

local function playHover()
    if sonidosActivos and sndHover.IsLoaded then sndHover:Play() end
end

local function playClick()
    if sonidosActivos and sndClick.IsLoaded then sndClick:Play() end
end

-- ══════════════════════════════════════════════════════════════
--  TOKENS DE DISEÑO (TRUE DARK PURE MODIFICATIONS)
-- ══════════════════════════════════════════════════════════════
local C = {
    bgBase      = Color3.fromRGB(10, 10, 10),     -- Negro Puro
    bgCard      = Color3.fromRGB(22, 22, 22),     -- Gris Carbón
    bgBtn       = Color3.fromRGB(32, 32, 32),     -- Botones Apagados
    bgBtnHover  = Color3.fromRGB(48, 48, 48),     -- Iluminación Neutra
    accent      = Color3.fromRGB(255, 255, 255),  -- Blanco Puro
    accentHover = Color3.fromRGB(220, 220, 220),
    success     = Color3.fromRGB(46, 204, 113),   -- Verde Resetear exitoso
    txtMain     = Color3.fromRGB(255, 255, 255),
    txtSub      = Color3.fromRGB(150, 150, 150),  -- Texto secundario sin azul
    txtMuted    = Color3.fromRGB(90, 90, 90),
    border      = Color3.fromRGB(38, 38, 38),
    borderHot   = Color3.fromRGB(255, 255, 255),
}

local F_BOLD   = Enum.Font.GothamBold
local F_NORMAL = Enum.Font.Gotham

-- Tiempos e Interpolaciones fluidas
local T_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local T_MED  = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_SLOW = TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ══════════════════════════════════════════════════════════════
--  ICONOGRAFÍA VECTORIAL MINIMALISTA
-- ══════════════════════════════════════════════════════════════
local ICONS = {
    Run      = "rbxassetid://116542655589112", -- Icono correr minimalista
    Cart     = "rbxassetid://136191071460353", -- Icono del Carrito de Compras
    Save     = "rbxassetid://12403099725",  -- Icono de Guardar
    Settings = "rbxassetid://98202862460239", -- Icono de Settings
    Reset    = "rbxassetid://87873470710971", -- Icono de Recargar Avatar
    Close    = "rbxassetid://9649924868", -- Icono de Cerrar la pestaña
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS DE INTERFAZ
-- ══════════════════════════════════════════════════════════════
local function uiCorner(p, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 12)
    c.Parent = p
    return c
end

local function uiStroke(p, col, px)
    local s = Instance.new("UIStroke")
    s.Color    = col or C.border
    s.Thickness = px or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent   = p
    return s
end

-- ══════════════════════════════════════════════════════════════
--  ROOT GUI
-- ══════════════════════════════════════════════════════════════
-- ─── Blur de Lighting (efecto cristal esmerilado) ─────────────
local Lighting   = game:GetService("Lighting")
local blurEffect = Instance.new("BlurEffect")
blurEffect.Size   = 0
blurEffect.Parent = Lighting

local T_BLUR = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function blurIn()
    TweenService:Create(blurEffect, T_BLUR, {Size = 16}):Play()
end
local function blurOut()
    TweenService:Create(blurEffect, T_BLUR, {Size = 0}):Play()
end

local GUI = Instance.new("ScreenGui")
GUI.Name           = "InfectedMemoriesUI"
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.IgnoreGuiInset = true
GUI.Parent         = playerGui

-- ══════════════════════════════════════════════════════════════
--  SISTEMA DE NOTIFICACIONES TOAST
--  Aparecen en la esquina superior derecha, se apilan,
--  y desaparecen solas después de unos segundos.
-- ══════════════════════════════════════════════════════════════
local TOAST_W       = 280
local TOAST_H       = 56
local TOAST_PADDING = 10
local TOAST_SHOW_Y  = 20   -- distancia desde el top
local toastQueue    = {}
local TOAST_TYPES   = {
    success = {icon = "✓", color = Color3.fromRGB(40, 185, 90)},
    error   = {icon = "✕", color = Color3.fromRGB(196, 22, 42)},
    info    = {icon = "i", color = Color3.fromRGB(80, 140, 220)},
    neutral = {icon = "·", color = Color3.fromRGB(150, 150, 150)},
}

-- Contenedor de toasts (esquina superior derecha)
local toastContainer = Instance.new("Frame")
toastContainer.Name             = "ToastContainer"
toastContainer.Size             = UDim2.new(0, TOAST_W, 1, 0)
toastContainer.Position         = UDim2.new(1, -(TOAST_W + 16), 0, 0)
toastContainer.BackgroundTransparency = 1
toastContainer.ZIndex           = 100

-- El parent se asigna después de crear GUI, lo hacemos en task.defer
task.defer(function()
    toastContainer.Parent = GUI
end)

local function showToast(message, toastType, duration)
    toastType = toastType or "neutral"
    duration  = duration  or 3

    local style = TOAST_TYPES[toastType] or TOAST_TYPES.neutral

    -- Calcular posición Y basada en toasts activos
    local yOffset = TOAST_SHOW_Y
    for _, existing in ipairs(toastQueue) do
        if existing and existing.Parent then
            yOffset = yOffset + TOAST_H + TOAST_PADDING
        end
    end

    -- Frame del toast
    local toast = Instance.new("Frame")
    toast.Name             = "Toast"
    toast.Size             = UDim2.new(1, 0, 0, TOAST_H)
    toast.Position         = UDim2.new(1.2, 0, 0, yOffset) -- empieza fuera de pantalla
    toast.BackgroundColor3 = C.bgCard
    toast.BorderSizePixel  = 0
    toast.ZIndex           = 101
    uiCorner(toast, 12)
    uiStroke(toast, C.border, 1)
    toast.Parent = toastContainer

    -- Ícono
    local icoLbl = Instance.new("TextLabel")
    icoLbl.Size             = UDim2.new(0, 28, 1, 0)
    icoLbl.Position         = UDim2.new(0, 18, 0, 0)
    icoLbl.BackgroundTransparency = 1
    icoLbl.Text             = style.icon
    icoLbl.TextColor3       = style.color
    icoLbl.TextSize         = 16
    icoLbl.Font             = F_BOLD
    icoLbl.ZIndex           = 102
    icoLbl.Parent           = toast

    -- Mensaje
    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size             = UDim2.new(1, -52, 1, 0)
    msgLbl.Position         = UDim2.new(0, 48, 0, 0)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text             = message
    msgLbl.TextColor3       = C.txtMain
    msgLbl.TextSize         = 12
    msgLbl.Font             = F_NORMAL
    msgLbl.TextXAlignment   = Enum.TextXAlignment.Left
    msgLbl.TextWrapped      = true
    msgLbl.ZIndex           = 102
    msgLbl.Parent           = toast

    -- Barra de progreso (lifetime indicator)
    local progressBg = Instance.new("Frame")
    progressBg.Size             = UDim2.new(1, -16, 0, 2)
    progressBg.Position         = UDim2.new(0, 8, 1, -6)
    progressBg.BackgroundColor3 = C.border
    progressBg.BorderSizePixel  = 0
    uiCorner(progressBg, 1)
    progressBg.Parent = toast

    local progressFill = Instance.new("Frame")
    progressFill.Size             = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = style.color
    progressFill.BorderSizePixel  = 0
    uiCorner(progressFill, 1)
    progressFill.Parent = progressBg

    -- Añadir a la cola
    table.insert(toastQueue, toast)

    local T_TOAST = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    -- Slide in desde la derecha
    TweenService:Create(toast, T_TOAST,
        {Position = UDim2.new(0, 0, 0, yOffset)}):Play()

    -- Animar la barra de progreso
    TweenService:Create(progressFill,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 1, 0)}):Play()

    -- Auto-dismiss
    task.delay(duration, function()
        if not toast or not toast.Parent then return end
        TweenService:Create(toast, T_TOAST,
            {Position = UDim2.new(1.2, 0, 0, yOffset),
             BackgroundTransparency = 0.6}):Play()
        task.delay(0.35, function()
            -- Remover de la cola
            for i, t in ipairs(toastQueue) do
                if t == toast then table.remove(toastQueue, i) break end
            end
            toast:Destroy()
            -- Reposicionar los toasts restantes
            for i, remaining in ipairs(toastQueue) do
                local newY = TOAST_SHOW_Y + (i - 1) * (TOAST_H + TOAST_PADDING)
                TweenService:Create(remaining, T_TOAST,
                    {Position = UDim2.new(0, 0, 0, newY)}):Play()
            end
        end)
    end)
end

-- API global para usar desde cualquier parte del script
-- Uso: showToast("Mensaje", "success" / "error" / "info" / "neutral", segundos)

-- ══════════════════════════════════════════════════════════════
--  BACKDROP TRANSLÚCIDO
-- ══════════════════════════════════════════════════════════════
local Backdrop = Instance.new("TextButton")
Backdrop.Name                   = "Backdrop"
Backdrop.Size                   = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3       = Color3.fromRGB(5, 5, 5)
Backdrop.BackgroundTransparency = 1
Backdrop.Text                   = ""
Backdrop.ZIndex                 = 9
Backdrop.Visible                = false
Backdrop.Parent                 = GUI

-- ══════════════════════════════════════════════════════════════
--  HUD HORIZONTAL DOCK INFERIOR
-- ══════════════════════════════════════════════════════════════
local HUD = Instance.new("Frame")
HUD.Name                   = "HorizontalHUD"
HUD.Size                   = UDim2.new(0, 0, 0, 74) -- Margen extra superior para expansiones
HUD.Position               = UDim2.new(0.5, 0, 1, -24)
HUD.AnchorPoint            = Vector2.new(0.5, 1)
HUD.BackgroundTransparency = 1
HUD.ZIndex                 = 30
HUD.Parent                 = GUI

local hudLayout = Instance.new("UIListLayout")
hudLayout.FillDirection   = Enum.FillDirection.Horizontal
hudLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hudLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- Alineación inferior obligatoria
hudLayout.SortOrder       = Enum.SortOrder.LayoutOrder
hudLayout.Padding         = UDim.new(0, 20)
hudLayout.Parent          = HUD

hudLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    HUD.Size = UDim2.new(0, hudLayout.AbsoluteContentSize.X + 20, 0, 74)
end)

-- ─── Fábrica de Botones del Dock HUD (Efecto Mac Semper Fi) ───
local function makeHudButton(iconAssetId, label, order)
    -- Contenedor estático para no romper la grilla de UIListLayout al crecer
    local container = Instance.new("Frame")
    container.Name = "Slot_" .. label
    container.Size = UDim2.new(0, 120, 0, 64)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = HUD

    local btn = Instance.new("TextButton")
    btn.Name             = "HudBtn_" .. label
    btn.Size             = UDim2.new(1, 0, 1, 0)
    btn.Position         = UDim2.new(0.5, 0, 1, 0)
    btn.AnchorPoint      = Vector2.new(0.5, 1) -- Crece hacia arriba de manera limpia
    btn.BackgroundColor3 = C.bgCard
    btn.Text             = ""
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 31
    btn.Parent           = container
    uiCorner(btn, 14)
    local stroke = uiStroke(btn, C.border, 1.2)

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = btn

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    contentLayout.Padding = UDim.new(0, 4)
    contentLayout.Parent = contentFrame

    -- Ícono Remasterizado
    local ico = Instance.new("ImageLabel")
    ico.Size             = UDim2.new(0, 22, 0, 22)
    ico.BackgroundTransparency = 1
    ico.Image            = iconAssetId
    ico.ImageColor3      = C.txtSub
    ico.ZIndex           = 32
    ico.Parent           = contentFrame

    -- Texto Inferior
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label:upper()
    lbl.TextColor3       = C.txtSub
    lbl.TextSize         = 10
    lbl.Font             = F_BOLD
    lbl.ZIndex           = 32
    lbl.Parent           = contentFrame

    -- Animaciones Fluidas de Interacción
    btn.MouseEnter:Connect(function()
        playHover()
        btn.ZIndex = 40 -- Sobresale en profundidad
        TweenService:Create(btn, T_FAST, {Size = UDim2.new(1.15, 0, 1.15, 0), BackgroundColor3 = C.bgBtnHover}):Play()
        TweenService:Create(stroke, T_FAST, {Color = C.borderHot}):Play()
        TweenService:Create(ico, T_FAST, {ImageColor3 = C.txtMain}):Play()
        TweenService:Create(lbl, T_FAST, {TextColor3 = C.txtMain}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        if not btn:GetAttribute("Active") then
            btn.ZIndex = 31
            TweenService:Create(btn, T_FAST, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.bgCard}):Play()
            TweenService:Create(stroke, T_FAST, {Color = C.border}):Play()
            TweenService:Create(ico, T_FAST, {ImageColor3 = C.txtSub}):Play()
            TweenService:Create(lbl, T_FAST, {TextColor3 = C.txtSub}):Play()
        end
    end)

    -- Feedback físico Mousedown
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, T_FAST, {Size = UDim2.new(0.95, 0, 0.95, 0)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        playClick()
        TweenService:Create(btn, T_FAST, {Size = UDim2.new(1.15, 0, 1.15, 0)}):Play()
    end)

    local function setActive(active)
        btn:SetAttribute("Active", active)
        local bg  = active and C.bgBtnHover or C.bgCard
        local bdr = active and C.borderHot or C.border
        local col = active and C.txtMain or C.txtSub
        TweenService:Create(btn, T_FAST, {BackgroundColor3 = bg}):Play()
        TweenService:Create(stroke, T_FAST, {Color = bdr}):Play()
        TweenService:Create(ico, T_FAST, {ImageColor3 = col}):Play()
        TweenService:Create(lbl, T_FAST, {TextColor3 = col}):Play()
    end

    return btn, lbl, setActive
end

-- ─── Instanciación del HUD Remasterizado (Excluye Música al Ajustes) ───
local btnSprint, lblSprint, setSprintActive = makeHudButton(ICONS.Run,      "Correr",   1)
local btnCart,     _, _                     = makeHudButton(ICONS.Cart,     "Carrito",  2)
local btnSave,     _, _                     = makeHudButton(ICONS.Save,     "Guardar",  3)
local btnSettings, _, _                     = makeHudButton(ICONS.Settings, "Ajustes",  4)
local btnReset,    _, _                     = makeHudButton(ICONS.Reset,    "Resetear", 5)

-- ══════════════════════════════════════════════════════════════
--  SISTEMAS ASOCIADOS A LOS BOTONES DEL DOCK
-- ══════════════════════════════════════════════════════════════

-- [1] SPRINT SYSTEM
local isSprinting = false
local SPD_WALK, SPD_SPRINT = 16, 32

local function applySprint(active)
    isSprinting = active
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = active and SPD_SPRINT or SPD_WALK end
    end
    lblSprint.Text = active and "CAMINANDO" or "CORRER"
    setSprintActive(active)
end

btnSprint.MouseButton1Click:Connect(function() applySprint(not isSprinting) end)

-- [2] RESET SYSTEM
btnReset.MouseButton1Click:Connect(function()
    ResetAvatar:FireServer()
    TweenService:Create(btnReset, T_FAST, {BackgroundColor3 = C.success}):Play()
    task.delay(0.5, function()
        TweenService:Create(btnReset, T_MED, {BackgroundColor3 = C.bgCard}):Play()
    end)
    showToast("Avatar reseteado", "neutral", 2)
end)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 1] SETTINGS PANEL
-- ══════════════════════════════════════════════════════════════
local SET_W, SET_H = 500, 480 -- Altura adaptada para alojar el Slider de Música de forma limpia
local SET_HIDE = UDim2.new(0.5, -SET_W/2, 1.5, 0)
local SET_SHOW = UDim2.new(0.5, -SET_W/2, 0.5, -SET_H/2)

local SetPanel = Instance.new("Frame")
SetPanel.Name             = "SettingsPanel"
SetPanel.Size             = UDim2.new(0, SET_W, 0, SET_H)
SetPanel.Position         = SET_HIDE
SetPanel.BackgroundColor3 = C.bgBase
SetPanel.BorderSizePixel  = 0
SetPanel.ZIndex           = 20
uiCorner(SetPanel, 20)
uiStroke(SetPanel, C.border, 1.5)
SetPanel.Parent = GUI

local setHeader = Instance.new("Frame")
setHeader.Size             = UDim2.new(1, 0, 0, 64)
setHeader.BackgroundTransparency = 1
setHeader.ZIndex           = 21
setHeader.Parent           = SetPanel

local setTitle = Instance.new("TextLabel")
setTitle.Size             = UDim2.new(1, -60, 1, 0)
setTitle.Position         = UDim2.new(0, 24, 0, 0)
setTitle.BackgroundTransparency = 1
setTitle.TextColor3       = C.txtMain
setTitle.TextSize         = 22 
setTitle.Font             = F_BOLD
setTitle.TextXAlignment   = Enum.TextXAlignment.Left
setTitle.Text             = "Ajustes de Sistema"
setTitle.ZIndex           = 22
setTitle.Parent           = setHeader

-- Botón de cerrar de Ajustes con Imagen Vectorial Limpia
local btnSetClose = Instance.new("ImageButton")
btnSetClose.Size             = UDim2.new(0, 36, 0, 36)
btnSetClose.Position         = UDim2.new(1, -48, 0.5, -18)
btnSetClose.BackgroundColor3 = C.bgBtn
btnSetClose.Image            = ICONS.Close
btnSetClose.ImageColor3      = C.txtSub
btnSetClose.ZIndex           = 22
btnSetClose.BorderSizePixel  = 0
uiCorner(btnSetClose, 10)
btnSetClose.Parent = setHeader
btnSetClose.MouseEnter:Connect(function()
    TweenService:Create(btnSetClose, T_FAST, {BackgroundColor3 = C.bgBtnHover, ImageColor3 = C.accent}):Play()
end)
btnSetClose.MouseLeave:Connect(function()
    TweenService:Create(btnSetClose, T_FAST, {BackgroundColor3 = C.bgBtn, ImageColor3 = C.txtSub}):Play()
end)

local setContent = Instance.new("Frame")
setContent.Size             = UDim2.new(1, -48, 1, -88)
setContent.Position         = UDim2.new(0, 24, 0, 76)
setContent.BackgroundTransparency = 1
setContent.ZIndex           = 21
setContent.Parent           = SetPanel

local setContentLayout = Instance.new("UIListLayout")
setContentLayout.FillDirection = Enum.FillDirection.Vertical
setContentLayout.SortOrder     = Enum.SortOrder.LayoutOrder
setContentLayout.Padding       = UDim.new(0, 12)
setContentLayout.Parent        = setContent

-- ─── Fábrica de Filas de Configuración ────────────────────────
local function makeToggleRow(label, sublabel, order, startOn, onChange)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 64) 
    row.BackgroundColor3 = C.bgCard
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.ZIndex           = 22
    uiCorner(row, 14)
    uiStroke(row, C.border, 1)
    row.Parent = setContent

    local lMain = Instance.new("TextLabel")
    lMain.Size           = UDim2.new(0.65, 0, 0, 24)
    lMain.Position       = UDim2.new(0, 18, 0, 12)
    lMain.BackgroundTransparency = 1
    lMain.TextColor3     = C.txtMain
    lMain.TextSize       = 14
    lMain.Font           = F_BOLD
    lMain.TextXAlignment = Enum.TextXAlignment.Left
    lMain.Text           = label
    lMain.Parent         = row

    local lSub = Instance.new("TextLabel")
    lSub.Size           = UDim2.new(0.65, 0, 0, 18)
    lSub.Position       = UDim2.new(0, 18, 0, 34)
    lSub.BackgroundTransparency = 1
    lSub.TextColor3     = C.txtMuted
    lSub.TextSize       = 11
    lSub.Font           = F_NORMAL
    lSub.TextXAlignment = Enum.TextXAlignment.Left
    lSub.Text           = sublabel
    lSub.Parent         = row

    local tBg = Instance.new("Frame")
    tBg.Size             = UDim2.new(0, 54, 0, 28)
    tBg.Position         = UDim2.new(1, -72, 0.5, -14)
    tBg.BackgroundColor3 = startOn and C.accent or C.bgBtn
    tBg.BorderSizePixel  = 0
    uiCorner(tBg, 14)
    tBg.Parent = row

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 22, 0, 22)
    knob.Position         = startOn and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = startOn and C.bgBase or C.txtMain
    knob.BorderSizePixel  = 0
    uiCorner(knob, 11)
    knob.Parent = tBg

    local hit = Instance.new("TextButton")
    hit.Size                   = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text                   = ""
    hit.ZIndex                 = 25
    hit.Parent                 = tBg

    local state = startOn
    hit.MouseButton1Click:Connect(function()
        state = not state
        playClick()
        TweenService:Create(tBg,  T_FAST, {BackgroundColor3 = state and C.accent or C.bgBtn}):Play()
        TweenService:Create(knob, T_FAST, {
            BackgroundColor3 = state and C.bgBase or C.txtMain,
            Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
        if onChange then task.defer(onChange, state) end
    end)
end

-- Instanciación de Ajustes Originales
makeToggleRow("Ocultar Jugadores", "Incrementa FPS haciendo invisibles a otros avatares", 1, false, function(active)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.LocalTransparencyModifier = active and 1 or 0 end
            end
        end
    end
end)
makeToggleRow("Efectos de Sonido", "Administra la salida de audio de la interfaz", 2, true, function(state)
    sonidosActivos = state
end)
makeToggleRow("Interfaz Limpia", "Oculta indicadores flotantes externos", 3, false, nil)

-- ─── BARRA DE SONIDO PARA LA MÚSICA  ───
local musicRow = Instance.new("Frame")
musicRow.Size             = UDim2.new(1, 0, 0, 68)
musicRow.BackgroundColor3 = C.bgCard
musicRow.BorderSizePixel  = 0
musicRow.LayoutOrder      = 4
musicRow.ZIndex           = 22
uiCorner(musicRow, 14)
uiStroke(musicRow, C.border, 1)
musicRow.Parent = setContent

local mLabel = Instance.new("TextLabel")
mLabel.Size           = UDim2.new(0.4, 0, 1, 0)
mLabel.Position       = UDim2.new(0, 18, 0, 0)
mLabel.BackgroundTransparency = 1
mLabel.TextColor3     = C.txtMain
mLabel.TextSize       = 14
mLabel.Font           = F_BOLD
mLabel.TextXAlignment = Enum.TextXAlignment.Left
mLabel.Text           = "Volumen Música"
mLabel.Parent         = musicRow

local sliderTrack = Instance.new("Frame")
sliderTrack.Size             = UDim2.new(0, 200, 0, 6)
sliderTrack.Position         = UDim2.new(1, -218, 0.5, -3)
sliderTrack.BackgroundColor3 = C.bgBtn
sliderTrack.BorderSizePixel  = 0
uiCorner(sliderTrack, 3)
sliderTrack.Parent           = musicRow

local sliderFill = Instance.new("Frame")
sliderFill.Size             = UDim2.new(0.8, 0, 1, 0) -- Iniciado al 80% por defecto
sliderFill.BackgroundColor3 = C.accent
sliderFill.BorderSizePixel  = 0
uiCorner(sliderFill, 3)
sliderFill.Parent           = sliderTrack

local knobSlider = Instance.new("Frame")
knobSlider.Size             = UDim2.new(0, 14, 0, 14)
knobSlider.Position         = UDim2.new(0.8, -7, 0.5, -7)
knobSlider.BackgroundColor3 = C.accent
knobSlider.BorderSizePixel  = 0
uiCorner(knobSlider, 7)
knobSlider.Parent           = sliderTrack

local sliderFillStroke = uiStroke(knobSlider, C.bgBase, 1.5)

-- Lógica Interactiva del Arrastre (Spotify Slider)
local isDragging = false
local function updateSlider(input)
    local trackWidth = sliderTrack.AbsoluteSize.X
    local mouseX = input.Position.X
    local trackX = sliderTrack.AbsolutePosition.X
    local relativeX = math.clamp((mouseX - trackX) / trackWidth, 0, 1)
    
    sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
    knobSlider.Position = UDim2.new(relativeX, -7, 0.5, -7)
    
    -- Aquí puedes conectar directamente el volumen maestro de tu SoundSystem usando `relativeX` (de 0 a 1)
end

knobSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)


-- ══════════════════════════════════════════════════════════════
--  [MODAL 2] OUTFIT PANEL
-- ══════════════════════════════════════════════════════════════
local PW, PH   = 720, 580 
local POS_HIDE = UDim2.new(0.5, -PW/2, 1.5, 0)
local POS_SHOW = UDim2.new(0.5, -PW/2, 0.5, -PH/2)

local Panel = Instance.new("Frame")
Panel.Name             = "OutfitPanel"
Panel.Size             = UDim2.new(0, PW, 0, PH)
Panel.Position         = POS_HIDE
Panel.BackgroundColor3 = C.bgBase
Panel.BorderSizePixel  = 0
Panel.ZIndex           = 10
uiCorner(Panel, 20)
uiStroke(Panel, C.border, 1.5)
Panel.Parent = GUI

local lblName = Instance.new("TextLabel")
lblName.Size             = UDim2.new(1, -90, 0, 50)
lblName.Position         = UDim2.new(0, 32, 0, 24)
lblName.BackgroundTransparency = 1
lblName.TextColor3       = C.txtMain
lblName.TextSize         = 28 
lblName.Font             = F_BOLD
lblName.TextXAlignment   = Enum.TextXAlignment.Left
lblName.Text             = "Visualizador de Look"
lblName.ZIndex           = 11
lblName.Parent           = Panel

local lblDesc = Instance.new("TextLabel")
lblDesc.Size             = UDim2.new(1, -90, 0, 30)
lblDesc.Position         = UDim2.new(0, 32, 0, 74)
lblDesc.BackgroundTransparency = 1
lblDesc.TextColor3       = C.txtSub
lblDesc.TextSize         = 14
lblDesc.Font             = F_NORMAL
lblDesc.TextXAlignment   = Enum.TextXAlignment.Left
lblDesc.TextWrapped      = true
lblDesc.Text             = "Inspecciona los elementos de este maniquí."
lblDesc.Parent           = Panel

-- Botón cerrar del probador con Imagen Vectorial Limpia
local btnClose = Instance.new("ImageButton")
btnClose.Size             = UDim2.new(0, 36, 0, 36)
btnClose.Position         = UDim2.new(1, -54, 0, 24)
btnClose.BackgroundColor3 = C.bgBtn
btnClose.Image            = ICONS.Close
btnClose.ImageColor3      = C.txtSub
btnClose.BorderSizePixel  = 0
uiCorner(btnClose, 10)
btnClose.Parent = Panel
btnClose.MouseEnter:Connect(function()
    TweenService:Create(btnClose, T_FAST, {BackgroundColor3 = C.bgBtnHover, ImageColor3 = C.accent}):Play()
end)
btnClose.MouseLeave:Connect(function()
    TweenService:Create(btnClose, T_FAST, {BackgroundColor3 = C.bgBtn, ImageColor3 = C.txtSub}):Play()
end)

-- Fábrica de slots de ítems dentro del probador
local function makeItemCard(xOffset, typeLabel)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0, 210, 0, 250) 
    card.Position         = UDim2.new(0, xOffset, 0, 130)
    card.BackgroundColor3 = C.bgCard
    card.BorderSizePixel  = 0
    uiCorner(card, 14)
    uiStroke(card, C.border)
    card.Parent = Panel

    local img = Instance.new("ImageLabel")
    img.Size             = UDim2.new(1, -16, 0, 160)
    img.Position         = UDim2.new(0, 8, 0, 8)
    img.BackgroundColor3 = C.bgBase
    img.ScaleType        = Enum.ScaleType.Fit
    uiCorner(img, 10)
    img.Parent = card

    local lType = Instance.new("TextLabel")
    lType.Size            = UDim2.new(1, -16, 0, 22)
    lType.Position        = UDim2.new(0, 12, 0, 178)
    lType.BackgroundTransparency = 1
    lType.TextColor3      = C.txtSub    
    lType.TextSize        = 11
    lType.Font            = F_BOLD
    lType.TextXAlignment  = Enum.TextXAlignment.Left
    lType.Text            = typeLabel
    lType.Parent          = card

    local lId = Instance.new("TextLabel")
    lId.Size            = UDim2.new(1, -16, 0, 22)
    lId.Position        = UDim2.new(0, 12, 0, 198)
    lId.BackgroundTransparency = 1
    lId.TextColor3      = C.txtMuted
    lId.TextSize        = 11
    lId.Font            = F_NORMAL
    lId.TextXAlignment  = Enum.TextXAlignment.Left
    lId.Text            = "ID: ---"
    lId.Parent          = card

    return img, lId
end

local shirtImg, shirtIdLbl = makeItemCard(32,  "PRENDA SUPERIOR")
local pantsImg, pantsIdLbl = makeItemCard(262, "PRENDA INFERIOR")

-- Botones de Acción Principales
local btnTryOn = Instance.new("TextButton")
btnTryOn.Size             = UDim2.new(0, 210, 0, 56)
btnTryOn.Position         = UDim2.new(0, 32, 1, -80)
btnTryOn.BackgroundColor3 = C.bgBtn
btnTryOn.Text             = "PROBAR AVATAR"
btnTryOn.TextColor3       = C.txtMain
btnTryOn.TextSize         = 14
btnTryOn.Font             = F_BOLD
btnTryOn.BorderSizePixel  = 0
uiCorner(btnTryOn, 14)
uiStroke(btnTryOn, C.border)
btnTryOn.Parent = Panel

local btnBuy = Instance.new("TextButton")
btnBuy.Size             = UDim2.new(0, 210, 0, 56)
btnBuy.Position         = UDim2.new(0, 262, 1, -80)
btnBuy.BackgroundColor3 = C.accent
btnBuy.Text             = "ADQUIRIR"
btnBuy.TextColor3       = C.bgBase
btnBuy.TextSize         = 14
btnBuy.Font             = F_BOLD
btnBuy.BorderSizePixel  = 0
uiCorner(btnBuy, 14)
btnBuy.Parent = Panel

-- Hover dinámico para botones de acción
local function setButtonInteractions(button, isAccent)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, T_FAST, {BackgroundColor3 = isAccent and C.accentHover or C.bgBtnHover}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, T_FAST, {BackgroundColor3 = isAccent and C.accent or C.bgBtn}):Play()
    end)
end
setButtonInteractions(btnTryOn, false)
setButtonInteractions(btnBuy, true)


-- ══════════════════════════════════════════════════════════════
--  CONTROL INTERACTIVO GLOBAL (MODALES)
-- ══════════════════════════════════════════════════════════════
local activeMenu = nil

local function closeAllMenus()
    if not activeMenu then return end
    blurOut()
    
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 1}):Play()
    
    if activeMenu == "Settings" then
        TweenService:Create(SetPanel, T_SLOW, {Position = SET_HIDE}):Play()
    elseif activeMenu == "Outfit" then
        TweenService:Create(Panel, T_SLOW, {Position = POS_HIDE}):Play()
    end
    
    task.delay(0.4, function() Backdrop.Visible = false end)
    activeMenu = nil
end

local function openMenu(menuType, data)
    closeAllMenus()
    activeMenu = menuType
    Backdrop.Visible = true
    blurIn()
    
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 0.3}):Play()

    if menuType == "Settings" then
        TweenService:Create(SetPanel, T_MED, {Position = SET_SHOW}):Play()
    elseif menuType == "Outfit" and data then
        lblName.Text = data.name or "Look Desconocido"
        local sid = data.shirt or 0
        local pid = data.pants or 0
        shirtImg.Image = sid ~= 0 and ("rbxthumb://type=Asset&id=" .. sid .. "&w=150&h=150") or ""
        shirtIdLbl.Text = sid ~= 0 and ("ID: " .. sid) or "Vacante"
        pantsImg.Image = pid ~= 0 and ("rbxthumb://type=Asset&id=" .. pid .. "&w=150&h=150") or ""
        pantsIdLbl.Text = pid ~= 0 and ("ID: " .. pid) or "Vacante"
        
        TweenService:Create(Panel, T_MED, {Position = POS_SHOW}):Play()
    end
end

-- Asignación de Triggers de Modales
btnSettings.MouseButton1Click:Connect(function()
    if activeMenu == "Settings" then closeAllMenus() else openMenu("Settings") end
end)

btnSetClose.MouseButton1Click:Connect(closeAllMenus)
btnClose.MouseButton1Click:Connect(closeAllMenus)
Backdrop.MouseButton1Click:Connect(closeAllMenus)

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Escape then closeAllMenus() end
end)

-- Conexiones lógicas de red (Vestir/Comprar)
local activeOutfitData = nil
btnTryOn.MouseButton1Click:Connect(function()
    if not activeOutfitData then return end
    TryOnOutfit:FireServer(activeOutfitData.id)
    btnTryOn.Text = "✓ CONECTADO"
    task.delay(1.5, function() btnTryOn.Text = "PROBAR AVATAR" end)
    showToast("Look equipado: " .. (activeOutfitData.name or "—"), "success", 3)
end)

btnBuy.MouseButton1Click:Connect(function()
    if not activeOutfitData then return end
    local sid = activeOutfitData.shirt or 0
    local pid = activeOutfitData.pants or 0
    if sid ~= 0 then BuyOutfit:FireServer(sid) end
    if pid ~= 0 then task.delay(0.5, function() BuyOutfit:FireServer(pid) end) end
    showToast("Abriendo tienda de Roblox...", "info", 2.5)
end)

-- ══════════════════════════════════════════════════════════════
--  [4] MANIPULACIÓN DEL ENTORNO (PROXIMITY PROMPTS - PRESERVADO AL 100%)
-- ══════════════════════════════════════════════════════════════
local function connectMannequin(mannequin)
    if not mannequin:IsA("Model") then return end
    local root = mannequin.PrimaryPart or mannequin:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local prompt = root:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return end

    prompt.Triggered:Connect(function()
        activeOutfitData = {
            id          = mannequin:GetAttribute("OutfitId"),
            name        = mannequin:GetAttribute("OutfitName"),
            description = mannequin:GetAttribute("OutfitDescription"),
            shirt       = mannequin:GetAttribute("ShirtId"),
            pants       = mannequin:GetAttribute("PantsId")
        }
        openMenu("Outfit", activeOutfitData)
    end)
end

local workspaceMannequins = workspace:FindFirstChild("Mannequins")
if workspaceMannequins then
    for _, m in ipairs(workspaceMannequins:GetChildren()) do connectMannequin(m) end
    workspaceMannequins.ChildAdded:Connect(connectMannequin)
end