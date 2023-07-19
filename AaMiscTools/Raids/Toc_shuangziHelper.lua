local _, addon = ...

------------------
local ShownFrame, ShownTextView
local normalTimeText, normalOutText, bossSkillText, leftBossSkillText
local function initCombatFrame()
	if ShownFrame then return end
	local cf = CreateFrame("Frame", "AaMiscCombatShownFrame", UIParent)
	cf:SetWidth(50)
	cf:SetHeight(30) --随便给一下
	local texture = cf:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints(cf)
	texture:SetColorTexture(0.0, 0.0, 0.0, 0.75);

	local text = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetFont(text:GetFont(), 16, "OUTLINE")
	text:SetPoint("TOP", 0, -3)
	text:SetJustifyH("LEFT")
	text:SetText("0.0")
	text:SetTextColor(0.035, 0.91, 0.082)

	ShownTextView = text
	ShownFrame = cf
end
------------------

local function showText()
	ShownTextView:SetText(leftBossSkillText.."\n"..bossSkillText.."\n"..normalTimeText.."\n"..normalOutText)
end

local lightDun = 65858
local darkDunn = 65874
local lightAoe = 66046
local darkAoee = 66058

local lastTime = 0
local isAlreadyKillLightDun = false
local isAlreadyOverDarkAoee = false

local isAlreadyKillDarkDunn = false
local isAlreadyOverLightAoe = false

local mStep = 0

local function resetAllParams()
	mStep = 0
	lastTime = 0
	isAlreadyKillLightDun = false
	isAlreadyOverDarkAoee = false
	isAlreadyKillDarkDunn = false
	isAlreadyOverLightAoe = false

	normalTimeText = ""
	normalOutText = ""
	bossSkillText = ""
	leftBossSkillText = ""
	showText()
end

local combatEvent = function(timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName)
	if     spellId == lightDun then
		isAlreadyKillLightDun = true
		bossSkillText = "开SX，轰方块光明boss！后续大团永远打黑boss骷髅即可！"
		mStep = mStep + 1
	elseif spellId == darkDunn then
		isAlreadyKillDarkDunn = true
		bossSkillText = "正常输出骷髅 黑暗boss即可。"
		mStep = mStep + 1
	elseif spellId == lightAoe then
		isAlreadyOverLightAoe = true
		bossSkillText = "大团不用管，外围>>开技能<<！"
		mStep = mStep + 1
	elseif spellId == darkAoee then
		isAlreadyOverDarkAoee = true
		bossSkillText = "大团开>>保命技能<<，外围无所谓！"
		mStep = mStep + 1
	end

	if mStep == 4 then
		isAlreadyKillLightDun = false
		isAlreadyOverDarkAoee = false
		isAlreadyKillDarkDunn = false
		isAlreadyOverLightAoe = false
	end

	if mStep == 4 then
		leftBossSkillText = ""
	elseif mStep == 1 or mStep == 5 then
		if isAlreadyKillDarkDunn then
			leftBossSkillText = "剩余：白盾 白AOE 黑AOE"
		elseif isAlreadyKillLightDun then
			leftBossSkillText = "剩余：黑盾 白AOE 黑AOE"
		elseif isAlreadyOverDarkAoee then
			leftBossSkillText = "剩余：白盾 黑盾 白AOE"
		else
			leftBossSkillText = "剩余：白盾 黑盾 黑AOE"
		end
	elseif mStep == 2 then
		if isAlreadyKillDarkDunn and isAlreadyKillLightDun then
			leftBossSkillText = "剩余：白AOE 黑AOE"
		elseif isAlreadyKillDarkDunn and isAlreadyOverDarkAoee then
			leftBossSkillText = "剩余：白AOE 白盾"
		elseif isAlreadyKillDarkDunn and isAlreadyOverLightAoe then
			leftBossSkillText = "剩余：白盾 黑AOE"

		elseif isAlreadyKillLightDun and isAlreadyOverDarkAoee then
			leftBossSkillText = "剩余：黑盾 白AOE"
		elseif isAlreadyKillLightDun and isAlreadyOverLightAoe then
			leftBossSkillText = "剩余：黑盾 黑AOE"

		elseif isAlreadyOverLightAoe and isAlreadyOverDarkAoee then
			leftBossSkillText = "剩余：白盾 黑盾"
		end
	elseif mStep == 3 then
		if not isAlreadyKillDarkDunn then
			leftBossSkillText = "剩余：黑盾"
		elseif not isAlreadyKillLightDun then
			leftBossSkillText = "剩余：白盾"
		elseif not isAlreadyOverDarkAoee then
			leftBossSkillText = "剩余：黑AOE"
		else
			leftBossSkillText = "剩余：白AOE"
		end
	end

	normalTimeText = ""
	normalOutText  = ""
	showText()
