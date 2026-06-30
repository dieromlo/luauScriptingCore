-- ============================================================
--  CustomScoreboard.client.lua
--  LocalScript | StarterPlayerScripts
--  Scoreboard horizontal con stats, hover y tarjeta de jugador
-- ============================================================

local Players          = game:GetService("Players")
local StarterGui       = game:GetService("StarterGui")
local GuiService       = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

-- ─── Tokens (True Dark, sin acentos de color) ─────────────────
local C = {
    bgBase     = Color3.fromRGB(10, 10, 10),
    bgRow      = Color3.fromRGB(22, 22, 22),
    bgRowHover = Color3.fromRGB(32, 32, 32),
    bgRowActive= Color3.fromRGB(40, 40, 40),
    bgBtn      = Color3.fromRGB(28, 28, 28),
    bgBtnHover = Color3.fromRGB(42, 42, 42),
    txtMain    = Color3.fromRGB(255, 255, 255),
    txtSub     = Color3.fromRGB(150, 150, 150),
    txtMuted   = Color3.fromRGB(95, 95, 95),
    border     = Color3.fromRGB(38, 38, 38),
}

local F_BOLD   = Enum.Font.GothamBold
local F_NORMAL = Enum.Font.Gotham

local T_MENU = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

-- ─── Sistema de audio UI (preservado) ──────────────────────────
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

local sndToggle = getOrCreateSound("ScoreboardToggle", "6895079853", 0.4, 0.85)
local sndClick  = getOrCreateSound("ScoreboardClick",  "6895079853", 0.35, 1.05)

-- ─── Helpers ───────────────────────────────────────────────────
local function uiCorner(p, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 12)
    c.Parent = p
end
local function uiStroke(p, col, px)
    local s = Instance.new("UIStroke")
    s.Color = col or C.border
    s.Thickness = px or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
end

local function getThumb(userId)
    local content
    pcall(function()
        content = Players:GetUserThumbnailAsync(
            userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
        )
    end)
    return content or "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

-- ─── Stats placeholder (listo para conectar a datos reales) ───
-- Por ahora todos los valores empiezan en 0. Cuando construyamos
-- el sistema de compras/donaciones persistente, este es el punto
-- donde conectaremos DataStoreService o un RemoteEvent del servidor.
local playerStats = {}
local function getStats(userId)
    if not playerStats[userId] then
        playerStats[userId] = {purchases = 0, donated = 0, spent = 0}
    end
    return playerStats[userId]
end

-- ─── Columnas (offsets compartidos entre header y filas) ──────
local COL_NAME_X,    COL_NAME_W    = 46,  150
local COL_PURCH_X,   COL_PURCH_W   = 206, 78
local COL_DONATED_X, COL_DONATED_W = 290, 78
local COL_SPENT_X,   COL_SPENT_W   = 374, 70

-- ══════════════════════════════════════════════════════════════
--  ROOT
-- ══════════════════════════════════════════════════════════════
local GUI = Instance.new("ScreenGui")
GUI.Name           = "CustomScoreboard"
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent         = playerGui

local PANEL_W, PANEL_H = 460, 320
local HIDE_POS = UDim2.new(1, 20, 0.5, -PANEL_H/2)
local SHOW_POS = UDim2.new(1, -(PANEL_W + 24), 0.5, -PANEL_H/2)

local Panel = Instance.new("Frame")
Panel.Size             = UDim2.new(0, PANEL_W, 0, PANEL_H)
Panel.Position         = HIDE_POS
Panel.BackgroundColor3 = C.bgBase
Panel.BorderSizePixel  = 0
Panel.ZIndex           = 50
uiCorner(Panel, 16)
uiStroke(Panel, C.border, 1.5)
Panel.Parent = GUI

-- Título
local header = Instance.new("TextLabel")
header.Size             = UDim2.new(1, -50, 0, 20)
header.Position         = UDim2.new(0, 16, 0, 10)
header.BackgroundTransparency = 1
header.Text             = "Jugadores en línea"
header.TextColor3       = C.txtMain
header.Font             = F_BOLD
header.TextSize         = 15
header.TextXAlignment   = Enum.TextXAlignment.Left
header.ZIndex           = 51
header.Parent           = Panel

