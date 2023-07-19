local _, addon = ...
local GetTime = GetTime

local CombatFrame
local FONT_SIZE, FRAME_HEIGHT = 21, 28

local function initCombatFrame()
	if CombatFrame then return end
	local cf = CreateFrame("Frame", "AaMiscCombatFrame", UIParent)
	cf:SetWidth(80)
	cf:SetHeight(FRAME_HEIGHT)
	if MiscDB.CombatTimePosition2 then
		local p = MiscDB.CombatTimePosition2
		cf:SetPoint(p.a, UIParent, p.b, p.c, p.d)
	else
		cf:SetPoint("TOP", 0, -8)
	end

	local texture = cf:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints(cf)
	texture:SetAtlas("search-select")

	local text = cf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetFont(text:GetFont(), FONT_SIZE, "OUTLINE")
	text:SetPoint("TOP", 0, -3)
	text:SetJustifyH("LEFT")
	text:SetText("0.0")
	text:SetTextColor(0.035, 0.91, 0.082)

	cf.numberTextView = text

	addon:SetUiMoveable(cf, nil, function()
		local a, _, b, c, d = CombatFrame:GetPoint()
		MiscDB.CombatTimePosition2 = {
			a = a,
			b = b,
			c = c,
			d = d
		}
	end)
	CombatFrame = cf
end

local function EventTimerFun(start)
    if start then
        CombatFrame.startTs = GetTime()
        CombatFrame.lastTs = 0
        CombatFrame:SetScript("OnUpdate", function(self)
			local now = GetTime()
			if now - self.lastTs > 0.07 then
				local combat = now - self.startTs
				if combat < 60 then
					self.numberTextView:SetFormattedText("%.1f", combat)
				else
					self.numberTextView:SetFormattedText("%d:%04.1f", combat / 60, combat % 60)
				end
			end
		end)
        CombatFrame.numberTextView:SetTextColor(1, 1, .2)
        --CombatFrame.Anim:Play()
    else
        CombatFrame.startTs = nil
        CombatFrame.numberTextView:SetTextColor(0.035, 0.92, 0.082)
        CombatFrame:SetScript("OnUpdate", nil)
        --CombatFrame.Anim:Stop()
    end
end

local function IsSolo()
    --ENCOUNTER_START 2059, 神后之怒没有END
    return not IsInGroup() or (GetNumGroupMembers() == 1 and not UnitExists("party1") and not UnitExists("raid1"))
end

local function EventLeave(encounter, success)
	if success then
		if not CombatFrame.startTs then return end
		if CombatFrame.encounter and not encounter and not IsSolo() then return end
		CombatFrame.encounter = nil
		CombatFrame.reAliveTime = nil
		CombatFrame.deadCount = nil
		EventTimerFun(false)
	end
end

local function EventEnter(encounter)
	if encounter then CombatFrame.encounter = true end
	if CombatFrame.startTs then return end

	EventTimerFun(true)
end

local function EventReAlive()
	if CombatFrame.deadCount then
		CombatFrame.deadCount = CombatFrame.deadCount + 1
		if CombatFrame.deadCount == 1 then
			CombatFrame.reAliveTime = GetTime()
		elseif CombatFrame.deadCount == 2 then
			if GetTime() - CombatFrame.reAliveTime < 0.5 then
				CombatFrame.numberTextView:SetTextColor(1, 1, .2)
			end

			CombatFrame.reAliveTime = nil
			CombatFrame.deadCount = nil
		end
	end
end

local function Init(enable)
	if enable then
		initCombatFrame()
		if not CombatFrame.isRegistCombatEvents then
			CombatFrame.isRegistCombatEvents = true

			CombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
			CombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
			CombatFrame:RegisterEvent("ENCOUNTER_START")
			CombatFrame:RegisterEvent("ENCOUNTER_END")
			CombatFrame:RegisterEvent("PLAYER_DEAD")
			CombatFrame:RegisterEvent("PLAYER_ALIVE")

			CombatFrame:SetScript("OnEvent", function(self, event, encounterID,_,_,_,success)
				if event == "PLAYER_REGEN_DISABLED" or event == "ENCOUNTER_START" then
					if CombatFrame.startTs ~= nil then
						EventReAlive()
					else
						EventEnter(event == "ENCOUNTER_START")
					end
				elseif event == "PLAYER_REGEN_ENABLED" then
					EventLeave(false, true)
				elseif event == "ENCOUNTER_END" then
					EventLeave(true, success)
				elseif event == "PLAYER_DEAD" then
					if CombatFrame.startTs then
						CombatFrame.numberTextView:SetTextColor(1, 0.2, 0)
						CombatFrame.deadCount = 0
					end
				elseif event == "PLAYER_ALIVE" then
					if CombatFrame.startTs ~= nil then
						EventReAlive()
					end
				end
			end)
		end
		CombatFrame:Show()
	elseif CombatFrame then
		CombatFrame:Hide()
		CombatFrame:SetScript("OnEvent", nil)
	end
end

addon:registGlobalEvent(function(event, ...)
	if event == "later" then
		if addon.getCfg("combatTime") then
			Init(true)
		end
		return true
	end
	return false
end)

addon:registCategoryCreator(function()
	addon:initCategoryCheckBox(3, "战斗计时", addon.getCfg("combatTime"), function(cb)
		local c = not addon.getCfg("combatTime")
        addon.setCfg("combatTime", c)
		Init(c)
	end)
end)