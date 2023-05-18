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
local teamTab = {} -- 存储团队成员的表

local paladinBaohuSpellID1 = 10278
local paladinBaohuTab = {} -- 存储QS保护之手特殊表：结构为{"大川"=180, "玛法了啊"=320}

local spellIdTab = {
	{
		spellID = {26994, 48477}, -- 
		spellName = "战复",
		spellCD = 600
	},
	{
		spellID = {31821}, -- 
		spellName = "光环掌握",
		spellCD = 120
	},
	{
		spellID = {64205},
		spellName = "大牺牲",
		spellCD = 120
	},
	{
		spellID = {64205},
		spellName = "牺牲之手",
		spellCD = 120
	},
	{
		spellID = {64843, 64844}, -- 
		spellName = "赞美诗",
		spellCD = 480
	},
	{
		spellID = {47788},
		spellName = "守护之魂",
		spellCD = 180
	},
	{
		spellID = {33206}, -- 
		spellName = "痛苦压制",
		spellCD = 144
	},
	{
		spellID = {paladinBaohuSpellID1},
		spellName = "保护之手",
		spellCD = 300,
	},
	{
		spellID = {1038},
		spellName = "拯救之手",
		spellCD = 180,
	},
}

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

local function combatEvent(frame, event, ...)
	local _, eventType, _, _, name, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
	if eventType == "SPELL_CAST_SUCCESS" then
		local class = teamTab[name]
		if debug then print("eventType "..tostring(eventType).." spelId "..tostring(spellID)) end
		local is48825 = spellID == 48825
		if class then
			if paladinBaohuTab[name] == nil and is48825 then  --使用了神圣震击48825就代表保护是3分钟；否则就是5分钟
				paladinBaohuTab[name] = 180
			end

			for i = 1, #spellIdTab do
				local item = spellIdTab[i]
				for _, sid in pairs(item.spellID) do
					if spellID == sid then
						if spellID == paladinBaohuSpellID1 then
							createOrUpdateALine(#allLines, name, class, item.spellName, paladinBaohuTab[name] or item.spellCD)
						else
							createOrUpdateALine(#allLines, name, class, item.spellName, item.spellCD)
						end
						return
					end
				end
			end
		end
	end
end

local function updateTeamTab()
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, class = GetRaidRosterInfo(i)
	if name then
            teamTab[name] = class
	end
    end

	local len = tabLength(teamTab)
	if debug then print("AaMiscCombat 更新team "..tostring(len)) end

	if len > 0 then
		if not isRegistCombatEvent then
			isRegistCombatEvent = true
			if debug then print("AaMiscCombat 注册战斗event") end
			frame:SetScript('OnEvent', combatEvent)
			frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	else
		if isRegistCombatEvent then
			isRegistCombatEvent = false
			if debug then print("AaMiscCombat 不再注册战斗event") end
			frame:SetScript('OnEvent', nil)
			frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
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
		
	function frame:GROUP_ROSTER_UPDATE()
		updateTeamTab()
	end

	function frame:ENCOUNTER_START()
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
			frame:RegisterEvent("GROUP_ROSTER_UPDATE")
			frame:RegisterEvent("ENCOUNTER_START") -- 不做监听boss战结束；因为我想看看谁没用技能
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