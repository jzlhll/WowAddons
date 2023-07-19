local _, addon = ...

local POINT_X = 20
local POINT_Y = -150
local GetSpellCooldown = GetSpellCooldown
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local frame

local isRegistCombatEvent = false
local isRegistTimer = false

local debug = false

local allLines = {}
local SpellMaps, SpellMarks, SpellMarksMembers = {}, {}, {}

local function InitSpellMaps()
	--一般
	SpellMaps[26994]  = {nm = "战复",     cd = 600}
	SpellMaps[48477]  = SpellMaps[26994]
	SpellMaps[31821]  = {nm = "战复",     cd = 120}
	SpellMaps[64205]  = {nm = "大牺牲",   cd = 120}
	SpellMaps[6940]   = {nm = "牺牲之手", cd = 120}
	SpellMaps[64843]  = {nm = "赞美诗",   cd = 480}
	SpellMaps[64844]  = SpellMaps[64843]
	SpellMaps[47788]  = {nm = "守护之魂", cd = 180}
	SpellMaps[33206]  = {nm = "痛苦压制", cd = 144}
	SpellMaps[1038]   = {nm = "拯救之手", cd = 180}
	SpellMaps[10278]  = {nm = "保护之手", cd = 300, cdx = 180}

	--特殊可以标定
	do
		 --使用道标或者震击 来标记 保护之手的短cd
		local t = {53563, 53651, 53652, 53653, 53654, 48825, 48824}
		for _, v in pairs(t) do
			SpellMarks[v] = 10278
		end
	end
end

local function tabLength(t)
    local len=0
    for k,v in pairs(t) do
        len=len+1
    end
    return len
end

local function createOrUpdateALine(index, name, class, skill, leftSec)
	if debug then print("createOrUpdateALine into "..tostring(skill)) end
	for i = 1, #allLines do
		local line = allLines[i]
		if line.name == name and line.skill == skill then
			line.startTs = GetTime()
			line.leftSec = leftSec

			line.cdText:SetText(SecondsToTime(leftSec))
			line.cdText:SetTextColor(1, 0, 0)
			frame:RegistTimerEvent()
			if debug then print("AaMiscCombat update已经有的line "..tostring(skill)) end
			return
		end
	end

    -- 创建第一个FontText，显示角色名字和颜色
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", POINT_X + 10, POINT_Y - index * 23)
    nameText:SetText(name)
    local color = RAID_CLASS_COLORS[class]
    nameText:SetTextColor(color.r, color.g, color.b)

    -- 创建第二个FontText，显示技能名称
    local skillText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    skillText:SetPoint("LEFT", POINT_X + 100, POINT_Y - index * 23)
    skillText:SetText(skill)

    -- 创建第三个FontText，显示冷却时间
    local cdText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cdText:SetPoint("RIGHT", POINT_X + 225, POINT_Y - index * 23)
    cdText:SetText(SecondsToTime(leftSec))
    cdText:SetTextColor(0.8, 0.1, 0)

	frame:Show()

	allLines[#allLines + 1] = {
		name = name,
		skill = skill,
		nameText = nameText,
		skillText = skillText,
		cdText = cdText,
		startTs = GetTime(),
		leftSec = leftSec,
	}

	frame:RegistTimerEvent()
	if debug then print("AaMiscCombat 新建一条line "..tostring(skill)) end
end

local function timerCallback(self, elapsed)
	self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
	if self.timeSinceLastUpdate > 1 then
		self.timeSinceLastUpdate = 0
		-- 在这里写入你要回调的事件
		frame:WhenTimeChange()
	end
end

