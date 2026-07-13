-- ============================================================
--  HudDock.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Dock horizontal (Correr/Carrito/Guardar/Ajustes/Resetear)
--  + botón de Customizar (medio izquierda).
-- ============================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIKit       = require(script.Parent.UIKit)
local SoundKit    = require(script.Parent.SoundKit)
local MenuManager = require(script.Parent.MenuManager)

local C, F_BOLD, F_NORMAL   = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_FAST, T_MED, T_SLOW = UIKit.T_FAST, UIKit.T_MED, UIKit.T_SLOW
local ICONS                  = UIKit.ICONS
local uiCorner, uiStroke     = UIKit.uiCorner, UIKit.uiStroke

local player = Players.LocalPlayer

local HudDock = {}

function HudDock.Init(guiParent)
    -- ─── Botón Customizar ───────────────────────────────────────
    local btnCustomize = Instance.new("TextButton")
    btnCustomize.Name             = "BtnCustomize"
    btnCustomize.Size             = UDim2.new(0, 132, 0, 46)
    btnCustomize.Position         = UDim2.new(0, 20, 0.5, -23)
    btnCustomize.BackgroundColor3 = C.bgCard
    btnCustomize.Text             = "CUSTOMIZAR"
    btnCustomize.TextColor3       = C.txtSub
    btnCustomize.Font             = F_BOLD
    btnCustomize.TextSize         = 12
    btnCustomize.BorderSizePixel  = 0
    btnCustomize.ZIndex           = 30
    uiCorner(btnCustomize, 12)
    local customizeStroke = uiStroke(btnCustomize, C.border, 1.2)
    btnCustomize.Parent = guiParent

    btnCustomize.MouseEnter:Connect(function()
        SoundKit.PlayHover()
        TweenService:Create(btnCustomize, T_FAST,
            {BackgroundColor3 = C.bgBtnHover, TextColor3 = C.txtMain}):Play()
        TweenService:Create(customizeStroke, T_FAST, {Color = C.borderHot}):Play()
    end)
    btnCustomize.MouseLeave:Connect(function()
        TweenService:Create(btnCustomize, T_FAST,
            {BackgroundColor3 = C.bgCard, TextColor3 = C.txtSub}):Play()
        TweenService:Create(customizeStroke, T_FAST, {Color = C.border}):Play()
    end)
    btnCustomize.MouseButton1Down:Connect(function()
        TweenService:Create(btnCustomize, T_FAST, {Size = UDim2.new(0, 126, 0, 44)}):Play()
    end)
    btnCustomize.MouseButton1Up:Connect(function()
        SoundKit.PlayClick()
        TweenService:Create(btnCustomize, T_FAST, {Size = UDim2.new(0, 132, 0, 46)}):Play()
    end)
    btnCustomize.MouseButton1Click:Connect(function()
        MenuManager.Toggle("Customize")
    end)

    -- ─── Dock horizontal inferior ───────────────────────────────
    local HUD = Instance.new("Frame")
    HUD.Name                   = "HorizontalHUD"
    HUD.Size                   = UDim2.new(0, 0, 0, 74)
    HUD.Position               = UDim2.new(0.5, 0, 1, -24)
    HUD.AnchorPoint            = Vector2.new(0.5, 1)
    HUD.BackgroundTransparency = 1
    HUD.ZIndex                 = 30
    HUD.Parent                 = guiParent

    local hudLayout = Instance.new("UIListLayout")
    hudLayout.FillDirection       = Enum.FillDirection.Horizontal
    hudLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hudLayout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    hudLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    hudLayout.Padding             = UDim.new(0, 20)
    hudLayout.Parent              = HUD

    hudLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        HUD.Size = UDim2.new(0, hudLayout.AbsoluteContentSize.X + 20, 0, 74)
    end)

    local function makeHudButton(iconAssetId, label, order)
        local container = Instance.new("Frame")
        container.Name = "Slot_" .. label
        container.Size = UDim2.new(0, 120, 0, 64)
        container.BackgroundTransparency = 1
        container.LayoutOrder = order
        container.Parent = HUD

        local btn = Instance.new("TextButton")
        btn.Name             = "HudBtn_" .. label
        btn.Size             = UDim2.new(1, 0, 1, 0)
        btn.Position         = UDim2.new(0.5, 0, 1, 0)
        btn.AnchorPoint      = Vector2.new(0.5, 1)
        btn.BackgroundColor3 = C.bgCard
        btn.Text             = ""
        btn.BorderSizePixel  = 0
        btn.ZIndex           = 31
        btn.Parent           = container
        uiCorner(btn, 14)
        local stroke = uiStroke(btn, C.border, 1.2)

        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = btn

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.FillDirection = Enum.FillDirection.Vertical
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        contentLayout.Padding = UDim.new(0, 4)
        contentLayout.Parent = contentFrame

        local ico = Instance.new("ImageLabel")
        ico.Size             = UDim2.new(0, 22, 0, 22)
        ico.BackgroundTransparency = 1
        ico.Image            = iconAssetId
        ico.ImageColor3      = C.txtSub
        ico.ZIndex           = 32
        ico.Parent           = contentFrame

        local lbl = Instance.new("TextLabel")
        lbl.Size             = UDim2.new(1, 0, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Text             = label:upper()
        lbl.TextColor3       = C.txtSub
        lbl.TextSize         = 10
        lbl.Font             = F_BOLD
        lbl.ZIndex           = 32
        lbl.Parent           = contentFrame

        btn.MouseEnter:Connect(function()
            SoundKit.PlayHover()
            btn.ZIndex = 40
            TweenService:Create(btn, T_FAST, {Size = UDim2.new(1.15, 0, 1.15, 0), BackgroundColor3 = C.bgBtnHover}):Play()
            TweenService:Create(stroke, T_FAST, {Color = C.borderHot}):Play()
            TweenService:Create(ico, T_FAST, {ImageColor3 = C.txtMain}):Play()
            TweenService:Create(lbl, T_FAST, {TextColor3 = C.txtMain}):Play()
        end)

        btn.MouseLeave:Connect(function()
            if not btn:GetAttribute("Active") then
                btn.ZIndex = 31
                TweenService:Create(btn, T_FAST, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.bgCard}):Play()
                TweenService:Create(stroke, T_FAST, {Color = C.border}):Play()
                TweenService:Create(ico, T_FAST, {ImageColor3 = C.txtSub}):Play()
                TweenService:Create(lbl, T_FAST, {TextColor3 = C.txtSub}):Play()
            end
        end)

        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, T_FAST, {Size = UDim2.new(0.95, 0, 0.95, 0)}):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            SoundKit.PlayClick()
            TweenService:Create(btn, T_FAST, {Size = UDim2.new(1.15, 0, 1.15, 0)}):Play()
        end)

        local function setActive(active)
            btn:SetAttribute("Active", active)
            local bg  = active and C.bgBtnHover or C.bgCard
            local bdr = active and C.borderHot or C.border
            local col = active and C.txtMain or C.txtSub
            TweenService:Create(btn, T_FAST, {BackgroundColor3 = bg}):Play()
            TweenService:Create(stroke, T_FAST, {Color = bdr}):Play()
            TweenService:Create(ico, T_FAST, {ImageColor3 = col}):Play()
            TweenService:Create(lbl, T_FAST, {TextColor3 = col}):Play()
        end

        return btn, lbl, setActive
    end

    local btnSprint, lblSprint, setSprintActive = makeHudButton(ICONS.Run,      "Correr",   1)
    local btnCart,     _, _                     = makeHudButton(ICONS.Cart,     "Carrito",  2)
    local btnSave,     _, _                     = makeHudButton(ICONS.Save,     "Guardar",  3)
    local btnSettings, _, _                     = makeHudButton(ICONS.Settings, "Ajustes",  4)
    local btnReset,    _, _                     = makeHudButton(ICONS.Reset,    "Resetear", 5)

    -- [1] SPRINT
    local isSprinting = false
    local SPD_WALK, SPD_SPRINT = 16, 32

    local function applySprint(active)
        isSprinting = active
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = active and SPD_SPRINT or SPD_WALK end
        end
        lblSprint.Text = active and "CAMINANDO" or "CORRER"
        setSprintActive(active)
    end

    btnSprint.MouseButton1Click:Connect(function() applySprint(not isSprinting) end)

    -- [2] RESET TRIGGER
    btnReset.MouseButton1Click:Connect(function()
        MenuManager.Toggle("ResetConfirm")
    end)

    -- [3] SETTINGS TRIGGER
    btnSettings.MouseButton1Click:Connect(function()
        MenuManager.Toggle("Settings")
    end)

    -- btnCart y btnSave quedan reservados para funciones futuras
    -- (carrito de compras, guardar outfit) — sin conectar todavía.
end

return HudDock