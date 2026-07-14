-- ============================================================
--  ToastSystem.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Notificaciones premium: físicas inerciales, barra integrada,
--  sombras atmosféricas y estética "True Dark" minimalista.
-- ============================================================

local TweenService = game:GetService("TweenService")
local RunService    = game:GetService("RunService")

local ToastSystem = {}

-- ─── CONFIGURACIÓN VISUAL (PROPORCIONES PREMIUM) ──────────────
local TOAST_WIDTH  = 320 -- Mayor anchura para más aire
local STACK_GAP    = 14  -- Separación entre tarjetas
local BASE_POS_X   = 24
local BASE_POS_Y   = 24
local DURATION_DEF = 4.5

local C = {
    Background = Color3.fromRGB(14, 14, 16),
    Title      = Color3.fromRGB(245, 245, 245), -- Blanco ligeramente apagado
    Message    = Color3.fromRGB(160, 160, 160), -- Gris equilibrado
    Stroke     = Color3.fromRGB(255, 255, 255), -- Reflejo de cristal
    Shadow     = Color3.fromRGB(0, 0, 0),
    TrackBg    = Color3.fromRGB(35, 35, 40),    -- Fondo sutil de la barra
}

local TYPES = {
    success = {color = Color3.fromRGB(70, 210, 130), icon = "✓"},
    error   = {color = Color3.fromRGB(240, 80, 100), icon = "✕"},
    info    = {color = Color3.fromRGB(90, 170, 255), icon = "i"},
    warning = {color = Color3.fromRGB(255, 190, 80), icon = "!"},
    neutral = {color = Color3.fromRGB(180, 180, 180), icon = "·"},
}

-- ─── EASINGS FÍSICOS (INERCIA Y RESPIRACIÓN) ──────────────────
-- Entrada posicional (suave y asintótica)
local T_ENTRY_POS   = TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
-- Escala de entrada (el sutil "rebote/respiración")
local T_ENTRY_SCALE = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
-- Opacidad (rápida para que aparezca, suave para que se vaya)
local T_FADE_IN     = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local T_FADE_OUT    = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
-- Apilado inercial (sensación de peso al ser empujadas)
local T_STACK       = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
-- Escala de salida (colapso elegante)
local T_EXIT_SCALE  = TweenInfo.new(0.45, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)

local activeToasts = {}
local containerGUI = nil

function ToastSystem.Init(guiParent)
    containerGUI = guiParent
end

local function getContainer()
    return containerGUI
end

local function updateStackLayout()
    local currentY = BASE_POS_Y
    for _, toastData in ipairs(activeToasts) do
        if toastData.root and toastData.root.Parent then
            local targetPos = UDim2.new(1, -BASE_POS_X, 0, currentY)
            -- El Tween de Stack da la inercia a las tarjetas existentes
            TweenService:Create(toastData.root, T_STACK, {Position = targetPos}):Play()
            currentY = currentY + toastData.root.AbsoluteSize.Y + STACK_GAP
        end
    end
end

