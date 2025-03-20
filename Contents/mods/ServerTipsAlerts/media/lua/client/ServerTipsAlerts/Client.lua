local Shared = require("ServerTipsAlerts/Shared")

local TipsClient = {}
local CONFIG = Shared.CONFIG
local COMMANDS = Shared.COMMANDS
local Utils = Shared.Utils

TipsClient.messages = {}
TipsClient.version = nil
TipsClient.lastCheckTime = 0
TipsClient.callbacks = {}
TipsClient.initialized = false
TipsClient.isSinglePlayer = Shared.isSinglePlayer()

TipsClient.loadMessages = function()
    local file = Utils.safeReadFile(CONFIG.TIPS_FILE)
    if file then
        local version = file:readLine()
        local messages = {}

        if version ~= TipsClient.version then
            TipsClient.version = version

            local line = file:readLine()
            while line do
                if line:trim() ~= "" then
                    table.insert(messages, line)
                end
                line = file:readLine()
            end
            TipsClient.messages = messages
            TipsClient.notifyCallbacks()
        end

        file:close()
    else
        if Utils.createDefaultFile(CONFIG.TIPS_FILE) then
            TipsClient.loadMessages()
        end
    end
end

TipsClient.checkForUpdates = function()
    if not TipsClient.isSinglePlayer then return end

    local currentTime = getTimeInMillis()
    if currentTime - TipsClient.lastCheckTime > CONFIG.UPDATE_CHECK_INTERVAL then
        TipsClient.lastCheckTime = currentTime
        TipsClient.loadMessages()
    end
end

TipsClient.requestMessages = function()
    if TipsClient.isSinglePlayer then return end

    local player = getSpecificPlayer(0)
    if player then
        sendClientCommand(player, CONFIG.MODULE_NAME, COMMANDS.REQUEST_MESSAGES, {})
    end
end

TipsClient.onServerCommand = function(module, command, args)
    if module ~= CONFIG.MODULE_NAME then return end

    if command == COMMANDS.RECEIVE_MESSAGES then
        if args and args.messages then
            TipsClient.messages = args.messages
            TipsClient.version = args.version
            TipsClient.notifyCallbacks()
        end
    elseif command == COMMANDS.UPDATE_AVAILABLE then
        TipsClient.requestMessages()
    end
end

TipsClient.addCallback = function(callback)
    table.insert(TipsClient.callbacks, callback)
    if #TipsClient.messages > 0 then
        callback(TipsClient.messages)
    end
end

TipsClient.notifyCallbacks = function()
    for _, callback in ipairs(TipsClient.callbacks) do
        callback(TipsClient.messages)
    end
end

TipsClient.init = function()
    if TipsClient.initialized then return end
    TipsClient.initialized = true

    if TipsClient.isSinglePlayer then
        TipsClient.loadMessages()
        Events.EveryOneMinute.Add(TipsClient.checkForUpdates)
    else
        Events.OnServerCommand.Add(TipsClient.onServerCommand)
        TipsClient.requestMessages()
    end
end

local doCommand = false;
local function sendCommand()
    if doCommand then
        TipsClient.init();
        Events.OnTick.Remove(sendCommand);
    end
    doCommand = true;
end
Events.OnTick.Add(sendCommand);

Shared.TipsClient = TipsClient
return TipsClient
