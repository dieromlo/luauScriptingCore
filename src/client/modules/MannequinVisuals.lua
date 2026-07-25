-- ============================================================
--  MannequinVisuals.lua
--  ModuleScript | StarterPlayerScripts/modules
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Todo lo que le pasa a UN maniquí cuando se vuelve el
--  objetivo actual: flotación, contorno, e indicador de
--  interacción con su anillo de progreso (hold). No decide
--  CUÁNDO enfocar ni cuánto dura el hold — eso lo decide
--  MannequinInteraction.lua. Este módulo solo sabe verse
--  enfocado, desenfocado, o "a medio mantener presionado".
--
--  DEPENDENCIAS
--  UIKit.lua
--
--  EXPONE
--  MannequinVisuals.new(model, root) → instancia
--  instancia:Focus()               -- flotar + contorno + badge
--  instancia:Unfocus()             -- volver todo a su estado base
--  instancia:SetHoldProgress(alpha) -- 0..1, llena el anillo
--  instancia:CancelHold()          -- regresa el anillo a 0 suave
--  instancia:Destroy()             -- limpieza al desaparecer
-- ============================================================

local TweenService = game:GetService("TweenService")

local UIKit = require(script.Parent.UIKit)
local C, F_BOLD = UIKit.C, UIKit.F_BOLD
local T_MED, T_FAST = UIKit.T_MED, UIKit.T_FAST
local uiCorner, uiStroke = UIKit.uiCorner, UIKit.uiStroke

local FLOAT_HEIGHT = 0.4
local FLOAT_LOOP   = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local FLOAT_RETURN = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local MannequinVisuals = {}
MannequinVisuals.__index = MannequinVisuals

