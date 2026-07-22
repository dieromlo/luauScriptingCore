-- ============================================================
--  BuyHandler.server.lua
--  Script | ServerScriptService
--  Abre el diálogo de compra oficial de Roblox.
-- ============================================================

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local OutfitSystem = ReplicatedStorage:WaitForChild("OutfitSystem",  15)
local RemoteEvents = OutfitSystem:WaitForChild("RemoteEvents",        10)
local BuyOutfit    = RemoteEvents:WaitForChild("BuyOutfit",           10)

if not BuyOutfit then
    error("[BuyHandler] ❌ BuyOutfit no encontrado. Revisa los init.meta.json")
end

BuyOutfit.OnServerEvent:Connect(function(player, assetId)
    if typeof(assetId) ~= "number" or assetId <= 0 then
        warn("[BuyHandler] Asset ID inválido de " .. player.Name)
        return
    end
    local ok, err = pcall(function()
        MarketplaceService:PromptPurchase(player, assetId)
    end)
    if not ok then
        warn("[BuyHandler] Error: " .. tostring(err))
    else
        print("[BuyHandler] ✅ Prompt abierto → " .. player.Name .. " → " .. assetId)
    end
end)