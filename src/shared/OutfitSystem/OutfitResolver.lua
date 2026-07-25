-- ============================================================
--  OutfitResolver.lua
--  ModuleScript | ReplicatedStorage/OutfitSystem
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Traducir los `pieces` de un outfit (OutfitData.lua) a un
--  HumanoidDescription real de Roblox. Es el ÚNICO lugar del
--  proyecto que sabe "cómo se ve" un outfit — tanto el maniquí
--  (MannequinSetup) como el Try On del jugador (AvatarHandler)
--  llaman a esta misma función, así que nunca pueden
--  desincronizarse visualmente entre sí.
--
--  EXPONE
--  OutfitResolver.Resolve(outfit, baseDescription?) → HumanoidDescription
--  OutfitResolver.FindPiece(outfit, pieceType) → piece | nil
--
--  ARQUITECTURA
--  Vive en ReplicatedStorage porque lo usan dos Scripts de
--  servidor distintos. No es cliente ni servidor específicamente
--  — es lógica compartida y sin estado.
-- ============================================================

local OutfitResolver = {}

-- Cada handler recibe (description, piece) y modifica la
-- descripción in-place. Agregar una categoría nueva es agregar
-- una entrada aquí — nada más del sistema necesita cambiar.
local PIECE_HANDLERS = {
    Shirt = function(desc, piece)
        desc.Shirt = piece.assetId
    end,

    Pants = function(desc, piece)
        desc.Pants = piece.assetId
    end,

    -- Preparado: los 7 slots de accesorio de Roblox (Hat, Face,
    -- Neck, Shoulder, Front, Back, Waist) son campos de tipo
    -- string con IDs separados por coma en HumanoidDescription.
    -- No implementado hoy porque no existe ningún accesorio real
    -- con el que probarlo — cuando exista, es una función corta
    -- que concatena sobre el campo correspondiente según
    -- piece.slot, sin tocar nada más de este archivo.
    Accessory = function(_desc, piece)
        warn("[OutfitResolver] Accessory aún no implementado (slot: "
            .. tostring(piece.slot) .. ", assetId: " .. tostring(piece.assetId) .. ")")
    end,

    -- Preparado: Layered Clothing NO es un campo de
    -- HumanoidDescription — requiere insertar un Instance de
    -- ropa (vía InsertService o una plantilla) directamente sobre
    -- el personaje, un paso aparte de ApplyDescription. Cuando
    -- exista dato real, este handler necesita coordinarse con
    -- quien llama a Resolve() para hacer ese paso extra.
    LayeredClothing = function(_desc, piece)
        warn("[OutfitResolver] Layered Clothing aún no implementado (assetId: "
            .. tostring(piece.assetId) .. ")")
    end,
}

-- Aplica los valores de escala corporal del outfit (cuando
-- existan) directamente sobre la descripción. A diferencia de
-- los accesorios, estas SÍ son propiedades numéricas simples —
-- están completamente implementadas desde hoy.
local function applyBodyScales(desc, scales)
    if not scales then return end
    if scales.Height     then desc.HeightScale     = scales.Height     end
    if scales.Width      then desc.WidthScale      = scales.Width      end
    if scales.Depth      then desc.DepthScale      = scales.Depth      end
    if scales.Head       then desc.HeadScale       = scales.Head       end
    if scales.Proportion then desc.ProportionScale = scales.Proportion end
    if scales.BodyType   then desc.BodyTypeScale   = scales.BodyType   end
end

-- Convierte un outfit en una HumanoidDescription lista para
-- Humanoid:ApplyDescription(). Si se pasa baseDescription, se
-- usa como punto de partida (clonada) y el outfit solo
-- sobreescribe lo que él mismo define — todo lo demás del look
-- base se conserva intacto.
function OutfitResolver.Resolve(outfit, baseDescription)
    local desc = baseDescription and baseDescription:Clone() or Instance.new("HumanoidDescription")

    for _, piece in ipairs(outfit.pieces or {}) do
        local handler = PIECE_HANDLERS[piece.type]
        if handler then
            handler(desc, piece)
        else
            warn("[OutfitResolver] Tipo de piece desconocido: " .. tostring(piece.type))
        end
    end

    applyBodyScales(desc, outfit.bodyScales)

    return desc
end

function OutfitResolver.FindPiece(outfit, pieceType)
    for _, piece in ipairs(outfit.pieces or {}) do
        if piece.type == pieceType then
            return piece
        end
    end
    return nil
end

return OutfitResolver