-- ============================================================
--  OutfitService.lua
--  ModuleScript | StarterPlayerScripts/modules
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Punto único de coordinación para todo lo relacionado con
--  outfits desde el cliente: Try On hoy; Buy, AddToCart y
--  Checkout cuando existan. La idea es que ningún panel dispare
--  RemoteEvents directamente — todos pasan por aquí, así que
--  el día que cambie CÓMO se prueba o se compra un outfit, se
--  edita un solo archivo.
--
--
--  EXPONE
--  OutfitService.Init(remotes)
--  OutfitService.TryOn(outfitId)
--  OutfitService.Buy(assetId)
--  OutfitService.AddToCart(item)  -- preparado, no implementado aun
-- ============================================================

local OutfitService = {}

local tryOnRemote, buyRemote

-- remotes: { tryOn = RemoteEvent, buy = RemoteEvent }
function OutfitService.Init(remotes)
    tryOnRemote = remotes.tryOn
    buyRemote   = remotes.buy
end

-- Pide al servidor aplicar el outfit indicado sobre el jugador.
-- La validación real (existencia del outfit, etc.) vive en
-- AvatarHandler.server.lua — esto solo dispara el pedido.
function OutfitService.TryOn(outfitId)
    if not tryOnRemote then
        warn("[OutfitService] TryOn llamado antes de Init().")
        return
    end
    tryOnRemote:FireServer(outfitId)
end

-- Abre el diálogo de compra oficial de Roblox para un AssetId.
function OutfitService.Buy(assetId)
    if not buyRemote then
        warn("[OutfitService] Buy llamado antes de Init().")
        return
    end
    if typeof(assetId) ~= "number" or assetId <= 0 then return end
    buyRemote:FireServer(assetId)
end

-- Preparado para el futuro carrito. Todavía no existe ningún
-- estado de carrito que mantener, así que por ahora solo avisa
-- que la función existe pero no está implementada — evita que
-- algo la llame en silencio sin saberlo.
function OutfitService.AddToCart(item)
    warn("[OutfitService] AddToCart no implementado todavía (el carrito no existe aún).")
end

return OutfitService