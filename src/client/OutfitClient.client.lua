-- ============================================================
--  OutfitClient.client.lua
--  LocalScript | StarterPlayerScripts
--  UI Premium: Horizontal Dock HUD + Adaptive Menus
-- ============================================================

print("[OutfitClient] 🔵 Script Pro-Grade iniciado")

--> SERVICIOS
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local SoundService      = game:GetService("SoundService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

--> REMOTE EVENTS (Preservados con validaciones estrictas)
local remoteFolder = ReplicatedStorage
    :WaitForChild("OutfitSystem")
    :WaitForChild("RemoteEvents")

local TryOnOutfit = remoteFolder:WaitForChild("TryOnOutfit", 15)
local ResetAvatar = remoteFolder:WaitForChild("ResetAvatar",  15)
local BuyOutfit   = remoteFolder:WaitForChild("BuyOutfit",    15)
local RemoveItem  = remoteFolder:WaitForChild("RemoveItem",   15)
if not RemoveItem then
    warn("[OutfitClient] ⚠️ RemoveItem no encontrado. Crea el init.meta.json correspondiente.")
end

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
    icoLbl.Size             = UDim2.new(0, 32, 1, -8)
    icoLbl.Position         = UDim2.new(0, 16, 0, 0)
    icoLbl.BackgroundTransparency = 1
    icoLbl.Text             = style.icon
    icoLbl.TextColor3       = style.color
    icoLbl.TextSize         = 20
    icoLbl.Font             = F_BOLD
    icoLbl.TextYAlignment   = Enum.TextYAlignment.Center
    icoLbl.ZIndex           = 102
    icoLbl.Parent           = toast

    -- Mensaje
    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size             = UDim2.new(1, -64, 1, -8)
    msgLbl.Position         = UDim2.new(0, 54, 0, 0)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text             = message
    msgLbl.TextColor3       = C.txtMain
    msgLbl.TextSize         = 14
    msgLbl.Font             = F_NORMAL
    msgLbl.TextXAlignment   = Enum.TextXAlignment.Left
    msgLbl.TextYAlignment   = Enum.TextYAlignment.Center
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
--  BOTÓN CUSTOMIZAR — medio izquierda de pantalla
-- ══════════════════════════════════════════════════════════════
local btnCustomize = Instance.new("TextButton")
btnCustomize.Name             = "BtnCustomize"
btnCustomize.Size             = UDim2.new(0, 132, 0, 46)
btnCustomize.Position         = UDim2.new(0, 20, 0.5, -23)
btnCustomize.BackgroundColor3 = C.bgCard
btnCustomize.Text             = "CUSTOMIZAR"
btnCustomize.TextColor3       = C.txtSub
btnCustomize.Font             = F_BOLD
btnCustomize.TextSize         = 12
btnCustomize.BorderSizePixel  = 0
btnCustomize.ZIndex           = 30
uiCorner(btnCustomize, 12)
local customizeStroke = uiStroke(btnCustomize, C.border, 1.2)
btnCustomize.Parent = GUI

btnCustomize.MouseEnter:Connect(function()
    playHover()
    TweenService:Create(btnCustomize, T_FAST,
        {BackgroundColor3 = C.bgBtnHover, TextColor3 = C.txtMain}):Play()
    TweenService:Create(customizeStroke, T_FAST, {Color = C.borderHot}):Play()
end)
btnCustomize.MouseLeave:Connect(function()
    TweenService:Create(btnCustomize, T_FAST,
        {BackgroundColor3 = C.bgCard, TextColor3 = C.txtSub}):Play()
    TweenService:Create(customizeStroke, T_FAST, {Color = C.border}):Play()
end)
btnCustomize.MouseButton1Down:Connect(function()
    TweenService:Create(btnCustomize, T_FAST, {Size = UDim2.new(0, 126, 0, 44)}):Play()
end)
btnCustomize.MouseButton1Up:Connect(function()
    playClick()
    TweenService:Create(btnCustomize, T_FAST, {Size = UDim2.new(0, 132, 0, 46)}):Play()
end)

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
    if activeMenu == "ResetConfirm" then closeAllMenus() else openMenu("ResetConfirm") end
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
    -- Controla la música ambiente del script AmbientAudio
    if _G.InfectedAudio then
        if state then
            _G.InfectedAudio.unmute()
        else
            _G.InfectedAudio.mute()
        end
    end
end)
makeToggleRow("Ocultar nombres", "Oculta los tags sobre los jugadores", 3, false,
    function(active)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local head = p.Character:FindFirstChild("Head")
                local tag  = head and head:FindFirstChild("NameTagGui")
                if tag then tag.Enabled = not active end
            end
        end
    end
)

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
--  [MODAL 3] CUSTOMIZE PANEL — Fase de pulido UI/UX
-- ══════════════════════════════════════════════════════════════

local activeMenu = nil

-- Colores de interacción Premium
C.buyGreen      = Color3.fromRGB(47, 143, 91)
C.buyGreenHover = Color3.fromRGB(58, 154, 103)

local sndBuy    = getOrCreateSound("Buy",       "6895079853", 0.45, 1.35)
local sndRemove = getOrCreateSound("Remove",    "6895079853", 0.40, 0.75)
local sndOpen   = getOrCreateSound("MenuOpen",  "6895079853", 0.35, 0.90)
local sndClose  = getOrCreateSound("MenuClose", "6895079853", 0.30, 0.65)

