-- 大脚插件爬的 工会和好友着色
local _, addon = ...

addon.registCategoryCreator(function()
	addon.initCategoryCheckBox("工会和好友职业颜色*", MiscDB.guildAndFreindColorEnable, function(cb)
		MiscDB.guildAndFreindColorEnable = not MiscDB.guildAndFreindColorEnable
	end)
end)

if not MiscDB.guildAndFreindColorEnable then return end

local _G = _G
local myName = UnitName("player")
local myRace = UnitRace("player")
local normal = NORMAL_FONT_COLOR
local green = GREEN_FONT_COLOR
local white = HIGHLIGHT_FONT_COLOR
local defColor = FRIENDS_WOW_NAME_COLOR_CODE

local levelFontSize = MiscDB.guildLevelFontSize

local BC = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do BC[v] = k end

local function colorString(string, class)
	local color = class and RAID_CLASS_COLORS[class] or GetQuestDifficultyColor(tonumber(string) or 1)
	return ("%s%s|r"):format(ConvertRGBtoColorString(color), string)
end

local function guildRankColor(index)
	local r, g, b = 1, 1, 1
	local pct = index / GuildControlGetNumRanks()
	if pct <= 1.0 and pct >= 0.5 then
		r, g, b = (1.0-pct)*2, 1, 0
	elseif pct >= 0 and pct < 0.5 then
		r, g, b = 1, pct*2, 0
	end
	return r, g, b
end

hooksecurefunc("GuildStatus_Update", function()
	local guildOffset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
	local myZone = GetRealZoneText()
	local name, rankIndex, level, zone, online, classFileName
	local color, zcolor, lcolor, r, g, b

	for i=1, GUILDMEMBERS_TO_DISPLAY, 1 do
		name, _, rankIndex, level, _, zone, _, _, online, _, classFileName = GetGuildRosterInfo(guildOffset + i)
		if not name then break end

		color = RAID_CLASS_COLORS[classFileName] or normal
		zcolor = zone == myZone and green or white
		lcolor = GetQuestDifficultyColor(level) or white
		r, g, b = guildRankColor(rankIndex)

		local lvl = _G["GuildFrameButton"..i.."Level"]
		if online then
			_G["GuildFrameButton"..i.."Name"]:SetTextColor(color.r, color.g, color.b)
			_G["GuildFrameButton"..i.."Zone"]:SetTextColor(zcolor.r, zcolor.g, zcolor.b)
			lvl:SetTextColor(lcolor.r, lcolor.g, lcolor.b)
			lvl:SetFont(lvl:GetFont(), 13)
			_G["GuildFrameButton"..i.."Class"]:SetTextColor(color.r, color.g, color.b)
			_G["GuildFrameGuildStatusButton"..i.."Name"]:SetTextColor(color.r, color.g, color.b)
			_G["GuildFrameGuildStatusButton"..i.."Rank"]:SetTextColor(r, g, b)
		else
			_G["GuildFrameButton"..i.."Name"]:SetTextColor(color.r/2, color.g/2, color.b/2)
			_G["GuildFrameButton"..i.."Zone"]:SetTextColor(zcolor.r/2, zcolor.g/2, zcolor.b/2)
			lvl:SetTextColor(lcolor.r/2, lcolor.g/2, lcolor.b/2)
			lvl:SetFont(lvl:GetFont(), 13)
			_G["GuildFrameButton"..i.."Class"]:SetTextColor(color.r/2, color.g/2, color.b/2)
			_G["GuildFrameGuildStatusButton"..i.."Name"]:SetTextColor(color.r/2, color.g/2, color.b/2)
			_G["GuildFrameGuildStatusButton"..i.."Rank"]:SetTextColor(r/2, g/2, b/2)
		end
	end
end)

local function updateFriends(button)
	local nameText,infoText
	if button:IsShown() then
		local myZone = GetRealZoneText()
		-- print(button.index,button.id,button.buttonType)
		if button.buttonType == FRIENDS_BUTTON_TYPE_BNET then	-- 战网
			local _, presenceName, _, _, _, toonID, client, isOnline = BNGetFriendInfo(button.id)
			if isOnline and client == BNET_CLIENT_WOW then
				local _, toonName, _, _, _, _, _, class, _, zoneName, level = BNGetGameAccountInfo(toonID)
				if presenceName and toonName then
					level = colorString(level)
					toonName = colorString(toonName, BC[class])
					nameText = presenceName .. " " .. defColor .. "(Lv" .. level .. " " .. toonName .. defColor .. ")"
				end
				if zoneName and zoneName == myZone then infoText = format("|cff00ff00%s|r", zoneName) end
			end
		elseif button.buttonType == FRIENDS_BUTTON_TYPE_WOW then		-- 游戏好友
			local info = C_FriendList.GetFriendInfoByIndex(button.id)
			if info and info.connected then
				local name = colorString(info.name, BC[info.className])
				local level = colorString(info.level)
				local class = colorString(info.className, BC[info.className])
				nameText = name .. ", Lv" .. level .. "  " .. class
				if info.area and info.area == myZone then infoText = format("|cff00ff00%s|r", info.area) end
			end
		end
	end
	if nameText then button.name:SetText(nameText) end
	if infoText then button.info:SetText(infoText) end
end
hooksecurefunc("FriendsFrame_UpdateFriendButton", updateFriends)

