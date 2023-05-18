local _, addon = ...

addon:registGlobalEvent(function(event, ...)
	if event == "later" then
		if addon.getCfg("raidAbilityWatcher") then
			Init()
			frame:RegisterEvent("GROUP_ROSTER_UPDATE")
			frame:RegisterEvent("ENCOUNTER_START") -- 不做监听boss战结束；因为我想看看谁没用技能
			updateTeamTab()
		end
		
		return true
	end
	return false
end)

addon:registCategoryCreator(function()
    local checks = {
        {
            name="团队", 
            checked=addon.getCfgWithDefault("sendGuanxingToRaid", false), 
            func= function ()
            
            end
        },
        {name="自己", checked=addon.getCfgWithDefault("sendGuanxingToRaid", false), func=}}
	addon:initCategoryCheckBox(3, "观星时间轴输出团队", addon.getCfgWithDefault("sendGuanxingToRaid", false), function(cb)
		local c = not addon.getCfgWithDefault("sendGuanxingToRaid", false)
        addon.setCfg("sendGuanxingToRaid", c)
	end)
end)