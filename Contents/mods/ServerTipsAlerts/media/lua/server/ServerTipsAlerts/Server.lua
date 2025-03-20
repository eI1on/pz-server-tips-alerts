local Shared = require("ServerTipsAlerts/Shared")

local TipsServer = {}
local CONFIG = Shared.CONFIG
local COMMANDS = Shared.COMMANDS
local Utils = Shared.Utils

TipsServer.version = "VERSION = 1.0"
TipsServer.messages = {}
TipsServer.lastCheckTime = 0

TipsServer.loadMessages = function()
    local file = Utils.safeReadFile(CONFIG.TIPS_FILE)
    if file then
        TipsServer.version = file:readLine()
        TipsServer.messages = {}

        local line = file:readLine()
        while line do
            if line:trim() ~= "" then
                table.insert(TipsServer.messages, line)
            end
            line = file:readLine()
        end

        file:close()
    else
        if Utils.createDefaultFile(CONFIG.TIPS_FILE) then
            TipsServer.loadMessages()
        end
    end
end

TipsServer.checkForUpdates = function()
    local currentTime = getTimeInMillis()
    if currentTime - TipsServer.lastCheckTime > CONFIG.UPDATE_CHECK_INTERVAL then
        TipsServer.lastCheckTime = currentTime

        local file = Utils.safeReadFile(CONFIG.TIPS_FILE)
        if file then
            local version = file:readLine()
            file:close()

            if version ~= TipsServer.version then
                TipsServer.loadMessages()
                TipsServer.notifyClientsOfUpdate()
            end
        end
    end
end

TipsServer.notifyClientsOfUpdate = function()
    sendServerCommand(CONFIG.MODULE_NAME, COMMANDS.UPDATE_AVAILABLE, {})
end

TipsServer.sendMessagesToClient = function(player)
    local data = {
        version = TipsServer.version,
        messages = TipsServer.messages
    }

    sendServerCommand(player, CONFIG.MODULE_NAME, COMMANDS.RECEIVE_MESSAGES, data)
end

TipsServer.onClientCommand = function(module, command, player, args)
    if module ~= CONFIG.MODULE_NAME then return end

    if command == COMMANDS.REQUEST_MESSAGES then
        TipsServer.sendMessagesToClient(player)
    end
end

TipsServer.init = function()
    TipsServer.loadMessages()

    Events.EveryTenMinutes.Add(TipsServer.checkForUpdates)

    Events.OnClientCommand.Add(TipsServer.onClientCommand)
end

if isServer() then
    Events.OnServerStarted.Add(TipsServer.init)
end

Shared.TipsServer = TipsServer
return TipsServer