local hookOnceWhoFrame = false

local popAccept, popFrame,popupEditText
local tabInsert = table.insert
local currentNameList = {}
local lastUpdateTime = 0
local function currentNameListToStr()
	local str = ""
	for n, _ in pairs(currentNameList) do
		str = str..n.."\n"
	end
	return str
end

local function ExportATab(str)
    if popFrame == nil then
        popFrame = CreateFrame("Frame", nil, UIParent) -- Recycle the popup frame as an event handler.
        popFrame:SetSize(400, 400)
        popFrame:SetPoint("CENTER", UIParent, "CENTER")
        popFrame:SetFrameStrata("DIALOG")
        popFrame:Hide()

        popupEditText = CreateFrame("EditBox", "exportEditBox", popFrame, "InputBoxTemplate")
        popupEditText:SetPoint("TOPLEFT", 0, 0)
        popupEditText:SetMultiLine(true)
        popupEditText:SetMaxLetters(99999)
        popupEditText:EnableMouse(true)
        popupEditText:SetAutoFocus(false)
        popupEditText:SetWidth(380)
        popupEditText:SetHeight(390)

        local scrollArea = CreateFrame("ScrollFrame", "ECSAboutScroll", popFrame, "UIPanelScrollFrameTemplate")
        scrollArea:SetPoint("TOPLEFT", popFrame, "TOPLEFT", 8, -30)
        scrollArea:SetPoint("BOTTOMRIGHT", popFrame, "BOTTOMRIGHT", -30, 8)
        scrollArea:SetScrollChild(popupEditText)
        popAccept = CreateFrame("Button", nil, popFrame)
        popAccept:SetSize(40, 40)
        popAccept:SetPoint("TOP", popFrame, "TOPRIGHT", -10, 35)

		popAccept = CreateFrame("Button", nil, popFrame)
        popAccept:SetSize(40, 40)
        popAccept:SetPoint("TOP", popFrame, "TOPRIGHT", -10, 35)
		popAccept:SetScript("OnClick",
        function(f)
            popFrame:Hide()
        end)
		popAccept:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		popAccept:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

		local text = popFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("TOPLEFT", check, "TOPRIGHT", 1, 0)
		text:SetPoint("TOPLEFT", popFrame, 0, 0)
		text:SetJustifyH("LEFT")
		text:SetText("捕捉/who名字。快速上下滑动几次，停止3秒，抓全窗口。")
    end
    popupEditText:SetText(str)
    popFrame:Show()
end

hooksecurefunc("WhoList_Update", function()
	if not hookOnceWhoFrame then
		hookOnceWhoFrame = true
		WhoFrame:HookScript("OnShow", function()
			currentNameList = {}
			ExportATab("")
		end)

		WhoFrame:HookScript("OnHide", function()
			currentNameList = {}
			if popFrame then popFrame:Hide() end
		end)
	end

	local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame)
	local menu = UIDropDownMenu_GetSelectedID(WhoFrameDropDown)
	local myZone = GetRealZoneText()
	local myGuild = GetGuildInfo("player")
	local myInfo = { myZone, myGuild, myRace }

	if GetTime() - lastUpdateTime > 3 then
		currentNameList = {}
		lastUpdateTime = GetTime()
	end

	for i = 1, WHOS_TO_DISPLAY, 1 do
		local info = C_FriendList.GetWhoInfo(whoOffset + i)
		if not info then break end
		local guild, level, race, zone, class = info.fullGuildName, info.level, info.raceStr, info.area, info.filename
		local color = class and RAID_CLASS_COLORS[class] or normal
		_G["WhoFrameButton"..i.."Name"]:SetTextColor(color.r, color.g, color.b)
		color = level and GetQuestDifficultyColor(level) or white
		_G["WhoFrameButton"..i.."Level"]:SetTextColor(color.r, color.g, color.b)
		_G["WhoFrameButton"..i.."Level"]:SetFont(_G["WhoFrameButton"..i.."Level"]:GetFont(), 13)
		local columnTable = { zone, guild, race }
		color = columnTable[menu] == myInfo[menu] and green or white
		_G["WhoFrameButton"..i.."Variable"]:SetTextColor(color.r, color.g, color.b)
		
		local n = _G["WhoFrameButton"..i.."Name"]:GetText()
		if currentNameList[n] == nil then
			currentNameList[n] = true
		end
	end

	if popupEditText then
		popupEditText:SetText(currentNameListToStr())
	end
end)

hooksecurefunc("WorldStateScoreFrame_Update", function()
	-- local isArena = IsActiveBattlefieldArena()
	local scrollOffset = FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame)

	for i = 1, 20 do
		local scoreButton = _G["WorldStateScoreButton"..i]
		local name, _, _, _, _, faction, _, _, classToken = GetBattlefieldScore(scrollOffset + i)
		if name and faction and classToken then
			local n, s = strsplit("-", name, 2)
			n = colorString(n, classToken)
			if n == myName then
				n = "> " .. n .. " <"
			end
			if s then
				-- if isArena then
					-- n = n.."|cffffffff - |r"..(faction==0 and "|cff20ff20" or "|cffffd200")..s.."|r"
				-- else
					n = n.."|cffffffff - |r"..(faction==0 and "|cffff2020" or "|cff00aef0")..s.."|r"
				-- end
			end
			scoreButton.name.text:SetText(n)
		end
	end
end)