local function playSoundBuy()    if sonidosActivos and sndBuy.IsLoaded    then sndBuy:Play()    end end
local function playSoundRemove() if sonidosActivos and sndRemove.IsLoaded then sndRemove:Play() end end
local function playSoundOpen()   if sonidosActivos and sndOpen.IsLoaded   then sndOpen:Play()   end end
local function playSoundClose()  if sonidosActivos and sndClose.IsLoaded  then sndClose:Play()  end end

-- Ajuste de altura para evitar sobreposición con el HUD inferior (Bug corregido)
local CW, CH       = 1120, 610 
local CUSTOM_HIDE  = UDim2.new(0.5, -CW/2, 1.5, 0)
local CUSTOM_SHOW  = UDim2.new(0.5, -CW/2, 0.5, -CH/2)

local CustomizePanel = Instance.new("Frame")
CustomizePanel.Name             = "CustomizePanel"
CustomizePanel.Size             = UDim2.new(0, CW, 0, CH)
CustomizePanel.Position         = CUSTOM_HIDE
CustomizePanel.BackgroundColor3 = C.bgBase
CustomizePanel.BorderSizePixel  = 0
CustomizePanel.ZIndex           = 10
uiCorner(CustomizePanel, 20)
uiStroke(CustomizePanel, C.border, 1.5)
CustomizePanel.Parent = GUI

local custTitle = Instance.new("TextLabel")
custTitle.Size             = UDim2.new(1, -100, 0, 40)
custTitle.Position         = UDim2.new(0, 32, 0, 24)
custTitle.BackgroundTransparency = 1
custTitle.TextColor3       = C.txtMain
custTitle.TextSize         = 28
custTitle.Font             = F_BOLD
custTitle.TextXAlignment   = Enum.TextXAlignment.Left
custTitle.Text             = "Personaliza tu Look"
custTitle.ZIndex           = 11
custTitle.Parent           = CustomizePanel

local custSubtitle = Instance.new("TextLabel")
custSubtitle.Size             = UDim2.new(1, -100, 0, 20)
custSubtitle.Position         = UDim2.new(0, 32, 0, 64)
custSubtitle.BackgroundTransparency = 1
custSubtitle.TextColor3       = C.txtSub
custSubtitle.TextSize         = 13
custSubtitle.Font             = F_NORMAL
custSubtitle.TextXAlignment   = Enum.TextXAlignment.Left
custSubtitle.Text             = "Revisa las prendas y accesorios que llevas equipados"
custSubtitle.ZIndex           = 11
custSubtitle.Parent           = CustomizePanel

local btnCustClose = Instance.new("ImageButton")
btnCustClose.Size             = UDim2.new(0, 36, 0, 36)
btnCustClose.Position         = UDim2.new(1, -54, 0, 26)
btnCustClose.BackgroundColor3 = C.bgBtn
btnCustClose.Image            = ICONS.Close
btnCustClose.ImageColor3      = C.txtSub
btnCustClose.BorderSizePixel  = 0
btnCustClose.ZIndex           = 12
uiCorner(btnCustClose, 10)
btnCustClose.Parent = CustomizePanel

local closeScale = Instance.new("UIScale", btnCustClose)
btnCustClose.MouseEnter:Connect(function()
    playHover()
    TweenService:Create(closeScale, T_FAST, {Scale = 1.08}):Play()
    TweenService:Create(btnCustClose, T_FAST, {BackgroundColor3 = C.bgBtnHover, ImageColor3 = C.accent, Rotation = 90}):Play()
end)
btnCustClose.MouseLeave:Connect(function()
    TweenService:Create(closeScale, T_FAST, {Scale = 1}):Play()
    TweenService:Create(btnCustClose, T_FAST, {BackgroundColor3 = C.bgBtn, ImageColor3 = C.txtSub, Rotation = 0}):Play()
end)

local custDivider = Instance.new("Frame")
custDivider.Size             = UDim2.new(1, -64, 0, 1)
custDivider.Position         = UDim2.new(0, 32, 0, 96)
custDivider.BackgroundColor3 = C.border
custDivider.BorderSizePixel  = 0
custDivider.ZIndex           = 11
custDivider.Parent           = CustomizePanel

-- ─── VIEWPORT 3D (Refinado) ──────────────
local previewViewport = Instance.new("ViewportFrame")
previewViewport.Size             = UDim2.new(0, 480, 0, 470)
previewViewport.Position         = UDim2.new(0, 32, 0, 114)
previewViewport.BackgroundColor3 = C.bgCard
previewViewport.BorderSizePixel  = 0
previewViewport.ZIndex           = 11
uiCorner(previewViewport, 18)
local previewViewportStroke = uiStroke(previewViewport, C.border)
previewViewport.Parent = CustomizePanel

local function pulseViewport()
    TweenService:Create(previewViewportStroke, T_FAST, {Color = C.accent}):Play()
    task.delay(0.18, function()
        TweenService:Create(previewViewportStroke, T_MED, {Color = C.border}):Play()
    end)
end

local previewWorldModel = Instance.new("WorldModel")
previewWorldModel.Parent = previewViewport

local previewCamera = Instance.new("Camera")
previewCamera.FieldOfView = 45
previewCamera.Parent = previewViewport
previewViewport.CurrentCamera = previewCamera

