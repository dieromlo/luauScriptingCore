-- ============================================================
--  ResetConfirmPanel.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Modal de confirmación antes de resetear el avatar.
-- ============================================================

local TweenService = game:GetService("TweenService")

local UIKit       = require(script.Parent.UIKit)
local SoundKit    = require(script.Parent.SoundKit)
local MenuManager = require(script.Parent.MenuManager)

local C, F_BOLD, F_NORMAL   = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_FAST, T_MED, T_SLOW = UIKit.T_FAST, UIKit.T_MED, UIKit.T_SLOW
local uiCorner, uiStroke    = UIKit.uiCorner, UIKit.uiStroke

local ResetConfirmPanel = {}

-- guiParent          → el ScreenGui compartido (GUI de OutfitClient)
-- resetAvatarRemote  → el RemoteEvent ResetAvatar
-- showToastFn        → la función showToast de OutfitClient
function ResetConfirmPanel.Init(guiParent, resetAvatarRemote, showToastFn)
    local RW, RH     = 380, 220
    local RESET_HIDE = UDim2.new(0.5, -RW/2, 1.5, 0)
    local RESET_SHOW = UDim2.new(0.5, -RW/2, 0.5, -RH/2)

    local Panel = Instance.new("Frame")
    Panel.Name             = "ResetConfirmPanel"
    Panel.Size             = UDim2.new(0, RW, 0, RH)
    Panel.Position         = RESET_HIDE
    Panel.BackgroundColor3 = C.bgBase
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 15
    uiCorner(Panel, 18)
    uiStroke(Panel, C.border, 1.5)
    Panel.Parent = guiParent

    local rcTitle = Instance.new("TextLabel")
    rcTitle.Size             = UDim2.new(1, -48, 0, 28)
    rcTitle.Position         = UDim2.new(0, 24, 0, 24)
    rcTitle.BackgroundTransparency = 1
    rcTitle.TextColor3       = C.txtMain
    rcTitle.Font             = F_BOLD
    rcTitle.TextSize         = 19
    rcTitle.TextXAlignment   = Enum.TextXAlignment.Left
    rcTitle.Text             = "¿Resetear tu avatar?"
    rcTitle.ZIndex           = 16
    rcTitle.Parent           = Panel

    local rcSubtitle = Instance.new("TextLabel")
    rcSubtitle.Size             = UDim2.new(1, -48, 0, 40)
    rcSubtitle.Position         = UDim2.new(0, 24, 0, 56)
    rcSubtitle.BackgroundTransparency = 1
    rcSubtitle.TextColor3       = C.txtSub
    rcSubtitle.Font             = F_NORMAL
    rcSubtitle.TextSize         = 13
    rcSubtitle.TextWrapped      = true
    rcSubtitle.TextXAlignment   = Enum.TextXAlignment.Left
    rcSubtitle.Text             = "Perderás cualquier prenda que te hayas probado y volverás a tu apariencia original."
    rcSubtitle.ZIndex           = 16
    rcSubtitle.Parent           = Panel

    local btnCancel = Instance.new("TextButton")
    btnCancel.Size             = UDim2.new(0, 160, 0, 46)
    btnCancel.Position         = UDim2.new(0, 24, 1, -70)
    btnCancel.BackgroundColor3 = C.bgBtn
    btnCancel.Text             = "CANCELAR"
    btnCancel.TextColor3       = C.txtMain
    btnCancel.Font             = F_BOLD
    btnCancel.TextSize         = 13
    btnCancel.BorderSizePixel  = 0
    btnCancel.ZIndex           = 16
    uiCorner(btnCancel, 10)
    uiStroke(btnCancel, C.border)
    btnCancel.Parent = Panel

    local btnConfirm = Instance.new("TextButton")
    btnConfirm.Size             = UDim2.new(0, 160, 0, 46)
    btnConfirm.Position         = UDim2.new(1, -184, 1, -70)
    btnConfirm.BackgroundColor3 = C.accent
    btnConfirm.Text             = "SÍ, RESETEAR"
    btnConfirm.TextColor3       = C.bgBase
    btnConfirm.Font             = F_BOLD
    btnConfirm.TextSize         = 13
    btnConfirm.BorderSizePixel  = 0
    btnConfirm.ZIndex           = 16
    uiCorner(btnConfirm, 10)
    btnConfirm.Parent = Panel

    btnCancel.MouseEnter:Connect(function()
        SoundKit.PlayHover()
        TweenService:Create(btnCancel, T_FAST, {BackgroundColor3 = C.bgBtnHover}):Play()
    end)
    btnCancel.MouseLeave:Connect(function()
        TweenService:Create(btnCancel, T_FAST, {BackgroundColor3 = C.bgBtn}):Play()
    end)
    btnConfirm.MouseEnter:Connect(function()
        SoundKit.PlayHover()
        TweenService:Create(btnConfirm, T_FAST, {BackgroundColor3 = C.accentHover}):Play()
    end)
    btnConfirm.MouseLeave:Connect(function()
        TweenService:Create(btnConfirm, T_FAST, {BackgroundColor3 = C.accent}):Play()
    end)

    MenuManager.Register("ResetConfirm",
        function()
            TweenService:Create(Panel, T_MED, {Position = RESET_SHOW}):Play()
        end,
        function()
            TweenService:Create(Panel, T_SLOW, {Position = RESET_HIDE}):Play()
        end
    )

    btnCancel.MouseButton1Click:Connect(function()
        SoundKit.PlayClick()
        MenuManager.CloseAll()
    end)

    btnConfirm.MouseButton1Click:Connect(function()
        SoundKit.PlayClick()
        resetAvatarRemote:FireServer()
        TweenService:Create(btnConfirm, T_FAST, {BackgroundColor3 = C.success}):Play()
        if showToastFn then showToastFn("Avatar reseteado", "neutral", 2) end
        task.delay(0.15, function() MenuManager.CloseAll() end)
    end)
end

return ResetConfirmPanel