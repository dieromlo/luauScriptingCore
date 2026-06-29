-- ============================================================
--  AmbientAudio.client.lua
--  LocalScript | StarterPlayerScripts
--  Música ambiente y efectos de sonido del entorno.
-- ============================================================

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- ─── Configuración ────────────────────────────────────────────
-- Pon aquí el Asset ID de la música que quieras de fondo.
-- Busca en Roblox "free ambient music dark" en la Toolbox
-- o usa uno de la biblioteca gratuita de Roblox.
local AMBIENT_TRACK_ID = "rbxassetid://1843671275" -- dark ambient loop (gratuito)
local AMBIENT_VOLUME   = 0.18  -- sutil, no invasivo
local FADE_TIME        = 3.5   -- segundos de fade in al entrar

-- ─── Crear carpeta de audio ────────────────────────────────────
local audioFolder = SoundService:FindFirstChild("InfectedMemories_Ambient")
if not audioFolder then
    audioFolder = Instance.new("Folder")
    audioFolder.Name   = "InfectedMemories_Ambient"
    audioFolder.Parent = SoundService
end

-- ─── Pista principal ──────────────────────────────────────────
local ambientTrack = Instance.new("Sound")
ambientTrack.Name          = "MainAmbient"
ambientTrack.SoundId       = AMBIENT_TRACK_ID
ambientTrack.Volume        = 0          -- empieza silenciosa
ambientTrack.Looped        = true
ambientTrack.RollOffMaxDistance = 10000 -- se escucha en todo el mapa
ambientTrack.Parent        = audioFolder

-- ─── Fade in al cargar ────────────────────────────────────────
local function startAmbient()
    ambientTrack:Play()
    TweenService:Create(
        ambientTrack,
        TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = AMBIENT_VOLUME}
    ):Play()
    print("[AmbientAudio] ✅ Música ambiente iniciada.")
end

-- Esperar a que el sonido cargue antes de reproducir
if ambientTrack.IsLoaded then
    startAmbient()
else
    ambientTrack.Loaded:Connect(startAmbient)
end

-- ─── API pública para que OutfitClient pueda mutear ───────────
-- El toggle de "Efectos de Sonido" en Settings puede llamar esto
_G.InfectedAudio = {
    setVolume = function(vol)
        TweenService:Create(
            ambientTrack,
            TweenInfo.new(1, Enum.EasingStyle.Quad),
            {Volume = vol}
        ):Play()
    end,
    mute = function()
        TweenService:Create(ambientTrack,
            TweenInfo.new(1), {Volume = 0}):Play()
    end,
    unmute = function()
        TweenService:Create(ambientTrack,
            TweenInfo.new(1), {Volume = AMBIENT_VOLUME}):Play()
    end,
}