local previewHint = Instance.new("TextLabel")
previewHint.Size             = UDim2.new(1, -20, 0, 18)
previewHint.Position         = UDim2.new(0, 14, 0, 12)
previewHint.BackgroundTransparency = 1
previewHint.TextTransparency = 1
previewHint.TextColor3       = C.txtMuted
previewHint.TextSize         = 11
previewHint.Font             = F_NORMAL
previewHint.TextXAlignment   = Enum.TextXAlignment.Left
previewHint.Text             = "  Arrastra para rotar"
previewHint.ZIndex           = 13
previewHint.Parent           = previewViewport

previewViewport.MouseEnter:Connect(function()
    TweenService:Create(previewHint, T_FAST, {TextTransparency = 0.35}):Play()
end)
previewViewport.MouseLeave:Connect(function()
    TweenService:Create(previewHint, T_FAST, {TextTransparency = 1}):Play()
end)

-- Controles de cámara minimalistas (Lenguaje visual sincronizado con HUD)
local viewportControls = Instance.new("Frame")
viewportControls.Size             = UDim2.new(0, 140, 0, 36)
viewportControls.AnchorPoint      = Vector2.new(1, 1)
viewportControls.Position         = UDim2.new(1, -12, 1, -12)
viewportControls.BackgroundTransparency = 1
viewportControls.ZIndex           = 13
viewportControls.Parent           = previewViewport

local vcLayout = Instance.new("UIListLayout")
vcLayout.FillDirection       = Enum.FillDirection.Horizontal
vcLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
vcLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
vcLayout.Padding             = UDim.new(0, 8)
vcLayout.Parent              = viewportControls

