-- ============================================================
--  MannequinSetup.server.lua
--  Script | ServerScriptService
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Clonar MannequinTemplate por cada outfit, posicionarlo sobre
--  su pedestal, y aplicarle el outfit vía OutfitResolver — el
--  mismo mecanismo que usa el Try On del jugador.
-- ============================================================

local ServerStorage      = game:GetService("ServerStorage")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CollectionService  = game:GetService("CollectionService")

-- Debe coincidir EXACTAMENTE con el tag usado en MannequinInteraction.lua
local MANNEQUIN_TAG = "Mannequin"

local OutfitSystem = ReplicatedStorage:WaitForChild("OutfitSystem", 15)
if not OutfitSystem then
    error("[MannequinSetup] ❌ OutfitSystem no encontrado en ReplicatedStorage.")
end

local OutfitData     = require(OutfitSystem:WaitForChild("OutfitData", 10))
local OutfitResolver = require(OutfitSystem:WaitForChild("OutfitResolver", 10))

-- ----------------------------------------------------------------
-- POSICIONES EN EL MAPA
-- ----------------------------------------------------------------
local MANNEQUIN_CFRAMES = {

    -- Sección 1
    CFrame.new(30.833,   5.8, -34.334),  -- Outfit 1
    CFrame.new(44.462,   5.8, -34.338),  -- Outfit 2
    CFrame.new(58.666, 5.8, -34.338),    -- Outfit 3
    CFrame.new(72.695, 5.8, -34.338),    -- Outfit 4
    CFrame.new(86.645, 5.8, -34.338),    -- Outfit 5
    CFrame.new(-11.33, 5.8, -34.338),    -- Outfit 6
    CFrame.new(-25.163, 5.8, -34.338),   -- Outfit 7
    CFrame.new(-39.167, 5.8, -34.338),   -- Outfit 8
    CFrame.new(-53.167, 5.8, -34.338),   -- Outfit 9
    CFrame.new(-67.167, 5.8, -34.338),   -- Outfit 10

    CFrame.new(-67.225, 5.8, -57.17),   -- Outfit 11
    CFrame.new(-53.596, 5.8, -57.17),   -- Outfit 12
    CFrame.new(-39.332, 5.8, -57.17),   -- Outfit 13
    CFrame.new(-25.445, 5.8, -57.17),   -- Outfit 14
    CFrame.new(-11.646, 5.8, -57.17),   -- Outfit 15
    CFrame.new(30.75, 5.8, -57.17),   -- Outfit 16
    CFrame.new(44.379, 5.8, -57.17),   -- Outfit 17
    CFrame.new(58.583, 5.8, -57.17),   -- Outfit 18
    CFrame.new(72.154, 5.8, -57.17),   -- Outfit 19
    CFrame.new(86.562, 5.8, -57.17),   -- Outfit 20

    -- Seccion 2
    CFrame.new(86.657, 5.8, -96.906), -- Outfit 21
    CFrame.new(72.707, 5.8, -96.906), -- Outfit 22
    CFrame.new(58.678, 5.8, -96.906), -- Outfit 23
    CFrame.new(44.474, 5.8, -96.906), -- Outfit 24
    CFrame.new(30.845, 5.8, -96.906), -- Outfit 25
    CFrame.new(-11.318, 5.8, -96.906), -- Outfit 26
    CFrame.new(-25.151, 5.8, -96.906), -- Outfit 27
    CFrame.new(-39.155, 5.8, -96.906), -- Outfit 28
    CFrame.new(-53.155, 5.8, -96.906), -- Outfit 29
    CFrame.new(-67.155, 5.8, -96.906), -- Outfit 30

    CFrame.new(86.574, 5.8, -119.738), -- Outfit 31
    CFrame.new(72.166, 5.8, -119.738), -- Outfit 32
    CFrame.new(58.595, 5.8, -119.738), -- Outfit 33
    CFrame.new(44.391, 5.8, -119.738), -- Outfit 34
    CFrame.new(30.762, 5.8, -119.738), -- Outfit 35
    CFrame.new(16.269, 5.8, -119.738), -- Outfit 36
    CFrame.new(2.47, 5.8, -119.738), -- Outfit 37
    CFrame.new(-11.634, 5.8, -119.738), -- Outfit 38
    CFrame.new(-25.433, 5.8, -119.738), -- Outfit 39
    CFrame.new(-39.32, 5.8, -119.738), -- Outfit 40
    CFrame.new(-53.584, 5.8, -119.738), -- Outfit 41
    CFrame.new(-67.213, 5.8, -119.738), -- Outfit 42

    -- Sección 3
    CFrame.new(86.657, 5.8, 27.924), -- Outfit 43
    CFrame.new(72.707, 5.8, 27.924), -- Outfit 44
    CFrame.new(58.678, 5.8, 27.924), -- Outfit 45
    CFrame.new(44.474, 5.8, 27.924), -- Outfit 46
    CFrame.new(30.845, 5.8, 27.924), -- Outfit 47
    CFrame.new(-11.318, 5.8, 27.924), -- Outfit 48
    CFrame.new(-25.151, 5.8, 27.924), -- Outfit 49
    CFrame.new(-39.155, 5.8, 27.924), -- Outfit 50
    CFrame.new(-53.155, 5.8, 27.924), -- Outfit 51
    CFrame.new(-67.155, 5.8, 27.924), -- Outfit 52

    CFrame.new(-67.213, 5.8, 5.092), -- Outfit 53
    CFrame.new(-53.584, 5.8, 5.092), -- Outfit 54
    CFrame.new(-39.32, 5.8, 5.092), -- Outfit 55
    CFrame.new(-25.433, 5.8, 5.092), -- Outfit 56
    CFrame.new(-11.634, 5.8, 5.092), -- Outfit 57
    CFrame.new(30.762, 5.8, 5.092), -- Outfit 58
    CFrame.new(44.391, 5.8, 5.092), -- Outfit 59
    CFrame.new(58.595, 5.8, 5.092), -- Outfit 60
    CFrame.new(72.166, 5.8, 5.092), -- Outfit 61
    CFrame.new(86.574, 5.8, 5.092), -- Outfit 62

    -- Sección 4

    CFrame.new(86.56, 5.8, 90.447), -- Outfit 63
    CFrame.new(72.61, 5.8, 90.447), -- Outfit 64
    CFrame.new(58.581, 5.8, 90.447), -- Outfit 65
    CFrame.new(44.377, 5.8, 90.447), -- Outfit 66
    CFrame.new(30.748, 5.8, 90.447), -- Outfit 67
    CFrame.new(16.833, 5.8, 90.447), -- Outfit 68
    CFrame.new(2.833, 5.8, 90.447), -- Outfit 69
    CFrame.new(-11.415, 5.8, 90.447), -- Outfit 70
    CFrame.new(-25.248, 5.8, 90.447), -- Outfit 71
    CFrame.new(-39.252, 5.8, 90.447), -- Outfit 72
    CFrame.new(-53.252, 5.8, 90.447), -- Outfit 73
    CFrame.new(-67.252, 5.8, 90.447), -- Outfit 74

    CFrame.new(86.477, 5.8, 67.615), -- Outfit 75
    CFrame.new(72.069, 5.8, 67.615), -- Outfit 76
    CFrame.new(58.498, 5.8, 67.615), -- Outfit 77
    CFrame.new(44.294, 5.8, 67.615), -- Outfit 78
    CFrame.new(30.665, 5.8, 67.615), -- Outfit 79
    CFrame.new(-11.731, 5.8, 67.615), -- Outfit 80
    CFrame.new(-25.53, 5.8, 67.615), -- Outfit 81
    CFrame.new(-39.417, 5.8, 67.615), -- Outfit 82
    CFrame.new(-53.681, 5.8, 67.615), -- Outfit 83
    CFrame.new(-67.31, 5.8, 67.615), -- Outfit 84
}

