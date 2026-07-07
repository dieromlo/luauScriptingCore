-- ============================================================
--  SoundKit.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Todos los sonidos de la interfaz en un un solo archivo
-- ============================================================

local SoundService = game:GetService("SoundService")

local SoundKit = {}

local uiSounds
local sonidosActivos = true

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

local sndHover, sndClick, sndBuy, sndRemove, sndOpen, sndClose

function SoundKit.Init()
    uiSounds = SoundService:FindFirstChild("InfectedMemories_UISounds")
    if not uiSounds then
        uiSounds = Instance.new("Folder")
        uiSounds.Name = "InfectedMemories_UISounds"
        uiSounds.Parent = SoundService
    end

    sndHover  = getOrCreateSound("Hover",     "6895079853", 0.5,  1.2)
    sndClick  = getOrCreateSound("Click",     "6895079853", 0.5,  1.0)
    sndBuy    = getOrCreateSound("Buy",       "6895079853", 0.45, 1.35)
    sndRemove = getOrCreateSound("Remove",    "6895079853", 0.40, 0.75)
    sndOpen   = getOrCreateSound("MenuOpen",  "6895079853", 0.35, 0.90)
    sndClose  = getOrCreateSound("MenuClose", "6895079853", 0.30, 0.65)
end

function SoundKit.SetEnabled(state) sonidosActivos = state end
function SoundKit.IsEnabled() return sonidosActivos end

function SoundKit.PlayHover()  if sonidosActivos and sndHover.IsLoaded  then sndHover:Play()  end end
function SoundKit.PlayClick()  if sonidosActivos and sndClick.IsLoaded  then sndClick:Play()  end end
function SoundKit.PlayBuy()    if sonidosActivos and sndBuy.IsLoaded    then sndBuy:Play()    end end
function SoundKit.PlayRemove() if sonidosActivos and sndRemove.IsLoaded then sndRemove:Play() end end
function SoundKit.PlayOpen()   if sonidosActivos and sndOpen.IsLoaded   then sndOpen:Play()   end end
function SoundKit.PlayClose()  if sonidosActivos and sndClose.IsLoaded  then sndClose:Play()  end end

return SoundKit