local function createToastUI(titleText, messageText, typeData)
    local root = Instance.new("Frame")
    root.Name                   = "ToastRoot"
    root.Size                   = UDim2.new(0, TOAST_WIDTH, 0, 0)
    -- Aparece ligeramente desplazada a la derecha y abajo para el efecto de entrada
    root.Position               = UDim2.new(1, -(BASE_POS_X - 15), 0, BASE_POS_Y + 10)
    root.AnchorPoint            = Vector2.new(1, 0)
    root.BackgroundTransparency = 1
    root.AutomaticSize          = Enum.AutomaticSize.Y
    root.ZIndex                 = 200

    local scale = Instance.new("UIScale")
    scale.Scale = 0.94 -- Respiración sutil
    scale.Parent = root

    -- Sombra atmosférica (Más amplia, más suave, no agresiva)
    local shadow = Instance.new("ImageLabel")
    shadow.Name              = "Shadow"
    shadow.Size              = UDim2.new(1, 50, 1, 50)
    shadow.Position          = UDim2.new(0.5, 0, 0.5, 8) -- Desplazamiento Y para profundidad
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
    card.ZIndex            = root.ZIndex + 1
    card.Parent            = root

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12) -- Bordes ligeramente más premium
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color           = C.Stroke
    stroke.Transparency    = 1
    stroke.Thickness       = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent          = card

    local content = Instance.new("Frame")
    content.Size             = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.ZIndex           = root.ZIndex + 2
    content.Parent           = card

    local padding = Instance.new("UIPadding")
    padding.PaddingTop    = UDim.new(0, 16)
    -- Padding inferior mayor para acomodar la barra de progreso integrada
    padding.PaddingBottom = UDim.new(0, 26) 
    padding.PaddingLeft   = UDim.new(0, 18)
    padding.PaddingRight  = UDim.new(0, 18)
    padding.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.FillDirection     = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder         = Enum.SortOrder.LayoutOrder
    layout.Padding           = UDim.new(0, 14) -- Más separación entre icono y texto
    layout.Parent            = content

    local icon = Instance.new("TextLabel")
    icon.Size              = UDim2.new(0, 22, 0, 22)
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
    textContainer.Size             = UDim2.new(1, -36, 0, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.AutomaticSize     = Enum.AutomaticSize.Y
    textContainer.LayoutOrder       = 2
    textContainer.Parent            = content

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    textLayout.Padding       = UDim.new(0, 4)
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

    -- ─── BARRA DE PROGRESO INTEGRADA Y REFINADA ───
    local progressContainer = Instance.new("Frame")
    progressContainer.Size             = UDim2.new(1, -36, 0, 3) -- 3px de grosor, 18px margen lat.
    progressContainer.Position         = UDim2.new(0, 18, 1, -12) -- 12px desde abajo
    progressContainer.AnchorPoint      = Vector2.new(0, 1)
    progressContainer.BackgroundColor3 = C.TrackBg
    progressContainer.BackgroundTransparency = 1
    progressContainer.BorderSizePixel  = 0
    progressContainer.ZIndex           = root.ZIndex + 3
    progressContainer.Parent           = card

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progressContainer

    local progressFill = Instance.new("Frame")
    progressFill.Size             = UDim2.new(1, 0, 1, 0)
    progressFill.Position         = UDim2.new(1, 0, 0, 0)
    progressFill.AnchorPoint      = Vector2.new(1, 0) -- Se consume hacia la derecha
    progressFill.BackgroundColor3 = typeData.color
    progressFill.BackgroundTransparency = 1
    progressFill.BorderSizePixel  = 0
    progressFill.Parent           = progressContainer

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = progressFill

    return root, scale, progressFill, progressContainer, card, stroke, icon, titleLbl, shadow
end

function ToastSystem.Show(message, toastType, duration)
    local tType     = TYPES[string.lower(toastType or "")] or TYPES.neutral
    local tDuration = duration or DURATION_DEF

    local container = getContainer()
    if not container then return end

    local root, scale, progressFill, progressContainer, card, stroke, icon, titleLbl, shadow =
        createToastUI(message, nil, tType)
    root.Parent = container

    -- Forzamos el cálculo de tamaños automáticos antes de animar posiciones
    RunService.RenderStepped:Wait()

    local toastData = {root = root}
    table.insert(activeToasts, 1, toastData)
    
    -- El layout se actualiza aquí. Empuja a las notificaciones antiguas con inercia.
    updateStackLayout()

    -- ─── SECUENCIA DE ENTRADA (MÚLTIPLES EASINGS) ───
    TweenService:Create(root, T_ENTRY_POS, {Position = UDim2.new(1, -BASE_POS_X, 0, BASE_POS_Y)}):Play()
    TweenService:Create(scale, T_ENTRY_SCALE, {Scale = 1}):Play()
    
    TweenService:Create(card, T_FADE_IN, {BackgroundTransparency = 0}):Play()
    -- Borde cristalino sutil (Transparencia 92%)
    TweenService:Create(stroke, T_FADE_IN, {Transparency = 0.92}):Play() 
    TweenService:Create(icon, T_FADE_IN, {TextTransparency = 0}):Play()
    TweenService:Create(titleLbl, T_FADE_IN, {TextTransparency = 0}):Play()
    TweenService:Create(shadow, T_FADE_IN, {ImageTransparency = 0.65}):Play()
    TweenService:Create(progressContainer, T_FADE_IN, {BackgroundTransparency = 0.4}):Play()

    -- Barra de progreso lineal visible
    TweenService:Create(progressFill, T_FADE_IN, {BackgroundTransparency = 0}):Play()
    TweenService:Create(progressFill, TweenInfo.new(tDuration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 1, 0)}):Play()

    -- ─── SECUENCIA DE SALIDA (SIMULTÁNEA Y FLUIDA) ───
    task.delay(tDuration, function()
        if not root or not root.Parent then return end

        -- 1. Lo removemos del registro lógico inmediatamente
        for i, data in ipairs(activeToasts) do
            if data.root == root then
                table.remove(activeToasts, i)
                break
            end
        end

        -- 2. Al actualizar, las demás tarjetas suben fluidamente para llenar el vacío
        updateStackLayout()

        -- 3. La tarjeta saliente colapsa su espacio, se encoge y desaparece con gracia
        TweenService:Create(scale, T_EXIT_SCALE, {Scale = 0.92}):Play()
        local currentY = root.Position.Y.Offset
        TweenService:Create(root, T_EXIT_SCALE, {Position = UDim2.new(1, -BASE_POS_X, 0, currentY + 6)}):Play()

        TweenService:Create(card, T_FADE_OUT, {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, T_FADE_OUT, {Transparency = 1}):Play()
        TweenService:Create(icon, T_FADE_OUT, {TextTransparency = 1}):Play()
        TweenService:Create(titleLbl, T_FADE_OUT, {TextTransparency = 1}):Play()
        TweenService:Create(shadow, T_FADE_OUT, {ImageTransparency = 1}):Play()
        TweenService:Create(progressContainer, T_FADE_OUT, {BackgroundTransparency = 1}):Play()
        TweenService:Create(progressFill, T_FADE_OUT, {BackgroundTransparency = 1}):Play()

        -- Destrucción limpia
        task.delay(0.5, function()
            root:Destroy()
        end)
    end)
end

return ToastSystem