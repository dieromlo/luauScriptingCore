-- ============================================================
--  OutfitViewerPanel.lua
--  ModuleScript | StarterPlayerScripts/modules
-- ------------------------------------------------------------
--  RESPONSABILIDAD
--  Panel que se abre al completar la interacción con un
--  maniquí: muestra una vista previa 3D real de cómo se vería
--  el jugador con el outfit puesto (vía AvatarViewport +
--  OutfitResolver, sin tocar el avatar real), lista compacta de
--  artículos con precio/estado real, y las acciones Try On /
--  Comprar Outfit.
--
--  DEPENDENCIAS
--  UIKit, SoundKit, MenuManager, OutfitService,
--  AssetInfoService, AvatarViewport (todos hermanos en modules/)
--  OutfitData, OutfitResolver (ReplicatedStorage/OutfitSystem)
--
--  EXPONE
--  OutfitViewerPanel.Init(guiParent, showToastFn)
--
--  ARQUITECTURA
--  Recibe solo el ID del outfit desde MannequinInteraction (vía
--  MenuManager.Open("Outfit", {id=...})) y resuelve TODO lo
--  demás (nombre, descripción, piezas) directamente desde
--  OutfitData — una sola fuente de verdad, sin atributos
--  duplicados en el maniquí.
-- ============================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit            = require(script.Parent.UIKit)
local SoundKit          = require(script.Parent.SoundKit)
local MenuManager       = require(script.Parent.MenuManager)
local OutfitService     = require(script.Parent.OutfitService)
local AssetInfoService  = require(script.Parent.AssetInfoService)
local AvatarViewport    = require(script.Parent.AvatarViewport)

local OutfitSystem   = ReplicatedStorage:WaitForChild("OutfitSystem")
local OutfitData     = require(OutfitSystem:WaitForChild("OutfitData"))
local OutfitResolver = require(OutfitSystem:WaitForChild("OutfitResolver"))

local C, F_BOLD, F_NORMAL = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_FAST                = UIKit.T_FAST
local ICONS                  = UIKit.ICONS
local uiCorner, uiStroke     = UIKit.uiCorner, UIKit.uiStroke

