local TipsClient = require("ServerTipsAlerts/Client")

local POPUP_CONFIG = {
    BACKGROUND_ALPHA = 0.5,
    MIN_HEIGHT = 20,
    HOTBAR_PADDING = 10,
    DASHBOARD_PADDING = 10,
    TEXT_PADDING = 5,
    WIDTH_PADDING = 5,
    MAX_WIDTH_PERCENT = 0.7,

    DISPLAY_TIME = 3000,
    FADE_IN_TIME = 1000,
    FADE_OUT_TIME = 1000,
    MIN_DISPLAY_INTERVAL = 10000,
    MAX_DISPLAY_INTERVAL = 30000,

    ZOMBIE_SAFETY_RADIUS = 15,
    ZOMBIE_CHECK_INTERVAL = 60,

    ENABLED = true
}

local function loadSandboxOptions()
    local sandboxOptions = SandboxVars.TipsPopup
    if not sandboxOptions then return end

    POPUP_CONFIG.ENABLED = sandboxOptions.Enabled ~= nil and sandboxOptions.Enabled or POPUP_CONFIG.ENABLED

    if sandboxOptions.DisplayTime ~= nil then
        POPUP_CONFIG.DISPLAY_TIME = sandboxOptions.DisplayTime * 1000
    end

    if sandboxOptions.FadeInTime ~= nil then
        POPUP_CONFIG.FADE_IN_TIME = sandboxOptions.FadeInTime * 1000
    end

    if sandboxOptions.FadeOutTime ~= nil then
        POPUP_CONFIG.FADE_OUT_TIME = sandboxOptions.FadeOutTime * 1000
    end

    if sandboxOptions.MinDisplayInterval ~= nil then
        POPUP_CONFIG.MIN_DISPLAY_INTERVAL = sandboxOptions.MinDisplayInterval * 1000
    end

    if sandboxOptions.MaxDisplayInterval ~= nil then
        POPUP_CONFIG.MAX_DISPLAY_INTERVAL = sandboxOptions.MaxDisplayInterval * 1000
    end

    POPUP_CONFIG.ZOMBIE_SAFETY_RADIUS = sandboxOptions.ZombieSafetyRadius ~= nil and sandboxOptions.ZombieSafetyRadius or
        POPUP_CONFIG.ZOMBIE_SAFETY_RADIUS

    if POPUP_CONFIG.MIN_DISPLAY_INTERVAL >= POPUP_CONFIG.MAX_DISPLAY_INTERVAL then
        POPUP_CONFIG.MAX_DISPLAY_INTERVAL = POPUP_CONFIG.MIN_DISPLAY_INTERVAL + 1000
    end
end

TipsPopup = ISPanel:derive("TipsPopup")

function TipsPopup:initialise()
    ISPanel.initialise(self)

    self.messages = {}

    TipsClient.addCallback(function(messages)
        self:updateFromClient(messages)
    end)

    self.currentAlpha = 0
    self.currentState = "hidden" -- states: hidden, fadingIn, visible, fadingOut
    self.stateStartTime = 0
    self.zombieCheckTimer = 0
    self.lastSafetyCheck = true
    self.isInVehicle = false
    self.playerNum = 0

    self.textPanel = ISRichTextPanel:new(0, 0, self.width, self.height)
    self.textPanel:initialise()
    self.textPanel.autosetheight = false
    self.textPanel.clip = true
    self.textPanel.background = false
    self.textPanel.marginLeft = POPUP_CONFIG.TEXT_PADDING
    self.textPanel.marginRight = POPUP_CONFIG.TEXT_PADDING
    self.textPanel.marginTop = POPUP_CONFIG.TEXT_PADDING
    self.textPanel.marginBottom = POPUP_CONFIG.TEXT_PADDING
    self.textPanel.defaultFont = UIFont.Medium
    self:addChild(self.textPanel)

    self:scheduleNextPopup()
    self:updatePosition()
end

function TipsPopup:updateFromClient(messages)
    self.messages = messages
end

