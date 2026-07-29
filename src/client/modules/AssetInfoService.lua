-- ============================================================
--  AssetInfoService.lua
--  ModuleScript | StarterPlayerScripts/modules
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Única fuente de verdad para información de un asset de
--  Roblox: nombre, precio, miniatura, creador, y estado
--  (Owned/ForSale/Limited/OffSale/Unavailable). Envuelve
--  MarketplaceService con caché — pedir el mismo assetId dos
--  veces solo golpea la API de Roblox una vez.
--
--  ARQUITECTURA
--  Diseñado para que el futuro carrito consuma exactamente esta
--  misma información sin ningún cambio.
-- ============================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players             = game:GetService("Players")

local player = Players.LocalPlayer

local AssetInfoService = {}

AssetInfoService.STATES = {
    Owned       = "Owned",
    ForSale     = "ForSale",
    Limited     = "Limited",
    OffSale     = "OffSale",
    Unavailable = "Unavailable",
}
local STATES = AssetInfoService.STATES

local cache            = {} -- [assetId] = resolvedInfo
local pendingCallbacks = {} -- [assetId] = { fn, fn, ... }

local function determineState(product, owned)
    if owned then return STATES.Owned end
    if not product then return STATES.Unavailable end

    local isLimited = product.IsLimited or product.IsLimitedUnique
    if not product.IsForSale then return STATES.OffSale end
    if isLimited then return STATES.Limited end
    return STATES.ForSale
end

local function fetchInfo(assetId)
    local product
    pcall(function()
        product = MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
    end)

    local owned = false
    pcall(function()
        owned = MarketplaceService:PlayerOwnsAsset(player, assetId)
    end)

    local state     = determineState(product, owned)
    local thumbnail = "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=150&h=150"

    if not product then
        return {
            assetId = assetId, name = "Ítem no disponible", price = nil,
            thumbnail = thumbnail, state = state, creator = nil, owned = owned,
        }
    end

    return {
        assetId   = assetId,
        name      = product.Name or "Sin nombre",
        price     = (product.IsForSale and state ~= STATES.Owned) and product.PriceInRobux or nil,
        thumbnail = thumbnail,
        state     = state,
        creator   = product.Creator and product.Creator.Name or nil,
        owned     = owned,
    }
end

-- Pide la info de un asset. Si dos llamadas piden el mismo
-- assetId antes de que la primera resuelva, comparten el mismo
-- viaje a la API — no se duplica la consulta.
function AssetInfoService.GetInfo(assetId, callback)
    if typeof(assetId) ~= "number" or assetId <= 0 then
        callback(nil)
        return
    end
    if cache[assetId] then
        callback(cache[assetId])
        return
    end
    if pendingCallbacks[assetId] then
        table.insert(pendingCallbacks[assetId], callback)
        return
    end

    pendingCallbacks[assetId] = { callback }
    task.spawn(function()
        local info = fetchInfo(assetId)
        cache[assetId] = info
        local callbacks = pendingCallbacks[assetId]
        pendingCallbacks[assetId] = nil
        for _, cb in ipairs(callbacks) do cb(info) end
    end)
end

function AssetInfoService.GetCached(assetId)
    return cache[assetId]
end

function AssetInfoService.Invalidate(assetId)
    cache[assetId] = nil
end

return AssetInfoService