local T_PANEL_IN  = TweenInfo.new(0.55, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local T_PANEL_OUT = TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

local player = Players.LocalPlayer

local OutfitViewerPanel = {}

function OutfitViewerPanel.Init(guiParent, showToastFn)
    local PW, PH   = 1120, 660
    local POS_HIDE = UDim2.new(0.5, -PW/2, 1.5, 0)
    local POS_SHOW = UDim2.new(0.5, -PW/2, 0.5, -PH/2)

    local Panel = Instance.new("Frame")
    Panel.Name             = "OutfitViewerPanel"
    Panel.Size             = UDim2.new(0, PW, 0, PH)
    Panel.Position         = POS_HIDE
    Panel.BackgroundColor3 = C.bgBase
    Panel.BorderSizePixel  = 0
    Panel.Visible          = false
    uiCorner(Panel, 20)
    local panelStroke = uiStroke(Panel, C.border, 1.5)
    panelStroke.Transparency = 0.5
    Panel.Parent = guiParent

    local panelScale = Instance.new("UIScale", Panel)
    panelScale.Scale = 0.94

    -- ─── Header ──────────────────────────────────────────────
    local title = Instance.new("TextLabel")
    title.Size             = UDim2.new(1, -100, 0, 36)
    title.Position         = UDim2.new(0, 32, 0, 24)
    title.BackgroundTransparency = 1
    title.TextColor3       = C.txtMain
    title.TextSize         = 26
    title.Font             = F_BOLD
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.Text             = "Visualizador de Outfit"
    title.Parent           = Panel

    local subtitle = Instance.new("TextLabel")
    subtitle.Size             = UDim2.new(1, -100, 0, 18)
    subtitle.Position         = UDim2.new(0, 32, 0, 62)
    subtitle.BackgroundTransparency = 1
    subtitle.TextColor3       = C.txtSub
    subtitle.TextSize         = 12
    subtitle.Font             = F_NORMAL
    subtitle.TextXAlignment   = Enum.TextXAlignment.Left
    subtitle.TextTruncate     = Enum.TextTruncate.AtEnd
    subtitle.Text             = ""
    subtitle.Parent           = Panel

    local btnClose = Instance.new("ImageButton")
    btnClose.Size             = UDim2.new(0, 36, 0, 36)
    btnClose.Position         = UDim2.new(1, -54, 0, 24)
    btnClose.BackgroundColor3 = C.bgBtn
    btnClose.Image            = ICONS.Close
    btnClose.ImageColor3      = C.txtSub
    btnClose.BorderSizePixel  = 0
    uiCorner(btnClose, 10)
    btnClose.Parent = Panel
    local closeScale = Instance.new("UIScale", btnClose)
    btnClose.MouseEnter:Connect(function()
        SoundKit.PlayHover()
        TweenService:Create(closeScale, T_FAST, {Scale = 1.08}):Play()
        TweenService:Create(btnClose, T_FAST, {BackgroundColor3 = C.bgBtnHover, ImageColor3 = C.accent, Rotation = 90}):Play()
    end)
    btnClose.MouseLeave:Connect(function()
        TweenService:Create(closeScale, T_FAST, {Scale = 1}):Play()
        TweenService:Create(btnClose, T_FAST, {BackgroundColor3 = C.bgBtn, ImageColor3 = C.txtSub, Rotation = 0}):Play()
    end)

    local headerDivider = Instance.new("Frame")
    headerDivider.Size             = UDim2.new(1, -64, 0, 1)
    headerDivider.Position         = UDim2.new(0, 32, 0, 92)
    headerDivider.BackgroundColor3 = C.border
    headerDivider.BackgroundTransparency = 0.4
    headerDivider.BorderSizePixel  = 0
    headerDivider.Parent           = Panel

    -- ─── Viewport (izquierda) ────────────────────────────────
    local viewportContainer = Instance.new("Frame")
    viewportContainer.Size             = UDim2.new(0, 456, 0, 390)
    viewportContainer.Position         = UDim2.new(0, 32, 0, 104)
    viewportContainer.BackgroundTransparency = 1
    viewportContainer.Parent           = Panel

    local viewport = AvatarViewport.new(viewportContainer)

    -- ─── Lista de artículos (derecha) ────────────────────────
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Size                   = UDim2.new(0, 580, 0, 390)
    listContainer.Position               = UDim2.new(0, 508, 0, 104)
    listContainer.BackgroundTransparency = 1
    listContainer.BorderSizePixel        = 0
    listContainer.ScrollBarThickness     = 3
    listContainer.ScrollBarImageColor3   = C.txtMuted
    listContainer.CanvasSize             = UDim2.new(0, 0, 0, 0)
    listContainer.Parent                 = Panel

    local emptyLbl = Instance.new("TextLabel")
    emptyLbl.Size             = UDim2.new(1, 0, 0, 40)
    emptyLbl.Position         = UDim2.new(0, 0, 0, 20)
    emptyLbl.BackgroundTransparency = 1
    emptyLbl.TextColor3       = C.txtMuted
    emptyLbl.Font             = F_NORMAL
    emptyLbl.TextSize         = 13
    emptyLbl.Text             = "Este outfit todavía no tiene artículos definidos."
    emptyLbl.Visible          = false
    emptyLbl.Parent           = listContainer

    -- ─── Zona inferior: total, botones, mensaje de confianza ─
    local bottomDivider = Instance.new("Frame")
    bottomDivider.Size             = UDim2.new(1, -64, 0, 1)
    bottomDivider.Position         = UDim2.new(0, 32, 0, 502)
    bottomDivider.BackgroundColor3 = C.border
    bottomDivider.BackgroundTransparency = 0.4
    bottomDivider.BorderSizePixel  = 0
    bottomDivider.Parent           = Panel

    local totalRow = Instance.new("Frame")
    totalRow.Size             = UDim2.new(1, -64, 0, 40)
    totalRow.Position         = UDim2.new(0, 32, 0, 516)
    totalRow.BackgroundColor3 = C.bgCard
    totalRow.BorderSizePixel  = 0
    uiCorner(totalRow, 12)
    totalRow.Parent = Panel

    local totalLbl = Instance.new("TextLabel")
    totalLbl.Size             = UDim2.new(0.5, 0, 1, 0)
    totalLbl.Position         = UDim2.new(0, 18, 0, 0)
    totalLbl.BackgroundTransparency = 1
    totalLbl.TextColor3       = C.txtSub
    totalLbl.Font             = F_NORMAL
    totalLbl.TextSize         = 13
    totalLbl.TextXAlignment   = Enum.TextXAlignment.Left
    totalLbl.Text             = "Total del outfit"
    totalLbl.Parent           = totalRow

    local totalValueLbl = Instance.new("TextLabel")
    totalValueLbl.Size             = UDim2.new(0.5, -18, 1, 0)
    totalValueLbl.Position         = UDim2.new(0.5, 0, 0, 0)
    totalValueLbl.BackgroundTransparency = 1
    totalValueLbl.TextColor3       = C.txtMain
    totalValueLbl.Font             = F_BOLD
    totalValueLbl.TextSize         = 14
    totalValueLbl.TextXAlignment   = Enum.TextXAlignment.Right
    totalValueLbl.Text             = "—"
    totalValueLbl.Parent           = totalRow

    local btnTryOn = Instance.new("TextButton")
    btnTryOn.Size             = UDim2.new(0, 520, 0, 48)
    btnTryOn.Position         = UDim2.new(0, 32, 0, 566)
    btnTryOn.BackgroundColor3 = C.bgBtn
    btnTryOn.Text             = "Probar Avatar"
    btnTryOn.TextColor3       = C.txtMain
    btnTryOn.TextSize         = 14
    btnTryOn.Font             = F_BOLD
    btnTryOn.BorderSizePixel  = 0
    uiCorner(btnTryOn, 12)
    uiStroke(btnTryOn, C.border)
    btnTryOn.Parent = Panel

    local btnBuyOutfit = Instance.new("TextButton")
    btnBuyOutfit.Size             = UDim2.new(0, 520, 0, 48)
    btnBuyOutfit.Position         = UDim2.new(0, 568, 0, 566)
    btnBuyOutfit.BackgroundColor3 = C.accent
    btnBuyOutfit.Text             = "Comprar Outfit"
    btnBuyOutfit.TextColor3       = C.bgBase
    btnBuyOutfit.TextSize         = 14
    btnBuyOutfit.Font             = F_BOLD
    btnBuyOutfit.BorderSizePixel  = 0
    uiCorner(btnBuyOutfit, 12)
    btnBuyOutfit.Parent = Panel

    for _, btn in ipairs({btnTryOn, btnBuyOutfit}) do
        local isAccent = (btn == btnBuyOutfit)
        btn.MouseEnter:Connect(function()
            if btn.Active then
                SoundKit.PlayHover()
                TweenService:Create(btn, T_FAST, {BackgroundColor3 = isAccent and C.accentHover or C.bgBtnHover}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if btn.Active then
                local col = (btn == btnBuyOutfit and btn.Active) and C.accent or C.bgBtn
                TweenService:Create(btn, T_FAST, {BackgroundColor3 = col}):Play()
            end
        end)
    end

    local captionLbl = Instance.new("TextLabel")
    captionLbl.Size             = UDim2.new(1, -64, 0, 16)
    captionLbl.Position         = UDim2.new(0, 32, 0, 624)
    captionLbl.BackgroundTransparency = 1
    captionLbl.TextColor3       = C.txtMuted
    captionLbl.Font             = F_NORMAL
    captionLbl.TextSize         = 10
    captionLbl.TextXAlignment   = Enum.TextXAlignment.Center
    captionLbl.Text             = "Los artículos comprados se añaden directamente a tu inventario de Roblox."
    captionLbl.Parent           = Panel

    -- ─── Base description del jugador (para el preview) ──────
    -- Mismo patrón robusto que ya usa el servidor para Reset:
    -- CharacterAppearanceLoaded en vez de un task.wait a ciegas.
    local baseDescription = nil
    local function captureBase(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end
        local ok, desc = pcall(function() return humanoid:GetAppliedDescription() end)
        if ok and desc then baseDescription = desc end
    end
    if player.Character then captureBase(player.Character) end
    player.CharacterAppearanceLoaded:Connect(captureBase)

    -- ─── Filas de artículos ───────────────────────────────────
    local ROW_H, ROW_GAP = 76, 10
    local activeRows      = {}
    local expandedRow     = nil
    local currentOutfit   = nil

    local function refreshTotals()
        local total, anyPurchasable, allOwned, allResolved = 0, false, true, true
        for _, ctrl in ipairs(activeRows) do
            if not ctrl.info then
                allResolved = false
            else
                if ctrl.info.state ~= AssetInfoService.STATES.Owned then allOwned = false end
                if (ctrl.info.state == AssetInfoService.STATES.ForSale
                    or ctrl.info.state == AssetInfoService.STATES.Limited) and ctrl.info.price then
                    total = total + ctrl.info.price
                    anyPurchasable = true
                end
            end
        end

        local active = false
        if #activeRows == 0 then
            totalValueLbl.Text = "—"
            btnBuyOutfit.Text  = "Sin artículos"
        elseif not allResolved then
            totalValueLbl.Text = "Calculando..."
            btnBuyOutfit.Text  = "Comprar Outfit"
        elseif allOwned then
            totalValueLbl.Text = "Ya lo tienes completo"
            btnBuyOutfit.Text  = "Ya tienes este outfit"
        elseif anyPurchasable then
            totalValueLbl.Text = total .. " Robux"
            btnBuyOutfit.Text  = "Comprar Outfit"
            active = true
        else
            totalValueLbl.Text = "No disponible"
            btnBuyOutfit.Text  = "No disponible"
        end

        btnBuyOutfit.Active = active
        TweenService:Create(btnBuyOutfit, T_FAST, {
            BackgroundColor3 = active and C.accent or C.bgBtn,
            TextColor3       = active and C.bgBase or C.txtMuted,
        }):Play()
    end

    local function buildItemRow(piece, orderIndex)
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, -4, 0, ROW_H)
        row.Position         = UDim2.new(0, 0, 0, (orderIndex - 1) * (ROW_H + ROW_GAP))
        row.BackgroundColor3 = C.bgCard
        row.BorderSizePixel  = 0
        uiCorner(row, 14)
        local rowStroke = uiStroke(row, C.border, 1)
        rowStroke.Transparency = 0.7
        row.Parent = listContainer

        local thumb = Instance.new("ImageLabel")
        thumb.Size             = UDim2.new(0, 56, 0, 56)
        thumb.Position         = UDim2.new(0, 10, 0.5, -28)
        thumb.BackgroundColor3 = C.bgBase
        thumb.ScaleType        = Enum.ScaleType.Fit
        thumb.Image            = "rbxthumb://type=Asset&id=" .. piece.assetId .. "&w=150&h=150"
        uiCorner(thumb, 10)
        thumb.Parent = row

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size             = UDim2.new(1, -210, 0, 20)
        nameLbl.Position         = UDim2.new(0, 78, 0, 16)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextColor3       = C.txtMain
        nameLbl.Font             = Enum.Font.GothamMedium
        nameLbl.TextSize         = 14
        nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
        nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
        nameLbl.Text             = "Cargando..."
        nameLbl.Parent           = row

        local metaLbl = Instance.new("TextLabel")
        metaLbl.Size             = UDim2.new(1, -210, 0, 16)
        metaLbl.Position         = UDim2.new(0, 78, 0, 38)
        metaLbl.BackgroundTransparency = 1
        metaLbl.TextColor3       = C.txtMuted
        metaLbl.Font             = F_NORMAL
        metaLbl.TextSize         = 11
        metaLbl.TextXAlignment   = Enum.TextXAlignment.Left
        metaLbl.Text             = piece.type or ""
        metaLbl.Parent           = row

        local rightZone = Instance.new("Frame")
        rightZone.Size             = UDim2.new(0, 118, 0, 40)
        rightZone.AnchorPoint      = Vector2.new(1, 0.5)
        rightZone.Position         = UDim2.new(1, -12, 0.5, 0)
        rightZone.BackgroundTransparency = 1
        rightZone.Parent           = row

        local badge = Instance.new("Frame")
        badge.Size             = UDim2.new(1, 0, 1, 0)
        badge.BackgroundColor3 = C.bgBtn
        badge.BorderSizePixel  = 0
        uiCorner(badge, 10)
        badge.Parent = rightZone

        local badgeLbl = Instance.new("TextLabel")
        badgeLbl.Size             = UDim2.new(1, 0, 1, 0)
        badgeLbl.BackgroundTransparency = 1
        badgeLbl.TextColor3       = C.txtSub
        badgeLbl.Font             = F_BOLD
        badgeLbl.TextSize         = 12
        badgeLbl.Text             = "···"
        badgeLbl.Parent           = badge

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size             = UDim2.new(1, 0, 1, 0)
        actionBtn.BackgroundColor3 = C.accent
        actionBtn.BackgroundTransparency = 1
        actionBtn.TextTransparency = 1
        actionBtn.TextColor3       = C.bgBase
        actionBtn.Font             = F_BOLD
        actionBtn.TextSize         = 12
        actionBtn.BorderSizePixel  = 0
        actionBtn.Text             = "Comprar"
        actionBtn.Active           = false
        uiCorner(actionBtn, 10)
        actionBtn.Parent = rightZone

        local hitArea = Instance.new("TextButton")
        hitArea.Size             = UDim2.new(1, 0, 1, 0)
        hitArea.BackgroundTransparency = 1
        hitArea.Text             = ""
        hitArea.Active           = false
        hitArea.Parent           = row

        local rowCtrl = {
            piece = piece, assetId = piece.assetId, row = row, info = nil, expanded = false,
        }

        function rowCtrl.collapse()
            if not rowCtrl.expanded then return end
            rowCtrl.expanded = false
            TweenService:Create(badge, T_FAST, {BackgroundTransparency = 0}):Play()
            TweenService:Create(badgeLbl, T_FAST, {TextTransparency = 0}):Play()
            TweenService:Create(actionBtn, T_FAST, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
            actionBtn.Active = false
        end

        local function expand()
            if expandedRow and expandedRow ~= rowCtrl then expandedRow.collapse() end
            rowCtrl.expanded = true
            expandedRow = rowCtrl
            TweenService:Create(badge, T_FAST, {BackgroundTransparency = 1}):Play()
            TweenService:Create(badgeLbl, T_FAST, {TextTransparency = 1}):Play()
            TweenService:Create(actionBtn, T_FAST, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
            actionBtn.Active = true
        end

        hitArea.MouseButton1Click:Connect(function()
            SoundKit.PlayClick()
            if rowCtrl.expanded then rowCtrl.collapse() else expand() end
        end)

        actionBtn.MouseEnter:Connect(function()
            SoundKit.PlayHover()
            TweenService:Create(actionBtn, T_FAST, {BackgroundColor3 = C.accentHover}):Play()
        end)
        actionBtn.MouseLeave:Connect(function()
            TweenService:Create(actionBtn, T_FAST, {BackgroundColor3 = C.accent}):Play()
        end)
        actionBtn.MouseButton1Click:Connect(function()
            if not rowCtrl.info then return end
            SoundKit.PlayClick()
            OutfitService.Buy(rowCtrl.assetId)
            if showToastFn then showToastFn("Abriendo tienda...", "info", 2.5) end
        end)

        -- Aplica la info resuelta (nombre, precio, thumbnail,
        -- estado) a esta fila. Se llama al resolver por primera
        -- vez, y de nuevo si se invalida tras una compra.
        function rowCtrl.applyInfo(info)
            rowCtrl.info = info
            nameLbl.Text = info.name
            thumb.Image  = info.thumbnail

            local S = AssetInfoService.STATES
            if info.state == S.Owned then
                badgeLbl.Text, badgeLbl.TextColor3 = "En inventario", C.txtSub
                hitArea.Active = false
            elseif info.state == S.ForSale then
                badgeLbl.Text, badgeLbl.TextColor3 = (info.price or 0) .. " R$", C.txtMain
                hitArea.Active = true
            elseif info.state == S.Limited then
                badgeLbl.Text, badgeLbl.TextColor3 = (info.price or 0) .. " R$ · Limitado", Color3.fromRGB(220, 180, 90)
                hitArea.Active = true
            elseif info.state == S.OffSale then
                badgeLbl.Text, badgeLbl.TextColor3 = "Agotado", C.txtMuted
                hitArea.Active = false
            else
                badgeLbl.Text, badgeLbl.TextColor3 = "No disponible", C.txtMuted
                hitArea.Active = false
            end

            if not hitArea.Active and rowCtrl.expanded then rowCtrl.collapse() end
            refreshTotals()
        end

        return rowCtrl
    end

    local function clearRows()
        for _, ctrl in ipairs(activeRows) do ctrl.row:Destroy() end
        activeRows, expandedRow = {}, nil
    end

    local function buildItemRows(pieces)
        clearRows()
        emptyLbl.Visible = (#pieces == 0)
        for index, piece in ipairs(pieces) do
            local ctrl = buildItemRow(piece, index)
            table.insert(activeRows, ctrl)
            AssetInfoService.GetInfo(piece.assetId, ctrl.applyInfo)
        end
        listContainer.CanvasSize = UDim2.new(0, 0, 0,
            #pieces > 0 and (#pieces * (ROW_H + ROW_GAP)) or 0)
        refreshTotals()
    end

    OutfitService.OnPurchaseFinished(function(assetId, wasPurchased)
        if not wasPurchased then return end
        AssetInfoService.Invalidate(assetId)
        for _, ctrl in ipairs(activeRows) do
            if ctrl.assetId == assetId then
                AssetInfoService.GetInfo(assetId, ctrl.applyInfo)
            end
        end
    end)

    -- ─── Mostrar un outfit (contenido, no la animación) ──────
    local function showOutfitPanel(data)
        if not data or not data.id then return end
        local outfit = OutfitData.GetOutfitById(data.id)
        if not outfit then
            warn("[OutfitViewerPanel] Outfit no encontrado: " .. tostring(data.id))
            return
        end

        currentOutfit    = outfit
        title.Text       = outfit.name or "Look"
        subtitle.Text    = outfit.description or ""

        local previewDescription = OutfitResolver.Resolve(outfit, baseDescription)
        viewport:ShowDescription(previewDescription)

        buildItemRows(outfit.pieces or {})
    end

    -- ─── Máquina de estados del panel (mismo patrón que
    --     CustomizePanel: Active se apaga de inmediato al
    --     cerrar, Visible solo al terminar la animación) ──────
    local PANEL_STATE = { CLOSED = "closed", OPENING = "opening", OPEN = "open", CLOSING = "closing" }
    local panelState  = PANEL_STATE.CLOSED
    local panelTweens = {}

    local function cancelPanelTweens()
        for _, tw in ipairs(panelTweens) do tw:Cancel() end
        panelTweens = {}
    end
    local function trackTween(tw)
        table.insert(panelTweens, tw)
        tw:Play()
        return tw
    end

    local function openPanelVisuals(data)
        if panelState == PANEL_STATE.OPEN or panelState == PANEL_STATE.OPENING then
            showOutfitPanel(data)
            return
        end
        cancelPanelTweens()
        panelState = PANEL_STATE.OPENING
        Panel.Visible = true
        Panel.Active  = true
        viewport:SetActive(true)

        showOutfitPanel(data)

        local tw = trackTween(TweenService:Create(Panel, T_PANEL_IN, {Position = POS_SHOW}))
        trackTween(TweenService:Create(panelScale, T_PANEL_IN, {Scale = 1}))
        trackTween(TweenService:Create(panelStroke, T_PANEL_IN, {Transparency = 0.5}))
        tw.Completed:Connect(function(ps)
            if ps == Enum.PlaybackState.Completed and panelState == PANEL_STATE.OPENING then
                panelState = PANEL_STATE.OPEN
            end
        end)
    end

    local function closePanelVisuals()
        if panelState == PANEL_STATE.CLOSED or panelState == PANEL_STATE.CLOSING then return end
        cancelPanelTweens()
        panelState = PANEL_STATE.CLOSING
        Panel.Active = false
        viewport:SetActive(false)

        local tw = trackTween(TweenService:Create(Panel, T_PANEL_OUT, {Position = POS_HIDE}))
        trackTween(TweenService:Create(panelScale, T_PANEL_OUT, {Scale = 0.95}))
        trackTween(TweenService:Create(panelStroke, T_PANEL_OUT, {Transparency = 1}))
        tw.Completed:Connect(function(ps)
            if ps == Enum.PlaybackState.Completed and panelState == PANEL_STATE.CLOSING then
                panelState = PANEL_STATE.CLOSED
                Panel.Visible = false
                viewport:Clear()
            end
        end)
    end

    MenuManager.Register("Outfit", openPanelVisuals, closePanelVisuals)

    btnClose.MouseButton1Click:Connect(function()
        SoundKit.PlayClick()
        MenuManager.CloseAll()
    end)

    btnTryOn.MouseButton1Click:Connect(function()
        if not currentOutfit then return end
        SoundKit.PlayClick()
        OutfitService.TryOn(currentOutfit.id)
        local original = btnTryOn.Text
        btnTryOn.Text = "✓ Aplicado"
        task.delay(1.5, function()
            if btnTryOn and btnTryOn.Parent then btnTryOn.Text = original end
        end)
        if showToastFn then
            showToastFn("Look aplicado: " .. (currentOutfit.name or "—"), "success", 3)
        end
    end)

    btnBuyOutfit.MouseButton1Click:Connect(function()
        if not btnBuyOutfit.Active or not currentOutfit then return end
        SoundKit.PlayClick()
        local delay = 0
        for _, ctrl in ipairs(activeRows) do
            if ctrl.info and (ctrl.info.state == AssetInfoService.STATES.ForSale
                or ctrl.info.state == AssetInfoService.STATES.Limited) then
                local assetId = ctrl.assetId
                task.delay(delay, function() OutfitService.Buy(assetId) end)
                delay += 0.5
            end
        end
        if showToastFn then showToastFn("Abriendo tienda de Roblox...", "info", 2.5) end
    end)
end

return OutfitViewerPanel