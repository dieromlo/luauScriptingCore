-- ============================================================
--  GroupPromptHandler.client.lua
--  Script | StarterPlayerScripts
--  Muestra la invitación oficial de Roblox para unirse al grupo
-- ============================================================

local SocialService = game:GetService("SocialService")
local Players       = game:GetService("Players")

local player = Players.LocalPlayer

-- ID del grupo de Roblox Infected Memories
local GROUP_ID = 351288253 

-- Tiempo de espera en segundos antes de que aparezca el mensaje en pantalla
local DELAY_TIME = 5 

local function promptGroupJoin()
    -- Esperamos unos segundos para que el mapa cargue y no asustar al jugador al entrar
    task.wait(DELAY_TIME)
    
    -- Verificamos de forma segura si el jugador YA está en el grupo
    local isInGroup = false
    local success, err = pcall(function()
        isInGroup = player:IsInGroup(GROUP_ID)
    end)
    
    -- Si la verificación falló (por temas de conexión de Roblox), asumimos false para no romper el flujo
    if not success then
        warn("[GroupPrompt] Error al verificar membresía: " .. tostring(err))
    end

    -- Si NO está en el grupo, le lanzamos la pestaña oficial de Roblox
    if not isInGroup then
        local promptSuccess, promptErr = pcall(function()
            SocialService:PromptGroupInvite(player, GROUP_ID)
        end)
        
        if not promptSuccess then
            warn("[GroupPrompt] No se pudo mostrar la invitación: " .. tostring(promptErr))
        end
    end
end

-- Ejecutar la función al spawnear
promptGroupJoin()