-- Subtítulo
local subtitle = Instance.new("TextLabel")
subtitle.Size             = UDim2.new(1, -32, 0, 16)
subtitle.Position         = UDim2.new(0, 16, 0, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text             = "TAB para alternar  ·  Clic en un jugador para más info"
subtitle.TextColor3       = C.txtMuted
subtitle.Font             = F_NORMAL
subtitle.TextSize         = 10
subtitle.TextXAlignment   = Enum.TextXAlignment.Left
subtitle.ZIndex           = 51
subtitle.Parent           = Panel

-- Botón cerrar (X)
local btnClosePanel = Instance.new("TextButton")
btnClosePanel.Size             = UDim2.new(0, 26, 0, 26)
btnClosePanel.Position         = UDim2.new(1, -38, 0, 10)
btnClosePanel.BackgroundColor3 = C.bgBtn
btnClosePanel.Text             = "✕"
btnClosePanel.TextColor3       = C.txtSub
btnClosePanel.TextSize         = 11
btnClosePanel.Font             = F_BOLD
btnClosePanel.BorderSizePixel  = 0
btnClosePanel.ZIndex           = 52
uiCorner(btnClosePanel, 7)
btnClosePanel.Parent = Panel
btnClosePanel.MouseEnter:Connect(function()
    TweenService:Create(btnClosePanel, T_FAST,
        {BackgroundColor3 = C.bgBtnHover, TextColor3 = C.txtMain}):Play()
end)
btnClosePanel.MouseLeave:Connect(function()
    TweenService:Create(btnClosePanel, T_FAST,
        {BackgroundColor3 = C.bgBtn, TextColor3 = C.txtSub}):Play()
end)

-- Divisor
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -32, 0, 1)
divider.Position         = UDim2.new(0, 16, 0, 50)
divider.BackgroundColor3 = C.border
divider.BorderSizePixel  = 0
divider.ZIndex           = 51
divider.Parent           = Panel

