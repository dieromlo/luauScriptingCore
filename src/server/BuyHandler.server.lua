-- ============================================================
--  BuyHandler.server.lua
--  Script | ServerScriptService
--  Recibe peticiones de compra del cliente y abre el
--  diálogo de compra oficial de Roblox.
--  MarketplaceService:PromptPurchase solo corre en servidor.
-- ============================================================

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage
    :WaitForChild("OutfitSystem")
    :WaitForChild("RemoteEvents")

local BuyOutfit = remoteFolder:WaitForChild("BuyOutfit")

BuyOutfit.OnServerEvent:Connect(function(player, assetId)
    -- Validar que el ID es un número real
    if typeof(assetId) ~= "number" or assetId <= 0 then
        warn("[BuyHandler] Asset ID inválido de " .. player.Name)
        return
    end

    local success, err = pcall(function()
        MarketplaceService:PromptPurchase(player, assetId)
    end)

    if not success then
        warn("[BuyHandler] Error al abrir prompt para "
            .. player.Name .. ": " .. tostring(err))
    else
        print("[BuyHandler] ✅ Prompt de compra abierto para "
            .. player.Name .. " → Asset " .. assetId)
    end
end)