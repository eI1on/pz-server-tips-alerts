local Shared = {}

Shared.CONFIG = {
    TIPS_FILE = "TipsAndAlerts/TipsAndAlerts.txt",
    UPDATE_CHECK_INTERVAL = 10000,
    MODULE_NAME = "ServerTipsAlerts"
}

Shared.COMMANDS = {
    REQUEST_MESSAGES = "requestMessages",
    RECEIVE_MESSAGES = "receiveMessages",
    UPDATE_AVAILABLE = "updateAvailable"
}

Shared.Utils = {}

Shared.Utils.safeReadFile = function(filePath)
    local success, file = pcall(getFileReader, filePath, false)
    if success and file then
        return file
    end
    return nil
end

Shared.Utils.safeWriteFile = function(filePath)
    local success, file = pcall(getFileWriter, filePath, true, false)
    if success and file then
        return file
    end
    return nil
end

Shared.Utils.createDefaultFile = function(filePath)
    local file = Shared.Utils.safeWriteFile(filePath)
    if not file then return false end

    file:write("VERSION = 1.0\r\n")

    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> Press Q to shout and attract zombies. Useful for creating distractions.\r\n")
    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> You can tear clothing into rags for bandages in a medical emergency.\r\n")
    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> Eat food before it spoils. Perishables go bad quickly without refrigeration.\r\n")
    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> Zombie bites are always fatal. Scratches and lacerations have a chance to infect you.\r\n")
    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> Reading skill books before training skills gives an XP multiplier.\r\n")
    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> Generators require fuel and maintenance. Check them regularly.\r\n")
    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> Winter is deadly without preparation. Collect warm clothing and wood for fires.\r\n")
    file:write("<GREEN> Tip: <SPACE><RGB:1,1,1> Fitness and Strength cannot be trained with books, only through exercise.\r\n")

    file:write("<ORANGE> Survival: <SPACE><RGB:1,1,1> Watch your weight! Being overweight will slow you down and tire you faster.\r\n")
    file:write("<ORANGE> Survival: <SPACE><RGB:1,1,1> Disinfect wounds immediately to prevent infection.\r\n")
    file:write("<ORANGE> Survival: <SPACE><RGB:1,1,1> Rain collectors only work when placed outside, not on interior floors.\r\n")
    file:write("<ORANGE> Survival: <SPACE><RGB:1,1,1> Fighting more than two zombies at once is extremely dangerous.\r\n")
    file:write("<ORANGE> Survival: <SPACE><RGB:1,1,1> Broken glass can cut you - wear shoes and be careful.\r\n")

    file:write("<RGB:1,0.8,0.1> Server Rule: <SPACE><RGB:1,1,1> Join our Discord server to stay updated with announcements.\r\n")
    file:write("<RGB:1,0.8,0.1> Server Rule: <SPACE><RGB:1,1,1> No base building that blocks important loot locations.\r\n")
    file:write("<RGB:1,0.8,0.1> Server Rule: <SPACE><RGB:1,1,1> Be respectful to other players in global chat.\r\n")
    file:write("<RGB:1,0.8,0.1> Server Rule: <SPACE><RGB:1,1,1> PVP is only allowed in designated areas.\r\n")
    file:write("<RGB:1,0.8,0.1> Server Rule: <SPACE><RGB:1,1,1> Report bugs and exploits to admins instead of abusing them.\r\n")

    file:close()
    return true
end

Shared.isSinglePlayer = function()
    return not isServer() and not isClient()
end

Shared.TipsClient = {}
Shared.TipsServer = {}

return Shared
