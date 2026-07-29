-- ============================================================
--  OutfitService.lua
--  ModuleScript | StarterPlayerScripts/modules
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Punto único de coordinación para todo lo relacionado con
--  outfits desde el cliente: Try On y Buy hoy; AddToCart y
--  Checkout cuando existan. Ningún panel dispara RemoteEvents
--  directamente — todos pasan por aquí.
--
--  DEPENDENCIAS
--  Ninguna en tiempo de require — recibe sus RemoteEvents vía
--  Init(), igual que MenuManager.
--
--  EXPONE
--  OutfitService.Init(remotes)
--  OutfitService.TryOn(outfitId)
--  OutfitService.Buy(assetId)
--  OutfitService.AddToCart(item)               -- preparado
--  OutfitService.OnPurchaseFinished(callback)
--    callback(assetId, wasPurchased) — se dispara cuando el
--    diálogo nativo de compra de Roblox se cierra, sin importar
--    si la compra se originó desde el cliente o el servidor.
-- ============================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players             = game:GetService("Players")

local player = Players.LocalPlayer

local OutfitService = {}

local tryOnRemote, buyRemote
local purchaseFinishedCallbacks = {}

function OutfitService.Init(remotes)
    tryOnRemote = remotes.tryOn
    buyRemote   = remotes.buy
end

function OutfitService.TryOn(outfitId)
    if not tryOnRemote then
        warn("[OutfitService] TryOn llamado antes de Init().")
        return
    end
    tryOnRemote:FireServer(outfitId)
end

function OutfitService.Buy(assetId)
    if not buyRemote then
        warn("[OutfitService] Buy llamado antes de Init().")
        return
    end
    if typeof(assetId) ~= "number" or assetId <= 0 then return end
    buyRemote:FireServer(assetId)
end

function OutfitService.AddToCart(item)
    warn("[OutfitService] AddToCart no implementado todavía (el carrito no existe aún).")
end

function OutfitService.OnPurchaseFinished(callback)
    table.insert(purchaseFinishedCallbacks, callback)
end

MarketplaceService.PromptPurchaseFinished:Connect(function(plr, assetId, wasPurchased)
    if plr ~= player then return end
    for _, cb in ipairs(purchaseFinishedCallbacks) do
        task.spawn(cb, assetId, wasPurchased)
    end
end)

return OutfitService