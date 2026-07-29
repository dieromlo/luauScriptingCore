-- ============================================================
--  AvatarViewport.lua
--  ModuleScript | StarterPlayerScripts/modules
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Componente de vista previa 3D de un avatar: encuadre
--  automático, rotación automática + arrastre manual, zoom, y
--  controles mini (+/-/reset/auto-rotar). Reutilizable por
--  cualquier panel que necesite mostrar un avatar girando — hoy
--  lo usa OutfitViewerPanel; CustomizePanel podría migrar a este
--  mismo componente en el futuro sin que eso rompa nada hoy.
--
--  EXPONE
--  AvatarViewport.new(container, config?) → instancia
--    container: un Frame ya existente donde se monta el
--    ViewportFrame (ocupa el tamaño completo de container).
--
--  instancia:ShowDescription(humanoidDescription)
--    Construye un avatar directamente desde una
--    HumanoidDescription vía Players:CreateHumanoidModelFrom-
--    Description — sin necesitar ningún Character existente.
--  instancia:ShowCharacter(character)
--    Alternativa: clona un Character ya existente.
--  instancia:Clear()          -- quita el modelo actual
--  instancia:SetActive(bool)  -- pausa el RenderStepped oculto
--  instancia:Destroy()        -- limpieza completa
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIKit    = require(script.Parent.UIKit)
local SoundKit = require(script.Parent.SoundKit)

local C, F_BOLD, F_NORMAL = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_FAST               = UIKit.T_FAST
local uiCorner, uiStroke   = UIKit.uiCorner, UIKit.uiStroke

local AvatarViewport = {}
AvatarViewport.__index = AvatarViewport

local DEFAULTS = {
    fieldOfView = 45, fitPadding = 1.38, lookYBias = 0.04,
    rotSpeed = 0.25, zoomMin = 0.55, zoomMax = 1.8, zoomStep = 0.15,
}

function AvatarViewport.new(container, config)
    config = config or {}
    local self = setmetatable({}, AvatarViewport)

    self.fieldOfView = config.fieldOfView or DEFAULTS.fieldOfView
    self.fitPadding  = config.fitPadding  or DEFAULTS.fitPadding
    self.lookYBias   = config.lookYBias   or DEFAULTS.lookYBias
    self.rotSpeed    = config.rotSpeed    or DEFAULTS.rotSpeed
    self.zoomMin     = config.zoomMin     or DEFAULTS.zoomMin
    self.zoomMax     = config.zoomMax     or DEFAULTS.zoomMax
    self.zoomStep    = config.zoomStep    or DEFAULTS.zoomStep

    self.active       = true
    self.previewModel = nil
    self.baseDistance = 6
    self.lookY        = 0
    self.angle        = 0
    self.zoom         = 1
    self.autoRotate   = true
    self.dragging     = false
    self.dragStartX   = 0

    local viewport = Instance.new("ViewportFrame")
    viewport.Size             = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundColor3 = C.bgCard
    viewport.BorderSizePixel  = 0
    uiCorner(viewport, 18)
    self.stroke = uiStroke(viewport, C.border)
    viewport.Parent = container
    self.frame = viewport

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport
    self.worldModel = worldModel

    local camera = Instance.new("Camera")
    camera.FieldOfView = self.fieldOfView
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    self.camera = camera

    local hint = Instance.new("TextLabel")
    hint.Size             = UDim2.new(1, -20, 0, 18)
    hint.Position         = UDim2.new(0, 14, 0, 12)
    hint.BackgroundTransparency = 1
    hint.TextTransparency = 1
    hint.TextColor3       = C.txtMuted
    hint.TextSize         = 11
    hint.Font             = F_NORMAL
    hint.TextXAlignment   = Enum.TextXAlignment.Left
    hint.Text             = "↺  Arrastra para rotar"
    hint.Parent           = viewport

    viewport.MouseEnter:Connect(function()
        TweenService:Create(hint, T_FAST, {TextTransparency = 0.35}):Play()
    end)
    viewport.MouseLeave:Connect(function()
        TweenService:Create(hint, T_FAST, {TextTransparency = 1}):Play()
    end)

    if config.showControls ~= false then self:_buildControls() end
    self:_bindInput()
    self:_bindRenderLoop()

    return self
end

