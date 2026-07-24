-- ============================================================
--  MannequinInteraction.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Decide CUÁL maniquí es el objetivo actual (cercanía + hacia
--  dónde mira la cámara) y le avisa a su MannequinVisuals cuándo
--  enfocar/desenfocar. Expone OnInteract(callback) para que
--  otros módulos reaccionen a la tecla E sin saber cómo se
--  eligió el objetivo.
-- ============================================================

local CollectionService = game:GetService("CollectionService")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")

local MannequinVisuals = require(script.Parent.MannequinVisuals)

-- Debe coincidir EXACTAMENTE con el tag usado en MannequinSetup.server.lua
local TAG = "Mannequin"

-- Filtro barato antes de calcular alineación con la cámara:
-- de N maniquíes, normalmente solo 0-3 pasan este primer corte.
local MAX_CANDIDATE_DISTANCE = 15

-- Producto punto mínimo entre "hacia dónde mira la cámara" y
-- "hacia dónde está el maniquí". 0.85 ≈ cono de ~32° al frente.
-- Súbelo para exigir apuntar más preciso, bájalo para que sea
-- más permisivo.
local MIN_ALIGNMENT = 0.85

local player = Players.LocalPlayer

local MannequinInteraction = {}

local onInteractCallback = nil
function MannequinInteraction.OnInteract(callback)
    onInteractCallback = callback
end

local visualsByModel = {}
local currentTarget  = nil

local function setupMannequin(model)
    if not model:IsA("Model") then return end
    if visualsByModel[model] then return end -- ya registrado, evita duplicados

    local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
    if not root then
        root = model:WaitForChild("HumanoidRootPart", 10)
    end
    if not root then
        warn("[MannequinInteraction] ⚠️ " .. model.Name .. ": HumanoidRootPart no llegó tras 10s.")
        return
    end

    visualsByModel[model] = MannequinVisuals.new(model, root)
end

local function teardownMannequin(model)
    local visuals = visualsByModel[model]
    if not visuals then return end

    if currentTarget == model then
        currentTarget = nil
    end
    visuals:Destroy()
    visualsByModel[model] = nil
end

-- ─── Elegir el objetivo actual ───────────────────────────────
local function pickTarget()
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local camCFrame = camera.CFrame
    local camPos     = camCFrame.Position
    local camLook    = camCFrame.LookVector

    local bestModel, bestAlignment = nil, MIN_ALIGNMENT

    for model, visuals in pairs(visualsByModel) do
        if model.Parent then
            local toMannequin = visuals.root.Position - hrp.Position
            if toMannequin.Magnitude <= MAX_CANDIDATE_DISTANCE then
                local direction = visuals.root.Position - camPos
                if direction.Magnitude > 0.01 then
                    local alignment = camLook:Dot(direction.Unit)
                    if alignment > bestAlignment then
                        bestAlignment = alignment
                        bestModel = model
                    end
                end
            end
        end
    end

    return bestModel
end

local function updateTarget()
    local newTarget = pickTarget()
    if newTarget == currentTarget then return end

    if currentTarget and visualsByModel[currentTarget] then
        visualsByModel[currentTarget]:Unfocus()
    end
    currentTarget = newTarget
    if currentTarget and visualsByModel[currentTarget] then
        visualsByModel[currentTarget]:Focus()
    end
end

-- ─── Init ──────────────────────────────────────────────────
function MannequinInteraction.Init()
    print("[MannequinInteraction] 🔵 Init() llamado, buscando maniquíes...")

    for _, model in ipairs(CollectionService:GetTagged(TAG)) do
        task.spawn(setupMannequin, model)
    end
    CollectionService:GetInstanceAddedSignal(TAG):Connect(function(model)
        task.spawn(setupMannequin, model)
    end)
    CollectionService:GetInstanceRemovedSignal(TAG):Connect(teardownMannequin)

    RunService.RenderStepped:Connect(updateTarget)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.E and currentTarget and onInteractCallback then
            onInteractCallback(currentTarget, player)
        end
    end)

    task.delay(3, function()
        local count = 0
        for _ in pairs(visualsByModel) do count += 1 end
        print("[MannequinInteraction] ✅ " .. count .. " maniquíes registrados y listos.")
    end)
end

return MannequinInteraction