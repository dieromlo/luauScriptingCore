-- ============================================================
--  AvatarHandler.server.lua
--  Script | ServerScriptService
--  Maneja Try On (probarse ropa) y Reset (volver a la skin original)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OutfitData    = require(ReplicatedStorage.OutfitSystem.OutfitData)
local RemoteEvents  = ReplicatedStorage.OutfitSystem.RemoteEvents
local TryOnOutfit   = RemoteEvents:WaitForChild("TryOnOutfit")
local ResetAvatar   = RemoteEvents:WaitForChild("ResetAvatar")

-- ----------------------------------------------------------------
-- Cache de apariencias originales
-- Guardamos cómo era el avatar ANTES de probarse ropa
-- Key: Player → Value: HumanoidDescription original
-- ----------------------------------------------------------------
local originalDescriptions = {}

-- Cuando el jugador aparece en el juego, guardamos su look
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end

        -- Esperar a que cargue la apariencia completamente
        task.wait(2)

        local success, description = pcall(function()
            return humanoid:GetAppliedDescription()
        end)

        if success and description then
            originalDescriptions[player] = description
            print("[AvatarHandler] Apariencia guardada: " .. player.Name)
        end
    end)
end)

-- Limpiar al desconectarse
Players.PlayerRemoving:Connect(function(player)
    originalDescriptions[player] = nil
end)

-- ----------------------------------------------------------------
-- EVENTO: TryOnOutfit
-- El cliente manda el ID del outfit. El servidor aplica la ropa.
-- ----------------------------------------------------------------
TryOnOutfit.OnServerEvent:Connect(function(player, outfitId)
    -- Validaciones de seguridad
    if typeof(outfitId) ~= "number" then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Buscar el outfit en los datos
    local outfit = OutfitData.GetOutfitById(outfitId)
    if not outfit then
        warn("[AvatarHandler] Outfit ID inválido recibido de " .. player.Name .. ": " .. tostring(outfitId))
        return
    end

    -- Eliminar ropa actual del jugador
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") then
            child:Destroy()
        end
    end

    -- Aplicar la ropa del outfit
    if outfit.items.shirt and outfit.items.shirt ~= 0 then
        local shirt = Instance.new("Shirt")
        shirt.ShirtTemplate = "rbxassetid://" .. tostring(outfit.items.shirt)
        shirt.Parent = character
    end

    if outfit.items.pants and outfit.items.pants ~= 0 then
        local pants = Instance.new("Pants")
        pants.PantsTemplate = "rbxassetid://" .. tostring(outfit.items.pants)
        pants.Parent = character
    end

    print("[AvatarHandler] ✅ " .. player.Name .. " se probó: " .. outfit.name)
end)

-- ----------------------------------------------------------------
-- EVENTO: ResetAvatar
-- El cliente pide volver a su look original
-- ----------------------------------------------------------------
ResetAvatar.OnServerEvent:Connect(function(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local originalDesc = originalDescriptions[player]

    if originalDesc then
        -- Restaurar descripción completa original
        local success, err = pcall(function()
            humanoid:ApplyDescription(originalDesc)
        end)

        if success then
            print("[AvatarHandler] ✅ Avatar reseteado: " .. player.Name)
        else
            warn("[AvatarHandler] Error al resetear: " .. tostring(err))
        end
    else
        -- Fallback: solo eliminar la ropa
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Shirt") or child:IsA("Pants") then
                child:Destroy()
            end
        end
        print("[AvatarHandler] ⚠️ Reset fallback (sin descripción guardada): " .. player.Name)
    end
end)