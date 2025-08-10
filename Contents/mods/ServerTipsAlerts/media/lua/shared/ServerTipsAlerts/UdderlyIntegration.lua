local Shared = require("ServerTipsAlerts/Shared")

local UdderlyIntegration = {}

UdderlyIntegration.activeRestartPopups = {}

UdderlyIntegration.isUdderlyLoaded = function()
    return UdderlyUpToDate ~= nil
end

UdderlyIntegration.showRestartMessage = function(message, isAlert)
    local formattedMessage = "<RED> SERVER RESTART <SPACE> " .. tostring(message)

    table.insert(UdderlyIntegration.activeRestartPopups, formattedMessage)

    local instances = UdderlyIntegration.getPopupInstances()

    for _, popup in pairs(instances) do
        if popup then
            popup:forceShowMessage(formattedMessage)
        end
    end
end

UdderlyIntegration.getPopupInstances = function()
    local instances = {}

    if _G.tipsAndAlertsPopups then
        instances = _G.tipsAndAlertsPopups
    end

    return instances
end

UdderlyIntegration.init = function()
    if not UdderlyIntegration.isUdderlyLoaded() then return end

    local originalMessage = UdderlyUpToDate.message

    UdderlyUpToDate.message = function(msg, isAlert)
        originalMessage(msg, isAlert)

        UdderlyIntegration.showRestartMessage(msg, isAlert)
    end
end

return UdderlyIntegration
