-- ============================================================
--  NameTagSetup.server.lua
--  Script | ServerScriptService
--  Crea un BillboardGui dinámico con nombre, foto, rol y 
--  barra de vida sobre cada jugador.
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
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not head or not humanoid then return end

    local existing = head:FindFirstChild("NameTagGui")
    if existing then existing:Destroy() end

    -- BillboardGui ajustado:
    local billboard             = Instance.new("BillboardGui")
    billboard.Name              = "NameTagGui"
    billboard.Size              = UDim2.new(0, 170, 0, 52) 
    billboard.StudsOffset       = Vector3.new(0, 2.8, 0)
    billboard.MaxDistance       = 50
    billboard.AlwaysOnTop       = false
    billboard.LightInfluence    = 0
    billboard.Parent            = head

    -- Fondo de la píldora
    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3       = Color3.fromRGB(15, 15, 20)
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel        = 0
    card.ClipsDescendants       = true
    card.Parent                 = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = card
    
    -- Borde sutil
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.85
    stroke.Thickness = 1
    stroke.Parent = card

    -- Foto del avatar
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size                   = UDim2.new(0, 36, 0, 36)
    avatarImg.Position               = UDim2.new(0, 8, 0.5, -18)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Image                  = getThumbnail(player.UserId)
    avatarImg.Parent                 = card

    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(1, 0)
    imgCorner.Parent = avatarImg

    -- Nombre del jugador
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(1, -60, 0, 20)
    nameLbl.Position         = UDim2.new(0, 52, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = player.DisplayName
    nameLbl.TextColor3       = Color3.fromRGB(255, 255, 255)
    nameLbl.TextSize         = 14
    nameLbl.Font             = Enum.Font.GothamBold
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    nameLbl.Parent           = card

    -- Subtítulo / Rol
    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size             = UDim2.new(1, -60, 0, 14)
    roleLbl.Position         = UDim2.new(0, 52, 0, 24)
    roleLbl.BackgroundTransparency = 1
    roleLbl.Text             = "Jugador"
    roleLbl.TextColor3       = Color3.fromRGB(180, 180, 180)
    roleLbl.TextSize         = 11
    roleLbl.Font             = Enum.Font.GothamMedium
    roleLbl.TextXAlignment   = Enum.TextXAlignment.Left
    roleLbl.Parent           = card

    -- Barra de vida dinámica (Fondo) - Ancho reducido para no chocar con la curva
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(1, -70, 0, 3) 
    healthBg.Position = UDim2.new(0, 52, 1, -9)
    healthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = card
    
    local healthBgCorner = Instance.new("UICorner")
    healthBgCorner.CornerRadius = UDim.new(1, 0)
    healthBgCorner.Parent = healthBg

    -- Barra de vida dinámica (Relleno)
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    
    local healthFillCorner = Instance.new("UICorner")
    healthFillCorner.CornerRadius = UDim.new(1, 0)
    healthFillCorner.Parent = healthFill

    -- Lógica para actualizar la barra de vida
    humanoid.HealthChanged:Connect(function(health)
        local mathHealth = math.clamp(health / humanoid.MaxHealth, 0, 1)
        
        healthFill:TweenSize(UDim2.new(mathHealth, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        
        if mathHealth < 0.3 then
            healthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        else
            healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
end

local function onCharacterAdded(character, player)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then disableDefaultNameplate(humanoid) end
    task.wait(0.5) 
    createNameTag(character, player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

print("[NameTagSetup] ✅ Name tags dinámicos y reescalados activos.")