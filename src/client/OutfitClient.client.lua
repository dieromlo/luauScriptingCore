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
--  SISTEMA DE AUDIO UI
--  Todos los sonidos ahora viven en SoundKit.lua. Cree el alias
--  con los mismos nombres de siempre para no tener que tocar
--  las decenas de MouseEnter/MouseButton1Click que ya los usan
-- ══════════════════════════════════════════════════════════════
local SoundKit = require(script.Parent.modules.SoundKit)
SoundKit.Init()

local MenuManager = require(script.Parent.modules.MenuManager)
local ResetConfirmPanel = require(script.Parent.modules.ResetConfirmPanel)
local function openMenu(name, data) MenuManager.Open(name, data) end
local function closeAllMenus() MenuManager.CloseAll() end
-- Lo hago aquí arriba, porque el botón de Reset (más abajo
-- en este mismo archivo) necesita leer MenuManager.GetActive()
-- antes de llegar a la sección donde configuramos los paneles

local function playHover()       SoundKit.PlayHover()  end
local function playClick()       SoundKit.PlayClick()  end
local function playSoundBuy()    SoundKit.PlayBuy()    end
local function playSoundRemove() SoundKit.PlayRemove() end
local function playSoundOpen()   SoundKit.PlayOpen()   end
local function playSoundClose()  SoundKit.PlayClose()  end

-- ══════════════════════════════════════════════════════════════
--  UI KIT COMPARTIDO
--  Antes estos valores se declaraban aquí mismo; ahora viven en
--  un ModuleScript para que otros paneles (que vamos a separar
--  en las próximas etapas) puedan usar exactamente los mismos
--  colores/fuentes/animaciones sin duplicar codigo
-- ══════════════════════════════════════════════════════════════
local UIKit = require(script.Parent.modules.UIKit)

local C           = UIKit.C
local F_BOLD      = UIKit.F_BOLD
local F_NORMAL    = UIKit.F_NORMAL
local T_FAST      = UIKit.T_FAST
local T_MED       = UIKit.T_MED
local T_SLOW      = UIKit.T_SLOW
local ICONS       = UIKit.ICONS
local uiCorner    = UIKit.uiCorner
local uiStroke    = UIKit.uiStroke

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
-- ══════════════════════════════════════════════════════════════
local ToastSystem = require(script.Parent.modules.ToastSystem)
ToastSystem.Init(GUI)

local function showToast(message, toastType, duration)
    ToastSystem.Show(message, toastType, duration)
end

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
    if MenuManager.GetActive() == "ResetConfirm" then closeAllMenus() else openMenu("ResetConfirm") end
end)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 1] SETTINGS PANEL
-- ══════════════════════════════════════════════════════════════
local SettingsPanel = require(script.Parent.modules.SettingsPanel)
SettingsPanel.Init(GUI)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 2] OUTFIT PANEL
-- ══════════════════════════════════════════════════════════════
local OutfitViewerPanel = require(script.Parent.modules.OutfitViewerPanel)
OutfitViewerPanel.Init(GUI, TryOnOutfit, BuyOutfit, showToast)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 3] CUSTOMIZE PANEL
-- ══════════════════════════════════════════════════════════════
local CustomizePanel = require(script.Parent.modules.CustomizePanel)
CustomizePanel.Init(GUI, RemoveItem, BuyOutfit, showToast)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 4] MENU CONFIRMACIÓN DE RESET
-- ══════════════════════════════════════════════════════════════   
ResetConfirmPanel.Init(GUI, ResetAvatar, showToast)

-- ══════════════════════════════════════════════════════════════
--  CONTROL INTERACTIVO GLOBAL (MODALES)
--  Delegado a MenuManager. Cada panel se registra con su propia
--  función de mostrar/ocultar.
-- ══════════════════════════════════════════════════════════════
MenuManager.Init({
    backdrop     = Backdrop,
    blurIn       = blurIn,
    blurOut      = blurOut,
    tweenMed     = T_MED,
    onOpenSound  = playSoundOpen,
    onCloseSound = playSoundClose,
})

btnSettings.MouseButton1Click:Connect(function()
    if MenuManager.GetActive() == "Settings" then closeAllMenus() else openMenu("Settings") end
end)
btnCustomize.MouseButton1Click:Connect(function()
    if MenuManager.GetActive() == "Customize" then closeAllMenus() else openMenu("Customize") end
end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Escape then closeAllMenus() end
end)