local function combatEvent(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName)
	--记录
	local markedSpellId = SpellMarks[spellId]
	if markedSpellId then
		local someonesSpells = SpellMarksMembers[sourceName]
		if someonesSpells == nil then
			SpellMarksMembers[sourceName] = {}
			someonesSpells = SpellMarksMembers[sourceName]
		end
		if someonesSpells[markedSpellId] == nil then
			someonesSpells[markedSpellId] = SpellMaps[markedSpellId].cdx
		end
	end
	--SpellMarks = {["memberName1"]= {"spellId1" = 200, "spellId2" = 300}, ...}

	local spellMap = SpellMaps[spellId]; if not spellMap then return end
	local class = addon.teamTab[sourceName]; if not class then return end

	local cd
	if SpellMarks[sourceName] then
		cd = SpellMarks[sourceName][spellId] or spellMap.cd
	else
		cd = spellMap.cd
	end
	createOrUpdateALine(#allLines, sourceName, class, spellMap.nm, cd)
end

local function updateTeamTab()
	local len = tabLength(addon.teamTab)
	if debug then print("AaMiscCombat 更新team "..tostring(len)) end

	if len > 0 then
		if not isRegistCombatEvent then
			isRegistCombatEvent = true
			if debug then print("AaMiscCombat 注册战斗event") end
			addon:RegistGlobalCombatEvent("raidMembersCd", nil, combatEvent)
		end
	else
		if isRegistCombatEvent then
			isRegistCombatEvent = false
			if debug then print("AaMiscCombat 不再注册战斗event") end
			addon:UnRegistGlobalCombatEvent("raidMembersCd", nil)
		end
	end
end

local function Init()
	if frame then return end
	frame = CreateFrame("Frame", "AaMiscCooldownFrame", UIParent, "BackdropTemplate")
	frame:SetSize(10, 25)
	frame:SetPoint("TOPLEFT", 0, 0)
	frame:SetBackdropColor(0, 0, 0, 0.8)
	frame:SetBackdropBorderColor(1, 1, 1, 0.5)
	frame:Hide()

	addon:registTeamMembersUpdate(function()
		updateTeamTab()
	end)

	function frame:ENCOUNTER_START()
		frame:ForceReset()
	end

	function frame:ENCOUNTER_END()
		frame:ForceReset()
	end

	function frame:RegistTimerEvent()
		if isRegistTimer then return end
		frame:SetScript("OnUpdate", timerCallback)
		isRegistTimer = true
		if debug then print("AaMiscCombat 注册时间信息") end
	end

	function frame:UnRegistTimerEvent()
		if not isRegistTimer then return end
		isRegistTimer = false
		frame:SetScript("OnUpdate", nil)
		if debug then print("AaMiscCombat 取消时间信息") end
	end

	function frame:ForceReset()
		for i = 1, #allLines do
			local line = allLines[i]
			line.cdText:SetTextColor(0, 1, 0)
			line.cdText:SetText("OK")
			line.startTs = 0
			line.leftSec = 0
		end

		frame:UnRegistTimerEvent()
	end

	function frame:WhenTimeChange()
		local t = GetTime()
		local isHasCding = false
		for i = 1, #allLines do
			local line = allLines[i]
			local curLeftSec = line.leftSec - (t - line.startTs)
			if curLeftSec > 0.5 then
				line.cdText:SetTextColor(1, 0, 0)
				line.cdText:SetText(SecondsToTime(curLeftSec))
				isHasCding = true
			else
				line.leftSec = 0
				line.cdText:SetTextColor(0, 1, 0)
				line.cdText:SetText("OK")
			end
		end

		if isHasCding then
			frame:RegistTimerEvent()
		else
			frame:UnRegistTimerEvent()
		end
	end
end

addon:registGlobalEvent(function(event, ...)
	if event == "later" then
		if addon.getCfg("raidAbilityWatcher") then
			Init()
			InitSpellMaps()
			frame:RegisterEvent("ENCOUNTER_START")
			frame:RegisterEvent("ENCOUNTER_END")
			updateTeamTab()
		end

		return true
	end
	return false
end)

addon:registCategoryCreator(function()
	addon:initCategoryCheckBox(3, "监控团队减伤技能*", addon.getCfg("raidAbilityWatcher"), function(cb)
		local c = not addon.getCfg("raidAbilityWatcher")
        addon.setCfg("raidAbilityWatcher", c)
	end)
end)