-- ─── Header de columnas ────────────────────────────────────────
local function makeColumnLabel(parent, text, x, w)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(0, w, 1, 0)
    lbl.Position         = UDim2.new(0, x, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = C.txtMuted
    lbl.Font             = F_BOLD
    lbl.TextSize         = 9
    lbl.TextXAlignment   = Enum.TextXAlignment.Center
    lbl.ZIndex           = 51
    lbl.Parent           = parent
    return lbl
end

local columnHeader = Instance.new("Frame")
columnHeader.Size             = UDim2.new(1, -24, 0, 20)
columnHeader.Position         = UDim2.new(0, 12, 0, 58)
columnHeader.BackgroundTransparency = 1
columnHeader.ZIndex           = 51
columnHeader.Parent           = Panel

local hName = makeColumnLabel(columnHeader, "JUGADOR", COL_NAME_X, COL_NAME_W)
hName.TextXAlignment = Enum.TextXAlignment.Left
makeColumnLabel(columnHeader, "COMPRAS", COL_PURCH_X,   COL_PURCH_W)
makeColumnLabel(columnHeader, "DONADO",  COL_DONATED_X, COL_DONATED_W)
makeColumnLabel(columnHeader, "GASTADO", COL_SPENT_X,   COL_SPENT_W)

-- ─── Lista de jugadores ────────────────────────────────────────
local list = Instance.new("ScrollingFrame")
list.Size                 = UDim2.new(1, -16, 1, -88)
list.Position             = UDim2.new(0, 8, 0, 84)
list.BackgroundTransparency = 1
list.BorderSizePixel      = 0
list.ScrollBarThickness   = 3
list.ScrollBarImageColor3 = C.txtSub
list.AutomaticCanvasSize  = Enum.AutomaticSize.Y
list.CanvasSize           = UDim2.new(0, 0, 0, 0)
list.ZIndex               = 51
list.Parent               = Panel

local layout = Instance.new("UIListLayout")
layout.Padding   = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent    = list

-- ══════════════════════════════════════════════════════════════
--  TARJETA DE JUGADOR (al hacer clic en una fila)
-- ══════════════════════════════════════════════════════════════
local CARD_W, CARD_H = 240, 300
local currentCardPlayer = nil

local PlayerCard = Instance.new("Frame")
PlayerCard.Size             = UDim2.new(0, CARD_W, 0, CARD_H)
PlayerCard.BackgroundColor3 = C.bgBase
PlayerCard.BorderSizePixel  = 0
PlayerCard.ZIndex           = 60
PlayerCard.Visible          = false
uiCorner(PlayerCard, 16)
uiStroke(PlayerCard, C.border, 1.5)
PlayerCard.Parent = GUI

local btnCardClose = Instance.new("TextButton")
btnCardClose.Size             = UDim2.new(0, 24, 0, 24)
btnCardClose.Position         = UDim2.new(1, -34, 0, 10)
btnCardClose.BackgroundColor3 = C.bgBtn
btnCardClose.Text             = "✕"
btnCardClose.TextColor3       = C.txtSub
btnCardClose.TextSize         = 10
btnCardClose.Font             = F_BOLD
btnCardClose.BorderSizePixel  = 0
btnCardClose.ZIndex           = 62
uiCorner(btnCardClose, 6)
btnCardClose.Parent = PlayerCard

local cardAvatar = Instance.new("ImageLabel")
cardAvatar.Size             = UDim2.new(0, 76, 0, 76)
cardAvatar.Position         = UDim2.new(0.5, -38, 0, 24)
cardAvatar.BackgroundColor3 = C.bgRow
cardAvatar.ZIndex           = 61
uiCorner(cardAvatar, 38)
cardAvatar.Parent = PlayerCard

local cardName = Instance.new("TextLabel")
cardName.Size             = UDim2.new(1, -24, 0, 22)
cardName.Position         = UDim2.new(0, 12, 0, 108)
cardName.BackgroundTransparency = 1
cardName.Text             = "—"
cardName.TextColor3       = C.txtMain
cardName.Font             = F_BOLD
cardName.TextSize         = 16
cardName.ZIndex           = 61
cardName.Parent           = PlayerCard

local cardUsername = Instance.new("TextLabel")
cardUsername.Size             = UDim2.new(1, -24, 0, 16)
cardUsername.Position         = UDim2.new(0, 12, 0, 130)
cardUsername.BackgroundTransparency = 1
cardUsername.Text             = "@—"
cardUsername.TextColor3       = C.txtMuted
cardUsername.Font             = F_NORMAL
cardUsername.TextSize         = 11
cardUsername.ZIndex           = 61
cardUsername.Parent           = PlayerCard

-- Fábrica de botones de acción de la tarjeta
local function makeCardButton(label, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -24, 0, 38)
    btn.Position         = UDim2.new(0, 12, 0, 156 + (order - 1) * 44)
    btn.BackgroundColor3 = C.bgBtn
    btn.Text             = label
    btn.TextColor3       = C.txtMain
    btn.TextSize         = 12
    btn.Font             = F_NORMAL
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 61
    uiCorner(btn, 9)
    btn.Parent = PlayerCard

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, T_FAST, {BackgroundColor3 = C.bgBtnHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, T_FAST, {BackgroundColor3 = C.bgBtn}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if sndClick.IsLoaded then sndClick:Play() end
        if onClick then onClick() end
    end)
    return btn
end

local btnExamine = makeCardButton("Examinar Avatar", 1, function()
    if currentCardPlayer then
        pcall(function()
            GuiService:InspectPlayerFromUserId(currentCardPlayer.UserId)
        end)
    end
end)

local btnFriend = makeCardButton("Agregar amigo", 2, function()
    if currentCardPlayer then
        pcall(function()
            StarterGui:SetCore("PromptSendFriendRequest", currentCardPlayer)
        end)
    end
end)

local btnBlock = makeCardButton("Bloquear", 3, function()
    if currentCardPlayer then
        pcall(function()
            StarterGui:SetCore("PromptBlockPlayer", currentCardPlayer)
        end)
    end
end)

local btnReport = makeCardButton("Reportar abuso", 4, function()
    if currentCardPlayer then
        local ok = pcall(function()
            StarterGui:SetCore("PromptReportAbuse", currentCardPlayer)
        end)
        if not ok then
            warn("[CustomScoreboard] ⚠️ PromptReportAbuse no disponible en esta sesión.")
        end
    end
end)

btnCardClose.MouseButton1Click:Connect(function()
    PlayerCard.Visible = false
end)

-- ─── Abrir tarjeta posicionada junto a la fila presionada ──────
local function openPlayerCard(p, rowFrame)
    currentCardPlayer = p

    cardAvatar.Image  = getThumb(p.UserId)
    cardName.Text     = p.DisplayName
    cardUsername.Text = "@" .. p.Name

    local isSelf = (p == player)
    btnFriend.Visible = not isSelf
    btnBlock.Visible  = not isSelf
    btnReport.Visible = not isSelf

    local rowAbsY   = rowFrame.AbsolutePosition.Y
    local panelAbsX = Panel.AbsolutePosition.X
    local viewportH = workspace.CurrentCamera.ViewportSize.Y

    local targetX = panelAbsX - CARD_W - 12
    local targetY = math.clamp(rowAbsY - 30, 12, viewportH - CARD_H - 12)

    PlayerCard.Visible = true
    PlayerCard.Position = UDim2.new(0, targetX + 16, 0, targetY)
    TweenService:Create(PlayerCard, T_MENU,
        {Position = UDim2.new(0, targetX, 0, targetY)}):Play()
end

-- ══════════════════════════════════════════════════════════════
--  FILAS DE JUGADORES (hover + click + stats)
-- ══════════════════════════════════════════════════════════════
local rows = {}
local selectedRow = nil

local function addRow(p)
    if rows[p.UserId] then return end

    local stats = getStats(p.UserId)

    local row = Instance.new("TextButton")
    row.Name             = "Row_" .. p.UserId
    row.Size             = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = C.bgRow
    row.Text             = ""
    row.BorderSizePixel  = 0
    row.ZIndex           = 51
    uiCorner(row, 10)
    row.Parent = list

    local avatar = Instance.new("ImageLabel")
    avatar.Size             = UDim2.new(0, 28, 0, 28)
    avatar.Position         = UDim2.new(0, 8, 0.5, -14)
    avatar.BackgroundTransparency = 1
    avatar.Image             = getThumb(p.UserId)
    avatar.ZIndex            = 52
    avatar.Parent            = row
    uiCorner(avatar, 14)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(0, COL_NAME_W, 1, 0)
    nameLbl.Position         = UDim2.new(0, COL_NAME_X, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = p.DisplayName
    nameLbl.TextColor3       = C.txtMain
    nameLbl.Font             = F_NORMAL
    nameLbl.TextSize         = 12
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex           = 52
    nameLbl.Parent           = row

    local function statLabel(x, w, value)
        local lbl = Instance.new("TextLabel")
        lbl.Size             = UDim2.new(0, w, 1, 0)
        lbl.Position         = UDim2.new(0, x, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text             = tostring(value)
        lbl.TextColor3       = C.txtSub
        lbl.Font             = F_NORMAL
        lbl.TextSize         = 12
        lbl.TextXAlignment   = Enum.TextXAlignment.Center
        lbl.ZIndex           = 52
        lbl.Parent           = row
        return lbl
    end

    local purchLbl   = statLabel(COL_PURCH_X,   COL_PURCH_W,   stats.purchases)
    local donatedLbl = statLabel(COL_DONATED_X, COL_DONATED_W, stats.donated)
    local spentLbl   = statLabel(COL_SPENT_X,   COL_SPENT_W,   stats.spent)

    -- Hover (igual que el tabulador default de Roblox)
    row.MouseEnter:Connect(function()
        if row ~= selectedRow then
            TweenService:Create(row, T_FAST, {BackgroundColor3 = C.bgRowHover}):Play()
        end
    end)
    row.MouseLeave:Connect(function()
        if row ~= selectedRow then
            TweenService:Create(row, T_FAST, {BackgroundColor3 = C.bgRow}):Play()
        end
    end)

    -- Click: abre la tarjeta del jugador
    row.MouseButton1Click:Connect(function()
        if sndClick.IsLoaded then sndClick:Play() end

        if selectedRow and selectedRow.Parent then
            TweenService:Create(selectedRow, T_FAST, {BackgroundColor3 = C.bgRow}):Play()
        end
        selectedRow = row
        TweenService:Create(row, T_FAST, {BackgroundColor3 = C.bgRowActive}):Play()

        openPlayerCard(p, row)
    end)

    rows[p.UserId] = {
        frame = row,
        purchLbl = purchLbl, donatedLbl = donatedLbl, spentLbl = spentLbl,
    }
end

local function removeRow(p)
    if rows[p.UserId] then
        if rows[p.UserId].frame == selectedRow then
            selectedRow = nil
            PlayerCard.Visible = false
        end
        rows[p.UserId].frame:Destroy()
        rows[p.UserId] = nil
    end
end

-- API pública: actualizar stats de un jugador en vivo
-- Uso futuro: _G.ScoreboardStats.update(userId, {purchases=5, donated=100, spent=420})
_G.ScoreboardStats = {
    update = function(userId, newStats)
        local stats = getStats(userId)
        for k, v in pairs(newStats) do stats[k] = v end
        local r = rows[userId]
        if r then
            r.purchLbl.Text   = tostring(stats.purchases)
            r.donatedLbl.Text = tostring(stats.donated)
            r.spentLbl.Text   = tostring(stats.spent)
        end
    end
}

for _, p in ipairs(Players:GetPlayers()) do addRow(p) end
Players.PlayerAdded:Connect(addRow)
Players.PlayerRemoving:Connect(removeRow)

-- ══════════════════════════════════════════════════════════════
--  TOGGLE (Tab + botón X)
-- ══════════════════════════════════════════════════════════════
local isOpen = false

local function setOpen(open)
    isOpen = open
    if sndToggle.IsLoaded then sndToggle:Play() end
    TweenService:Create(Panel, T_MENU, {Position = open and SHOW_POS or HIDE_POS}):Play()
    if not open then
        PlayerCard.Visible = false
        if selectedRow then
            TweenService:Create(selectedRow, T_FAST, {BackgroundColor3 = C.bgRow}):Play()
            selectedRow = nil
        end
    end
end

btnClosePanel.MouseButton1Click:Connect(function() setOpen(false) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Tab then
        setOpen(not isOpen)
    end
end)

print("[CustomScoreboard] ✅ Scoreboard Pro listo: stats, hover, tarjeta de jugador.")