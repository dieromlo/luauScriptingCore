-- ============================================================
--  CustomCursor.client.lua
--  LocalScript | StarterPlayerScripts
--  Reemplaza el cursor del sistema por uno propio.
-- ============================================================

local Players = game:GetService("Players")
local player  = Players.LocalPlayer
local mouse   = player:GetMouse()

-- Sube tu imagen a Studio (mismo proceso que los íconos del HUD:
-- arrastra el PNG al Explorer y copia el rbxassetid generado)
mouse.Icon = "rbxassetid://0"  -- ← reemplaza este 0 por tu ID real

print("[CustomCursor] ✅ Cursor personalizado activo")