local function makeMiniBtn(glyph, order)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 32, 0, 32)
    b.BackgroundColor3 = C.bgBtn
    b.Text             = glyph
    b.TextColor3       = C.txtSub
    b.Font             = F_BOLD
    b.TextSize         = 14
    b.BorderSizePixel  = 0
    b.LayoutOrder      = order
    b.ZIndex           = 14
    uiCorner(b, 10)
    b.Parent = viewportControls
    
    local scale = Instance.new("UIScale", b)

    b.MouseEnter:Connect(function()
        if not b:GetAttribute("Active") then
            playHover()
            TweenService:Create(scale, T_FAST, {Scale = 1.08}):Play()
            TweenService:Create(b, T_FAST, {BackgroundColor3 = C.bgBtnHover, TextColor3 = C.txtMain}):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if not b:GetAttribute("Active") then
            TweenService:Create(scale, T_FAST, {Scale = 1.0}):Play()
            TweenService:Create(b, T_FAST, {BackgroundColor3 = C.bgBtn, TextColor3 = C.txtSub}):Play()
        end
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(scale, T_FAST, {Scale = 0.92}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        playClick()
        TweenService:Create(scale, T_FAST, {Scale = 1.08}):Play()
    end)
    
    return b, scale
end

local btnZoomIn, scIn   = makeMiniBtn("+", 1)
local btnZoomOut, scOut = makeMiniBtn("–", 2)
local btnCamReset, scRst= makeMiniBtn("⟲", 3)
local btnAutoRot, scRot = makeMiniBtn("⟳", 4)

-- ─── LISTA DE ITEMS (Derecha) ───────────────────────
local ROW_H, ROW_GAP = 96, 12

local gridContainer = Instance.new("ScrollingFrame")
gridContainer.Size                   = UDim2.new(0, 540, 0, 470)
gridContainer.Position               = UDim2.new(0, 544, 0, 114)
gridContainer.BackgroundTransparency = 1
gridContainer.BorderSizePixel        = 0
gridContainer.ScrollBarThickness     = 3
gridContainer.ScrollBarImageColor3   = C.txtMuted
gridContainer.CanvasSize             = UDim2.new(0, 0, 0, 0)
gridContainer.ZIndex                 = 11
gridContainer.Parent                 = CustomizePanel

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingRight = UDim.new(0, 10)
gridPadding.PaddingTop   = UDim.new(0, 4)
gridPadding.PaddingBottom= UDim.new(0, 4)
gridPadding.Parent = gridContainer

-- ─── Lógica de Scrollbar Auto-ocultable ───
gridContainer.ScrollBarImageTransparency = 1 -- Transparente por defecto
local scrollFadeTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local hideScrollDelay = 1.2 -- Tiempo de espera antes de desaparecer
local hideScrollTask = nil

local function showScrollbar()
    TweenService:Create(gridContainer, scrollFadeTweenInfo, {ScrollBarImageTransparency = 0}):Play()
    if hideScrollTask then task.cancel(hideScrollTask) end
    hideScrollTask = task.delay(hideScrollDelay, function()
        TweenService:Create(gridContainer, scrollFadeTweenInfo, {ScrollBarImageTransparency = 1}):Play()
    end)
end

-- Detectar interacciones para mostrar la barra
gridContainer.MouseEnter:Connect(showScrollbar)
gridContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(showScrollbar)
-- ──────────────────────────────────────────

local emptyStateContainer = Instance.new("Frame")
emptyStateContainer.Size             = UDim2.new(1, 0, 0, 160)
emptyStateContainer.Position         = UDim2.new(0, 0, 0, 60)
emptyStateContainer.BackgroundTransparency = 1
emptyStateContainer.Visible          = false
emptyStateContainer.ZIndex           = 11
emptyStateContainer.Parent           = gridContainer

local emptyIcon = Instance.new("Frame")
emptyIcon.Size             = UDim2.new(0, 48, 0, 48)
emptyIcon.Position         = UDim2.new(0.5, -24, 0, 0)
emptyIcon.BackgroundTransparency = 1
emptyIcon.ZIndex           = 12
uiCorner(emptyIcon, 24)
uiStroke(emptyIcon, C.border, 1.5)
emptyIcon.Parent = emptyStateContainer

local emptyTitle = Instance.new("TextLabel")
emptyTitle.Size             = UDim2.new(1, -32, 0, 22)
emptyTitle.Position         = UDim2.new(0, 16, 0, 64)
emptyTitle.BackgroundTransparency = 1
emptyTitle.TextColor3       = C.txtSub
emptyTitle.Font             = Enum.Font.GothamMedium
emptyTitle.TextSize         = 15
emptyTitle.Text             = "No llevas ningún objeto equipado"
emptyTitle.ZIndex           = 12
emptyTitle.Parent           = emptyStateContainer

local emptySubtitle = Instance.new("TextLabel")
emptySubtitle.Size             = UDim2.new(1, -32, 0, 18)
emptySubtitle.Position         = UDim2.new(0, 16, 0, 90)
emptySubtitle.BackgroundTransparency = 1
emptySubtitle.TextColor3       = C.txtMuted
emptySubtitle.Font             = F_NORMAL
emptySubtitle.TextSize         = 12
emptySubtitle.Text             = "Prueba un outfit desde uno de los maniquíes"
emptySubtitle.ZIndex           = 12
emptySubtitle.Parent           = emptyStateContainer

-- ─── Lógica Preview 3D ──
local previewModel        = nil
local previewBasePivot    = nil
local previewAngle        = 0
local previewBaseDistance = 6
local previewLookY        = 0
local zoomMultiplier      = 1
local autoRotateEnabled   = true
local isDraggingPreview   = false
local dragStartX          = 0
local dragStartAngle      = 0
local breathTime          = 0

local PREVIEW_ROT_SPEED = 0.3
local ZOOM_MIN, ZOOM_MAX, ZOOM_STEP = 0.55, 1.8, 0.12
local FIT_PADDING   = 1.38  -- Aumentado para dar aire y que el personaje no domine la pantalla
local LOOK_Y_BIAS   = 0.04 
local BREATH_AMPLITUDE = 0.035
local BREATH_SPEED     = 1.1

local function fitCameraToModel()
    if not previewModel then return end
    local ok, cf, size = pcall(function() return previewModel:GetBoundingBox() end)
    if not ok or not size then return end
    local fovRad = math.rad(previewCamera.FieldOfView)
    previewBaseDistance = (size.Y / 2) / math.tan(fovRad / 2) * FIT_PADDING
    previewLookY = cf.Position.Y + (size.Y * LOOK_Y_BIAS)
end

local function loadPreviewCharacter()
    if previewModel then previewModel:Destroy() end
    local char = player.Character
    if not char then return end

    local originalArchivable = char.Archivable
    char.Archivable = true
    local clone = char:Clone()
    char.Archivable = originalArchivable
    if not clone then return end

    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored   = true
            d.CanCollide = false
        end
    end

    clone.Parent = previewWorldModel
    previewModel = clone

    zoomMultiplier = 1
    fitCameraToModel()
    previewBasePivot = previewModel:GetPivot()
    breathTime = 0
end

RunService.RenderStepped:Connect(function(dt)
    if not previewModel or not CustomizePanel.Visible then return end
    local root = previewModel:FindFirstChild("HumanoidRootPart") or previewModel.PrimaryPart
    if not root then return end

    if autoRotateEnabled and not isDraggingPreview then
        previewAngle += dt * PREVIEW_ROT_SPEED
    end

    breathTime += dt * BREATH_SPEED
    if previewBasePivot then
        local breathOffset = math.sin(breathTime) * BREATH_AMPLITUDE
        previewModel:PivotTo(previewBasePivot + Vector3.new(0, breathOffset, 0))
    end

    local distance   = previewBaseDistance * zoomMultiplier
    local lookCenter = Vector3.new(root.Position.X, previewLookY, root.Position.Z)
    local camX       = root.Position.X + math.sin(previewAngle) * distance
    local camZ       = root.Position.Z + math.cos(previewAngle) * distance

    previewCamera.CFrame = CFrame.new(Vector3.new(camX, previewLookY, camZ), lookCenter)
end)

previewViewport.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingPreview = true
        dragStartX        = input.Position.X
        dragStartAngle    = previewAngle
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingPreview and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position.X - dragStartX
        previewAngle = dragStartAngle - delta * 0.01
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingPreview = false
    end
end)

btnZoomIn.MouseButton1Click:Connect(function() zoomMultiplier = math.clamp(zoomMultiplier - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX) end)
btnZoomOut.MouseButton1Click:Connect(function() zoomMultiplier = math.clamp(zoomMultiplier + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX) end)
btnCamReset.MouseButton1Click:Connect(function() zoomMultiplier = 1 previewAngle = 0 end)

local function refreshAutoRotButton()
    btnAutoRot:SetAttribute("Active", autoRotateEnabled)
    TweenService:Create(btnAutoRot, T_FAST, {
        BackgroundColor3 = autoRotateEnabled and C.accent or C.bgBtn,
        TextColor3       = autoRotateEnabled and C.bgBase or C.txtSub,
    }):Play()
