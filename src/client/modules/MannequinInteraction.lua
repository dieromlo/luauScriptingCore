-- ============================================================
--  MannequinInteraction.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Detecta todos los maniquíes del mapa (sin nombres fijos),
--  les agrega una tarjeta de interacción premium y una
--  animación idle de flotación. No conoce paneles ni
--  MenuManager — solo avisa "esto se activó" a quien se
--  suscriba con OnInteract().
-- ============================================================

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UIKit = require(script.Parent.UIKit)

local C, F_BOLD, F_NORMAL = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_MED                = UIKit.T_MED
local uiCorner, uiStroke   = UIKit.uiCorner, UIKit.uiStroke

local MannequinInteraction = {}

-- ─── Callback externo ────────────────────────────────────────
local onInteractCallback = nil
function MannequinInteraction.OnInteract(callback)
    onInteractCallback = callback
end

-- ─── Animación idle: UN SOLO Heartbeat para todos ──────────────
local floatingMannequins = {} -- [model] = {basePivot=, phase=}
local FLOAT_AMPLITUDE = 1
local FLOAT_SPEED     = 2

RunService.Heartbeat:Connect(function()
    local t = os.clock()
    for model, data in pairs(floatingMannequins) do
        if model.Parent then
            local wave   = (math.sin(t * FLOAT_SPEED + data.phase) + 1) / 2
            local offset = wave * FLOAT_AMPLITUDE
            model:PivotTo(data.basePivot + Vector3.new(0, offset, 0))
        else
            floatingMannequins[model] = nil
        end
    end
end)

local function registerFloatingMannequin(model)
    floatingMannequins[model] = {
        basePivot = model:GetPivot(),
        phase     = math.random() * math.pi * 2, -- desfase para que no floten sincronizados
    }
end

