-- ============================================================
--  CustomizePanel.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Panel de personalización: viewport 3D con encuadre
--  automático + zoom/reset/auto-rotar, lista de prendas con
--  reconciliación en vivo, highlight cruzado con el avatar.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local UIKit       = require(script.Parent.UIKit)
local SoundKit    = require(script.Parent.SoundKit)
local MenuManager = require(script.Parent.MenuManager)

local C, F_BOLD, F_NORMAL   = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_FAST, T_MED, T_SLOW = UIKit.T_FAST, UIKit.T_MED, UIKit.T_SLOW
local ICONS                  = UIKit.ICONS
local uiCorner, uiStroke     = UIKit.uiCorner, UIKit.uiStroke

local player = Players.LocalPlayer

local playHover       = SoundKit.PlayHover
local playClick       = SoundKit.PlayClick
local playSoundBuy    = SoundKit.PlayBuy
local playSoundRemove = SoundKit.PlayRemove

local CustomizePanel = {}

-- guiParent   → GUI compartido
-- RemoveItem  → RemoteEvent RemoveItem
-- BuyOutfit   → RemoteEvent BuyOutfit
-- showToast   → función showToast de OutfitClient
function CustomizePanel.Init(guiParent, RemoveItem, BuyOutfit, showToast)

    local CW, CH       = 1120, 610
    local CUSTOM_HIDE  = UDim2.new(0.5, -CW/2, 1.5, 0)
    local CUSTOM_SHOW  = UDim2.new(0.5, -CW/2, 0.5, -CH/2)

    local Panel = Instance.new("Frame")
    Panel.Name             = "CustomizePanel"
    Panel.Size             = UDim2.new(0, CW, 0, CH)
    Panel.Position         = CUSTOM_HIDE
    Panel.BackgroundColor3 = C.bgBase
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 10
    uiCorner(Panel, 20)
    uiStroke(Panel, C.border, 1.5)
    Panel.Parent = guiParent

    local custTitle = Instance.new("TextLabel")
    custTitle.Size             = UDim2.new(1, -100, 0, 40)
    custTitle.Position         = UDim2.new(0, 32, 0, 24)
    custTitle.BackgroundTransparency = 1
    custTitle.TextColor3       = C.txtMain
    custTitle.TextSize         = 28
    custTitle.Font             = F_BOLD
    custTitle.TextXAlignment   = Enum.TextXAlignment.Left
    custTitle.Text             = "Personaliza tu Look"
    custTitle.ZIndex           = 11
    custTitle.Parent           = Panel

    local custSubtitle = Instance.new("TextLabel")
    custSubtitle.Size             = UDim2.new(1, -100, 0, 20)
    custSubtitle.Position         = UDim2.new(0, 32, 0, 64)
    custSubtitle.BackgroundTransparency = 1
    custSubtitle.TextColor3       = C.txtSub
    custSubtitle.TextSize         = 13
    custSubtitle.Font             = F_NORMAL
    custSubtitle.TextXAlignment   = Enum.TextXAlignment.Left
    custSubtitle.Text             = "Revisa las prendas y accesorios que llevas equipados"
    custSubtitle.ZIndex           = 11
    custSubtitle.Parent           = Panel

    local btnCustClose = Instance.new("ImageButton")
    btnCustClose.Size             = UDim2.new(0, 36, 0, 36)
    btnCustClose.Position         = UDim2.new(1, -54, 0, 26)
    btnCustClose.BackgroundColor3 = C.bgBtn
    btnCustClose.Image            = ICONS.Close
    btnCustClose.ImageColor3      = C.txtSub
    btnCustClose.BorderSizePixel  = 0
    btnCustClose.ZIndex           = 12
    uiCorner(btnCustClose, 10)
    btnCustClose.Parent = Panel

    local closeScale = Instance.new("UIScale", btnCustClose)
    btnCustClose.MouseEnter:Connect(function()
        playHover()
        TweenService:Create(closeScale, T_FAST, {Scale = 1.08}):Play()
        TweenService:Create(btnCustClose, T_FAST, {BackgroundColor3 = C.bgBtnHover, ImageColor3 = C.accent, Rotation = 90}):Play()
    end)
    btnCustClose.MouseLeave:Connect(function()
        TweenService:Create(closeScale, T_FAST, {Scale = 1}):Play()
        TweenService:Create(btnCustClose, T_FAST, {BackgroundColor3 = C.bgBtn, ImageColor3 = C.txtSub, Rotation = 0}):Play()
    end)

    local custDivider = Instance.new("Frame")
    custDivider.Size             = UDim2.new(1, -64, 0, 1)
    custDivider.Position         = UDim2.new(0, 32, 0, 96)
    custDivider.BackgroundColor3 = C.border
    custDivider.BorderSizePixel  = 0
    custDivider.ZIndex           = 11
    custDivider.Parent           = Panel

    -- ─── VIEWPORT 3D ────────────────────────────────────────────
    local previewViewport = Instance.new("ViewportFrame")
    previewViewport.Size             = UDim2.new(0, 480, 0, 470)
    previewViewport.Position         = UDim2.new(0, 32, 0, 114)
    previewViewport.BackgroundColor3 = C.bgCard
    previewViewport.BorderSizePixel  = 0
    previewViewport.ZIndex           = 11
    uiCorner(previewViewport, 18)
    local previewViewportStroke = uiStroke(previewViewport, C.border)
    previewViewport.Parent = Panel

    local function pulseViewport()
        TweenService:Create(previewViewportStroke, T_FAST, {Color = C.accent}):Play()
        task.delay(0.18, function()
            TweenService:Create(previewViewportStroke, T_MED, {Color = C.border}):Play()
        end)
    end

    local previewWorldModel = Instance.new("WorldModel")
    previewWorldModel.Parent = previewViewport

    local previewCamera = Instance.new("Camera")
    previewCamera.FieldOfView = 45
    previewCamera.Parent = previewViewport
    previewViewport.CurrentCamera = previewCamera

    local previewHint = Instance.new("TextLabel")
    previewHint.Size             = UDim2.new(1, -20, 0, 18)
    previewHint.Position         = UDim2.new(0, 14, 0, 12)
    previewHint.BackgroundTransparency = 1
    previewHint.TextTransparency = 1
    previewHint.TextColor3       = C.txtMuted
    previewHint.TextSize         = 11
    previewHint.Font             = F_NORMAL
    previewHint.TextXAlignment   = Enum.TextXAlignment.Left
    previewHint.Text             = "↺  Arrastra para rotar"
    previewHint.ZIndex           = 13
    previewHint.Parent           = previewViewport

    previewViewport.MouseEnter:Connect(function()
        TweenService:Create(previewHint, T_FAST, {TextTransparency = 0.35}):Play()
    end)
    previewViewport.MouseLeave:Connect(function()
        TweenService:Create(previewHint, T_FAST, {TextTransparency = 1}):Play()
    end)

    local viewportControls = Instance.new("Frame")
    viewportControls.Size             = UDim2.new(0, 140, 0, 36)
    viewportControls.AnchorPoint      = Vector2.new(1, 1)
    viewportControls.Position         = UDim2.new(1, -12, 1, -12)
    viewportControls.BackgroundTransparency = 1
    viewportControls.ZIndex           = 13
    viewportControls.Parent           = previewViewport

    local vcLayout = Instance.new("UIListLayout")
    vcLayout.FillDirection       = Enum.FillDirection.Horizontal
    vcLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    vcLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    vcLayout.Padding             = UDim.new(0, 8)
    vcLayout.Parent              = viewportControls

    local function makeMiniBtn(glyph, order)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 32, 0, 32)
        b.BackgroundColor3 = C.bgBtn
        b.Text             = glyph
        b.TextColor3       = C.txtSub
        b.Font             = F_BOLD
        b.TextSize         = 14
        b.BorderSizePixel  = 0
        b.LayoutOrder      = order
        b.ZIndex           = 14
        uiCorner(b, 10)
        b.Parent = viewportControls

        local scale = Instance.new("UIScale", b)

        b.MouseEnter:Connect(function()
            if not b:GetAttribute("Active") then
                playHover()
                TweenService:Create(scale, T_FAST, {Scale = 1.08}):Play()
                TweenService:Create(b, T_FAST, {BackgroundColor3 = C.bgBtnHover, TextColor3 = C.txtMain}):Play()
            end
        end)
        b.MouseLeave:Connect(function()
            if not b:GetAttribute("Active") then
                TweenService:Create(scale, T_FAST, {Scale = 1.0}):Play()
                TweenService:Create(b, T_FAST, {BackgroundColor3 = C.bgBtn, TextColor3 = C.txtSub}):Play()
            end
        end)
        b.MouseButton1Down:Connect(function()
            TweenService:Create(scale, T_FAST, {Scale = 0.92}):Play()
        end)
        b.MouseButton1Up:Connect(function()
            playClick()
            TweenService:Create(scale, T_FAST, {Scale = 1.08}):Play()
        end)

        return b, scale
    end

    local btnZoomIn, scIn   = makeMiniBtn("+", 1)
    local btnZoomOut, scOut = makeMiniBtn("–", 2)
    local btnCamReset, scRst= makeMiniBtn("⟲", 3)
    local btnAutoRot, scRot = makeMiniBtn("⟳", 4)

    -- ─── LISTA DE ITEMS ───────────────────────────────────────────
    local ROW_H, ROW_GAP = 96, 12

    local gridContainer = Instance.new("ScrollingFrame")
    gridContainer.Size                   = UDim2.new(0, 540, 0, 470)
    gridContainer.Position               = UDim2.new(0, 544, 0, 114)
    gridContainer.BackgroundTransparency = 1
    gridContainer.BorderSizePixel        = 0
    gridContainer.ScrollBarThickness     = 3
    gridContainer.ScrollBarImageColor3   = C.txtMuted
    gridContainer.CanvasSize             = UDim2.new(0, 0, 0, 0)
    gridContainer.ZIndex                 = 11
    gridContainer.Parent                 = Panel

    local gridPadding = Instance.new("UIPadding")
    gridPadding.PaddingRight  = UDim.new(0, 10)
    gridPadding.PaddingTop    = UDim.new(0, 4)
    gridPadding.PaddingBottom = UDim.new(0, 4)
    gridPadding.Parent = gridContainer

    gridContainer.ScrollBarImageTransparency = 1
    local scrollFadeTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local hideScrollDelay = 1.2
    local hideScrollTask = nil

    local function showScrollbar()
        TweenService:Create(gridContainer, scrollFadeTweenInfo, {ScrollBarImageTransparency = 0}):Play()
        if hideScrollTask then task.cancel(hideScrollTask) end
        hideScrollTask = task.delay(hideScrollDelay, function()
            TweenService:Create(gridContainer, scrollFadeTweenInfo, {ScrollBarImageTransparency = 1}):Play()
        end)
    end

    gridContainer.MouseEnter:Connect(showScrollbar)
    gridContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(showScrollbar)

    local emptyStateContainer = Instance.new("Frame")
    emptyStateContainer.Size             = UDim2.new(1, 0, 0, 160)
    emptyStateContainer.Position         = UDim2.new(0, 0, 0, 60)
    emptyStateContainer.BackgroundTransparency = 1
    emptyStateContainer.Visible          = false
    emptyStateContainer.ZIndex           = 11
    emptyStateContainer.Parent           = gridContainer

    local emptyIcon = Instance.new("Frame")
    emptyIcon.Size             = UDim2.new(0, 48, 0, 48)
    emptyIcon.Position         = UDim2.new(0.5, -24, 0, 0)
    emptyIcon.BackgroundTransparency = 1
    emptyIcon.ZIndex           = 12
    uiCorner(emptyIcon, 24)
    uiStroke(emptyIcon, C.border, 1.5)
    emptyIcon.Parent = emptyStateContainer

    local emptyTitle = Instance.new("TextLabel")
    emptyTitle.Size             = UDim2.new(1, -32, 0, 22)
    emptyTitle.Position         = UDim2.new(0, 16, 0, 64)
    emptyTitle.BackgroundTransparency = 1
    emptyTitle.TextColor3       = C.txtSub
    emptyTitle.Font             = Enum.Font.GothamMedium
    emptyTitle.TextSize         = 15
    emptyTitle.Text             = "No llevas ningún objeto equipado"
    emptyTitle.ZIndex           = 12
    emptyTitle.Parent           = emptyStateContainer

    local emptySubtitle = Instance.new("TextLabel")
    emptySubtitle.Size             = UDim2.new(1, -32, 0, 18)
    emptySubtitle.Position         = UDim2.new(0, 16, 0, 90)
    emptySubtitle.BackgroundTransparency = 1
    emptySubtitle.TextColor3       = C.txtMuted
    emptySubtitle.Font             = F_NORMAL
    emptySubtitle.TextSize         = 12
    emptySubtitle.Text             = "Prueba un outfit desde uno de los maniquíes"
    emptySubtitle.ZIndex           = 12
    emptySubtitle.Parent           = emptyStateContainer

    -- ─── Preview 3D ────────────────────────────────────────────
    local previewModel        = nil
    local previewBasePivot    = nil
    local previewAngle        = 0
    local previewBaseDistance = 6
    local previewLookY        = 0
    local zoomMultiplier      = 1
    local autoRotateEnabled   = true
    local isDraggingPreview   = false
    local dragStartX          = 0
    local dragStartAngle      = 0
    local breathTime          = 0

    local PREVIEW_ROT_SPEED = 0.3
    local ZOOM_MIN, ZOOM_MAX, ZOOM_STEP = 0.55, 1.8, 0.12
    local FIT_PADDING   = 1.38
    local LOOK_Y_BIAS   = 0.04
    local BREATH_AMPLITUDE = 0.035
    local BREATH_SPEED     = 1.1

    local function fitCameraToModel()
        if not previewModel then return end
        local ok, cf, size = pcall(function() return previewModel:GetBoundingBox() end)
        if not ok or not size then return end
        local fovRad = math.rad(previewCamera.FieldOfView)
        previewBaseDistance = (size.Y / 2) / math.tan(fovRad / 2) * FIT_PADDING
        previewLookY = cf.Position.Y + (size.Y * LOOK_Y_BIAS)
    end

    local function loadPreviewCharacter()
        if previewModel then previewModel:Destroy() end
        local char = player.Character
        if not char then return end

        local originalArchivable = char.Archivable
        char.Archivable = true
        local clone = char:Clone()
        char.Archivable = originalArchivable
        if not clone then return end

        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored   = true
                d.CanCollide = false
            end
        end

        clone.Parent = previewWorldModel
        previewModel = clone

        zoomMultiplier = 1
        fitCameraToModel()
        previewBasePivot = previewModel:GetPivot()
        breathTime = 0
    end

    RunService.RenderStepped:Connect(function(dt)
        if not previewModel or not Panel.Visible then return end
        local root = previewModel:FindFirstChild("HumanoidRootPart") or previewModel.PrimaryPart
        if not root then return end

        if autoRotateEnabled and not isDraggingPreview then
            previewAngle += dt * PREVIEW_ROT_SPEED
        end

        breathTime += dt * BREATH_SPEED
        if previewBasePivot then
            local breathOffset = math.sin(breathTime) * BREATH_AMPLITUDE
            previewModel:PivotTo(previewBasePivot + Vector3.new(0, breathOffset, 0))
        end

        local distance   = previewBaseDistance * zoomMultiplier
        local lookCenter = Vector3.new(root.Position.X, previewLookY, root.Position.Z)
        local camX       = root.Position.X + math.sin(previewAngle) * distance
        local camZ       = root.Position.Z + math.cos(previewAngle) * distance

        previewCamera.CFrame = CFrame.new(Vector3.new(camX, previewLookY, camZ), lookCenter)
    end)

    previewViewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingPreview = true
            dragStartX        = input.Position.X
            dragStartAngle    = previewAngle
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingPreview and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position.X - dragStartX
            previewAngle = dragStartAngle - delta * 0.01
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingPreview = false
        end
    end)

    btnZoomIn.MouseButton1Click:Connect(function() zoomMultiplier = math.clamp(zoomMultiplier - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX) end)
    btnZoomOut.MouseButton1Click:Connect(function() zoomMultiplier = math.clamp(zoomMultiplier + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX) end)
    btnCamReset.MouseButton1Click:Connect(function() zoomMultiplier = 1 previewAngle = 0 end)

    local function refreshAutoRotButton()
        btnAutoRot:SetAttribute("Active", autoRotateEnabled)
        TweenService:Create(btnAutoRot, T_FAST, {
            BackgroundColor3 = autoRotateEnabled and C.accent or C.bgBtn,
            TextColor3       = autoRotateEnabled and C.bgBase or C.txtSub,
        }):Play()
    end
    btnAutoRot.MouseButton1Click:Connect(function()
        autoRotateEnabled = not autoRotateEnabled
        refreshAutoRotButton()
    end)
    refreshAutoRotButton()

    -- ─── Highlight ────────────────────────────────────────────────
    local SHIRT_PARTS = {"UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "Torso", "Left Arm", "Right Arm"}
    local PANTS_PARTS = {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Left Leg", "Right Leg"}
    local highlightPool = {}
    for i = 1, 10 do
        local h = Instance.new("Highlight")
        h.FillColor = C.accent h.FillTransparency = 1 h.OutlineColor = C.accent h.OutlineTransparency = 1 h.Enabled = false h.Parent = previewWorldModel
        table.insert(highlightPool, h)
    end

    local function resolveHighlightTargets(item)
        if not previewModel then return {} end
        local targets = {}
        if item.itemType == "Shirt" then
            for _, name in ipairs(SHIRT_PARTS) do
                local p = previewModel:FindFirstChild(name)
                if p and p:IsA("BasePart") then table.insert(targets, p) end
            end
        elseif item.itemType == "Pants" then
            for _, name in ipairs(PANTS_PARTS) do
                local p = previewModel:FindFirstChild(name)
                if p and p:IsA("BasePart") then table.insert(targets, p) end
            end
        elseif item.itemType == "Accessory" then
            local acc = previewModel:FindFirstChild(item.name)
            local handle = acc and acc:FindFirstChild("Handle")
            if handle then table.insert(targets, handle) end
        end
        return targets
    end

    local function showHighlight(targets)
        for i, part in ipairs(targets) do
            local h = highlightPool[i]
            if h then
                h.Adornee = part h.Enabled = true h.FillTransparency = 1 h.OutlineTransparency = 1
                TweenService:Create(h, T_FAST, {FillTransparency = 0.75, OutlineTransparency = 0.15}):Play()
            end
        end
    end
    local function hideHighlight()
        for _, h in ipairs(highlightPool) do
            if h.Enabled then TweenService:Create(h, T_FAST, {FillTransparency = 1, OutlineTransparency = 1}):Play() end
        end
        task.delay(0.15, function()
            for _, h in ipairs(highlightPool) do h.Enabled = false h.Adornee = nil end
        end)
    end

    -- ─── Escaneo ──────────────────────────────────────────────────
    local equippedItems = {}
    local function scanEquippedItems()
        equippedItems = {}
        local char = player.Character
        if not char then return end

        local shirt = char:FindFirstChildOfClass("Shirt")
        if shirt then table.insert(equippedItems, {itemType = "Shirt", name = "Camisa", assetId = shirt.ShirtTemplate:match("%d+"), owned = not shirt:GetAttribute("FromOutfit")}) end

        local pants = char:FindFirstChildOfClass("Pants")
        if pants then table.insert(equippedItems, {itemType = "Pants", name = "Pantalón", assetId = pants.PantsTemplate:match("%d+"), owned = not pants:GetAttribute("FromOutfit")}) end

        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Accessory") then
                local handle = child:FindFirstChild("Handle")
                local mesh   = handle and (handle:FindFirstChildOfClass("SpecialMesh") or handle:FindFirstChildOfClass("MeshPart"))
                local assetId = mesh and mesh.MeshId and mesh.MeshId:match("%d+")
                table.insert(equippedItems, {itemType = "Accessory", name = child.Name, assetId = assetId, owned = not child:GetAttribute("FromOutfit")})
            end
        end
    end

    -- ─── Tarjeta ────────────────────────────────────────────────
    local function buildItemCard(item, targetY, staggerDelay)
        local card = Instance.new("Frame")
        card.Size                   = UDim2.new(1, 0, 0, ROW_H)
        card.Position               = UDim2.new(0, 0, 0, targetY + 10)
        card.BackgroundColor3       = C.bgCard
        card.BackgroundTransparency = 1
        card.BorderSizePixel        = 0
        card.ZIndex                 = 12
        card:SetAttribute("BaseY", targetY)
        uiCorner(card, 14)

        local cardScale = Instance.new("UIScale", card)
        local cardStroke = uiStroke(card, C.border)
        cardStroke.Transparency = 1
        card.Parent = gridContainer

        local img = Instance.new("ImageLabel")
        img.Size              = UDim2.new(0, 64, 0, 64)
        img.Position          = UDim2.new(0, 16, 0.5, -32)
        img.BackgroundColor3  = C.bgBase
        img.ScaleType         = Enum.ScaleType.Fit
        img.ImageTransparency = 1
        img.Image              = item.assetId and ("rbxthumb://type=Asset&id=" .. item.assetId .. "&w=150&h=150") or ""
        img.ZIndex             = 13
        uiCorner(img, 10)
        img.Parent = card

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size              = UDim2.new(1, -260, 0, 22)
        nameLbl.Position          = UDim2.new(0, 96, 0, 24)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextTransparency  = 1
        nameLbl.TextColor3        = C.txtMain
        nameLbl.Font              = Enum.Font.GothamMedium
        nameLbl.TextSize          = 16
        nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
        nameLbl.TextTruncate      = Enum.TextTruncate.AtEnd
        nameLbl.Text              = item.name
        nameLbl.ZIndex            = 13
        nameLbl.Parent            = card

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size              = UDim2.new(1, -260, 0, 16)
        statusLbl.Position          = UDim2.new(0, 96, 0, 50)
        statusLbl.BackgroundTransparency = 1
        statusLbl.TextTransparency  = 1
        statusLbl.TextColor3        = C.txtSub
        statusLbl.Font              = F_NORMAL
        statusLbl.TextSize          = 12
        statusLbl.TextXAlignment    = Enum.TextXAlignment.Left
        statusLbl.Text              = item.owned and "En inventario" or "Vista previa"
        statusLbl.ZIndex            = 13
        statusLbl.Parent            = card

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size              = UDim2.new(0, 120, 0, 40)
        actionBtn.AnchorPoint       = Vector2.new(1, 0.5)
        actionBtn.Position          = UDim2.new(1, -16, 0.5, 0)
        local C_REMOVE_IDLE  = Color3.fromRGB(48, 48, 52)
        local C_REMOVE_HOVER = Color3.fromRGB(65, 65, 70)

        actionBtn.BackgroundColor3  = item.owned and C_REMOVE_IDLE or C.buyGreen
        actionBtn.BackgroundTransparency = 1
        actionBtn.Text              = item.owned and "QUITAR" or "COMPRAR"
        actionBtn.TextTransparency  = 1
        actionBtn.TextColor3        = item.owned and C.txtMain or Color3.new(1, 1, 1)
        actionBtn.Font              = F_BOLD
        actionBtn.TextSize          = 13
        actionBtn.BorderSizePixel   = 0
        actionBtn.ZIndex            = 14
        uiCorner(actionBtn, 10)
        if item.owned then uiStroke(actionBtn, C.border) end
        actionBtn.Parent = card

        local actionBtnScale = Instance.new("UIScale", actionBtn)

        task.delay(staggerDelay or 0, function()
            if not card or not card.Parent then return end
            TweenService:Create(card, T_MED, { Position = UDim2.new(0, 0, 0, targetY), BackgroundTransparency = 0 }):Play()
            TweenService:Create(cardStroke, T_MED, {Transparency = 0.4}):Play()
            TweenService:Create(actionBtn, T_MED, {BackgroundTransparency = 0}):Play()
            for _, d in ipairs(card:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then TweenService:Create(d, T_MED, {TextTransparency = 0}):Play()
                elseif d:IsA("ImageLabel") then TweenService:Create(d, T_MED, {ImageTransparency = 0}):Play() end
            end
        end)

        card.MouseEnter:Connect(function()
            playHover()
            TweenService:Create(cardScale, T_FAST, {Scale = 1.015}):Play()
            TweenService:Create(card, T_FAST, {BackgroundColor3 = C.bgBtnHover}):Play()
            showHighlight(resolveHighlightTargets(item))
        end)
        card.MouseLeave:Connect(function()
            TweenService:Create(cardScale, T_FAST, {Scale = 1.0}):Play()
            TweenService:Create(card, T_FAST, {BackgroundColor3 = C.bgCard}):Play()
            hideHighlight()
        end)

        actionBtn.MouseEnter:Connect(function()
            playHover()
            TweenService:Create(actionBtnScale, T_FAST, {Scale = 1.05}):Play()
            TweenService:Create(actionBtn, T_FAST, {
                BackgroundColor3 = item.owned and C_REMOVE_HOVER or C.buyGreenHover
            }):Play()
        end)

        actionBtn.MouseLeave:Connect(function()
            TweenService:Create(actionBtnScale, T_FAST, {Scale = 1.0}):Play()
            TweenService:Create(actionBtn, T_FAST, {
                BackgroundColor3 = item.owned and C_REMOVE_IDLE or C.buyGreen
            }):Play()
        end)

        actionBtn.MouseButton1Down:Connect(function()
            TweenService:Create(actionBtnScale, T_FAST, {Scale = 0.94}):Play()
        end)

        actionBtn.MouseButton1Click:Connect(function()
            if not actionBtn.Active then return end
            actionBtn.Active = false
            TweenService:Create(actionBtnScale, T_FAST, {Scale = 1.05}):Play()

            if item.owned then
                playSoundRemove()

                TweenService:Create(cardScale, T_FAST, {Scale = 0.85}):Play()
                TweenService:Create(card, T_FAST, {BackgroundTransparency = 1}):Play()
                TweenService:Create(cardStroke, T_FAST, {Transparency = 1}):Play()
                TweenService:Create(actionBtn, T_FAST, {BackgroundTransparency = 1}):Play()

                for _, d in ipairs(card:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then TweenService:Create(d, T_FAST, {TextTransparency = 1}):Play()
                    elseif d:IsA("ImageLabel") then TweenService:Create(d, T_FAST, {ImageTransparency = 1}):Play() end
                end

                if RemoveItem then RemoveItem:FireServer(item.itemType, item.name) end
                if showToast then showToast(item.name .. " quitado", "neutral", 2) end
            else
                playClick()
                playSoundBuy()
                if item.assetId and BuyOutfit then
                    BuyOutfit:FireServer(tonumber(item.assetId))
                    if showToast then showToast("Abriendo tienda...", "info", 2.5) end
                end
                task.delay(0.6, function()
                    if actionBtn and actionBtn.Parent then actionBtn.Active = true end
                end)
            end
        end)

        return card
    end

    -- ─── Reconciliación ────────────────────────────────────────
    local activeCards = {}
    local function cardKeyFor(item) return item.itemType == "Accessory" and ("Accessory:" .. item.name) or item.itemType end

    local function reconcileItemsGrid()
        scanEquippedItems()
        local newItemsByKey, orderedKeys = {}, {}
        for _, item in ipairs(equippedItems) do
            local key = cardKeyFor(item)
            newItemsByKey[key] = item
            table.insert(orderedKeys, key)
        end

        for key, card in pairs(activeCards) do
            if not newItemsByKey[key] then
                local cs = card:FindFirstChild("UIScale")
                if cs then TweenService:Create(cs, T_FAST, {Scale = 0.8}):Play() end
                TweenService:Create(card, T_FAST, { BackgroundTransparency = 1 }):Play()
                for _, d in ipairs(card:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then TweenService:Create(d, T_FAST, {TextTransparency = 1}):Play()
                    elseif d:IsA("ImageLabel") then TweenService:Create(d, T_FAST, {ImageTransparency = 1}):Play() end
                end
                local cardRef = card
                task.delay(0.2, function() if cardRef then cardRef:Destroy() end end)
                activeCards[key] = nil
            end
        end

        local staggerIndex = 0
        for index, key in ipairs(orderedKeys) do
            local targetY = (index - 1) * (ROW_H + ROW_GAP)
            local existing = activeCards[key]

            if existing then
                if existing:GetAttribute("BaseY") ~= targetY then
                    existing:SetAttribute("BaseY", targetY)
                    TweenService:Create(existing, T_MED, {Position = UDim2.new(0, 0, 0, targetY)}):Play()
                end
            else
                staggerIndex += 1
                activeCards[key] = buildItemCard(newItemsByKey[key], targetY, (staggerIndex - 1) * 0.03)
            end
        end

        emptyStateContainer.Visible = (#orderedKeys == 0)
        gridContainer.CanvasSize = UDim2.new(0, 0, 0, #orderedKeys > 0 and (#orderedKeys * (ROW_H + ROW_GAP)) or 0)
    end

    -- ─── Registro en MenuManager ─────────────────────────────────
    MenuManager.Register("Customize",
        function()
            loadPreviewCharacter()
            reconcileItemsGrid()
            Panel.Position = CUSTOM_SHOW
            TweenService:Create(Panel, T_MED, {Position = CUSTOM_SHOW}):Play()
        end,
        function()
            TweenService:Create(Panel, T_SLOW, {Position = CUSTOM_HIDE}):Play()
        end
    )

    btnCustClose.MouseButton1Click:Connect(function()
        playClick()
        MenuManager.CloseAll()
    end)

    -- ─── Detección en tiempo real ────────────────────────────────
    local function watchCharacterForCustomize(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("Accessory") then
                task.wait(0.1)
                if MenuManager.GetActive() == "Customize" then reconcileItemsGrid() pulseViewport() end
            end
        end)
        character.ChildRemoved:Connect(function(child)
            if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("Accessory") then
                if MenuManager.GetActive() == "Customize" then reconcileItemsGrid() end
            end
        end)
    end

    if player.Character then watchCharacterForCustomize(player.Character) end
    player.CharacterAdded:Connect(function(char)
        watchCharacterForCustomize(char)
        task.wait(0.5)
        if MenuManager.GetActive() == "Customize" then loadPreviewCharacter() end
    end)
end

return CustomizePanel