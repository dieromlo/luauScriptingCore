-- ============================================================
--  ToastSystem.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Notificaciones tipo "toast": arriba a la derecha, se apilan,
--  desaparecen solas.
-- ============================================================

local TweenService = game:GetService("TweenService")

local UIKit = require(script.Parent.UIKit)
local C, F_BOLD, F_NORMAL = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local uiCorner, uiStroke = UIKit.uiCorner, UIKit.uiStroke

local ToastSystem = {}

local TOAST_W       = 280
local TOAST_H       = 56
local TOAST_PADDING = 10
local TOAST_SHOW_Y  = 20
local toastQueue    = {}
local TOAST_TYPES   = {
    success = {icon = "✓", color = Color3.fromRGB(40, 185, 90)},
    error   = {icon = "✕", color = Color3.fromRGB(196, 22, 42)},
    info    = {icon = "i", color = Color3.fromRGB(80, 140, 220)},
    neutral = {icon = "·", color = Color3.fromRGB(150, 150, 150)},
}

local toastContainer

function ToastSystem.Init(guiParent)
    toastContainer = Instance.new("Frame")
    toastContainer.Name             = "ToastContainer"
    toastContainer.Size             = UDim2.new(0, TOAST_W, 1, 0)
    toastContainer.Position         = UDim2.new(1, -(TOAST_W + 16), 0, 0)
    toastContainer.BackgroundTransparency = 1
    toastContainer.ZIndex           = 100
    toastContainer.Parent           = guiParent
end

function ToastSystem.Show(message, toastType, duration)
    toastType = toastType or "neutral"
    duration  = duration  or 3
    local style = TOAST_TYPES[toastType] or TOAST_TYPES.neutral

    local yOffset = TOAST_SHOW_Y
    for _, existing in ipairs(toastQueue) do
        if existing and existing.Parent then
            yOffset = yOffset + TOAST_H + TOAST_PADDING
        end
    end

    local toast = Instance.new("Frame")
    toast.Name             = "Toast"
    toast.Size             = UDim2.new(1, 0, 0, TOAST_H)
    toast.Position         = UDim2.new(1.2, 0, 0, yOffset)
    toast.BackgroundColor3 = C.bgCard
    toast.BorderSizePixel  = 0
    toast.ZIndex           = 101
    uiCorner(toast, 12)
    uiStroke(toast, C.border, 1)
    toast.Parent = toastContainer

    local icoLbl = Instance.new("TextLabel")
    icoLbl.Size             = UDim2.new(0, 32, 1, -8)
    icoLbl.Position         = UDim2.new(0, 16, 0, 0)
    icoLbl.BackgroundTransparency = 1
    icoLbl.Text             = style.icon
    icoLbl.TextColor3       = style.color
    icoLbl.TextSize         = 20
    icoLbl.Font             = F_BOLD
    icoLbl.TextYAlignment   = Enum.TextYAlignment.Center
    icoLbl.ZIndex           = 102
    icoLbl.Parent           = toast

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size             = UDim2.new(1, -64, 1, -8)
    msgLbl.Position         = UDim2.new(0, 54, 0, 0)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text             = message
    msgLbl.TextColor3       = C.txtMain
    msgLbl.TextSize         = 14
    msgLbl.Font             = F_NORMAL
    msgLbl.TextXAlignment   = Enum.TextXAlignment.Left
    msgLbl.TextYAlignment   = Enum.TextYAlignment.Center
    msgLbl.TextWrapped      = true
    msgLbl.ZIndex           = 102
    msgLbl.Parent           = toast

    local progressBg = Instance.new("Frame")
    progressBg.Size             = UDim2.new(1, -16, 0, 2)
    progressBg.Position         = UDim2.new(0, 8, 1, -6)
    progressBg.BackgroundColor3 = C.border
    progressBg.BorderSizePixel  = 0
    uiCorner(progressBg, 1)
    progressBg.Parent = toast

    local progressFill = Instance.new("Frame")
    progressFill.Size             = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = style.color
    progressFill.BorderSizePixel  = 0
    uiCorner(progressFill, 1)
    progressFill.Parent = progressBg

    table.insert(toastQueue, toast)
    local T_TOAST = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    TweenService:Create(toast, T_TOAST, {Position = UDim2.new(0, 0, 0, yOffset)}):Play()
    TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 1, 0)}):Play()

    task.delay(duration, function()
        if not toast or not toast.Parent then return end
        TweenService:Create(toast, T_TOAST,
            {Position = UDim2.new(1.2, 0, 0, yOffset), BackgroundTransparency = 0.6}):Play()
        task.delay(0.35, function()
            for i, t in ipairs(toastQueue) do
                if t == toast then table.remove(toastQueue, i) break end
            end
            toast:Destroy()
            for i, remaining in ipairs(toastQueue) do
                local newY = TOAST_SHOW_Y + (i - 1) * (TOAST_H + TOAST_PADDING)
                TweenService:Create(remaining, T_TOAST, {Position = UDim2.new(0, 0, 0, newY)}):Play()
            end
        end)
    end)
end

return ToastSystem