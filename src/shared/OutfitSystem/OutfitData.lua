-- ============================================================
--  OutfitData.lua
--  ModuleScript | ReplicatedStorage > OutfitSystem
--  Base de datos central de todos los outfits del grupo Infected Memories.
-- ============================================================

local OutfitData = {}

OutfitData.Outfits = {

    {
        id          = 1,
        name        = "Dark Circuit", -- Nombre del Outfit
        description = "Cyberpunk underground. Hecha para los que no duermen.", -- Descripción del outfit
        items = {
            shirt  = 585519635,  -- Reemplazar con Asset ID real
            pants  = 585520483,  -- Reemplazar con Asset ID real
        },
        thumbnail = "rbxassetid://0",
    },

    {
        id          = 2,
        name        = "Infected Memories",
        description = "Gótico moderno. Rojo profundo, negro absoluto.",
        items = {
            shirt  = 585519635,
            pants  = 585520483,
        },
        thumbnail = "rbxassetid://0",
    },
}

function OutfitData.GetOutfitById(targetId)
    for _, outfit in ipairs(OutfitData.Outfits) do
        if outfit.id == targetId then
            return outfit
        end
    end
    return nil
end

return OutfitData