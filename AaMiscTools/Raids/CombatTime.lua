local _, addon = ...
local GetTime = GetTime

local CombatFrame
local FONT_SIZE, FRAME_HEIGHT = 21, 30

local function initCombatFrame()
	if CombatFrame then return end
	local cf = CreateFrame("Frame", "AaMiscCombatFrame", UIParent)
	cf:SetWidth(80)
	cf:SetHeight(FRAME_HEIGHT)
	local pos = MiscDB.CombatTimePosition or {
		x = 0,
		y = -8
	}
	cf:SetPoint("TOP", pos.x, pos.y)

	local texture = cf:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints(cf)
	texture:SetAtlas("search-select")

	local text = cf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetFont(NumberFontNormal:GetFont(), FONT_SIZE, "OUTLINE")
	text:SetPoint("TOP", 0, -3)
	text:SetJustifyH("LEFT")
	text:SetText("0.0")
	text:SetTextColor(0, 1, 0)

	cf.numberTextView = text

	addon:SetUiMoveable(cf, nil, function()
		local a, _, b, c, d = CombatFrame:GetPoint()
		MiscDB.CombatTimePosition = {
			x = c,
			y = d
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
			if now - self.lastTs > 0.05 then
				local combat = now - self.startTs
				if combat < 60 then
					self.numberTextView:SetFormattedText("%.1f", combat)
				else
					self.numberTextView:SetFormattedText("%d:%04.1f", combat / 60, combat % 60)
				end
			end
		end)
        CombatFrame.numberTextView:SetTextColor(1, 1, .2, 1)
        --CombatFrame.Anim:Play()
    else
        CombatFrame.startTs = nil
        CombatFrame.numberTextView:SetTextColor(0, 1, 0, 1)
        CombatFrame:SetScript("OnUpdate", nil)
        --CombatFrame.Anim:Stop()
    end
end

local function IsSolo()
    --ENCOUNTER_START 2059, 神后之怒没有END
    return not IsInGroup() or (GetNumGroupMembers() == 1 and not UnitExists("party1") and not UnitExists("raid1"))
end

local function EventLeave(encounter)
    if not CombatFrame.startTs then return end
    if CombatFrame.encounter and not encounter and not IsSolo() then return end
    CombatFrame.encounter = nil

    EventTimerFun(false)
end

local function EventEnter(encounter)
	if encounter then CombatFrame.encounter = true end
	if CombatFrame.startTs then return end

	EventTimerFun(true)
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

			CombatFrame:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_REGEN_DISABLED" or event == "ENCOUNTER_START" then
					EventEnter(event == "ENCOUNTER_START")
				elseif event == "PLAYER_REGEN_ENABLED" or event == "ENCOUNTER_END" then
					EventLeave(event == "ENCOUNTER_END")
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