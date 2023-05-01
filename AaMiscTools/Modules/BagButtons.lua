local _, addon = ...
local getCfg = addon.getCfg
local setCfg = addon.setCfg

local strgmatch = string.gmatch
local GetItemInfoInstant = GetItemInfoInstant;
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo;
local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots

local strsub = string.sub

local showBagTrade, showBagItemLevel

local function initCfg()
    showBagTrade = getCfg("showBagTrade")
    showBagItemLevel = getCfg("showBagItemLevel")
end

local tip, processedMatcher, allTradeEquipsList

local initDTooltip = function()
    tip = CreateFrame("GAMETOOLTIP", "AaMiscToolTip", nil, "GameTooltipTemplate")
    local L = tip:CreateFontString()
    local R = tip:CreateFontString()
    L:SetFontObject(GameFontNormal)
    R:SetFontObject(GameFontNormal)
    tip:AddFontStrings(L,R)
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    processedMatcher = string.gsub(BIND_TRADE_TIME_REMAINING,"%%s","(.-)")
    
    allTradeEquipsList = {}
end

--更新一件装备可交易
local updateCanTradeEquip = function(itemId, bagId, slotId)
    allTradeEquipsList[itemId] = {
    }
end

--到期一件装备
local removeCanTradeEquip = function(itemId)
    allTradeEquipsList[itemId] = nil
end

local checkAnItem = function(itemLink, bag, slot)
    tip:ClearLines()
    tip:SetBagItem(bag, slot)
    for i = 20, 1, -1 do
        local line = _G["AaMiscToolTipTextLeft"..i]
        if line then
            local text = line:GetText()
            if text then
                local showText = strgmatch(text, processedMatcher)()
                if showText then
                    -- check time
                    -- todo: global formatter replace
                    local hours = strgmatch(showText,"(%w+)小时")()  or "0"
                    local minutes = strgmatch(showText,"(%w+)分钟")() or "0"

                    return "易"..hours..":"..minutes
                end
            end
        end
    end

    return nil
end

local checkAllBags = function()
    --addon:printTab(Bagnon, 1, 1)
    --addon:printAllHasLevelItems()
    local canTradeWords
    local f, fontStr, lvl
    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(bag)
        for slot = 1, slots do
            local link = GetContainerItemLink(bag, slot)
            if (link ~= nil and IsEquippableItem(link)) then
                canTradeWords = checkAnItem(link, bag, slot)
                --print("canTradeWords "..tostring(canTradeWords).." bag "..bag.." slot "..slot)
                if canTradeWords then
                    f = addon.allHasLevelItems[bag][slot]
                    fontStr = f.miscToolBagExtraText
                    if fontStr then
                        lvl = GetDetailedItemLevelInfo(link)
                        fontStr:SetText(lvl.."\n"..canTradeWords)
                    end
                end
            end
        end
    end
end

addon:registCategoryCreator(function()
    addon:initCategoryCheckBox("显示可交易物品*", getCfg("showBagTrade"), function(cb)
		local c = not getCfg("showBagTrade")
        setCfg("showBagTrade", c)
	end)
end)

local bagnonListMenuButtons
local bagnonMenuBtns
local bagnonCreateButtonFunc

local initBagnon = function()
    bagnonListMenuButtons = Bagnon.Frame.ListMenuButtons
    bagnonMenuBtns = {}
    bagnonCreateButtonFunc = function(frame, isBank)
        local button = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
        button:SetText("可易")
        button:SetScript("OnClick", function(self)
            checkAllBags()
        end)
        button:SetWidth(36)
        button:SetHeight(22)
        bagnonMenuBtns[frame] = button
        return bagnonMenuBtns[frame]
    end

    function Bagnon.Frame:ListMenuButtons()
        bagnonListMenuButtons(self)
        local frameId = self:GetFrameID()
        if frameId == 'inventory' or frameId == 'bank' then
            tinsert(self.menuButtons, bagnonMenuBtns[self] or bagnonCreateButtonFunc(self, frameId == 'bank'))
        end
    end
end

local combuctorFrameNew
local initCombuctor = function()
    combuctorFrameNew = Combuctor.Frame.New

    function Combuctor.Frame:New(...)
        local f = combuctorFrameNew(self, ...)

        local button = CreateFrame('Button', nil, f, 'CombuctorBagToggleTemplate')
        button:SetText("可易")
        button:SetScript("OnClick", function(self)
            checkAllBags()
        end)

        button:SetPoint('RIGHT', f.bagToggle, 'LEFT', 200, 0)

        return f
    end
end

local receiveMainMsg = function(event, ...)
    if event == "later2" then
        initCfg()

        if showBagTrade then
            if IsAddOnLoaded("Bagnon") then
                initDTooltip()
                initBagnon()
            end

            if IsAddOnLoaded("Combuctor") then
                initDTooltip()
                initCombuctor()
            end
        end

        addon:unRegistGlobalEvent(receiveMainMsg)
    end
end

addon:registGlobalEvent(receiveMainMsg)