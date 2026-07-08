-- ============================================================
--  ToastSystem.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Notificaciones premium: stacking dinámico, sombra, slide +
--  scale + fade, barra de progreso lineal.
-- ============================================================

local TweenService = game:GetService("TweenService")
local RunService    = game:GetService("RunService")

local ToastSystem = {}

local TOAST_WIDTH  = 300
local STACK_GAP    = 12
local BASE_POS_X   = 24
local BASE_POS_Y   = 24
local DURATION_DEF = 4.5

local C = {
    Background = Color3.fromRGB(14, 14, 16),
    Title      = Color3.fromRGB(255, 255, 255),
    Message    = Color3.fromRGB(170, 170, 170),
    Stroke     = Color3.fromRGB(255, 255, 255),
    Shadow     = Color3.fromRGB(0, 0, 0),
}

-- Íconos como texto: siempre se ven, cero dependencia de Asset IDs
local TYPES = {
    success = {color = Color3.fromRGB(70, 210, 130), icon = "✓"},
    error   = {color = Color3.fromRGB(240, 80, 100), icon = "✕"},
    info    = {color = Color3.fromRGB(90, 170, 255), icon = "i"},
    warning = {color = Color3.fromRGB(255, 190, 80), icon = "!"},
    neutral = {color = Color3.fromRGB(180, 180, 180), icon = "·"},
}

