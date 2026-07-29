-- ============================================================
--  OutfitClient.client.lua
--  LocalScript | StarterPlayerScripts
--  UI Premium: Horizontal Dock HUD + Adaptive Menus
-- ============================================================

print("[OutfitClient] Script Iniciado con éxito")

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
--  HUD DOCK
-- ══════════════════════════════════════════════════════════════
local HudDock = require(script.Parent.modules.HudDock)
HudDock.Init(GUI)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 1] SETTINGS PANEL
-- ══════════════════════════════════════════════════════════════
local SettingsPanel = require(script.Parent.modules.SettingsPanel)
SettingsPanel.Init(GUI)

-- ══════════════════════════════════════════════════════════════
--  [MODAL 2] OUTFIT PANEL
-- ══════════════════════════════════════════════════════════════
local OutfitService = require(script.Parent.modules.OutfitService)
OutfitService.Init({ tryOn = TryOnOutfit, buy = BuyOutfit })

local OutfitViewerPanel = require(script.Parent.modules.OutfitViewerPanel)
OutfitViewerPanel.Init(GUI, showToast)

local MannequinInteraction = require(script.Parent.modules.MannequinInteraction)
MannequinInteraction.Init()
MannequinInteraction.OnInteract(function(mannequin, player)
    MenuManager.Open("Outfit", { id = mannequin:GetAttribute("OutfitId") })
end)

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

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Escape then closeAllMenus() end
end)