end
btnAutoRot.MouseButton1Click:Connect(function()
    autoRotateEnabled = not autoRotateEnabled
    refreshAutoRotButton()
end)
refreshAutoRotButton()

-- ─── Highlight (Sin cambios estructurales) ──
local SHIRT_PARTS = {"UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "Torso", "Left Arm", "Right Arm"}
local PANTS_PARTS = {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Left Leg", "Right Leg"}
local highlightPool = {}
for i = 1, 10 do
    local h = Instance.new("Highlight")
    h.FillColor = C.accent h.FillTransparency = 1 h.OutlineColor = C.accent h.OutlineTransparency = 1 h.Enabled = false h.Parent = previewWorldModel
    table.insert(highlightPool, h)
end

local function resolveHighlightTargets(item)
    if not previewModel then return {} end
    local targets = {}
    if item.itemType == "Shirt" then
        for _, name in ipairs(SHIRT_PARTS) do
            local p = previewModel:FindFirstChild(name)
            if p and p:IsA("BasePart") then table.insert(targets, p) end
        end
    elseif item.itemType == "Pants" then
        for _, name in ipairs(PANTS_PARTS) do
            local p = previewModel:FindFirstChild(name)
            if p and p:IsA("BasePart") then table.insert(targets, p) end
        end
    elseif item.itemType == "Accessory" then
        local acc = previewModel:FindFirstChild(item.name)
        local handle = acc and acc:FindFirstChild("Handle")
        if handle then table.insert(targets, handle) end
    end
    return targets
end

local function showHighlight(targets)
    for i, part in ipairs(targets) do
        local h = highlightPool[i]
        if h then
            h.Adornee = part h.Enabled = true h.FillTransparency = 1 h.OutlineTransparency = 1
            TweenService:Create(h, T_FAST, {FillTransparency = 0.75, OutlineTransparency = 0.15}):Play()
        end
    end
end
local function hideHighlight()
    for _, h in ipairs(highlightPool) do
        if h.Enabled then TweenService:Create(h, T_FAST, {FillTransparency = 1, OutlineTransparency = 1}):Play() end
    end
    task.delay(0.15, function()
        for _, h in ipairs(highlightPool) do h.Enabled = false h.Adornee = nil end
    end)
end

-- ─── Escaneo ──
local equippedItems = {}
local function scanEquippedItems()
    equippedItems = {}
    local char = player.Character
    if not char then return end

    local shirt = char:FindFirstChildOfClass("Shirt")
    if shirt then table.insert(equippedItems, {itemType = "Shirt", name = "Camisa", assetId = shirt.ShirtTemplate:match("%d+"), owned = not shirt:GetAttribute("FromOutfit")}) end

    local pants = char:FindFirstChildOfClass("Pants")
    if pants then table.insert(equippedItems, {itemType = "Pants", name = "Pantalón", assetId = pants.PantsTemplate:match("%d+"), owned = not pants:GetAttribute("FromOutfit")}) end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            local mesh   = handle and (handle:FindFirstChildOfClass("SpecialMesh") or handle:FindFirstChildOfClass("MeshPart"))
            local assetId = mesh and mesh.MeshId and mesh.MeshId:match("%d+")
            table.insert(equippedItems, {itemType = "Accessory", name = child.Name, assetId = assetId, owned = not child:GetAttribute("FromOutfit")})
        end
    end
end

-- ─── Tarjeta con interactividad pulida (UIScale + Diseño sin bordes blancos) ──
local function buildItemCard(item, targetY, staggerDelay)
    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, 0, 0, ROW_H)
    card.Position               = UDim2.new(0, 0, 0, targetY + 10)
    card.BackgroundColor3       = C.bgCard
    card.BackgroundTransparency = 1
    card.BorderSizePixel        = 0
    card.ZIndex                 = 12
    card:SetAttribute("BaseY", targetY)
    uiCorner(card, 14)
    
    local cardScale = Instance.new("UIScale", card)
    local cardStroke = uiStroke(card, C.border)
    cardStroke.Transparency = 1
    card.Parent = gridContainer

    local img = Instance.new("ImageLabel")
    img.Size              = UDim2.new(0, 64, 0, 64)
    img.Position          = UDim2.new(0, 16, 0.5, -32)
    img.BackgroundColor3  = C.bgBase
    img.ScaleType         = Enum.ScaleType.Fit
    img.ImageTransparency = 1
    img.Image             = item.assetId and ("rbxthumb://type=Asset&id=" .. item.assetId .. "&w=150&h=150") or ""
    img.ZIndex            = 13
    uiCorner(img, 10)
    img.Parent = card

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size              = UDim2.new(1, -260, 0, 22)
    nameLbl.Position          = UDim2.new(0, 96, 0, 24)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextTransparency  = 1
    nameLbl.TextColor3        = C.txtMain
    nameLbl.Font              = Enum.Font.GothamMedium
    nameLbl.TextSize          = 16
    nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
    nameLbl.TextTruncate      = Enum.TextTruncate.AtEnd
    nameLbl.Text              = item.name
    nameLbl.ZIndex            = 13
    nameLbl.Parent            = card

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size              = UDim2.new(1, -260, 0, 16)
    statusLbl.Position          = UDim2.new(0, 96, 0, 50)
    statusLbl.BackgroundTransparency = 1
    statusLbl.TextTransparency  = 1
    statusLbl.TextColor3        = C.txtSub
    statusLbl.Font              = F_NORMAL
    statusLbl.TextSize          = 12
    statusLbl.TextXAlignment    = Enum.TextXAlignment.Left
    statusLbl.Text              = item.owned and "En inventario" or "Vista previa"
    statusLbl.ZIndex            = 13
    statusLbl.Parent            = card

    local actionBtn = Instance.new("TextButton")
    actionBtn.Size              = UDim2.new(0, 120, 0, 40)
    actionBtn.AnchorPoint       = Vector2.new(1, 0.5)
    actionBtn.Position          = UDim2.new(1, -16, 0.5, 0)
    local C_REMOVE_IDLE  = Color3.fromRGB(48, 48, 52) -- Gris sutil para separar de la tarjeta
    local C_REMOVE_HOVER = Color3.fromRGB(65, 65, 70) -- Hover equilibrado
    
    actionBtn.BackgroundColor3  = item.owned and C_REMOVE_IDLE or C.buyGreen
    actionBtn.BackgroundTransparency = 1
    actionBtn.Text              = item.owned and "QUITAR" or "COMPRAR"
    actionBtn.TextTransparency  = 1
    actionBtn.TextColor3        = item.owned and C.txtMain or Color3.new(1, 1, 1)
    actionBtn.Font              = F_BOLD
    actionBtn.TextSize          = 13
    actionBtn.BorderSizePixel   = 0
    actionBtn.ZIndex            = 14
    uiCorner(actionBtn, 10)
    if item.owned then uiStroke(actionBtn, C.border) end
    actionBtn.Parent = card

    local actionBtnScale = Instance.new("UIScale", actionBtn)

    task.delay(staggerDelay or 0, function()
        if not card or not card.Parent then return end
        TweenService:Create(card, T_MED, { Position = UDim2.new(0, 0, 0, targetY), BackgroundTransparency = 0 }):Play()
        TweenService:Create(cardStroke, T_MED, {Transparency = 0.4}):Play()
        TweenService:Create(actionBtn, T_MED, {BackgroundTransparency = 0}):Play()
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then TweenService:Create(d, T_MED, {TextTransparency = 0}):Play()
            elseif d:IsA("ImageLabel") then TweenService:Create(d, T_MED, {ImageTransparency = 0}):Play() end
        end
    end)

    -- Animación de Hover Elegante (Corrección de bordes cortados)
    card.MouseEnter:Connect(function()
        playHover()
        TweenService:Create(cardScale, T_FAST, {Scale = 1.015}):Play()
        TweenService:Create(card, T_FAST, {BackgroundColor3 = C.bgBtnHover}):Play()
        showHighlight(resolveHighlightTargets(item))
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(cardScale, T_FAST, {Scale = 1.0}):Play()
        TweenService:Create(card, T_FAST, {BackgroundColor3 = C.bgCard}):Play()
        hideHighlight()
    end)

    -- Interacción Premium del Botón
    actionBtn.MouseEnter:Connect(function()
        playHover()
        TweenService:Create(actionBtnScale, T_FAST, {Scale = 1.05}):Play()
        TweenService:Create(actionBtn, T_FAST, {
            BackgroundColor3 = item.owned and C_REMOVE_HOVER or C.buyGreenHover
        }):Play()
    end)
    
    actionBtn.MouseLeave:Connect(function()
        TweenService:Create(actionBtnScale, T_FAST, {Scale = 1.0}):Play()
        TweenService:Create(actionBtn, T_FAST, {
            BackgroundColor3 = item.owned and C_REMOVE_IDLE or C.buyGreen
        }):Play()
    end)

    actionBtn.MouseButton1Down:Connect(function()
        TweenService:Create(actionBtnScale, T_FAST, {Scale = 0.94}):Play()
    end)

    actionBtn.MouseButton1Click:Connect(function()
        if not actionBtn.Active then return end
        actionBtn.Active = false
        TweenService:Create(actionBtnScale, T_FAST, {Scale = 1.05}):Play()

        if item.owned then
            playSoundRemove()
            
            -- UI Optimista: Comienza animación de salida antes de respuesta del servidor
            TweenService:Create(cardScale, T_FAST, {Scale = 0.85}):Play()
            TweenService:Create(card, T_FAST, {BackgroundTransparency = 1}):Play()
            TweenService:Create(cardStroke, T_FAST, {Transparency = 1}):Play()

            TweenService:Create(actionBtn, T_FAST, {BackgroundTransparency = 1}):Play()
            
            for _, d in ipairs(card:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then TweenService:Create(d, T_FAST, {TextTransparency = 1}):Play()
                elseif d:IsA("ImageLabel") then TweenService:Create(d, T_FAST, {ImageTransparency = 1}):Play() end
            end

            if RemoveItem then RemoveItem:FireServer(item.itemType, item.name) end
            showToast(item.name .. " quitado", "neutral", 2)
        else
            playClick()
            playSoundBuy()
            if item.assetId and BuyOutfit then
                BuyOutfit:FireServer(tonumber(item.assetId))
                showToast("Abriendo tienda...", "info", 2.5)
            end
            task.delay(0.6, function()
                if actionBtn and actionBtn.Parent then actionBtn.Active = true end
            end)
        end
    end)

    return card
end

-- ─── Reconciliación ──
local activeCards = {}
local function cardKeyFor(item) return item.itemType == "Accessory" and ("Accessory:" .. item.name) or item.itemType end

local function reconcileItemsGrid()
    scanEquippedItems()
    local newItemsByKey, orderedKeys = {}, {}
    for _, item in ipairs(equippedItems) do
        local key = cardKeyFor(item)
        newItemsByKey[key] = item
        table.insert(orderedKeys, key)
    end

    for key, card in pairs(activeCards) do
        if not newItemsByKey[key] then
            local cardScale = card:FindFirstChild("UIScale")
            if cardScale then TweenService:Create(cardScale, T_FAST, {Scale = 0.8}):Play() end
            TweenService:Create(card, T_FAST, { BackgroundTransparency = 1 }):Play()
            for _, d in ipairs(card:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then TweenService:Create(d, T_FAST, {TextTransparency = 1}):Play()
                elseif d:IsA("ImageLabel") then TweenService:Create(d, T_FAST, {ImageTransparency = 1}):Play() end
            end
            local cardRef = card
            task.delay(0.2, function() if cardRef then cardRef:Destroy() end end)
            activeCards[key] = nil
        end
    end

    local staggerIndex = 0
    for index, key in ipairs(orderedKeys) do
        local targetY = (index - 1) * (ROW_H + ROW_GAP)
        local existing = activeCards[key]

        if existing then
            if existing:GetAttribute("BaseY") ~= targetY then
                existing:SetAttribute("BaseY", targetY)
                TweenService:Create(existing, T_MED, {Position = UDim2.new(0, 0, 0, targetY)}):Play()
            end
        else
            staggerIndex += 1
            activeCards[key] = buildItemCard(newItemsByKey[key], targetY, (staggerIndex - 1) * 0.03)
        end
    end

    emptyStateContainer.Visible = (#orderedKeys == 0)
    gridContainer.CanvasSize = UDim2.new(0, 0, 0, #orderedKeys > 0 and (#orderedKeys * (ROW_H + ROW_GAP)) or 0)
end

-- ─── Detección ──
local function watchCharacterForCustomize(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("Accessory") then
            task.wait(0.1)
            if activeMenu == "Customize" then reconcileItemsGrid() pulseViewport() end
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("Accessory") then
            if activeMenu == "Customize" then reconcileItemsGrid() end
        end
    end)
end

if player.Character then watchCharacterForCustomize(player.Character) end
player.CharacterAdded:Connect(function(char)
    watchCharacterForCustomize(char)
    task.wait(0.5)
    if activeMenu == "Customize" then loadPreviewCharacter() end
end)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 4] MENU CONFIRMACIÓN DE RESET
-- ══════════════════════════════════════════════════════════════
local RW, RH     = 380, 220
local RESET_HIDE = UDim2.new(0.5, -RW/2, 1.5, 0)
local RESET_SHOW = UDim2.new(0.5, -RW/2, 0.5, -RH/2)

local ResetConfirmPanel = Instance.new("Frame")
ResetConfirmPanel.Name             = "ResetConfirmPanel"
ResetConfirmPanel.Size             = UDim2.new(0, RW, 0, RH)
ResetConfirmPanel.Position         = RESET_HIDE
ResetConfirmPanel.BackgroundColor3 = C.bgBase
ResetConfirmPanel.BorderSizePixel  = 0
ResetConfirmPanel.ZIndex           = 15
uiCorner(ResetConfirmPanel, 18)
uiStroke(ResetConfirmPanel, C.border, 1.5)
ResetConfirmPanel.Parent = GUI

local rcTitle = Instance.new("TextLabel")
rcTitle.Size             = UDim2.new(1, -48, 0, 28)
rcTitle.Position         = UDim2.new(0, 24, 0, 24)
rcTitle.BackgroundTransparency = 1
rcTitle.TextColor3       = C.txtMain
rcTitle.Font             = F_BOLD
rcTitle.TextSize         = 19
rcTitle.TextXAlignment   = Enum.TextXAlignment.Left
rcTitle.Text             = "¿Resetear tu avatar?"
rcTitle.ZIndex           = 16
rcTitle.Parent           = ResetConfirmPanel

local rcSubtitle = Instance.new("TextLabel")
rcSubtitle.Size             = UDim2.new(1, -48, 0, 40)
rcSubtitle.Position         = UDim2.new(0, 24, 0, 56)
rcSubtitle.BackgroundTransparency = 1
rcSubtitle.TextColor3       = C.txtSub
rcSubtitle.Font             = F_NORMAL
rcSubtitle.TextSize         = 13
rcSubtitle.TextWrapped      = true
rcSubtitle.TextXAlignment   = Enum.TextXAlignment.Left
rcSubtitle.Text             = "Perderás cualquier prenda que te hayas probado y volverás a tu apariencia original."
rcSubtitle.ZIndex           = 16
rcSubtitle.Parent           = ResetConfirmPanel

local btnRcCancel = Instance.new("TextButton")
btnRcCancel.Size             = UDim2.new(0, 160, 0, 46)
btnRcCancel.Position         = UDim2.new(0, 24, 1, -70)
btnRcCancel.BackgroundColor3 = C.bgBtn
btnRcCancel.Text             = "CANCELAR"
btnRcCancel.TextColor3       = C.txtMain
btnRcCancel.Font             = F_BOLD
btnRcCancel.TextSize         = 13
btnRcCancel.BorderSizePixel  = 0
btnRcCancel.ZIndex           = 16
uiCorner(btnRcCancel, 10)
uiStroke(btnRcCancel, C.border)
btnRcCancel.Parent = ResetConfirmPanel

local btnRcConfirm = Instance.new("TextButton")
btnRcConfirm.Size             = UDim2.new(0, 160, 0, 46)
btnRcConfirm.Position         = UDim2.new(1, -184, 1, -70)
btnRcConfirm.BackgroundColor3 = C.accent
btnRcConfirm.Text             = "SÍ, RESETEAR"
btnRcConfirm.TextColor3       = C.bgBase
btnRcConfirm.Font             = F_BOLD
btnRcConfirm.TextSize         = 13
btnRcConfirm.BorderSizePixel  = 0
btnRcConfirm.ZIndex           = 16
uiCorner(btnRcConfirm, 10)
btnRcConfirm.Parent = ResetConfirmPanel

btnRcCancel.MouseEnter:Connect(function()
    playHover()
    TweenService:Create(btnRcCancel, T_FAST, {BackgroundColor3 = C.bgBtnHover}):Play()
end)
btnRcCancel.MouseLeave:Connect(function()
    TweenService:Create(btnRcCancel, T_FAST, {BackgroundColor3 = C.bgBtn}):Play()
end)
btnRcConfirm.MouseEnter:Connect(function()
    playHover()
    TweenService:Create(btnRcConfirm, T_FAST, {BackgroundColor3 = C.accentHover}):Play()
end)
btnRcConfirm.MouseLeave:Connect(function()
    TweenService:Create(btnRcConfirm, T_FAST, {BackgroundColor3 = C.accent}):Play()
end)

-- ══════════════════════════════════════════════════════════════
--  CONTROL INTERACTIVO GLOBAL (MODALES)
-- ══════════════════════════════════════════════════════════════
local function closeAllMenus()
    if not activeMenu then return end
    playSoundClose()
    blurOut()
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 1}):Play()

    if activeMenu == "Settings" then
        TweenService:Create(SetPanel, T_SLOW, {Position = SET_HIDE}):Play()
    elseif activeMenu == "Outfit" then
        TweenService:Create(Panel, T_SLOW, {Position = POS_HIDE}):Play()
    elseif activeMenu == "Customize" then
        TweenService:Create(CustomizePanel, T_SLOW, {Position = CUSTOM_HIDE}):Play()
    elseif activeMenu == "ResetConfirm" then
        TweenService:Create(ResetConfirmPanel, T_SLOW, {Position = RESET_HIDE}):Play()
    end

    task.delay(0.4, function() Backdrop.Visible = false end)
    activeMenu = nil
end

local function openMenu(menuType, data)
    closeAllMenus()
    activeMenu = menuType
    playSoundOpen()
    Backdrop.Visible = true
    blurIn()
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 0.3}):Play()

    if menuType == "Settings" then
        TweenService:Create(SetPanel, T_MED, {Position = SET_SHOW}):Play()

    elseif menuType == "Outfit" and data then
        lblName.Text = data.name or "Look Desconocido"
        local sid = data.shirt or 0
        local pid = data.pants or 0
        shirtImg.Image  = sid ~= 0 and ("rbxthumb://type=Asset&id=" .. sid .. "&w=150&h=150") or ""
        shirtIdLbl.Text = sid ~= 0 and ("ID: " .. sid) or "Vacante"
        pantsImg.Image  = pid ~= 0 and ("rbxthumb://type=Asset&id=" .. pid .. "&w=150&h=150") or ""
        pantsIdLbl.Text = pid ~= 0 and ("ID: " .. pid) or "Vacante"
        TweenService:Create(Panel, T_MED, {Position = POS_SHOW}):Play()

    elseif menuType == "Customize" then
        loadPreviewCharacter()
        reconcileItemsGrid()
        CustomizePanel.Position = CUSTOM_SHOW
        TweenService:Create(CustomizePanel, T_MED, {Position = CUSTOM_SHOW}):Play()

    elseif menuType == "ResetConfirm" then
        TweenService:Create(ResetConfirmPanel, T_MED, {Position = RESET_SHOW}):Play()
    end