local T_SLIDE = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_FADE  = TweenInfo.new(0.35, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

local activeToasts = {}
local containerGUI = nil

-- Antes creaba su propio ScreenGui aparte. Ahora usa el GUI
-- compartido que arma OutfitClient (el mismo de Settings/Outfit/
-- Customize/ResetConfirm).
function ToastSystem.Init(guiParent)
    containerGUI = guiParent
end

local function getContainer()
    return containerGUI
end

local function applyFade(element, targetTransparency)
    if element:IsA("TextLabel") then
        TweenService:Create(element, T_FADE, {TextTransparency = targetTransparency}):Play()
    elseif element:IsA("ImageLabel") then
        TweenService:Create(element, T_FADE, {ImageTransparency = targetTransparency}):Play()
    elseif element:IsA("Frame") then
        TweenService:Create(element, T_FADE, {BackgroundTransparency = targetTransparency}):Play()
    elseif element:IsA("UIStroke") then
        local alpha = targetTransparency == 0 and 0.92 or 1
        TweenService:Create(element, T_FADE, {Transparency = alpha}):Play()
    end
    for _, child in ipairs(element:GetChildren()) do
        applyFade(child, targetTransparency)
    end
end

local function updateStackLayout()
    local currentY = BASE_POS_Y
    for _, toastData in ipairs(activeToasts) do
        if toastData.root and toastData.root.Parent then
            local targetPos = UDim2.new(1, -BASE_POS_X, 0, currentY)
            TweenService:Create(toastData.root, T_SLIDE, {Position = targetPos}):Play()
            currentY = currentY + toastData.root.AbsoluteSize.Y + STACK_GAP
        end
    end
end

local function createToastUI(titleText, messageText, typeData)
    local root = Instance.new("Frame")
    root.Name                   = "ToastRoot"
    root.Size                   = UDim2.new(0, TOAST_WIDTH, 0, 0)
    root.Position                = UDim2.new(1, 0, 0, BASE_POS_Y)
    root.AnchorPoint             = Vector2.new(1, 0)
    root.BackgroundTransparency = 1
    root.AutomaticSize           = Enum.AutomaticSize.Y
    root.ZIndex                  = 200 -- Encima de cualquier modal abierto

    local scale = Instance.new("UIScale")
    scale.Scale = 0.9
    scale.Parent = root

    local shadow = Instance.new("ImageLabel")
    shadow.Name              = "Shadow"
    shadow.Size              = UDim2.new(1, 30, 1, 30)
    shadow.Position          = UDim2.new(0.5, 0, 0.5, 4)
    shadow.AnchorPoint       = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image             = "rbxassetid://13162797317"
    shadow.ImageColor3       = C.Shadow
    shadow.ImageTransparency = 1
    shadow.ScaleType         = Enum.ScaleType.Slice
    shadow.SliceCenter       = Rect.new(10, 10, 118, 118)
    shadow.ZIndex            = root.ZIndex
    shadow.Parent            = root

    local card = Instance.new("Frame")
    card.Name              = "Card"
    card.Size              = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3  = C.Background
    card.BackgroundTransparency = 1
    card.ClipsDescendants  = true
    card.ZIndex             = root.ZIndex + 1
    card.Parent             = root

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color           = C.Stroke
    stroke.Transparency     = 1
    stroke.Thickness        = 1
    stroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    stroke.Parent           = card

    local content = Instance.new("Frame")
    content.Size             = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.ZIndex           = root.ZIndex + 2
    content.Parent           = card

    local padding = Instance.new("UIPadding")
    padding.PaddingTop    = UDim.new(0, 14)
    padding.PaddingBottom = UDim.new(0, 14)
    padding.PaddingLeft   = UDim.new(0, 18)
    padding.PaddingRight  = UDim.new(0, 18)
    padding.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.FillDirection     = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder         = Enum.SortOrder.LayoutOrder
    layout.Padding           = UDim.new(0, 14)
    layout.Parent            = content

    local icon = Instance.new("TextLabel")
    icon.Size              = UDim2.new(0, 20, 0, 20)
    icon.BackgroundTransparency = 1
    icon.Text               = typeData.icon
    icon.TextColor3         = typeData.color
    icon.TextTransparency   = 1
    icon.Font               = Enum.Font.GothamBold
    icon.TextSize           = 16
    icon.LayoutOrder        = 1
    icon.ZIndex             = root.ZIndex + 3
    icon.Parent             = content

    local textContainer = Instance.new("Frame")
    textContainer.Size             = UDim2.new(1, -34, 0, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.AutomaticSize     = Enum.AutomaticSize.Y
    textContainer.LayoutOrder       = 2
    textContainer.Parent            = content

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    textLayout.Padding       = UDim.new(0, 3)
    textLayout.Parent        = textContainer

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size             = UDim2.new(1, 0, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text              = titleText
    titleLbl.TextColor3        = C.Title
    titleLbl.TextTransparency  = 1
    titleLbl.Font              = Enum.Font.GothamBold
    titleLbl.TextSize          = 14
    titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
    titleLbl.AutomaticSize     = Enum.AutomaticSize.Y
    titleLbl.TextWrapped       = true
    titleLbl.LayoutOrder       = 1
    titleLbl.ZIndex            = root.ZIndex + 3
    titleLbl.Parent            = textContainer

    if messageText and messageText ~= "" then
        local msgLbl = Instance.new("TextLabel")
        msgLbl.Size             = UDim2.new(1, 0, 0, 0)
        msgLbl.BackgroundTransparency = 1
        msgLbl.Text              = messageText
        msgLbl.TextColor3        = C.Message
        msgLbl.TextTransparency  = 1
        msgLbl.Font              = Enum.Font.Gotham
        msgLbl.TextSize          = 12
        msgLbl.TextXAlignment    = Enum.TextXAlignment.Left
        msgLbl.AutomaticSize     = Enum.AutomaticSize.Y
        msgLbl.TextWrapped       = true
        msgLbl.LayoutOrder       = 2
        msgLbl.ZIndex            = root.ZIndex + 3
        msgLbl.Parent            = textContainer
    else
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
    end

    local progressTrack = Instance.new("Frame")
    progressTrack.Size             = UDim2.new(1, 0, 0, 2)
    progressTrack.Position         = UDim2.new(0, 0, 1, 0)
    progressTrack.AnchorPoint      = Vector2.new(0, 1)
    progressTrack.BackgroundTransparency = 1
    progressTrack.BorderSizePixel  = 0
    progressTrack.ZIndex           = root.ZIndex + 4
    progressTrack.Parent           = card

    local progressFill = Instance.new("Frame")
    progressFill.Size             = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = typeData.color
    progressFill.BackgroundTransparency = 1
    progressFill.BorderSizePixel  = 0
    progressFill.Parent           = progressTrack

    return root, scale, progressFill
end

-- ─── API PÚBLICA ─────────────────────────────────────────────
-- Misma firma que ya usa todo el proyecto: Show(message, type, duration)
function ToastSystem.Show(message, toastType, duration)
    local tType     = TYPES[string.lower(toastType or "")] or TYPES.neutral
    local tDuration = duration or DURATION_DEF

    local container = getContainer()
    if not container then
        warn("[ToastSystem] ⚠️ Show() llamado antes de Init(). Notificación ignorada.")
        return
    end

    local root, scale, progressFill = createToastUI(message, nil, tType)
    root.Parent = container

    RunService.RenderStepped:Wait()

    local toastData = {root = root}
    table.insert(activeToasts, 1, toastData)
    updateStackLayout()

    TweenService:Create(scale, T_SLIDE, {Scale = 1}):Play()
    applyFade(root, 0)
    TweenService:Create(root.Shadow, T_FADE, {ImageTransparency = 0.5}):Play()

    TweenService:Create(progressFill, TweenInfo.new(tDuration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 1, 0)}):Play()

    task.delay(tDuration, function()
        if not root or not root.Parent then return end

        for i, data in ipairs(activeToasts) do
            if data.root == root then
                table.remove(activeToasts, i)
                break
            end
        end

        TweenService:Create(scale, T_FADE, {Scale = 0.95}):Play()
        applyFade(root, 1)

        local currentY = root.Position.Y.Offset
        TweenService:Create(root, T_FADE, {Position = UDim2.new(1, 0, 0, currentY)}):Play()

        updateStackLayout()

        task.delay(0.4, function()
            root:Destroy()
        end)
    end)
end

return ToastSystem