-- ─── Tarjeta de interacción (reemplaza la UI nativa) ───────────
local function buildInteractionCard(prompt, root)
    local billboard = Instance.new("BillboardGui")
    billboard.Name          = "InteractionCard"
    billboard.Size           = UDim2.new(0, 190, 0, 64)
    billboard.StudsOffset    = Vector3.new(0, 1.4, 0)
    billboard.AlwaysOnTop    = true
    billboard.Enabled        = false -- oculta hasta que el jugador esté cerca
    billboard.Parent         = root

    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3       = C.bgBase
    card.BackgroundTransparency = 1
    card.BorderSizePixel        = 0
    uiCorner(card, 14)
    local cardStroke = uiStroke(card, C.border, 1)
    cardStroke.Transparency = 1
    card.Parent = billboard

    local cardScale = Instance.new("UIScale", card)
    cardScale.Scale = 0.85

    -- Tecla resaltada
    local keyBadge = Instance.new("Frame")
    keyBadge.Size                   = UDim2.new(0, 34, 0, 34)
    keyBadge.Position               = UDim2.new(0, 12, 0.5, -17)
    keyBadge.BackgroundColor3       = C.accent
    keyBadge.BackgroundTransparency = 1
    keyBadge.BorderSizePixel        = 0
    uiCorner(keyBadge, 9)
    keyBadge.Parent = card

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size             = UDim2.new(1, 0, 1, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text              = "E"
    keyLbl.TextColor3        = C.bgBase
    keyLbl.TextTransparency  = 1
    keyLbl.Font              = F_BOLD
    keyLbl.TextSize          = 16
    keyLbl.Parent            = keyBadge

    -- Texto principal
    local actionLbl = Instance.new("TextLabel")
    actionLbl.Size             = UDim2.new(1, -58, 0, 20)
    actionLbl.Position         = UDim2.new(0, 56, 0, 12)
    actionLbl.BackgroundTransparency = 1
    actionLbl.TextTransparency = 1
    actionLbl.TextColor3       = C.txtMain
    actionLbl.Font             = F_BOLD
    actionLbl.TextSize         = 14
    actionLbl.TextXAlignment   = Enum.TextXAlignment.Left
    actionLbl.Text             = "Ver Outfit"
    actionLbl.Parent           = card

    -- Subtítulo: usa el ObjectText del prompt (nombre del outfit)
    local subLbl = Instance.new("TextLabel")
    subLbl.Size             = UDim2.new(1, -58, 0, 16)
    subLbl.Position         = UDim2.new(0, 56, 0, 34)
    subLbl.BackgroundTransparency = 1
    subLbl.TextTransparency = 1
    subLbl.TextColor3       = C.txtSub
    subLbl.Font             = F_NORMAL
    subLbl.TextSize         = 11
    subLbl.TextXAlignment   = Enum.TextXAlignment.Left
    subLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    subLbl.Text              = prompt.ObjectText
    subLbl.Parent            = card

    local isShown = false
    local function setShown(shown)
        if isShown == shown then return end
        isShown = shown
        if shown then billboard.Enabled = true end

        TweenService:Create(card, T_MED, {BackgroundTransparency = shown and 0 or 1}):Play()
        TweenService:Create(keyBadge, T_MED, {BackgroundTransparency = shown and 0 or 1}):Play()
        TweenService:Create(cardStroke, T_MED, {Transparency = shown and 0.4 or 1}):Play()
        TweenService:Create(cardScale, T_MED, {Scale = shown and 1 or 0.85}):Play()
        for _, lbl in ipairs({keyLbl, actionLbl, subLbl}) do
            TweenService:Create(lbl, T_MED, {TextTransparency = shown and 0 or 1}):Play()
        end

        if not shown then
            task.delay(0.25, function()
                if not isShown then billboard.Enabled = false end
            end)
        end
    end

    prompt.PromptShown:Connect(function()
        print("[MannequinInteraction] 👁️ PromptShown en: " .. prompt.Parent.Parent.Name)
        setShown(true)
    end)
    prompt.PromptHidden:Connect(function()
        print("[MannequinInteraction] 🙈 PromptHidden en: " .. prompt.Parent.Parent.Name)
        setShown(false)
    end)
end

-- ─── Cablear un maniquí individual (tolerante a la replicación) ─
-- Cada maniquí se configura en su propia corrutina: si uno tarda
-- más en replicar sus partes, no bloquea a los demás.
local connectedCount = 0

local function setupMannequin(model)
    if not model:IsA("Model") then return end

    task.spawn(function()
        local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
        if not root then
            root = model:WaitForChild("HumanoidRootPart", 10)
        end
        if not root then
            warn("[MannequinInteraction] ⚠️ " .. model.Name .. ": HumanoidRootPart no llegó tras 10s.")
            return
        end

        local prompt = root:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then
            prompt = root:WaitForChild("ProximityPrompt", 10)
        end
        if not prompt then
            warn("[MannequinInteraction] ⚠️ " .. model.Name .. ": ProximityPrompt no llegó tras 10s.")
            return
        end

        buildInteractionCard(prompt, root)
        registerFloatingMannequin(model)

        prompt.Triggered:Connect(function(player)
            if onInteractCallback then
                onInteractCallback(model, player)
            end
        end)

        connectedCount += 1
    end)
end

-- ─── Init: detecta todos los maniquíes existentes + futuros ───
function MannequinInteraction.Init()
    print("[MannequinInteraction] 🔵 Init() llamado, buscando maniquíes...")

    local mannequinsFolder = workspace:WaitForChild("Mannequins", 15)
    if not mannequinsFolder then
        warn("[MannequinInteraction] ⚠️ No se encontró workspace.Mannequins tras 15s de espera.")
        return
    end

    for _, m in ipairs(mannequinsFolder:GetChildren()) do
        setupMannequin(m)
    end
    mannequinsFolder.ChildAdded:Connect(setupMannequin)

    -- El conteo final se imprime con un pequeño margen, ya que
    -- cada maniquí termina de conectarse en su propio momento
    -- (no todos en el mismo frame).
    task.delay(3, function()
        print("[MannequinInteraction] ✅ " .. connectedCount .. " maniquíes conectados con tarjeta de interacción.")
    end)
end
return MannequinInteraction