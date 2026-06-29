-- ============================================================
--  CameraController.client.lua
--  LocalScript | StarterPlayerScripts
--  Controla el zoom mínimo/máximo de la cámara del jugador.
-- ============================================================

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

-- Esperar a que el jugador exista
player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Wait()

-- ─── Límites de zoom ──────────────────────────────────────────
-- MIN: qué tan cerca puede acercarse (en studs)
-- MAX: qué tan lejos puede alejarse (en studs)
local MIN_ZOOM = 8
local MAX_ZOOM = 25

player.CameraMinZoomDistance = MIN_ZOOM
player.CameraMaxZoomDistance = MAX_ZOOM

-- Mantener los límites si el jugador respawnea
player.CharacterAdded:Connect(function()
    task.wait() -- un frame para que Roblox no los resetee
    player.CameraMinZoomDistance = MIN_ZOOM
    player.CameraMaxZoomDistance = MAX_ZOOM
end)

print("[CameraController] ✅ Zoom limitado: " .. MIN_ZOOM .. " - " .. MAX_ZOOM .. " studs")