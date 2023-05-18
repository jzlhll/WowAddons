local _, addon = ...

-----------------init codes---------------
local GetTime = GetTime
local DELAY_TIME, DELAY_TIME_X2 = 4, 8
local lastEnterTime
local isLaterNotified = 0

function addon:notifyEvent(event, ...)
	local delTab = {}
	local func
    for _, func in pairs(addon.modFuncs) do
        if func then
			local isDel = func(event, ...)
			if isDel then
				table.insert(delTab, func)
			end
		end
	end

    for _, func in pairs(delTab) do
		addon:unRegistGlobalEvent(func)
	end
	delTab = nil
end

local function OnTimerUpdate()
	local delta = GetTime() - lastEnterTime
    if isLaterNotified == 0 and delta >= 3 then
        isLaterNotified = 1
        addon:categoriesUi()
        addon:notifyEvent("later")
		return
	elseif isLaterNotified == 1 and delta >= 5 then
        isLaterNotified = 2
        addon:notifyEvent("later2")
		return
    elseif isLaterNotified == 2 and delta >= 7 then
        isLaterNotified = 3
        addon:notifyEvent("later3")
		addon:GlobalTimerStop("InitAtLastMask")
    end
end

local onEvent = function(frame, event, ...)
	if event == 'LOADING_SCREEN_DISABLED' then
		--ok print("loaded "..tostring(MiscDB))
		lastEnterTime = GetTime()

		addon:GlobalTimerStart(OnTimerUpdate, "InitAtLastMask")

		addon.eventframe:UnregisterEvent("LOADING_SCREEN_DISABLED")
    else
        addon:notifyEvent(event, ...)
    end
end

addon.eventframe:SetScript('OnEvent', onEvent)
addon.eventframe:RegisterEvent("LOADING_SCREEN_DISABLED")

addon:registCategoryMenuName("一般", 1)
addon:registCategoryMenuName("AH", 2)
addon:registCategoryMenuName("战斗", 3)