function TipsPopup:scheduleNextPopup()
    local interval = ZombRand(POPUP_CONFIG.MIN_DISPLAY_INTERVAL, POPUP_CONFIG.MAX_DISPLAY_INTERVAL)
    self.nextPopupTime = getTimestampMs() + interval
end

function TipsPopup:isSafeToShowPopup()
    if POPUP_CONFIG.ZOMBIE_SAFETY_RADIUS <= 0 then
        return true
    end

    local player = getSpecificPlayer(self.playerNum)
    if not player then return false end

    if player:getVehicle() then
        return true
    end

    self.zombieCheckTimer = self.zombieCheckTimer + 1
    if self.zombieCheckTimer < POPUP_CONFIG.ZOMBIE_CHECK_INTERVAL then
        return self.lastSafetyCheck
    end
    self.zombieCheckTimer = 0

    local playerSquare = player:getCurrentSquare()
    local px = playerSquare:getX()
    local py = playerSquare:getY()
    local z = playerSquare:getZ()

    for x = px - POPUP_CONFIG.ZOMBIE_SAFETY_RADIUS, px + POPUP_CONFIG.ZOMBIE_SAFETY_RADIUS do
        for y = py - POPUP_CONFIG.ZOMBIE_SAFETY_RADIUS, py + POPUP_CONFIG.ZOMBIE_SAFETY_RADIUS do
            local square = playerSquare:getCell():getGridSquare(x, y, z)
            if square then
                for i = 0, square:getMovingObjects():size() - 1 do
                    local o = square:getMovingObjects():get(i)
                    if instanceof(o, "IsoZombie") then
                        self.lastSafetyCheck = false
                        return false
                    end
                end
            end
        end
    end

    self.lastSafetyCheck = true
    return true
end

function TipsPopup:calculateTextWidth(message)
    local plainText = message
    plainText = plainText:gsub("<[^>]+>", "")

    local textWidth = getTextManager():MeasureStringX(self.textPanel.defaultFont, plainText)
    textWidth = textWidth + (POPUP_CONFIG.TEXT_PADDING * 2) + (POPUP_CONFIG.WIDTH_PADDING * 2)

    local screenWidth = getCore():getScreenWidth()
    local maxWidth = screenWidth * POPUP_CONFIG.MAX_WIDTH_PERCENT

    return math.min(textWidth, maxWidth)
end

