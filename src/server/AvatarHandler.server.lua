-- ============================================================
--  AvatarHandler.server.lua
--  Script | ServerScriptService
--  Escucha TryOnOutfit y ResetAvatar desde el cliente.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OutfitSystem  = ReplicatedStorage:WaitForChild("OutfitSystem", 15)
local OutfitData    = require(OutfitSystem:WaitForChild("OutfitData", 10))
local RemoteEvents  = OutfitSystem:WaitForChild("RemoteEvents", 10)

-- WaitForChild en los RemoteEvents para respetar el tiempo de replicación de Rojo
local TryOnOutfit = RemoteEvents:WaitForChild("TryOnOutfit", 10)
local ResetAvatar = RemoteEvents:WaitForChild("ResetAvatar",  10)

if not TryOnOutfit then
    error("[AvatarHandler] ❌ TryOnOutfit no encontrado. Revisa los init.meta.json")
end
if not ResetAvatar then
    error("[AvatarHandler] ❌ ResetAvatar no encontrado. Revisa los init.meta.json")
end

-- Cache: guarda la apariencia original de cada jugador
local originalDescriptions = {}

-- CharacterAppearanceLoaded es el evento correcto para esto: se dispara
-- justo cuando Roblox terminó de cargar tu ropa/accesorios reales.
local function cacheOriginalAppearance(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    local ok, desc = pcall(function()
        return humanoid:GetAppliedDescription()
    end)

    if ok and desc then
        originalDescriptions[player] = desc
        print("[AvatarHandler] ✅ Apariencia guardada: " .. player.Name)
    else
        warn("[AvatarHandler] ⚠️ No se pudo guardar apariencia de "
            .. player.Name .. ": " .. tostring(desc))
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAppearanceLoaded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end

        local ok, desc = pcall(function()
            return humanoid:GetAppliedDescription()
        end)

        if ok and desc then
            originalDescriptions[player] = desc
            print("[AvatarHandler] ✅ Apariencia guardada: " .. player.Name)
        else
            warn("[AvatarHandler] ⚠️ No se pudo guardar apariencia de "
                .. player.Name .. ": " .. tostring(desc))
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    originalDescriptions[player] = nil
end)

-- ─── VESTIR ────────────────────────────────────────────────────
TryOnOutfit.OnServerEvent:Connect(function(player, outfitId)
    if typeof(outfitId) ~= "number" then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local outfit = OutfitData.GetOutfitById(outfitId)
    if not outfit then
        warn("[AvatarHandler] Outfit ID inválido: " .. tostring(outfitId))
        return
    end

    -- Eliminar ropa actual
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") then child:Destroy() end
    end

    local sid = outfit.items and outfit.items.shirt or 0
    local pid = outfit.items and outfit.items.pants or 0

    if sid ~= 0 then
        local shirt = Instance.new("Shirt")
        shirt.ShirtTemplate = "rbxassetid://" .. tostring(sid)
        shirt:SetAttribute("FromOutfit", true)
        shirt.Parent = char
    end
    if pid ~= 0 then
        local pants = Instance.new("Pants")
        pants.PantsTemplate = "rbxassetid://" .. tostring(pid)
        pants:SetAttribute("FromOutfit", true)
        pants.Parent = char
    end

    print("[AvatarHandler] ✅ " .. player.Name .. " → " .. outfit.name)
end)

-- ─── RESETEAR ──────────────────────────────────────────────────
ResetAvatar.OnServerEvent:Connect(function(player)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local desc = originalDescriptions[player]
if desc then
    local ok, err = pcall(function() hum:ApplyDescription(desc) end)
    if ok then
        print("[AvatarHandler] ✅ Reset: " .. player.Name)
    else
        warn("[AvatarHandler] ❌ Error al resetear a " .. player.Name .. ": " .. tostring(err))
    end
else
        -- Fallback: solo borrar la ropa
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Shirt") or child:IsA("Pants") then child:Destroy() end
        end
    end
end)

local RemoveItem = RemoteEvents:WaitForChild("RemoveItem", 10)

RemoveItem.OnServerEvent:Connect(function(player, itemType, itemName)
    local char = player.Character
    if not char then return end

    if itemType == "Shirt" or itemType == "Pants" then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA(itemType) then 
                child:Destroy() 
            end
        end
    elseif itemType == "Accessory" and itemName then
        local acc = char:FindFirstChild(itemName)
        if acc and acc:IsA("Accessory") then 
            acc:Destroy() 
        end
    end
end)