-- root: guardado como campo público porque el orquestador
-- necesita leer su posición cada frame para calcular
-- distancia/alineación, sin tener que volver a buscarla.
function MannequinVisuals.new(model, root)
    local self = setmetatable({}, MannequinVisuals)

    self.model      = model
    self.root       = root
    self.basePivot  = model:GetPivot()
    self.floatTween = nil
    self.focused    = false

    -- ─── Contorno ────────────────────────────────────────────
    local highlight = Instance.new("Highlight")
    highlight.FillColor           = C.accent
    highlight.FillTransparency    = 1
    highlight.OutlineColor        = C.accent
    highlight.OutlineTransparency = 1
    highlight.Enabled             = false
    highlight.Adornee             = model
    highlight.Parent              = model
    self.highlight = highlight

    -- ─── Indicador compacto: solo un círculo con "E" y un
    --     anillo de progreso que crece desde el centro mientras
    --     se mantiene presionada la tecla. Sin nombre de outfit,
    --     sin texto adicional — pediste algo pequeño y limpio.
    local billboard = Instance.new("BillboardGui")
    billboard.Name         = "InteractionIndicator"
    billboard.Size          = UDim2.new(0, 44, 0, 44)
    billboard.StudsOffset   = Vector3.new(0, 1.2, 0)
    billboard.AlwaysOnTop   = true
    billboard.Enabled       = false
    billboard.Parent        = root

    local badge = Instance.new("Frame")
    badge.Size                   = UDim2.new(1, 0, 1, 0)
    badge.BackgroundColor3       = C.bgBase
    badge.BackgroundTransparency = 1
    badge.BorderSizePixel        = 0
    uiCorner(badge, 22)
    local badgeStroke = uiStroke(badge, C.border, 1.2)
    badgeStroke.Transparency = 1
    badge.Parent = billboard

    local badgeScale = Instance.new("UIScale", badge)
    badgeScale.Scale = 0.7

    -- Anillo de progreso: crece desde el centro hacia afuera.
    local progressFill = Instance.new("Frame")
    progressFill.AnchorPoint       = Vector2.new(0.5, 0.5)
    progressFill.Position          = UDim2.new(0.5, 0, 0.5, 0)
    progressFill.Size              = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3  = C.accent
    progressFill.BackgroundTransparency = 0.2
    progressFill.BorderSizePixel   = 0
    progressFill.ZIndex            = 2
    uiCorner(progressFill, 22)
    progressFill.Parent = badge

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size             = UDim2.new(1, 0, 1, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text              = "E"
    keyLbl.TextColor3        = C.txtMain
    keyLbl.TextTransparency  = 1
    keyLbl.Font              = F_BOLD
    keyLbl.TextSize          = 15
    keyLbl.ZIndex            = 3
    keyLbl.Parent            = badge

    self.billboard    = billboard
    self.badge         = badge
    self.badgeStroke   = badgeStroke
    self.badgeScale    = badgeScale
    self.progressFill  = progressFill
    self.keyLbl        = keyLbl

    return self
end

function MannequinVisuals:Focus()
    if self.focused then return end
    self.focused = true

    if self.floatTween then self.floatTween:Cancel() end
    self.floatTween = TweenService:Create(self.model, FLOAT_LOOP, {
        WorldPivot = self.basePivot + Vector3.new(0, FLOAT_HEIGHT, 0)
    })
    self.floatTween:Play()

    self.highlight.Enabled = true
    TweenService:Create(self.highlight, T_MED, {
        FillTransparency = 0.85, OutlineTransparency = 0.25
    }):Play()

    self.progressFill.Size = UDim2.new(0, 0, 0, 0)
    self.billboard.Enabled = true
    TweenService:Create(self.badge, T_MED, {BackgroundTransparency = 0}):Play()
    TweenService:Create(self.badgeStroke, T_MED, {Transparency = 0.4}):Play()
    TweenService:Create(self.badgeScale, T_MED, {Scale = 1}):Play()
    TweenService:Create(self.keyLbl, T_MED, {TextTransparency = 0}):Play()
end

function MannequinVisuals:Unfocus()
    if not self.focused then return end
    self.focused = false

    -- Cancela el loop infinito y regresa suavemente a la pose
    -- base, desde donde sea que esté en ese instante — sin salto.
    if self.floatTween then self.floatTween:Cancel() end
    self.floatTween = TweenService:Create(self.model, FLOAT_RETURN, {WorldPivot = self.basePivot})
    self.floatTween:Play()

    TweenService:Create(self.highlight, T_MED, {FillTransparency = 1, OutlineTransparency = 1}):Play()

    self.progressFill.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(self.badge, T_MED, {BackgroundTransparency = 1}):Play()
    TweenService:Create(self.badgeStroke, T_MED, {Transparency = 1}):Play()
    TweenService:Create(self.badgeScale, T_MED, {Scale = 0.7}):Play()
    TweenService:Create(self.keyLbl, T_MED, {TextTransparency = 1}):Play()

    task.delay(0.3, function()
        if not self.focused then
            self.highlight.Enabled = false
            self.billboard.Enabled = false
        end
    end)
end

-- alpha: 0..1. Se llama cada frame mientras se mantiene E
-- presionada — asignación directa, no tween (ya se actualiza
-- constantemente, un tween por-frame competiría consigo mismo).
function MannequinVisuals:SetHoldProgress(alpha)
    alpha = math.clamp(alpha, 0, 1)
    self.progressFill.Size = UDim2.new(alpha, 0, alpha, 0)
end

-- Se soltó E antes de completar el hold: el anillo regresa a
-- cero con una transición suave, no de golpe.
function MannequinVisuals:CancelHold()
    TweenService:Create(self.progressFill, T_FAST, {Size = UDim2.new(0, 0, 0, 0)}):Play()
end

function MannequinVisuals:Destroy()
    if self.floatTween then self.floatTween:Cancel() end
    if self.highlight then self.highlight:Destroy() end
    if self.billboard then self.billboard:Destroy() end
end

return MannequinVisuals