function AvatarViewport:_buildControls()
    local controls = Instance.new("Frame")
    controls.Size             = UDim2.new(0, 140, 0, 36)
    controls.AnchorPoint      = Vector2.new(1, 1)
    controls.Position         = UDim2.new(1, -12, 1, -12)
    controls.BackgroundTransparency = 1
    controls.Parent           = self.frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 8)
    layout.Parent              = controls

    local function miniButton(glyph, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 32, 0, 32)
        b.BackgroundColor3 = C.bgBtn
        b.Text = glyph
        b.TextColor3 = C.txtSub
        b.Font = F_BOLD
        b.TextSize = 14
        b.BorderSizePixel = 0
        b.LayoutOrder = order
        uiCorner(b, 10)
        local bStroke = uiStroke(b, C.border, 1)
        bStroke.Transparency = 0.8
        b.Parent = controls
        local scale = Instance.new("UIScale", b)

        b.MouseEnter:Connect(function()
            if not b:GetAttribute("Active") then
                SoundKit.PlayHover()
                TweenService:Create(scale, T_FAST, {Scale = 1.06}):Play()
                TweenService:Create(b, T_FAST, {BackgroundColor3 = C.bgBtnHover, TextColor3 = C.txtMain}):Play()
                TweenService:Create(bStroke, T_FAST, {Transparency = 0.4}):Play()
            end
        end)
        b.MouseLeave:Connect(function()
            if not b:GetAttribute("Active") then
                TweenService:Create(scale, T_FAST, {Scale = 1.0}):Play()
                TweenService:Create(b, T_FAST, {BackgroundColor3 = C.bgBtn, TextColor3 = C.txtSub}):Play()
                TweenService:Create(bStroke, T_FAST, {Transparency = 0.8}):Play()
            end
        end)
        b.MouseButton1Down:Connect(function() TweenService:Create(scale, T_FAST, {Scale = 0.92}):Play() end)
        b.MouseButton1Up:Connect(function()
            SoundKit.PlayClick()
            TweenService:Create(scale, T_FAST, {Scale = 1.06}):Play()
        end)
        return b
    end

    local btnZoomIn, btnZoomOut = miniButton("+", 1), miniButton("–", 2)
    local btnReset, btnAutoRot  = miniButton("⟲", 3), miniButton("⟳", 4)

    btnZoomIn.MouseButton1Click:Connect(function()
        self.zoom = math.clamp(self.zoom - self.zoomStep, self.zoomMin, self.zoomMax)
    end)
    btnZoomOut.MouseButton1Click:Connect(function()
        self.zoom = math.clamp(self.zoom + self.zoomStep, self.zoomMin, self.zoomMax)
    end)
    btnReset.MouseButton1Click:Connect(function()
        self.zoom, self.angle = 1, 0
    end)

    local function refreshAutoRot()
        btnAutoRot:SetAttribute("Active", self.autoRotate)
        TweenService:Create(btnAutoRot, T_FAST, {
            BackgroundColor3 = self.autoRotate and C.accent or C.bgBtn,
            TextColor3       = self.autoRotate and C.bgBase or C.txtSub,
        }):Play()
    end
    btnAutoRot.MouseButton1Click:Connect(function()
        self.autoRotate = not self.autoRotate
        refreshAutoRot()
    end)
    refreshAutoRot()
end

function AvatarViewport:_bindInput()
    self.frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            self.dragging, self.dragStartX = true, input.Position.X
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if self.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position.X - self.dragStartX
            self.angle = self.angle - delta * 0.008
            self.dragStartX = input.Position.X
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            self.dragging = false
        end
    end)
end

function AvatarViewport:_fitCamera()
    if not self.previewModel then return end
    local ok, cf, size = pcall(function() return self.previewModel:GetBoundingBox() end)
    if not ok or not size then return end
    local fovRad = math.rad(self.camera.FieldOfView)
    self.baseDistance = (size.Y / 2) / math.tan(fovRad / 2) * self.fitPadding
    self.lookY = cf.Position.Y + (size.Y * self.lookYBias)
end

function AvatarViewport:_bindRenderLoop()
    RunService.RenderStepped:Connect(function(dt)
        if not self.active or not self.previewModel then return end
        local root = self.previewModel:FindFirstChild("HumanoidRootPart") or self.previewModel.PrimaryPart
        if not root then return end

        if self.autoRotate and not self.dragging then
            self.angle = self.angle + dt * self.rotSpeed
        end

        local distance   = self.baseDistance * self.zoom
        local lookCenter = Vector3.new(root.Position.X, self.lookY, root.Position.Z)
        local camX = root.Position.X + math.sin(self.angle) * distance
        local camZ = root.Position.Z + math.cos(self.angle) * distance
        self.camera.CFrame = CFrame.new(Vector3.new(camX, self.lookY, camZ), lookCenter)
    end)
end

function AvatarViewport:Clear()
    if self.previewModel then
        self.previewModel:Destroy()
        self.previewModel = nil
    end
end

local function prepareModel(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Anchored, d.CanCollide = true, false
        elseif d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        end
    end
end

-- Construye un avatar directamente desde una HumanoidDescription
-- — no necesita ningún Character existente.
function AvatarViewport:ShowDescription(description)
    self:Clear()
    if not description then return end

    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
    end)
    if not ok or not model then
        warn("[AvatarViewport] No se pudo construir el modelo de vista previa: " .. tostring(model))
        return
    end

    prepareModel(model)
    model.Parent = self.worldModel
    self.previewModel = model
    self.zoom, self.angle = 1, 0
    self:_fitCamera()
end

-- Alternativa: clona un Character ya existente.
function AvatarViewport:ShowCharacter(character)
    self:Clear()
    if not character then return end

    local originalArchivable = character.Archivable
    character.Archivable = true
    local ok, clone = pcall(function() return character:Clone() end)
    character.Archivable = originalArchivable
    if not ok or not clone then return end

    prepareModel(clone)
    clone.Parent = self.worldModel
    self.previewModel = clone
    self.zoom, self.angle = 1, 0
    self:_fitCamera()
end

function AvatarViewport:SetActive(active)
    self.active = active
end

function AvatarViewport:Destroy()
    self:Clear()
    if self.frame then self.frame:Destroy() end
end

return AvatarViewport