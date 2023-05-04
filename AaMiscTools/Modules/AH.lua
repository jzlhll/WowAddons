--因为WA里面默认自己可以配置冷却倒计时；而OmniCC又会搞进去
local _, addon = ...

local buttonFrame
local function initButtonFrame()
	if buttonFrame then return end
	local b = CreateFrame("Button", nil, UIParent, "GameMenuButtonTemplate")
	b:SetWidth(120)
	b:SetHeight(40)
	b:SetText("AaMisc扫描")
	b:SetScript("OnClick", function()
		print("扫描...")
	end)
	b:SetPoint("LEFT", AuctionFrame, "RIGHT", 1, -50)
	buttonFrame = b
end

local receiveMainMsg = function(event, ...)
	if event == "AUCTION_HOUSE_SHOW" then
		initButtonFrame()
		return
	elseif event == "AUCTION_HOUSE_CLOSED" then
		buttonFrame:Hide()
		return
	end

	if event == "later" then
		addon.eventframe:RegisterEvent("AUCTION_HOUSE_SHOW")
		addon.eventframe:RegisterEvent("AUCTION_HOUSE_CLOSED")

		addon.UnregisterEvent(receiveMainMsg)
	end
end

addon:registGlobalEvent(receiveMainMsg)

-- addon.initAddonCategoryButton("按价格排序背包", "Sort", 80, 40, function()
-- 	iterateAll()
-- end)
