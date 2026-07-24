-- ============================================================
--  MannequinVisuals.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Todo lo que le pasa a UN maniquí cuando se vuelve el
--  objetivo actual: flotación, contorno y tarjeta. No decide
--  CUÁNDO enfocar — solo sabe verse enfocado o no. Eso lo
--  decide MannequinInteraction.lua.
-- ============================================================

local TweenService = game:GetService("TweenService")

local UIKit = require(script.Parent.UIKit)
local C, F_BOLD, F_NORMAL = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_MED                = UIKit.T_MED
local uiCorner, uiStroke   = UIKit.uiCorner, UIKit.uiStroke

local FLOAT_HEIGHT = 0.4
local FLOAT_LOOP   = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local FLOAT_RETURN = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local MannequinVisuals = {}
MannequinVisuals.__index = MannequinVisuals

-- root: se guarda como campo público (self.root) porque el
-- orquestador necesita leer su posición cada frame para calcular
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

    -- ─── Tarjeta de interacción ─────────────────────────────
    local billboard = Instance.new("BillboardGui")
    billboard.Name       = "InteractionCard"
    billboard.Size        = UDim2.new(0, 190, 0, 64)
    billboard.StudsOffset = Vector3.new(0, 1.4, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled     = false
    billboard.Parent      = root

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
    subLbl.Text              = model:GetAttribute("OutfitName") or ""
    subLbl.Parent            = card

    self.billboard  = billboard
    self.card       = card
    self.cardStroke = cardStroke
    self.cardScale  = cardScale
    self.fadeElements = {keyBadge, keyLbl, actionLbl, subLbl}

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

    self.billboard.Enabled = true
    TweenService:Create(self.card, T_MED, {BackgroundTransparency = 0}):Play()
    TweenService:Create(self.cardStroke, T_MED, {Transparency = 0.4}):Play()
    TweenService:Create(self.cardScale, T_MED, {Scale = 1}):Play()
    for _, el in ipairs(self.fadeElements) do
        if el:IsA("TextLabel") then
            TweenService:Create(el, T_MED, {TextTransparency = 0}):Play()
        else
            TweenService:Create(el, T_MED, {BackgroundTransparency = 0}):Play()
        end
    end
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

    TweenService:Create(self.card, T_MED, {BackgroundTransparency = 1}):Play()
    TweenService:Create(self.cardStroke, T_MED, {Transparency = 1}):Play()
    TweenService:Create(self.cardScale, T_MED, {Scale = 0.85}):Play()
    for _, el in ipairs(self.fadeElements) do
        if el:IsA("TextLabel") then
            TweenService:Create(el, T_MED, {TextTransparency = 1}):Play()
        else
            TweenService:Create(el, T_MED, {BackgroundTransparency = 1}):Play()
        end
    end

    task.delay(0.3, function()
        if not self.focused then
            self.highlight.Enabled = false
            self.billboard.Enabled = false
        end
    end)
end

function MannequinVisuals:Destroy()
    if self.floatTween then self.floatTween:Cancel() end
    if self.highlight then self.highlight:Destroy() end
    if self.billboard then self.billboard:Destroy() end
end

return MannequinVisuals