end

local function c_num(num)
	return string.format("%.2f", num)
end

local onCombatTimerUpdate = function()
	local cur = GetTime()
	local t = cur - lastTime

	if (t >= 40 and t < 45) or (t >= 220 and t < 225) then
		if mStep == 0 or mStep == 4 then
			if mStep == 4 then
				t = t - 180
			end
			normalTimeText = "#1 所有人转方块boss，手里捏好保命。剩"..c_num(45 - t).."秒"
			normalOutText = ""
			showText()
		end
	elseif (t >= 85 and t < 90) or (t >= 265 and t < 270) then
		--马上第二个，只放了一个技能
		if mStep == 1 or mStep == 5 then
			--大团
			if isAlreadyKillLightDun then
				normalTimeText = "#2 大团全程骷髅黑boss，手里捏好保命，剩"..c_num(90 - t).."秒"
			elseif isAlreadyOverDarkAoee then
				normalTimeText = "#2 所有人转方块boss打一会儿，剩"..c_num(90 - t).."秒"
			else
				normalTimeText = "#2 所有人转到方块boss，手里捏好保命。剩"..c_num(90 - t).."秒"
			end

			--外围
			if not isAlreadyOverLightAoe then
				normalOutText = "#2 外围的，手里捏好保命准备着，剩"..c_num(90 - t).."秒"
			else
				normalOutText = ""
			end

			showText()
		end
	elseif t >= 130 and t < 135 then
		--马上第三个，放了2个技能
		if mStep == 2 then
			if isAlreadyKillLightDun and isAlreadyOverDarkAoee then
				normalTimeText = "#3！简单了，正常输出黑boss即可，剩"..c_num(135 - t).."秒"
			elseif isAlreadyKillLightDun then
				normalTimeText = "#3！大团捏好保命，剩"..c_num(135 - t).."秒"
			elseif isAlreadyOverDarkAoee then
				normalTimeText = "#3！提前转到方块boss，剩"..c_num(135 - t).."秒"
			else
				normalTimeText = "#3！所有人转方块boss，手里捏好保命。剩"..c_num(135 - t).."秒"
			end

			--外围
			if not isAlreadyOverLightAoe then
				normalOutText = "外围的，手里捏好保命准备着，剩"..c_num(135 - t).."秒"
			else
				normalOutText = ""
			end

			showText()
		end
	elseif t >= 175 and t < 180 then
		--马上最后一个技能
		if mStep == 3 then
			if not isAlreadyKillDarkDunn then
				normalTimeText = "#4！还剩黑盾直接打就行，剩"..c_num(180 - t).."秒"
			elseif not isAlreadyKillLightDun then
				normalTimeText = "#4！还剩白盾，转过去，直接开SX现在打，剩"..c_num(180 - t).."秒"
			elseif not isAlreadyOverDarkAoee then
				normalTimeText = "#4！大团还剩黑AOE，准备"..c_num(180 - t).."秒后开保命技能"
			else
				normalTimeText = "#4！还剩一个白AOE大团安全，剩"..c_num(180 - t).."秒"
			end

			--外围
			if not isAlreadyOverLightAoe then
				normalOutText = "外围的，捏好保命，剩"..c_num(180 - t).."秒开技能！"
			else
				normalOutText = ""
			end

			showText()
		end
	end
end

local function resetACombat()
	resetAllParams()
	lastTime = GetTime()
	addon:GlobalTimerStart(onCombatTimerUpdate, "Toc_shuangzi_combat")
end

local function closeACombat()
	resetAllParams()
	addon:GlobalTimerStop("Toc_shuangzi_combat")
end

addon:registGlobalEvent(function(event, ...)
	if event == "later" then
		if addon.getCfg("toc_shuangzi_help") then
			addon:RegistGlobalCombatEvent("toc_shuangzi_help", 641, combatEvent)
			addon:RegistGlobalCombatStatusEvent("toc_shuangzi_help", function(status, encounterID)
				if encounterID == 641 then
					if status == "ENTER_COMBAT" then
						initCombatFrame()
						resetACombat()
					elseif status == "LEVEL_COMBAT" then
						closeACombat()
					end
				end
			end)
		end

		return true
	end
	return false
end)

addon:registCategoryCreator(function()
	addon:initCategoryCheckBox(3, "双子不换色打法*", addon.getCfg("toc_shuangzi_help"), function(cb)
		local c = not addon.getCfg("toc_shuangzi_help")
        addon.setCfg("toc_shuangzi_help", c)
	end)
end)
