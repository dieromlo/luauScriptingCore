-- ============================================================
--  MannequinInteraction.lua
--  ModuleScript | StarterPlayerScripts/modules
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Decide CUÁL maniquí es el objetivo actual (cercanía + hacia
--  dónde mira la cámara), gestiona el hold de la tecla E sobre
--  ese objetivo, y avisa a MannequinVisuals cuándo enfocar,
--  desenfocar, o actualizar el progreso del hold. Al completarse
--  el hold, garantiza salir de primera persona y liberar el
--  mouse antes de avisar a quien esté escuchando.
--
--  DEPENDENCIAS
--  MannequinVisuals.lua
--
--  EXPONE
--  MannequinInteraction.Init()
--  MannequinInteraction.OnInteract(callback)
--    callback recibe (mannequinModel, player) cuando se
--    completa un hold exitoso sobre un maniquí.
--
--  ARQUITECTURA
--  Nunca conoce MenuManager ni ningún panel — solo dice "esto
--  se activó". Quien quiera reaccionar (hoy OutfitClient) se
--  suscribe con OnInteract() sin que este módulo sepa qué hace
--  con esa información.
-- ============================================================

local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local MannequinVisuals = require(script.Parent.MannequinVisuals)

-- Debe coincidir EXACTAMENTE con el tag usado en MannequinSetup.server.lua
local TAG = "Mannequin"

-- Filtro barato antes de calcular alineación con la cámara.
local MAX_CANDIDATE_DISTANCE = 15

-- Producto punto mínimo para considerar que la cámara "mira" al
-- maniquí. 0.85 ≈ cono de ~32° al frente.
local MIN_ALIGNMENT = 0.85

-- Cuánto tiempo hay que mantener E presionada para abrir el panel.
local HOLD_DURATION = 0.5

local player = Players.LocalPlayer

local MannequinInteraction = {}

local onInteractCallback = nil
function MannequinInteraction.OnInteract(callback)
    onInteractCallback = callback
end

local visualsByModel = {}
local currentTarget  = nil

local isHolding     = false
local holdingModel  = nil
local holdStartTime = 0

-- ─── Registro / limpieza de maniquíes ──────────────────────────
local function setupMannequin(model)
    if not model:IsA("Model") then return end
    if visualsByModel[model] then return end

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

    if currentTarget == model then currentTarget = nil end
    if holdingModel == model then
        isHolding, holdingModel = false, nil
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
    local camPos    = camCFrame.Position
    local camLook   = camCFrame.LookVector

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

-- ─── Hold de la tecla E ─────────────────────────────────────
local function cancelHold()
    if holdingModel and visualsByModel[holdingModel] then
        visualsByModel[holdingModel]:CancelHold()
    end
    isHolding    = false
    holdingModel = nil
end

-- Garantiza que la cámara y el mouse estén en un estado normal
-- antes de abrir el panel — evita cualquier bug de cámara
-- bloqueada o mouse invisible al entrar al Viewer Panel.
local function ensureNormalCameraState()
    if player.CameraMode == Enum.CameraMode.LockFirstPerson then
        player.CameraMode = Enum.CameraMode.Classic
    end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
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

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode ~= Enum.KeyCode.E then return end
        if not currentTarget then return end

        isHolding     = true
        holdingModel  = currentTarget
        holdStartTime = os.clock()
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode ~= Enum.KeyCode.E then return end
        if isHolding then cancelHold() end
    end)

    -- Un solo RenderStepped: elige objetivo Y avanza el hold en
    -- el mismo paso, para que ambos usen el mismo estado del frame.
    RunService.RenderStepped:Connect(function()
        updateTarget()

        if not isHolding then return end

        -- Si el objetivo cambió mientras se mantenía E (el
        -- jugador giró la cámara), cancelamos: mantener
        -- presionado nunca debe "saltar" de un maniquí a otro.
        if holdingModel ~= currentTarget then
            cancelHold()
            return
        end

        local elapsed = os.clock() - holdStartTime
        local alpha   = math.clamp(elapsed / HOLD_DURATION, 0, 1)
        local visuals = visualsByModel[holdingModel]
        if visuals then visuals:SetHoldProgress(alpha) end

        if elapsed >= HOLD_DURATION then
            local completedModel = holdingModel
            cancelHold()

            ensureNormalCameraState()

            if onInteractCallback then
                onInteractCallback(completedModel, player)
            end
        end
    end)

    task.delay(3, function()
        local count = 0
        for _ in pairs(visualsByModel) do count += 1 end
        print("[MannequinInteraction] ✅ " .. count .. " maniquíes registrados y listos.")
    end)
end

return MannequinInteraction