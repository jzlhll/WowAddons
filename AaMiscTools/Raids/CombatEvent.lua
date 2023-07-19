local _, addon = ...

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local EVENT_FRAME = CreateFrame('Frame')
local isInit = false
local isInCombat = false
local registCombatEventCount = 0

---注册通知战斗日志
--mask是用于取消注册的回调， encounterID注册某个boss的通知；否则就不通知
function addon:RegistGlobalCombatEvent(mask, encounterID, func)
    if encounterID == nil then
        if EVENT_FRAME.subCombatEvents == nil then
            EVENT_FRAME.subCombatEvents = {}
        end
        if EVENT_FRAME.subCombatEvents[mask] == nil then
            EVENT_FRAME.subCombatEvents[mask] = func
            registCombatEventCount = registCombatEventCount + 1
        end
    else
        if EVENT_FRAME.subCombatIDEvents == nil then
            EVENT_FRAME.subCombatIDEvents = {}
        end
        if EVENT_FRAME.subCombatIDEvents[encounterID] == nil then
            EVENT_FRAME.subCombatIDEvents[encounterID] = {}
        end
        if EVENT_FRAME.subCombatIDEvents[encounterID][mask] == nil then
            EVENT_FRAME.subCombatIDEvents[encounterID][mask] = func
            registCombatEventCount = registCombatEventCount + 1
        end
    end

    if registCombatEventCount == 1 then
        EVENT_FRAME:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function addon:UnRegistGlobalCombatEvent(mask, encounterID)
    if encounterID == nil then
        if EVENT_FRAME.subCombatEvents == nil then
            return
        end

        if EVENT_FRAME.subCombatEvents[mask] then
            EVENT_FRAME.subCombatEvents[mask] = nil
            registCombatEventCount = registCombatEventCount - 1
            if registCombatEventCount == 0 then
                EVENT_FRAME:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
    else
        if EVENT_FRAME.subCombatIDEvents == nil then
            return
        end
        if EVENT_FRAME.subCombatIDEvents[encounterID] == nil then
            return
        end
        if EVENT_FRAME.subCombatIDEvents[encounterID][mask] then
            EVENT_FRAME.subCombatIDEvents[encounterID][mask] = nil
            registCombatEventCount = registCombatEventCount - 1
            if registCombatEventCount == 0 then
                EVENT_FRAME:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
    end
end

---注册通知进入或者离开boss战的通知。
-- mask是用于取消的标记，func是回调函数，会收到ENTER_COMBAT|LEVEL_COMBAT 和 encounterID
function addon:RegistGlobalCombatStatusEvent(mask, func)
    if EVENT_FRAME.combatStatusEvents == nil then
        EVENT_FRAME.combatStatusEvents = {}
    end
    EVENT_FRAME.combatStatusEvents[mask] = func
end

---解除注册监听boss战消息。
function addon:UnRegistGlobalCombatStatusEvent(mask)
    if EVENT_FRAME.combatStatusEvents == nil then
        EVENT_FRAME.combatStatusEvents = {}
    end

    EVENT_FRAME.combatStatusEvents[mask] = nil
end

--=======================

local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName

local function enterOvLevelCombat(event, encounterID)
    if EVENT_FRAME.combatStatusEvents == nil then return end
    local size = #EVENT_FRAME.combatStatusEvents
    if size == 0 then return end
    for _, func in pairs(EVENT_FRAME.combatStatusEvents) do
        if func then func(event, encounterID) end
    end
end

local function combatEvent(frame, event, arg1)
    if event == "ENCOUNTER_START" then
        isInCombat = true
        enterOvLevelCombat("ENTER_COMBAT", arg1)
        return
    elseif event == "ENCOUNTER_END" then
        isInCombat = false
        enterOvLevelCombat("LEVEL_COMBAT", arg1)
        return
    end

    if isInCombat == false then return end
    if registCombatEventCount == 0 then return end

    timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()

    if subevent ~= "SPELL_CAST_SUCCESS" then return end
	if not spellId then return end

    if EVENT_FRAME.subCombatEvents then
        for _, func in pairs(EVENT_FRAME.subCombatEvents) do
            if func then func(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName) end
        end
    end

    if EVENT_FRAME.subCombatIDEvents then
        for _, bossEventTab in pairs(EVENT_FRAME.subCombatIDEvents) do
            for _, func in pairs(bossEventTab) do
                if func then func(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName) end
            end
        end
    end
end

local function Init()
    EVENT_FRAME:SetScript('OnEvent', combatEvent)
    EVENT_FRAME:RegisterEvent("ENCOUNTER_START")
    EVENT_FRAME:RegisterEvent("ENCOUNTER_END")
end

addon:registGlobalEvent(function(event, ...)
    if isInit then return end
    isInit = true
	if event == "LOADING_SCREEN_DISABLED" then
		Init()
	end
end)