-- ----------------------------------------------------------------
local function anchorAllParts(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored   = true
            part.CanCollide = false
        end
    end
end

local function makeHeadless(model)
    local head = model:FindFirstChild("Head")
    if not head then return end
    head.Transparency = 1
    for _, decal in ipairs(head:GetChildren()) do
        if decal:IsA("Decal") then decal:Destroy() end
    end
end

-- Aplica el outfit al maniquí vía OutfitResolver + ApplyDescription
-- — el mismo mecanismo que usa AvatarHandler para el jugador.
local function applyOutfitAppearance(model, outfit)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[MannequinSetup] Sin Humanoid en: " .. model.Name .. ". No se puede aplicar el outfit.")
        return
    end

    -- La apariencia original de la plantilla es la base: el
    -- outfit solo sobreescribe lo que él mismo define.
    local ok, baseDescription = pcall(function()
        return humanoid:GetAppliedDescription()
    end)

    local description = OutfitResolver.Resolve(outfit, ok and baseDescription or nil)

    local applied, err = pcall(function()
        humanoid:ApplyDescription(description)
    end)
    if not applied then
        warn("[MannequinSetup] Error aplicando outfit a " .. model.Name .. ": " .. tostring(err))
    end
end

local function tagMannequin(model)
    CollectionService:AddTag(model, MANNEQUIN_TAG)
end

-- ----------------------------------------------------------------
local function setupAllMannequins()
    local template = ServerStorage:FindFirstChild("MannequinTemplate")
    if not template then
        warn("[MannequinSetup] ❌ 'MannequinTemplate' no encontrado en ServerStorage.")
        return
    end

    local existing = workspace:FindFirstChild("Mannequins")
    if existing then existing:Destroy() end

    local folder    = Instance.new("Folder")
    folder.Name     = "Mannequins"
    folder.Parent   = workspace

    for index, outfit in ipairs(OutfitData.Outfits) do
        local targetCF = MANNEQUIN_CFRAMES[index]

        if not targetCF then
            warn("[MannequinSetup] Sin CFrame para outfit #" .. index
                .. " (" .. outfit.name .. "). Agrégala a MANNEQUIN_CFRAMES.")
            continue
        end

        local mannequin = template:Clone()
        mannequin.Name  = "Mannequin_" .. outfit.id
        
        mannequin:SetAttribute("OutfitId", outfit.id)

        mannequin:SetPrimaryPartCFrame(targetCF)

        mannequin.Parent = folder

        applyOutfitAppearance(mannequin, outfit)
        anchorAllParts(mannequin)
        makeHeadless(mannequin)
        tagMannequin(mannequin)

        print("[MannequinSetup] ✅ " .. outfit.name)
    end

    print("[MannequinSetup] 🎉 Total: " .. #OutfitData.Outfits .. " maniquíes activos.")
end

setupAllMannequins()