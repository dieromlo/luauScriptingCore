-- ============================================================
--  NameTagSetup.server.lua
--  Script | ServerScriptService
--  Crea un BillboardGui con nombre + headshot sobre cada
--  jugador, reemplazando el nametag default de Roblox.
-- ============================================================

local Players = game:GetService("Players")

local function disableDefaultNameplate(humanoid)
    humanoid.NameDisplayDistance   = 0
    humanoid.HealthDisplayDistance = 0
end

local function getThumbnail(userId)
    local content
    pcall(function()
        content = Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)
    return content or "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function createNameTag(character, player)
    local head = character:WaitForChild("Head", 10)
    if not head then return end

    local existing = head:FindFirstChild("NameTagGui")
    if existing then existing:Destroy() end

    -- BillboardGui: tamaño en studs, se reduce al alejar la cámara
    local billboard             = Instance.new("BillboardGui")
    billboard.Name              = "NameTagGui"
    billboard.Size              = UDim2.new(0, 130, 0, 38)
    billboard.StudsOffset       = Vector3.new(0, 1.4, 0)
    billboard.MaxDistance       = 40     -- desaparece si estás muy lejos
    billboard.AlwaysOnTop       = false
    billboard.LightInfluence    = 0
    billboard.Parent            = head

    -- Fondo píldora oscuro y translúcido (sin ningún borde de color)
    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3       = Color3.fromRGB(12, 12, 18)
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel        = 0
    card.Parent                 = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)  -- píldora completa
    corner.Parent = card

    -- Foto del avatar (círculo a la izquierda)
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size                   = UDim2.new(0, 28, 0, 28)
    avatarImg.Position               = UDim2.new(0, 5, 0.5, -14)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Image                  = getThumbnail(player.UserId)
    avatarImg.Parent                 = card

    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(1, 0)
    imgCorner.Parent = avatarImg

    -- Nombre del jugador
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(1, -42, 1, 0)
    nameLbl.Position         = UDim2.new(0, 38, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = player.DisplayName
    nameLbl.TextColor3       = Color3.fromRGB(255, 255, 255)
    nameLbl.TextSize         = 13
    nameLbl.Font             = Enum.Font.GothamBold
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    nameLbl.Parent           = card
end

local function onCharacterAdded(character, player)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then disableDefaultNameplate(humanoid) end
    task.wait(0.5)  -- pequeña espera para que el head esté listo
    createNameTag(character, player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
    -- Si ya tiene personaje al conectarse
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

print("[NameTagSetup] ✅ Name tags minimalistas activos.")