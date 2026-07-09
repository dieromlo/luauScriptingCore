-- ============================================================
--  OutfitViewerPanel.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Panel al presionar E en un maniquí: Probar/Comprar. También
--  conecta los ProximityPrompt de todos los maniquíes del mapa.
-- ============================================================

local TweenService = game:GetService("TweenService")

local UIKit       = require(script.Parent.UIKit)
local SoundKit    = require(script.Parent.SoundKit)
local MenuManager = require(script.Parent.MenuManager)

local C, F_BOLD, F_NORMAL = UIKit.C, UIKit.F_BOLD, UIKit.F_NORMAL
local T_FAST, T_MED, T_SLOW = UIKit.T_FAST, UIKit.T_MED, UIKit.T_SLOW
local ICONS                  = UIKit.ICONS
local uiCorner, uiStroke     = UIKit.uiCorner, UIKit.uiStroke

local OutfitViewerPanel = {}

function OutfitViewerPanel.Init(guiParent, tryOnRemote, buyRemote, showToastFn)
    local PW, PH   = 720, 580
    local POS_HIDE = UDim2.new(0.5, -PW/2, 1.5, 0)
    local POS_SHOW = UDim2.new(0.5, -PW/2, 0.5, -PH/2)

    local Panel = Instance.new("Frame")
    Panel.Name             = "OutfitPanel"
    Panel.Size             = UDim2.new(0, PW, 0, PH)
    Panel.Position         = POS_HIDE
    Panel.BackgroundColor3 = C.bgBase
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 10
    uiCorner(Panel, 20)
    uiStroke(Panel, C.border, 1.5)
    Panel.Parent = guiParent

    local lblName = Instance.new("TextLabel")
    lblName.Size             = UDim2.new(1, -90, 0, 50)
    lblName.Position         = UDim2.new(0, 32, 0, 24)
    lblName.BackgroundTransparency = 1
    lblName.TextColor3       = C.txtMain
    lblName.TextSize         = 28
    lblName.Font             = F_BOLD
    lblName.TextXAlignment   = Enum.TextXAlignment.Left
    lblName.Text             = "Visualizador de Look"
    lblName.ZIndex           = 11
    lblName.Parent           = Panel

    local lblDesc = Instance.new("TextLabel")
    lblDesc.Size             = UDim2.new(1, -90, 0, 30)
    lblDesc.Position         = UDim2.new(0, 32, 0, 74)
    lblDesc.BackgroundTransparency = 1
    lblDesc.TextColor3       = C.txtSub
    lblDesc.TextSize         = 14
    lblDesc.Font             = F_NORMAL
    lblDesc.TextXAlignment   = Enum.TextXAlignment.Left
    lblDesc.TextWrapped      = true
    lblDesc.Text             = "Inspecciona los elementos de este maniquí."
    lblDesc.Parent           = Panel

    local btnClose = Instance.new("ImageButton")
    btnClose.Size             = UDim2.new(0, 36, 0, 36)
    btnClose.Position         = UDim2.new(1, -54, 0, 24)
    btnClose.BackgroundColor3 = C.bgBtn
    btnClose.Image            = ICONS.Close
    btnClose.ImageColor3      = C.txtSub
    btnClose.BorderSizePixel  = 0
    uiCorner(btnClose, 10)
    btnClose.Parent = Panel
    btnClose.MouseEnter:Connect(function()
        TweenService:Create(btnClose, T_FAST, {BackgroundColor3 = C.bgBtnHover, ImageColor3 = C.accent}):Play()
    end)
    btnClose.MouseLeave:Connect(function()
        TweenService:Create(btnClose, T_FAST, {BackgroundColor3 = C.bgBtn, ImageColor3 = C.txtSub}):Play()
    end)

    local function makeItemCard(xOffset, typeLabel)
        local card = Instance.new("Frame")
        card.Size             = UDim2.new(0, 210, 0, 250)
        card.Position         = UDim2.new(0, xOffset, 0, 130)
        card.BackgroundColor3 = C.bgCard
        card.BorderSizePixel  = 0
        uiCorner(card, 14)
        uiStroke(card, C.border)
        card.Parent = Panel

        local img = Instance.new("ImageLabel")
        img.Size             = UDim2.new(1, -16, 0, 160)
        img.Position         = UDim2.new(0, 8, 0, 8)
        img.BackgroundColor3 = C.bgBase
        img.ScaleType        = Enum.ScaleType.Fit
        uiCorner(img, 10)
        img.Parent = card

        local lType = Instance.new("TextLabel")
        lType.Size            = UDim2.new(1, -16, 0, 22)
        lType.Position        = UDim2.new(0, 12, 0, 178)
        lType.BackgroundTransparency = 1
        lType.TextColor3      = C.txtSub
        lType.TextSize        = 11
        lType.Font            = F_BOLD
        lType.TextXAlignment  = Enum.TextXAlignment.Left
        lType.Text            = typeLabel
        lType.Parent          = card

        local lId = Instance.new("TextLabel")
        lId.Size            = UDim2.new(1, -16, 0, 22)
        lId.Position        = UDim2.new(0, 12, 0, 198)
        lId.BackgroundTransparency = 1
        lId.TextColor3      = C.txtMuted
        lId.TextSize        = 11
        lId.Font            = F_NORMAL
        lId.TextXAlignment  = Enum.TextXAlignment.Left
        lId.Text            = "ID: ---"
        lId.Parent          = card

        return img, lId
    end

    local shirtImg, shirtIdLbl = makeItemCard(32,  "PRENDA SUPERIOR")
    local pantsImg, pantsIdLbl = makeItemCard(262, "PRENDA INFERIOR")

    local btnTryOn = Instance.new("TextButton")
    btnTryOn.Size             = UDim2.new(0, 210, 0, 56)
    btnTryOn.Position         = UDim2.new(0, 32, 1, -80)
    btnTryOn.BackgroundColor3 = C.bgBtn
    btnTryOn.Text             = "PROBAR AVATAR"
    btnTryOn.TextColor3       = C.txtMain
    btnTryOn.TextSize         = 14
    btnTryOn.Font             = F_BOLD
    btnTryOn.BorderSizePixel  = 0
    uiCorner(btnTryOn, 14)
    uiStroke(btnTryOn, C.border)
    btnTryOn.Parent = Panel

    local btnBuy = Instance.new("TextButton")
    btnBuy.Size             = UDim2.new(0, 210, 0, 56)
    btnBuy.Position         = UDim2.new(0, 262, 1, -80)
    btnBuy.BackgroundColor3 = C.accent
    btnBuy.Text             = "ADQUIRIR"
    btnBuy.TextColor3       = C.bgBase
    btnBuy.TextSize         = 14
    btnBuy.Font             = F_BOLD
    btnBuy.BorderSizePixel  = 0
    uiCorner(btnBuy, 14)
    btnBuy.Parent = Panel

    local function setButtonInteractions(button, isAccent)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, T_FAST, {BackgroundColor3 = isAccent and C.accentHover or C.bgBtnHover}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, T_FAST, {BackgroundColor3 = isAccent and C.accent or C.bgBtn}):Play()
        end)
    end
    setButtonInteractions(btnTryOn, false)
    setButtonInteractions(btnBuy, true)

    local activeOutfitData = nil

    MenuManager.Register("Outfit",
        function(data)
            if data then
                activeOutfitData = data
                lblName.Text = data.name or "Look Desconocido"
                local sid = data.shirt or 0
                local pid = data.pants or 0
                shirtImg.Image  = sid ~= 0 and ("rbxthumb://type=Asset&id=" .. sid .. "&w=150&h=150") or ""
                shirtIdLbl.Text = sid ~= 0 and ("ID: " .. sid) or "Vacante"
                pantsImg.Image  = pid ~= 0 and ("rbxthumb://type=Asset&id=" .. pid .. "&w=150&h=150") or ""
                pantsIdLbl.Text = pid ~= 0 and ("ID: " .. pid) or "Vacante"
            end
            TweenService:Create(Panel, T_MED, {Position = POS_SHOW}):Play()
        end,
        function()
            TweenService:Create(Panel, T_SLOW, {Position = POS_HIDE}):Play()
        end
    )

    btnClose.MouseButton1Click:Connect(function()
        SoundKit.PlayClick()
        MenuManager.CloseAll()
    end)

    btnTryOn.MouseButton1Click:Connect(function()
        if not activeOutfitData then return end
        SoundKit.PlayClick()
        tryOnRemote:FireServer(activeOutfitData.id)
        btnTryOn.Text = "✓ CONECTADO"
        task.delay(1.5, function() btnTryOn.Text = "PROBAR AVATAR" end)
        if showToastFn then
            showToastFn("Look equipado: " .. (activeOutfitData.name or "—"), "success", 3)
        end
    end)

    btnBuy.MouseButton1Click:Connect(function()
        if not activeOutfitData then return end
        SoundKit.PlayClick()
        local sid = activeOutfitData.shirt or 0
        local pid = activeOutfitData.pants or 0
        if sid ~= 0 then buyRemote:FireServer(sid) end
        if pid ~= 0 then task.delay(0.5, function() buyRemote:FireServer(pid) end) end
        if showToastFn then showToastFn("Abriendo tienda...", "info", 2.5) end
    end)

    local function connectMannequin(mannequin)
        if not mannequin:IsA("Model") then return end
        local root = mannequin.PrimaryPart or mannequin:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local prompt = root:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then return end

        prompt.Triggered:Connect(function()
            MenuManager.Open("Outfit", {
                id          = mannequin:GetAttribute("OutfitId"),
                name        = mannequin:GetAttribute("OutfitName"),
                description = mannequin:GetAttribute("OutfitDescription"),
                shirt       = mannequin:GetAttribute("ShirtId"),
                pants       = mannequin:GetAttribute("PantsId"),
            })
        end)
    end

    local workspaceMannequins = workspace:FindFirstChild("Mannequins")
    if workspaceMannequins then
        for _, m in ipairs(workspaceMannequins:GetChildren()) do connectMannequin(m) end
        workspaceMannequins.ChildAdded:Connect(connectMannequin)
    end
end

return OutfitViewerPanel