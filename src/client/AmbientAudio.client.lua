-- ============================================================
--  AmbientAudio.client.lua
--  LocalScript | StarterPlayerScripts
--  Música ambiente y efectos de sonido del entorno.
-- ============================================================

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- ─── Configuración ────────────────────────────────────────────
-- ID verificado de la librería de Roblox (Dark Ambient Tension)
local AMBIENT_TRACK_ID = "rbxassetid://9112795583"
local AMBIENT_VOLUME   = 0.18   -- sutil, no invasivo
local FADE_TIME        = 3.5    -- segundos de fade in al entrar

-- ─── Crear carpeta de audio ────────────────────────────────────
local audioFolder = SoundService:FindFirstChild("InfectedMemories_Ambient")
if not audioFolder then
    audioFolder = Instance.new("Folder")
    audioFolder.Name   = "InfectedMemories_Ambient"
    audioFolder.Parent = SoundService
end

-- ─── Pista principal (Corregido para evitar el nil error) ──────
local ambientTrack = audioFolder:FindFirstChild("MainAmbient")
if not ambientTrack then
    ambientTrack = Instance.new("Sound")
    ambientTrack.Name          = "MainAmbient"
    ambientTrack.SoundId       = AMBIENT_TRACK_ID
    ambientTrack.Volume        = 0          -- empieza silenciosa
    ambientTrack.Looped        = true
    ambientTrack.RollOffMaxDistance = 10000
    ambientTrack.Parent        = audioFolder
end

-- ─── Fade in al cargar ────────────────────────────────────────
local function startAmbient()
    ambientTrack:Play()
    
    TweenService:Create(
        ambientTrack,
        TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = AMBIENT_VOLUME}
    ):Play()
    
    print("[AmbientAudio] ✅ Música ambiente iniciada correctamente.")
end

-- Aseguramos la reproducción ignorando bloqueos de carga de Roblox
task.spawn(function()
    if ambientTrack.IsLoaded then
        startAmbient()
    else
        ambientTrack.Loaded:Connect(startAmbient)
        -- Salvaguarda: si el evento tarda más de 1 segundo, forzamos el Play
        task.wait(1)
        if not ambientTrack.IsPlaying then 
            startAmbient() 
        end
    end
end)

-- ─── API pública para que OutfitClient pueda mutear ───────────
_G.InfectedAudio = {
    setVolume = function(vol)
        TweenService:Create(
            ambientTrack,
            TweenInfo.new(1, Enum.EasingStyle.Quad),
            {Volume = vol}
        ):Play()
    end,
    mute = function()
        TweenService:Create(ambientTrack, TweenInfo.new(1), {Volume = 0}):Play()
    end,
    unmute = function()
        TweenService:Create(ambientTrack, TweenInfo.new(1), {Volume = AMBIENT_VOLUME}):Play()
    end,
}