--因为WA里面默认自己可以配置冷却倒计时；而OmniCC又会搞进去
local _, addon = ...

local buttonFrame
local AH = addon.AHCustomScan

local function initButtonFrame()
	if buttonFrame then return end
	local b = CreateFrame("Button", nil, UIParent, "GameMenuButtonTemplate")
	b:SetWidth(110)
	b:SetHeight(38)
	b:SetText("AaMisc扫描")
	b:SetScript("OnClick", function()
		AH:Init()
		AH:StartScan(true)
	end)
	b:SetPoint("LEFT", AuctionFrame, "BOTTOMRIGHT", -111, -7)
	buttonFrame = b
end

local function auctionEventAction(init)
	if init then
		addon.eventframe:RegisterEvent("AUCTION_HOUSE_SHOW")
		addon.eventframe:RegisterEvent("AUCTION_HOUSE_CLOSED")
	else
		addon.eventframe:UnregisterEvent("AUCTION_HOUSE_SHOW")
		addon.eventframe:UnregisterEvent("AUCTION_HOUSE_CLOSED")
		if buttonFrame then buttonFrame:Hide() end
	end
end

addon:registGlobalEvent(function(event, ...)
	if event == "AUCTION_HOUSE_SHOW" then
		initButtonFrame()
		buttonFrame:Show()
	elseif event == "AUCTION_HOUSE_CLOSED" then
		AH:EndScan(false)
		buttonFrame:Hide()
	elseif event == "later" then
		local show = addon.getCfg("scanAH")
		if show then
			addon.eventframe:RegisterEvent("AUCTION_HOUSE_SHOW")
			addon.eventframe:RegisterEvent("AUCTION_HOUSE_CLOSED")
		end
	elseif event == "later3" then
		AH.initHookTooltip()
	end
end)

local function ReadText()
	local AH = addon.AHCustomScan
	local r = ""
	for _, v in pairs(AH.Constants.ScanList) do
		r = r..v.."\n"
	end
	return r
end

addon:registCategoryCreator(function()
	addon:initCategoryCheckBox(2, "扫描AH装绑和附魔材料价格", addon.getCfg("scanAH"), function(cb)
		local c = not addon.getCfg("scanAH")
		auctionEventAction(c)
		addon.setCfg("scanAH", c)
	end)

	addon:initCategoryEdit(2, "扫描列表", ReadText(), 500, 500)
end)