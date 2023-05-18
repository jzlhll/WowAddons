--因为WA里面默认自己可以配置冷却倒计时；而OmniCC又会搞进去
local _, addon = ...
if MiscDB.showPriceSortBag == false then return end

local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerItemInfo = GetContainerItemInfo or C_Container.GetContainerItemInfo;

local isSorting = false

local function iterateAll()
	if isSorting then return end
	isSorting = true
	
	local count, price = 0, 0
	local itemLink

	local minPrices = nil
	local curBagId = 0
	local curBagSlot = 1
	local minBagId, minBagSlot

	for BagID = 0, 4 do
		for BagSlot = 1, GetContainerNumSlots(BagID) do
			itemLink = GetContainerItemLink(BagID, BagSlot)
			if itemLink then
				_, _, _, _, _, _, _, _, _, _, price = GetItemInfo(itemLink)
				local cInfo = GetContainerItemInfo(BagID, BagSlot)
				local count = cInfo.stackCount
				local currentPrices = price*count
				if minPrices == nil or minestPrices > currentPrices then
					minPrices = currentPrices
				end
			end
		end
	end

	isSorting = false
end

local function sort()
	addon.startTimer("sortByPrice", function()
		
	end)
end

local f = CreateFrame("Frame")
-- f:RegisterEvent("CHAT_MSG_SYSTEM")

-- f:SetScript("OnEvent", function(self, event, message)
-- 	print("msg:"..message)
-- end)

local receiveMainMsg = function(event, ...)
	if event == "later" then
		print("later in priceSort Bag")
	elseif event == "later2" then
		print("late2 in priceBag")
	end
end

--addon:registGlobalEvent(receiveMainMsg)

-- addon.initAddonCategoryButton("按价格排序背包", "Sort", 80, 40, function()
-- 	iterateAll()
-- end)
