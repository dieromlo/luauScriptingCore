-- ============================================================
--  MannequinSetup.server.lua
--  Script | ServerScriptService
--  Clona el MannequinTemplate por cada outfit definido
--  en OutfitData y los posiciona en el mapa.
-- ============================================================

local ServerStorage   = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OutfitData = require(ReplicatedStorage.OutfitSystem.OutfitData)

-- ----------------------------------------------------------------
-- POSICIONES DE LOS MANIQUÍES EN EL MAPA
-- Cada CFrame corresponde al outfit del mismo índice en OutfitData.
-- Ajusta las coordenadas X, Y, Z cuando diseñes tu mapa.
-- Por ahora están en fila recta para testear.
-- ----------------------------------------------------------------
local MANNEQUIN_CFRAMES = {
    CFrame.new(0,  3, -10),   -- Outfit 1: Dark Circuit
    CFrame.new(6,  3, -10),   -- Outfit 2: Infected Memories
    CFrame.new(12, 3, -10),   -- Outfit 3: (agrega más cuando tengas más outfits)
}

-- ----------------------------------------------------------------
-- Anclar todas las BaseParts del maniquí para que no caiga
-- ----------------------------------------------------------------
local function anchorAllParts(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false -- Los jugadores pueden atravesarlo
        end
    end
end

-- ----------------------------------------------------------------
-- Hacer la cabeza invisible + borrar la cara (headless look)
-- ----------------------------------------------------------------
local function makeHeadless(model)
    local head = model:FindFirstChild("Head")
    if head then
        head.Transparency = 1
        -- Borrar los Decals de la cara
        for _, decal in ipairs(head:GetChildren()) do
            if decal:IsA("Decal") then
                decal:Destroy()
            end
        end
    end
end

-- ----------------------------------------------------------------
-- Aplicar camisa y pantalón al maniquí usando HumanoidDescription
-- ----------------------------------------------------------------
local function applyClothing(model, outfit)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then 
        warn("[MannequinSetup] No se encontró Humanoid en el maniquí para aplicar ropa.")
        return 
    end

    -- Creamos una descripción de apariencia temporal
    local description = Instance.new("HumanoidDescription")
    description.Shirt = outfit.items.shirt or 0
    description.Pants = outfit.items.pants or 0
    
    -- ============================================================
    -- CONFIGURACIÓN ESTÉTICA: AVATARES MÁS DELGADOS Y ESTILIZADOS
    -- ============================================================
    description.WidthScale = 0.85      -- Reduce el ancho (85% del tamaño original)
    description.DepthScale = 0.85      -- Reduce el grosor de perfil
    description.HeightScale = 1.05     -- Los hace ligeramente más altos
    description.ProportionScale = 0    -- Mantiene la proporción estilizada

    -- ============================================================
    -- CONFIGURACIÓN DE COLOR DE PIEL NEUTRAL (Maniquí Gris Elegante)
    -- ============================================================
    local mannequinColor = Color3.fromRGB(180, 180, 180) -- Gris claro neutral
    description.HeadColor     = mannequinColor
    description.TorsoColor    = mannequinColor
    description.LeftArmColor  = mannequinColor
    description.RightArmColor = mannequinColor
    description.LeftLegColor  = mannequinColor
    description.RightLegColor = mannequinColor
    
    -- Aplicamos la descripción al Humanoid de forma segura
    local success, err = pcall(function()
        humanoid:ApplyDescription(description)
    end)
    
    if not success then
        warn("[MannequinSetup] Error al aplicar ropa al outfit " .. outfit.name .. ": " .. tostring(err))
    end
end

-- ----------------------------------------------------------------
-- Agregar ProximityPrompt para que el jugador pueda interactuar
-- ----------------------------------------------------------------
local function addInteractionPrompt(model, outfit)
    -- Buscar la parte raíz del rig
    local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        warn("[MannequinSetup] No se encontró PrimaryPart en: " .. model.Name)
        return
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText  = "Ver Outfit"
    prompt.ObjectText  = outfit.name        -- Nombre que aparece sobre el maniquí
    prompt.HoldDuration = 0                 -- Clic simple (sin mantener pulsado)
    prompt.MaxActivationDistance = 8        -- Distancia de activación en studs
    prompt.KeyboardKeyCode = Enum.KeyCode.E -- Tecla de activación
    prompt.Parent = rootPart
end

-- ----------------------------------------------------------------
-- FUNCIÓN PRINCIPAL
-- ----------------------------------------------------------------
local function setupAllMannequins()
    local template = ServerStorage:FindFirstChild("MannequinTemplate")

    if not template then
        warn("[MannequinSetup] ❌ 'MannequinTemplate' no encontrado en ServerStorage.")
        warn("[MannequinSetup] Crea el rig en Studio y muévelo a ServerStorage.")
        return
    end

    -- Limpiar maniquíes viejos si el script se recarga
    local existingFolder = workspace:FindFirstChild("Mannequins")
    if existingFolder then existingFolder:Destroy() end

    -- Carpeta organizadora en Workspace
    local mannequinFolder      = Instance.new("Folder")
    mannequinFolder.Name       = "Mannequins"
    mannequinFolder.Parent     = workspace

    -- Crear un maniquí por cada outfit
    for index, outfit in ipairs(OutfitData.Outfits) do
        local targetCFrame = MANNEQUIN_CFRAMES[index]

        if not targetCFrame then
            warn("[MannequinSetup] Sin posición para outfit #" .. index .. " (" .. outfit.name .. "). Agrégala a MANNEQUIN_CFRAMES.")
            continue
        end

        -- Clonar el template
        local mannequin      = template:Clone()
        mannequin.Name       = "Mannequin_" .. outfit.id

        -- Guardar metadata como atributos (el cliente los leerá luego)
        mannequin:SetAttribute("OutfitId",          outfit.id)
        mannequin:SetAttribute("OutfitName",         outfit.name)
        mannequin:SetAttribute("OutfitDescription",  outfit.description)
        mannequin:SetAttribute("ShirtId",            outfit.items.shirt or 0)
        mannequin:SetAttribute("PantsId",            outfit.items.pants or 0)

        -- Posicionar en el mapa
        mannequin:SetPrimaryPartCFrame(targetCFrame)

        -- ============================================================
        -- Primero lo metemos al Workspace para que el motor de Roblox
        -- sepa que el personaje existe y pueda descargar la ropa.
        -- ============================================================
        mannequin.Parent = mannequinFolder
        
        -- Esperamos un instante mínimo a que el motor procese el cambio de entorno
        task.wait()

        -- Ahora sí, aplicamos los ajustes visuales con el maniquí ya en el mundo
        anchorAllParts(mannequin)
        applyClothing(mannequin, outfit) 
        makeHeadless(mannequin)          
        addInteractionPrompt(mannequin, outfit)

        print("[MannequinSetup] ✅ Maniquí creado y vestido: " .. outfit.name)
    end

    print("[MannequinSetup] 🎉 Total: " .. #OutfitData.Outfits .. " maniquíes activos.")
end

setupAllMannequins()