-- ============================================================
--  CameraController.client.lua
--  LocalScript | StarterPlayerScripts
--  Controla el zoom mínimo/máximo de la cámara del jugador.
-- ============================================================

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

-- ─── Límites de zoom ──────────────────────────────────────────
-- MIN: qué tan cerca puede acercarse (en studs)
-- MAX: qué tan lejos puede alejarse (en studs)
local MIN_ZOOM = 5
local MAX_ZOOM = 20

player.CameraMinZoomDistance = MIN_ZOOM
player.CameraMaxZoomDistance = MAX_ZOOM

-- Mantener los límites si el jugador se resetea 
player.CharacterAdded:Connect(function()
    task.wait()
    player.CameraMinZoomDistance = MIN_ZOOM
    player.CameraMaxZoomDistance = MAX_ZOOM
end)

print("[CameraController] ✅ Zoom limitado: " .. MIN_ZOOM .. " - " .. MAX_ZOOM .. " studs")