-- ============================================================
--  CustomCursor.client.lua
--  LocalScript | StarterPlayerScripts
-- ============================================================

local Players = game:GetService("Players")
local player  = Players.LocalPlayer
local mouse   = player:GetMouse()

mouse.Icon = "rbxassetid://0"  -- ← reemplazar este 0 por un ID real

print("[CustomCursor] ✅ Cursor personalizado activo")