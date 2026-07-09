-- ============================================================
--  SettingsPanel.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Panel de Ajustes: toggles + slider de volumen de música.
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIKit       = require(script.Parent.UIKit)
local SoundKit    = require(script.Parent.SoundKit)
local MenuManager = require(script.Parent.MenuManager)

local C, F_BOLD, F_NORMAL   = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_FAST, T_MED, T_SLOW = UIKit.T_FAST, UIKit.T_MED, UIKit.T_SLOW
local ICONS                  = UIKit.ICONS
local uiCorner, uiStroke     = UIKit.uiCorner, UIKit.uiStroke

local player = Players.LocalPlayer

local SettingsPanel = {}

function SettingsPanel.Init(guiParent)
    local SET_W, SET_H = 500, 480
    local SET_HIDE = UDim2.new(0.5, -SET_W/2, 1.5, 0)
    local SET_SHOW = UDim2.new(0.5, -SET_W/2, 0.5, -SET_H/2)

    local SetPanel = Instance.new("Frame")
    SetPanel.Name             = "SettingsPanel"
    SetPanel.Size             = UDim2.new(0, SET_W, 0, SET_H)
    SetPanel.Position         = SET_HIDE
    SetPanel.BackgroundColor3 = C.bgBase
    SetPanel.BorderSizePixel  = 0
    SetPanel.ZIndex           = 20
    uiCorner(SetPanel, 20)
    uiStroke(SetPanel, C.border, 1.5)
    SetPanel.Parent = guiParent

    local setHeader = Instance.new("Frame")
    setHeader.Size             = UDim2.new(1, 0, 0, 64)
    setHeader.BackgroundTransparency = 1
    setHeader.ZIndex           = 21
    setHeader.Parent           = SetPanel

    local setTitle = Instance.new("TextLabel")
    setTitle.Size             = UDim2.new(1, -60, 1, 0)
    setTitle.Position         = UDim2.new(0, 24, 0, 0)
    setTitle.BackgroundTransparency = 1
    setTitle.TextColor3       = C.txtMain
    setTitle.TextSize         = 22
    setTitle.Font             = F_BOLD
    setTitle.TextXAlignment   = Enum.TextXAlignment.Left
    setTitle.Text             = "Ajustes de Sistema"
    setTitle.ZIndex           = 22
    setTitle.Parent           = setHeader

    local btnSetClose = Instance.new("ImageButton")
    btnSetClose.Size             = UDim2.new(0, 36, 0, 36)
    btnSetClose.Position         = UDim2.new(1, -48, 0.5, -18)
    btnSetClose.BackgroundColor3 = C.bgBtn
    btnSetClose.Image            = ICONS.Close
    btnSetClose.ImageColor3      = C.txtSub
    btnSetClose.ZIndex           = 22
    btnSetClose.BorderSizePixel  = 0
    uiCorner(btnSetClose, 10)
    btnSetClose.Parent = setHeader
    btnSetClose.MouseEnter:Connect(function()
        TweenService:Create(btnSetClose, T_FAST, {BackgroundColor3 = C.bgBtnHover, ImageColor3 = C.accent}):Play()
    end)
    btnSetClose.MouseLeave:Connect(function()
        TweenService:Create(btnSetClose, T_FAST, {BackgroundColor3 = C.bgBtn, ImageColor3 = C.txtSub}):Play()
    end)

    local setContent = Instance.new("Frame")
    setContent.Size             = UDim2.new(1, -48, 1, -88)
    setContent.Position         = UDim2.new(0, 24, 0, 76)
    setContent.BackgroundTransparency = 1
    setContent.ZIndex           = 21
    setContent.Parent           = SetPanel

    local setContentLayout = Instance.new("UIListLayout")
    setContentLayout.FillDirection = Enum.FillDirection.Vertical
    setContentLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    setContentLayout.Padding       = UDim.new(0, 12)
    setContentLayout.Parent        = setContent

    local function makeToggleRow(label, sublabel, order, startOn, onChange)
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 64)
        row.BackgroundColor3 = C.bgCard
        row.BorderSizePixel  = 0
        row.LayoutOrder      = order
        row.ZIndex           = 22
        uiCorner(row, 14)
        uiStroke(row, C.border, 1)
        row.Parent = setContent

        local lMain = Instance.new("TextLabel")
        lMain.Size           = UDim2.new(0.65, 0, 0, 24)
        lMain.Position       = UDim2.new(0, 18, 0, 12)
        lMain.BackgroundTransparency = 1
        lMain.TextColor3     = C.txtMain
        lMain.TextSize       = 14
        lMain.Font           = F_BOLD
        lMain.TextXAlignment = Enum.TextXAlignment.Left
        lMain.Text           = label
        lMain.Parent         = row

        local lSub = Instance.new("TextLabel")
        lSub.Size           = UDim2.new(0.65, 0, 0, 18)
        lSub.Position       = UDim2.new(0, 18, 0, 34)
        lSub.BackgroundTransparency = 1
        lSub.TextColor3     = C.txtMuted
        lSub.TextSize       = 11
        lSub.Font           = F_NORMAL
        lSub.TextXAlignment = Enum.TextXAlignment.Left
        lSub.Text           = sublabel
        lSub.Parent         = row

        local tBg = Instance.new("Frame")
        tBg.Size             = UDim2.new(0, 54, 0, 28)
        tBg.Position         = UDim2.new(1, -72, 0.5, -14)
        tBg.BackgroundColor3 = startOn and C.accent or C.bgBtn
        tBg.BorderSizePixel  = 0
        uiCorner(tBg, 14)
        tBg.Parent = row

        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 22, 0, 22)
        knob.Position         = startOn and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        knob.BackgroundColor3 = startOn and C.bgBase or C.txtMain
        knob.BorderSizePixel  = 0
        uiCorner(knob, 11)
        knob.Parent = tBg

        local hit = Instance.new("TextButton")
        hit.Size                   = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text                   = ""
        hit.ZIndex                 = 25
        hit.Parent                 = tBg

        local state = startOn
        hit.MouseButton1Click:Connect(function()
            state = not state
            SoundKit.PlayClick()
            TweenService:Create(tBg,  T_FAST, {BackgroundColor3 = state and C.accent or C.bgBtn}):Play()
            TweenService:Create(knob, T_FAST, {
                BackgroundColor3 = state and C.bgBase or C.txtMain,
                Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
            }):Play()
            if onChange then task.defer(onChange, state) end
        end)
    end

    makeToggleRow("Ocultar Jugadores", "Incrementa FPS haciendo invisibles a otros avatares", 1, false, function(active)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.LocalTransparencyModifier = active and 1 or 0 end
                end
            end
        end
    end)
    makeToggleRow("Efectos de Sonido", "Administra la salida de audio de la interfaz", 2, true, function(state)
        SoundKit.SetEnabled(state)
        if _G.InfectedAudio then
            if state then _G.InfectedAudio.unmute() else _G.InfectedAudio.mute() end
        end
    end)
    makeToggleRow("Ocultar nombres", "Oculta los tags sobre los jugadores", 3, false,
        function(active)
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    local tag  = head and head:FindFirstChild("NameTagGui")
                    if tag then tag.Enabled = not active end
                end
            end
        end
    )

    local musicRow = Instance.new("Frame")
    musicRow.Size             = UDim2.new(1, 0, 0, 68)
    musicRow.BackgroundColor3 = C.bgCard
    musicRow.BorderSizePixel  = 0
    musicRow.LayoutOrder      = 4
    musicRow.ZIndex           = 22
    uiCorner(musicRow, 14)
    uiStroke(musicRow, C.border, 1)
    musicRow.Parent = setContent

    local mLabel = Instance.new("TextLabel")
    mLabel.Size           = UDim2.new(0.4, 0, 1, 0)
    mLabel.Position       = UDim2.new(0, 18, 0, 0)
    mLabel.BackgroundTransparency = 1
    mLabel.TextColor3     = C.txtMain
    mLabel.TextSize       = 14
    mLabel.Font           = F_BOLD
    mLabel.TextXAlignment = Enum.TextXAlignment.Left
    mLabel.Text           = "Volumen Música"
    mLabel.Parent         = musicRow

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size             = UDim2.new(0, 200, 0, 6)
    sliderTrack.Position         = UDim2.new(1, -218, 0.5, -3)
    sliderTrack.BackgroundColor3 = C.bgBtn
    sliderTrack.BorderSizePixel  = 0
    uiCorner(sliderTrack, 3)
    sliderTrack.Parent           = musicRow

    local sliderFill = Instance.new("Frame")
    sliderFill.Size             = UDim2.new(0.8, 0, 1, 0)
    sliderFill.BackgroundColor3 = C.accent
    sliderFill.BorderSizePixel  = 0
    uiCorner(sliderFill, 3)
    sliderFill.Parent           = sliderTrack

    local knobSlider = Instance.new("Frame")
    knobSlider.Size             = UDim2.new(0, 14, 0, 14)
    knobSlider.Position         = UDim2.new(0.8, -7, 0.5, -7)
    knobSlider.BackgroundColor3 = C.accent
    knobSlider.BorderSizePixel  = 0
    uiCorner(knobSlider, 7)
    knobSlider.Parent           = sliderTrack

    uiStroke(knobSlider, C.bgBase, 1.5)

    local isDragging = false
    local function updateSlider(input)
        local trackWidth = sliderTrack.AbsoluteSize.X
        local mouseX = input.Position.X
        local trackX = sliderTrack.AbsolutePosition.X
        local relativeX = math.clamp((mouseX - trackX) / trackWidth, 0, 1)
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        knobSlider.Position = UDim2.new(relativeX, -7, 0.5, -7)
    end

    knobSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    MenuManager.Register("Settings",
        function()
            TweenService:Create(SetPanel, T_MED, {Position = SET_SHOW}):Play()
        end,
        function()
            TweenService:Create(SetPanel, T_SLOW, {Position = SET_HIDE}):Play()
        end
    )

    btnSetClose.MouseButton1Click:Connect(function()
        SoundKit.PlayClick()
        MenuManager.CloseAll()
    end)
end

return SettingsPanel