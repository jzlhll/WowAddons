--因为WA里面默认自己可以配置冷却倒计时；而OmniCC又会搞进去
local _, addon = ...

local showScanBtn
local buttonFrame
local AH = addon.AHCustomScan

local function initButtonFrame()
	if buttonFrame then return end
	local b = CreateFrame("Button", nil, UIParent, "GameMenuButtonTemplate")
	b:SetWidth(110)
	b:SetHeight(38)
	b:SetText("AaMisc扫描")
	b:SetScript("OnClick", function()
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

local receiveMainMsg
receiveMainMsg = function(event, ...)
	if event == "AUCTION_HOUSE_SHOW" then
		initButtonFrame()
		buttonFrame:Show()
		return
	elseif event == "AUCTION_HOUSE_CLOSED" then
		buttonFrame:Hide()
		return
	end

	if event == "later" then
		local show = addon.getCfg("scanAH")
		if show then
			addon.eventframe:RegisterEvent("AUCTION_HOUSE_SHOW")
			addon.eventframe:RegisterEvent("AUCTION_HOUSE_CLOSED")

			AH:Init()
		end
		addon:unRegistGlobalEvent(receiveMainMsg)
	end
end

addon:registGlobalEvent(receiveMainMsg)

addon:registCategoryCreator(function()
	addon:initCategoryCheckBox("扫描AH装绑和附魔材料价格", addon.getCfg("scanAH"), function(cb)
		local c = not addon.getCfg("scanAH")
		showScanBtn = c
		auctionEventAction(c)
		addon.setCfg("scanAH", c)
	end)
end)
