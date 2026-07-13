-- ============================================================
--  UIKit.lua
--  ModuleScript | StarterPlayerScripts/modules
--  Tokens de diseño compartidos: colores, fuentes, tiempos de
--  animación, íconos, y helpers de construcción de UI.
--  Cualquier módulo que necesite verse "igual" al resto del
--  juego hace require(UIKit) y usa estos valores.
-- ============================================================

local UIKit = {}

-- ─── COLORES ────────────────────────────────
UIKit.C = {
    bgBase      = Color3.fromRGB(10, 10, 10),
    bgCard      = Color3.fromRGB(22, 22, 22),
    bgBtn       = Color3.fromRGB(32, 32, 32),
    bgBtnHover  = Color3.fromRGB(48, 48, 48),
    accent      = Color3.fromRGB(255, 255, 255),
    accentHover = Color3.fromRGB(220, 220, 220),
    success     = Color3.fromRGB(46, 204, 113),
    txtMain     = Color3.fromRGB(255, 255, 255),
    txtSub      = Color3.fromRGB(150, 150, 150),
    txtMuted    = Color3.fromRGB(90, 90, 90),
    border      = Color3.fromRGB(38, 38, 38),
    borderHot   = Color3.fromRGB(255, 255, 255),

    buyGreen      = Color3.fromRGB(47, 143, 91),
    buyGreenHover = Color3.fromRGB(58, 154, 103),
}

-- ─── FUENTES ──────────────────────────────────────────────────
UIKit.F_BOLD   = Enum.Font.GothamBold
UIKit.F_NORMAL = Enum.Font.Gotham

-- ─── TIEMPOS DE ANIMACIÓN ───────────────────────────────────────
UIKit.T_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
UIKit.T_MED  = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
UIKit.T_SLOW = TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ─── ÍCONOS ───────────────────────────────────────────────────
UIKit.ICONS = {
    Run      = "rbxassetid://116542655589112",
    Cart     = "rbxassetid://136191071460353",
    Save     = "rbxassetid://12403099725",
    Settings = "rbxassetid://98202862460239",
    Reset    = "rbxassetid://87873470710971",
    Close    = "rbxassetid://98320673588366",
}

-- ─── HELPERS ──────────────────────────────────────────────────
function UIKit.uiCorner(p, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px or 12)
    c.Parent = p
    return c
end

function UIKit.uiStroke(p, col, px)
    local s = Instance.new("UIStroke")
    s.Color           = col or UIKit.C.border
    s.Thickness        = px or 1.2
    s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    s.Parent           = p
    return s
end

return UIKit