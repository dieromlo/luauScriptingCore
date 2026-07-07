-- ============================================================
--  MenuManager.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Registro genérico de paneles. No conoce los nombres de los
--  paneles del juego — cada uno se registra con su propia
--  función de mostrar y ocultar.
-- ============================================================

local TweenService = game:GetService("TweenService")

local MenuManager = {}

local Backdrop
local blurIn, blurOut
local T_MED
local onOpenSound, onCloseSound

local activeMenu = nil
local registeredMenus = {}

-- Se llama UNA VEZ desde OutfitClient, pasándole las piezas
-- compartidas que todo panel necesita (fondo oscuro, blur, sonido)
function MenuManager.Init(config)
    Backdrop     = config.backdrop
    blurIn       = config.blurIn
    blurOut      = config.blurOut
    T_MED        = config.tweenMed
    onOpenSound  = config.onOpenSound
    onCloseSound = config.onCloseSound
end

-- Cada panel llama esto durante su propia inicialización
function MenuManager.Register(name, showFn, hideFn)
    registeredMenus[name] = {show = showFn, hide = hideFn}
end

function MenuManager.GetActive()
    return activeMenu
end

function MenuManager.CloseAll()
    if not activeMenu then return end
    if onCloseSound then onCloseSound() end
    blurOut()
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 1}):Play()

    local entry = registeredMenus[activeMenu]
    if entry and entry.hide then entry.hide() end

    task.delay(0.4, function() Backdrop.Visible = false end)
    activeMenu = nil
end

function MenuManager.Open(name, data)
    MenuManager.CloseAll()

    local entry = registeredMenus[name]
    if not entry then
        warn("[MenuManager] ⚠️ Menú no registrado: " .. tostring(name))
        return
    end

    activeMenu = name
    if onOpenSound then onOpenSound() end
    Backdrop.Visible = true
    blurIn()
    TweenService:Create(Backdrop, T_MED, {BackgroundTransparency = 0.3}):Play()

    entry.show(data)
end

function MenuManager.Toggle(name, data)
    if activeMenu == name then
        MenuManager.CloseAll()
    else
        MenuManager.Open(name, data)
    end
end

return MenuManager