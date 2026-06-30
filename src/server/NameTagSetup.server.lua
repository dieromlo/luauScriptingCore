-- ============================================================
--  NameTagSetup.server.lua
--  Script | ServerScriptService
--  Crea un BillboardGui con nombre + headshot sobre cada
--  jugador, reemplazando el nametag default de Roblox.
-- ============================================================

local Players = game:GetService("Players")

-- Apagar el nametag blanco simple de Roblox
local function disableDefaultNameplate(humanoid)
    humanoid.NameDisplayDistance   = 0
    humanoid.HealthDisplayDistance = 0
end

-- Cache de thumbnails: evita pedir la misma imagen varias veces
local thumbnailCache = {}

local function getThumbnail(userId)
    if thumbnailCache[userId] then
        return thumbnailCache[userId]
    end
    local content
    local ok = pcall(function()
        content = Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)
    if ok and content then
        thumbnailCache[userId] = content
        return content
    end
    return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function createNameTag(character, player)
    local head = character:WaitForChild("Head", 10)
    if not head then return end

    local existing = head:FindFirstChild("NameTagGui")
    if existing then existing:Destroy() end

    local billboard = Instance.new("BillboardGui")
    billboard.Name         = "NameTagGui"
    billboard.Size         = UDim2.new(0, 160, 0, 46)
    billboard.StudsOffset  = Vector3.new(0, 1.2, 0)
    billboard.MaxDistance  = 60
    billboard.Parent       = head

    -- Tarjeta de fondo
    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3       = Color3.fromRGB(14, 14, 20)
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel        = 0
    card.Parent                 = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(196, 22, 42)
    stroke.Thickness     = 1
    stroke.Transparency  = 0.4
    stroke.Parent        = card

    -- Avatar headshot circular
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size             = UDim2.new(0, 32, 0, 32)
    avatarImg.Position         = UDim2.new(0, 7, 0.5, -16)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Image            = getThumbnail(player.UserId)
    avatarImg.Parent           = card

    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(1, 0)
    imgCorner.Parent = avatarImg

    -- Nombre del jugador
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(1, -50, 1, 0)
    nameLbl.Position         = UDim2.new(0, 46, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = player.DisplayName
    nameLbl.TextColor3       = Color3.fromRGB(255, 255, 255)
    nameLbl.TextSize         = 14
    nameLbl.Font             = Enum.Font.GothamBold
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    nameLbl.Parent           = card
end

local function onCharacterAdded(character, player)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then disableDefaultNameplate(humanoid) end
    createNameTag(character, player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
end)

-- Soporte para jugadores que ya estaban conectados (hot-reload del script)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

print("[NameTagSetup] ✅ Sistema de name tags activo.")