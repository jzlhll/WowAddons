------背包可以交易按钮

local _, addon = ...
addon.BagButtonCanTrade = {}
local TD = addon.BagButtonCanTrade

local strgmatch, strsub = string.gmatch, string.sub
local GetItemInfoInstant,GetDetailedItemLevelInfo = GetItemInfoInstant, GetDetailedItemLevelInfo
local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots

function TD:Init()
    if addon.getCfg("showBagTrade") then
        if IsAddOnLoaded("Bagnon") then
            self:initDTooltip()
            self:initBagnon()
        end

        if IsAddOnLoaded("Combuctor") then
            self:initDTooltip()
            self:initCombuctor()
        end
    end
end

function TD:timeMatch(showText)
    --中文
    local hours = strgmatch(showText,"(%w+)小时")()  or "0"
    local minutes = strgmatch(showText,"(%w+)分钟")() or "0"
    return hours, minutes
end

function TD:initDTooltip()
    self.tip = CreateFrame("GAMETOOLTIP", "AaMiscToolTip", nil, "GameTooltipTemplate")
    local L = self.tip:CreateFontString()
    local R = self.tip:CreateFontString()
    L:SetFontObject(GameFontNormal)
    R:SetFontObject(GameFontNormal)
    self.tip:AddFontStrings(L,R)
    self.tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    self.processedMatcher = string.gsub(BIND_TRADE_TIME_REMAINING,"%%s","(.-)")
end

function TD:checkAnItem(itemLink, bag, slot)
    self.tip:ClearLines()
    self.tip:SetBagItem(bag, slot)
    for i = 20, 1, -1 do
        local line = _G["AaMiscToolTipTextLeft"..i]
        if line then
            local text = line:GetText()
            if text then
                local showText = strgmatch(text, self.processedMatcher)()
                if showText then
                    -- check time
                    -- todo: global formatter replace
                    local hours, minutes = TD:timeMatch(showText)
                    return "剩余"..hours..":"..minutes
                end
            end
        end
    end

    return nil
end

function TD:CheckAllBags()
    --addon:printTab(Bagnon, 1, 1)
    --addon:printAllHasLevelItems()
    local canTradeWords
    local f, fontStr, lvl
    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(bag)
        for slot = 1, slots do
            local link = GetContainerItemLink(bag, slot)
            if (link ~= nil and IsEquippableItem(link)) then
                canTradeWords = self:checkAnItem(link, bag, slot)
                if canTradeWords then
                    f = addon.allHasLevelItems[bag][slot]
                    fontStr = f.miscToolBagExtraText
                    if fontStr then
                        lvl = GetDetailedItemLevelInfo(link)
                        fontStr:SetFont(STANDARD_TEXT_FONT, 11, 'OUTLINE')
                        fontStr:SetText(lvl.."\n"..canTradeWords)
                    end
                end
            end
        end
    end
end

function TD:initBagnon()
    self.bagnonListMenuButtons = Bagnon.Frame.ListMenuButtons
    self.bagnonMenuBtns = {}

    self.bagnonCreateButtonFunc = function(frame, isBank)
        local button = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
        button:SetText("可易")
        button:SetScript("OnClick", function(self)
            TD:CheckAllBags()
        end)
        button:SetWidth(36)
        button:SetHeight(22)
        TD.bagnonMenuBtns[frame] = button
        return TD.bagnonMenuBtns[frame]
    end

    print("TD initBagnon self: "..tostring(self))
    function Bagnon.Frame:ListMenuButtons()
        print("bagnon listMenuButtons self: "..tostring(self))
        TD.bagnonListMenuButtons(self)
        local frameId = self:GetFrameID()
        if frameId == 'inventory' or frameId == 'bank' then
            tinsert(TD.menuButtons, TD.bagnonMenuBtns[self] or TD.bagnonCreateButtonFunc(self, frameId == 'bank'))
        end
    end

    hooksecurefunc(Bagnon.Frame, "Layout", function(self)
        print("Layout")
        TD:ResetCheckAllBagsTimer(true)
    end)
end

function TD:initCombuctor()
    self.combuctorFrameNew = Combuctor.Frame.New

    function Combuctor.Frame:New(...)
        local f = self.combuctorFrameNew(self, ...)

        local button = CreateFrame('Button', nil, f, 'CombuctorBagToggleTemplate')
        button:SetText("可易")
        button:SetScript("OnClick", function(self)
            TD:CheckAllBags()
        end)

        button:SetPoint('RIGHT', f.bagToggle, 'LEFT', 200, 0)

        return f
    end
end

local function CheckAllBagsUpdateTicker()
    TD:CancelCheckAllbagsTimer()

    TD:CheckAllBags()
end

function TD:ResetCheckAllBagsTimer(imditely)
    TD:CancelCheckAllbagsTimer()

    if imditely and addon.isHasUpdateExtraText then
        TD:CheckAllBags()
    end

    self.checkAllBagsTicker = C_Timer.NewTicker(3, CheckAllBagsUpdateTicker)
end

function TD:CancelCheckAllbagsTimer()
    if self.checkAllBagsTicker then
        self.checkAllBagsTicker:Cancel()
        self.checkAllBagsTicker = nil
    end
end