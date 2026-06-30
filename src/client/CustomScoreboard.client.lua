-- ============================================================
--  CustomScoreboard.client.lua
--  LocalScript | StarterPlayerScripts
-- ============================================================

local Players          = game:GetService("Players")
local StarterGui       = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")

local player    = Players.LocalPlayer   
local playerGui = player:WaitForChild("PlayerGui")

-- Apagar el leaderboard default
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

-- ─── Tokens (Sincronizados con OutfitClient) ───────────
local C = {
    bgBase  = Color3.fromRGB(10, 10, 10),     -- Negro Puro
    bgRow   = Color3.fromRGB(22, 22, 22),     -- Gris Carbón
    txtMain = Color3.fromRGB(255, 255, 255),  -- Blanco Puro
    txtSub  = Color3.fromRGB(150, 150, 150),  -- Gris Neutro
    border  = Color3.fromRGB(38, 38, 38),
}

local F_BOLD   = Enum.Font.GothamBold
local F_NORMAL = Enum.Font.Gotham

-- ─── Sistema de Audio UI ───────────────────────────────────────
local uiSounds = SoundService:FindFirstChild("InfectedMemories_UISounds")
if not uiSounds then
    uiSounds = Instance.new("Folder")
    uiSounds.Name = "InfectedMemories_UISounds"
    uiSounds.Parent = SoundService
end

local function getOrCreateSound(name, id, vol, pitch)
    local s = uiSounds:FindFirstChild(name)
    if not s then
        s = Instance.new("Sound")
        s.Name = name
        s.SoundId = "rbxassetid://" .. id
        s.Volume = vol or 0.5
        s.PlaybackSpeed = pitch or 1
        s.Parent = uiSounds
    end
    return s
end

-- Sonido suave para abrir/cerrar el panel
local sndToggle = getOrCreateSound("ScoreboardToggle", "6895079853", 0.4, 0.85)

-- ─── Helpers ───────────────────────────────────────────────────
local function uiCorner(p, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 12)
    c.Parent = p
end
local function uiStroke(p, col, px)
    local s = Instance.new("UIStroke")
    s.Color = col or C.border
    s.Thickness = px or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
end

-- ─── Root ──────────────────────────────────────────────────────
local GUI = Instance.new("ScreenGui")
GUI.Name           = "CustomScoreboard"
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent         = playerGui

-- Ajuste de tamaño: un poco más pequeño a lo alto
local PANEL_W, PANEL_H = 280, 340
local HIDE_POS = UDim2.new(1, 20, 0.5, -PANEL_H/2)
local SHOW_POS = UDim2.new(1, -(PANEL_W + 16), 0.5, -PANEL_H/2)

local Panel = Instance.new("Frame")
Panel.Size             = UDim2.new(0, PANEL_W, 0, PANEL_H)
Panel.Position         = HIDE_POS
Panel.BackgroundColor3 = C.bgBase
Panel.BorderSizePixel  = 0
Panel.ZIndex           = 50
uiCorner(Panel, 16)
uiStroke(Panel, C.border, 1.5)
Panel.Parent = GUI

local header = Instance.new("TextLabel")
header.Size             = UDim2.new(1, -24, 0, 40)
header.Position         = UDim2.new(0, 12, 0, 12)
header.BackgroundTransparency = 1
header.Text             = "Jugadores en línea"
header.TextColor3       = C.txtMain
header.Font             = F_BOLD
header.TextSize         = 14
header.TextXAlignment   = Enum.TextXAlignment.Left
header.Parent           = Panel

local list = Instance.new("ScrollingFrame")
list.Size                 = UDim2.new(1, -16, 1, -64)
list.Position             = UDim2.new(0, 8, 0, 56)
list.BackgroundTransparency = 1
list.BorderSizePixel      = 0
list.ScrollBarThickness   = 3
list.ScrollBarImageColor3 = C.txtSub
list.AutomaticCanvasSize  = Enum.AutomaticSize.Y
list.CanvasSize           = UDim2.new(0, 0, 0, 0)
list.Parent               = Panel

local layout = Instance.new("UIListLayout")
layout.Padding   = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent    = list

local rows = {}

local function getThumb(userId)
    local content
    pcall(function()
        content = Players:GetUserThumbnailAsync(
            userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
        )
    end)
    return content or "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function addRow(p)
    if rows[p.UserId] then return end

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = C.bgRow
    row.BorderSizePixel  = 0
    uiCorner(row, 10)
    row.Parent = list

    local avatar = Instance.new("ImageLabel")
    avatar.Size             = UDim2.new(0, 30, 0, 30)
    avatar.Position         = UDim2.new(0, 7, 0.5, -15)
    avatar.BackgroundTransparency = 1
    avatar.Image            = getThumb(p.UserId)
    avatar.Parent           = row
    
    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(1, 0)
    ic.Parent = avatar

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(1, -50, 1, 0)
    nameLbl.Position         = UDim2.new(0, 44, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = p.DisplayName
    nameLbl.TextColor3       = C.txtMain
    nameLbl.Font             = F_NORMAL
    nameLbl.TextSize         = 12
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    nameLbl.Parent           = row

    rows[p.UserId] = row
end

local function removeRow(p)
    if rows[p.UserId] then
        rows[p.UserId]:Destroy()
        rows[p.UserId] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do addRow(p) end
Players.PlayerAdded:Connect(addRow)
Players.PlayerRemoving:Connect(removeRow)

-- ─── Toggle con Tab e Integración de Animación fluida ────────
local isOpen = false
local T_MENU = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function setOpen(open)
    isOpen = open
    if sndToggle.IsLoaded then sndToggle:Play() end
    TweenService:Create(Panel, T_MENU, {Position = open and SHOW_POS or HIDE_POS}):Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Tab then
        setOpen(not isOpen)
    end
end)

print("[CustomScoreboard] ✅ Scoreboard minimalista sincronizado y listo.")