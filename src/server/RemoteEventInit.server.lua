-- ============================================================
--  RemoteEventInit.server.lua
--  Script | ServerScriptService
--  Crea todos los RemoteEvents al inicio del servidor.
--  Esto reemplaza el enfoque de .meta.json que no es confiable.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar a que OutfitSystem exista (lo crea Rojo al sincronizar)
local outfitSystem = ReplicatedStorage:WaitForChild("OutfitSystem", 15)
if not outfitSystem then
    error("[RemoteEventInit] ❌ OutfitSystem no encontrado en ReplicatedStorage.")
end

-- Obtener o crear la carpeta RemoteEvents
local remoteFolder = outfitSystem:FindFirstChild("RemoteEvents")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = outfitSystem
end

-- Lista de todos los RemoteEvents que necesita el juego
local eventNames = {
    "TryOnOutfit",
    "ResetAvatar",
    "RequestOutfitUI",
}

for _, name in ipairs(eventNames) do
    if not remoteFolder:FindFirstChild(name) then
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = remoteFolder
        print("[RemoteEventInit] ✅ Creado: " .. name)
    else
        print("[RemoteEventInit] ℹ️ Ya existe: " .. name)
    end
end

print("[RemoteEventInit] ✅ Todos los RemoteEvents listos.")