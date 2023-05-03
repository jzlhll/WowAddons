local _, addon = ...
local getCfg = addon.getCfg
local setCfg = addon.setCfg

local GetItemInfoInstant = GetItemInfoInstant;
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo;

local strsub = string.sub

local showBagGreenZhubao, showBagItemLevel, showBagTrade

local BagButtons = addon.BagButtons

local initCfg = function()
    showBagGreenZhubao = getCfg("showBagGreenZhubao")
    showBagItemLevel = getCfg("showBagItemLevel")
    showBagTrade = getCfg("showBagTrade")
end

local ZhubaoList = {
	36917,
    36923,
    36920,
    36926,
    36932,
    36929,
}

local function isZhubaoFile(itemId)
    for _, v in pairs(ZhubaoList) do
        if v == itemId then
            return true
        end
    end
    return false
end

local function CreateExtraText(f)
	if f.miscToolBagExtraText == nil then
		f.miscToolBagExtraText = f:CreateFontString(nil, 'OVERLAY');
		f.miscToolBagExtraText:SetPoint('TOPLEFT', f, 'TOPLEFT', -2, -1);
		f.miscToolBagExtraText:SetFont(STANDARD_TEXT_FONT, 13, 'OUTLINE');
	end
end

local function UpdateExtraText(f)
	local itemLink = f:GetInfo().link --两个插件兼容处理 f:GetItem()
    local text = nil

	if itemLink then
		local itemId, _, _, _, _, type = GetItemInfoInstant(itemLink)
        -- 是珠宝绿色石头
        if showBagGreenZhubao and isZhubaoFile(itemId) then
			local itemNam = GetItemInfo(itemLink)
            local nameText = (itemNam and strsub(GetItemInfo(itemLink), 1, 6)) or ""
            f.miscToolBagExtraText:SetText(nameText)
            return --直接return掉对于这种情况
        end

        -- 显示itemLevel
        if showBagItemLevel then
            if type == 2 or type == 4 then
                text = GetDetailedItemLevelInfo(itemLink)
            end
        end
	end

    f.miscToolBagExtraText:SetVertexColor(1.0, 1.0, 1.0, 1.0)
    f.miscToolBagExtraText:SetText(text)

    if showBagTrade then
        BagButtons:RecordBagList(f)
        BagButtons:ResetTimer()
    end
end

addon:registCategoryCreator(function()
    addon:initCategoryFont("支持Combuctor和Bagnon相关的背包显示")

	addon:initCategoryCheckBox("显示绿色珠宝石头名字*", getCfg("showBagGreenZhubao"), function(cb)
		local c = not getCfg("showBagGreenZhubao")
        setCfg("showBagGreenZhubao", c)
	end)

    addon:initCategoryCheckBox("显示左上角装备等级*", getCfg("showBagItemLevel"), function(cb)
		local c = not getCfg("showBagItemLevel")
        setCfg("showBagItemLevel", c)
	end)

    addon:initCategoryCheckBox("显示可交易物品*", getCfg("showBagTrade"), function(cb)
		local c = not getCfg("showBagTrade")
        setCfg("showBagTrade", c)
	end)
end)

local receiveMainMsg = function(event, ...)
    if event == "later2" then
        initCfg()

        if showBagTrade then
            BagButtons:Init()
        end

        if showBagGreenZhubao or showBagItemLevel or showBagTrade then
            if IsAddOnLoaded("Bagnon") then
                hooksecurefunc(Bagnon.Item, "Update", function(self)
                    CreateExtraText(self)
                    UpdateExtraText(self)
                end)
            end
 
            if IsAddOnLoaded("Combuctor") then
                hooksecurefunc(Combuctor.Item, "Update", function(self)
                    CreateExtraText(self)
                    UpdateExtraText(self)
                end);
            end
        end

        addon:unRegistGlobalEvent(receiveMainMsg)
    end
end
addon:registGlobalEvent(receiveMainMsg)