end

btnSettings.MouseButton1Click:Connect(function()
    if activeMenu == "Settings" then closeAllMenus() else openMenu("Settings") end
end)
btnCustomize.MouseButton1Click:Connect(function()
    if activeMenu == "Customize" then closeAllMenus() else openMenu("Customize") end
end)

btnSetClose.MouseButton1Click:Connect(closeAllMenus)
btnClose.MouseButton1Click:Connect(closeAllMenus)
btnCustClose.MouseButton1Click:Connect(closeAllMenus)
btnRcCancel.MouseButton1Click:Connect(function()
    playClick()
    closeAllMenus()
end)

btnRcConfirm.MouseButton1Click:Connect(function()
    playClick()
    ResetAvatar:FireServer()
    TweenService:Create(btnRcConfirm, T_FAST, {BackgroundColor3 = C.success}):Play()
    showToast("Avatar reseteado", "neutral", 2)
    task.delay(0.15, function() closeAllMenus() end)
end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Escape then closeAllMenus() end
end)

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
    showToast("Abriendo tienda...", "info", 2.5)
end)

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
            pants       = mannequin:GetAttribute("PantsId"),
        }
        openMenu("Outfit", activeOutfitData)
    end)
end

local workspaceMannequins = workspace:FindFirstChild("Mannequins")
if workspaceMannequins then
    for _, m in ipairs(workspaceMannequins:GetChildren()) do connectMannequin(m) end
    workspaceMannequins.ChildAdded:Connect(connectMannequin)
end