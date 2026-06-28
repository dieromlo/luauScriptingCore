-- ============================================================
--  MannequinSetup.server.lua
--  Script | ServerScriptService
--  Clona MannequinTemplate por cada outfit y lo coloca en mapa.
--  SERVIDOR PURO: sin PlayerGui, sin LocalPlayer, sin GUI.
-- ============================================================

local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar a que OutfitData esté disponible (Rojo puede tardar un frame)
local OutfitSystem = ReplicatedStorage:WaitForChild("OutfitSystem", 15)
if not OutfitSystem then
    error("[MannequinSetup] ❌ OutfitSystem no encontrado en ReplicatedStorage.")
end

local OutfitData = require(OutfitSystem:WaitForChild("OutfitData", 10))

-- ----------------------------------------------------------------
-- POSICIONES EN EL MAPA
-- Ajusta X, Y, Z según los pedestales que ya tienes en tu mapa.
-- El +5 en Y es para que el maniquí quede parado encima del pedestal.
-- ----------------------------------------------------------------
local MANNEQUIN_CFRAMES = {
    CFrame.new(0,   5, -10),  -- Outfit 1
    CFrame.new(8,   5, -10),  -- Outfit 2
    CFrame.new(16,  5, -10),  -- Outfit 3 (agrega más si tienes más outfits)
}

-- ----------------------------------------------------------------
-- Anclar y quitar colisión a todas las partes del maniquí
-- ----------------------------------------------------------------
local function anchorAllParts(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored    = true
            part.CanCollide  = false
        end
    end
end

-- ----------------------------------------------------------------
-- Headless: cabeza invisible + borrar decals de la cara
-- ----------------------------------------------------------------
local function makeHeadless(model)
    local head = model:FindFirstChild("Head")
    if not head then return end
    head.Transparency = 1
    for _, decal in ipairs(head:GetChildren()) do
        if decal:IsA("Decal") then decal:Destroy() end
    end
end

-- ----------------------------------------------------------------
-- Aplicar camisa y pantalón al maniquí
-- ----------------------------------------------------------------
local function applyClothing(model, outfit)
    -- Limpiar ropa previa
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("Shirt") or child:IsA("Pants") then
            child:Destroy()
        end
    end

    local sid = outfit.items and outfit.items.shirt or 0
    local pid = outfit.items and outfit.items.pants or 0

    if sid ~= 0 then
        local shirt = Instance.new("Shirt")
        shirt.ShirtTemplate = "rbxassetid://" .. tostring(sid)
        shirt.Parent = model
    end

    if pid ~= 0 then
        local pants = Instance.new("Pants")
        pants.PantsTemplate = "rbxassetid://" .. tostring(pid)
        pants.Parent = model
    end
end

-- ----------------------------------------------------------------
-- Agregar ProximityPrompt al HumanoidRootPart del maniquí
-- ----------------------------------------------------------------
local function addPrompt(model, outfit)
    local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
    if not root then
        warn("[MannequinSetup] Sin PrimaryPart en: " .. model.Name)
        return
    end

    local prompt                  = Instance.new("ProximityPrompt")
    prompt.ActionText             = "Ver Outfit"
    prompt.ObjectText             = outfit.name
    prompt.HoldDuration           = 0
    prompt.MaxActivationDistance  = 8
    prompt.KeyboardKeyCode        = Enum.KeyCode.E
    prompt.Parent                 = root
end

-- ----------------------------------------------------------------
-- FUNCIÓN PRINCIPAL
-- ----------------------------------------------------------------
local function setupAllMannequins()
    local template = ServerStorage:FindFirstChild("MannequinTemplate")
    if not template then
        warn("[MannequinSetup] ❌ 'MannequinTemplate' no encontrado en ServerStorage.")
        warn("[MannequinSetup]    Crea el rig R15 en Studio y muévelo a ServerStorage.")
        return
    end

    -- Limpiar maniquíes anteriores si el script se recarga
    local existing = workspace:FindFirstChild("Mannequins")
    if existing then existing:Destroy() end

    local folder        = Instance.new("Folder")
    folder.Name         = "Mannequins"
    folder.Parent       = workspace

    for index, outfit in ipairs(OutfitData.Outfits) do
        local targetCF = MANNEQUIN_CFRAMES[index]

        if not targetCF then
            warn("[MannequinSetup] Sin CFrame para outfit #" .. index
                .. " (" .. outfit.name .. "). Agrégala a MANNEQUIN_CFRAMES.")
            continue
        end

        local mannequin      = template:Clone()
        mannequin.Name       = "Mannequin_" .. outfit.id

        -- Guardar datos como atributos (el cliente los leerá desde el ProximityPrompt)
        mannequin:SetAttribute("OutfitId",          outfit.id)
        mannequin:SetAttribute("OutfitName",         outfit.name)
        mannequin:SetAttribute("OutfitDescription",  outfit.description)
        mannequin:SetAttribute("ShirtId",            (outfit.items and outfit.items.shirt) or 0)
        mannequin:SetAttribute("PantsId",            (outfit.items and outfit.items.pants) or 0)

        mannequin:SetPrimaryPartCFrame(targetCF)
        anchorAllParts(mannequin)
        makeHeadless(mannequin)
        applyClothing(mannequin, outfit)
        addPrompt(mannequin, outfit)

        mannequin.Parent = folder
        print("[MannequinSetup] ✅ " .. outfit.name)
    end

    print("[MannequinSetup] 🎉 Total: " .. #OutfitData.Outfits .. " maniquíes activos.")
end

setupAllMannequins()