function TipsPopup:showPopup()
    if self.messages and #self.messages == 0 then return end

    local messageIndex = ZombRand(1, #self.messages + 1)
    local message = self.messages[messageIndex]

    local textWidth = self:calculateTextWidth(message)
    self:setWidth(textWidth)
    self.textPanel:setWidth(textWidth)

    self.textPanel.text = "<CENTRE> " .. message
    self.textPanel:paginate()

    local textHeight = self.textPanel:getScrollHeight()
    local panelHeight = math.max(POPUP_CONFIG.MIN_HEIGHT, textHeight)
    self:setHeight(panelHeight)
    self.textPanel:setHeight(panelHeight)

    self.currentState = "fadingIn"
    self.stateStartTime = getTimestampMs()
    self.currentAlpha = 0
    self.textPanel:setContentTransparency(self.currentAlpha)

    self:updatePosition()
end

function TipsPopup:update()
    ISPanel.update(self)

    self:checkVehicleStatus()
    self:updatePosition()

    local currentTime = getTimestampMs()

    if self.currentState == "hidden" and currentTime >= self.nextPopupTime then
        local isSafe = self:isSafeToShowPopup()

        if isSafe then
            self:showPopup()
        else
            self.nextPopupTime = currentTime + 5000
        end
    end

    local timeInState = currentTime - self.stateStartTime

    if self.currentState == "fadingIn" then
        self.currentAlpha = math.min(1, timeInState / POPUP_CONFIG.FADE_IN_TIME)
        self.textPanel:setContentTransparency(self.currentAlpha)
        if timeInState >= POPUP_CONFIG.FADE_IN_TIME then
            self.currentState = "visible"
            self.stateStartTime = currentTime
        end
    elseif self.currentState == "visible" then
        if timeInState >= POPUP_CONFIG.DISPLAY_TIME then
            self.currentState = "fadingOut"
            self.stateStartTime = currentTime
        end
    elseif self.currentState == "fadingOut" then
        self.currentAlpha = math.max(0, 1 - (timeInState / POPUP_CONFIG.FADE_OUT_TIME))
        self.textPanel:setContentTransparency(self.currentAlpha)
        if timeInState >= POPUP_CONFIG.FADE_OUT_TIME then
            self.currentState = "hidden"
            self.stateStartTime = currentTime
            self:scheduleNextPopup()
        end
    end
end

function TipsPopup:checkVehicleStatus()
    local player = getSpecificPlayer(self.playerNum)
    if not player then return end

    local wasInVehicle = self.isInVehicle
    local vehicle = player:getVehicle()

    self.isInVehicle = vehicle ~= nil and vehicle:isDriver(player)

    if wasInVehicle ~= self.isInVehicle then
        self:updatePosition()
    end
end

function TipsPopup:updatePosition()
    local player = getSpecificPlayer(self.playerNum)
    if not player then return end

    self:setX((getCore():getScreenWidth() - self:getWidth()) / 2)

    local yPosition = 0

    if self.isInVehicle then
        local dashboard = getPlayerVehicleDashboard(self.playerNum)
        if dashboard and dashboard:isVisible() then
            yPosition = dashboard:getY() - self:getHeight() - POPUP_CONFIG.DASHBOARD_PADDING
        else
            yPosition = getCore():getScreenHeight() - 200 - self:getHeight() - POPUP_CONFIG.DASHBOARD_PADDING
        end
    else
        local hotbar = getPlayerHotbar(self.playerNum)
        if hotbar then
            yPosition = hotbar:getY() - self:getHeight() - POPUP_CONFIG.HOTBAR_PADDING
        else
            yPosition = getCore():getScreenHeight() - 100 - self:getHeight()
        end
    end

    if yPosition < 0 then
        yPosition = 0
    end

    self:setY(yPosition)
end

function TipsPopup:prerender()
    if self.currentState == "hidden" then return end

    self:drawRect(0, 0, self.width, self.height, POPUP_CONFIG.BACKGROUND_ALPHA * self.currentAlpha, 0, 0, 0)

    ISPanel.prerender(self)
end

function TipsPopup:new(playerNum)
    local o = ISPanel:new(0, 0, 100, POPUP_CONFIG.MIN_HEIGHT)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.playerNum = playerNum or 0

    return o
end

local tipsPopups = {}

local function onEnterVehicle(player)
    local playerNum = player:getPlayerNum()
    if tipsPopups[playerNum] then
        tipsPopups[playerNum]:checkVehicleStatus()
    end
end

local function onExitVehicle(player)
    local playerNum = player:getPlayerNum()
    if tipsPopups[playerNum] then
        tipsPopups[playerNum]:checkVehicleStatus()
    end
end

local function onSwitchVehicleSeat(player)
    local playerNum = player:getPlayerNum()
    if tipsPopups[playerNum] then
        tipsPopups[playerNum]:checkVehicleStatus()
    end
end

local function createTipsPopup()
    loadSandboxOptions()

    if not POPUP_CONFIG.ENABLED then
        return
    end

    for i = 0, getNumActivePlayers() - 1 do
        if not tipsPopups[i] then
            tipsPopups[i] = TipsPopup:new(i)
            tipsPopups[i]:initialise()
            tipsPopups[i]:addToUIManager()
        end
    end
end

Events.OnCreatePlayer.Add(createTipsPopup)
Events.OnGameStart.Add(createTipsPopup)
Events.OnInitGlobalModData.Add(loadSandboxOptions)

Events.OnEnterVehicle.Add(onEnterVehicle)
Events.OnExitVehicle.Add(onExitVehicle)
Events.OnSwitchVehicleSeat.Add(onSwitchVehicleSeat)

return TipsPopup
