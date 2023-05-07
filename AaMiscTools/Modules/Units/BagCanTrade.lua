-----当打开背包的时候，自动计算当前剩余时间，todo 更好的实时更新没有实现，缺乏知道bag关闭的事件。

local _, addon = ...

local strsub, strgmatch        = string.sub, string.gmatch
local GetItemInfoInstant       = GetItemInfoInstant;
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo;
local GetContainerItemLink     = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerNumSlots     = GetContainerNumSlots or C_Container.GetContainerNumSlots

addon.BagCanTrade = {}
local TD = addon.BagCanTrade 

local function timeMatch(showText)
    --中文
    local hours = strgmatch(showText,"(%w+)小时")()  or "0"
    local minutes = strgmatch(showText,"(%w+)分钟")() or "0"
    
    return tonumber(hours), tonumber(minutes)
end

local initDTooltip = function()
    TD.tip = CreateFrame("GAMETOOLTIP", "AaMiscToolTip", nil, "GameTooltipTemplate")
    local tip = TD.tip
    local L = tip:CreateFontString()
    local R = tip:CreateFontString()
    L:SetFontObject(GameFontNormal)
    R:SetFontObject(GameFontNormal)
    tip:AddFontStrings(L, R)
    tip:SetScript("OnTooltipAddMoney", nil) --直接移除， 可以解决一个报错问题
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    tip.processedMatcher = string.gsub(BIND_TRADE_TIME_REMAINING,"%%s","(.-)")
end

local checkAnItem = function(itemLink, bag, slot)
    local tip = TD.tip
    tip:ClearLines()
    tip:SetBagItem(bag, slot)
    local text, showText
    for i=1, 26 do
        text = addon.GetTooltipLeftTextFuncs[i]()
        if text then
            if text == "装备后绑定" then
                return "装绑"
            end

            showText = strgmatch(text, tip.processedMatcher)()
            if showText then
                -- check time
                -- todo: global formatter replace
                local hours, minutes = timeMatch(showText)
                if hours == 0 then
                    return minutes.."分"
                else
                    return hours * 60 + minutes.."分"
                end
            end
        end
    end

    return nil
end

-- 背包是0-4，银行是-1，然后5,6,7,8，9,10,11
function TD:printAllHasLevelItems()
    local count = 0
    for _,v in pairs(addon.allBagSlotsItems) do
        for _, v2 in pairs (v) do
            if v2 then count = count + 1 end
        end
    end
    print("count="..count)
end

function TD:RecordBagList(f)
    local slot = f:GetID()
    local bag = f.bag
    -- 保存所有装备。
    --local isBank = Bagnon.IsBank(bag)
    -- -1,5,6,7,8,9,10,11都是银行。所以与背包0-4不冲突。
    addon.allBagSlotsItems[bag] = addon.allBagSlotsItems[bag] or {}
    addon.allBagSlotsItems[bag][slot] = f

    addon.isHasUpdateExtraText = true
end

function TD:CheckAllBags()
    if not addon.isHasUpdateExtraText then return end
    --addon:printTab(Bagnon, 1, 1)
    --self:printAllHasLevelItems()
    local canTradeWords
    local f, fontStr, lvl, link, bags, slots
    for bag = 0, NUM_BAG_SLOTS do
        slots = GetContainerNumSlots(bag)
        for slot = 1, slots do
            link = GetContainerItemLink(bag, slot)
            if link then
                canTradeWords = checkAnItem(link, bag, slot)
                if canTradeWords then
                    bags = addon.allBagSlotsItems[bag]
                    if bags then
                        f = bags[slot]
                        if f then
                            fontStr = f.miscToolBagExtraText
                            if fontStr then
                                lvl = GetDetailedItemLevelInfo(link)
                                fontStr:SetVertexColor(1.0, 0.1, 0.55, 1.0)
                                fontStr:SetText(lvl.."\n"..canTradeWords)
                            end
                        end
                    end
                end
            end
        end
    end
end

local initBagnon = function()
    -- TD.bagnonListMenuButtons = Bagnon.Frame.ListMenuButtons
    -- TD.bagnonFrameLayout     = Bagnon.Frame.Layout
    -- TD.bagnonMenuBtns = {}
    -- TD.bagnonCreateButtonFunc = function(frame, isBank)
    --     local button = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    --     button:SetText("可易")
    --     button:SetScript("OnClick", function(self)
    --         TD:CheckAllBags()
    --     end)
    --     button:SetWidth(36)
    --     button:SetHeight(22)
    --     TD.bagnonMenuBtns[frame] = button
    --     return TD.bagnonMenuBtns[frame]
    -- end

    -- function Bagnon.Frame:ListMenuButtons()
    --     TD.bagnonListMenuButtons(self)
    --     local frameId = self:GetFrameID()
    --     if frameId == 'inventory' or frameId == 'bank' then
    --         tinsert(self.menuButtons, TD.bagnonMenuBtns[self] or TD.bagnonCreateButtonFunc(self, frameId == 'bank'))
    --     end
    -- end
    -- todo 对比来看，每次一打开就自动Update，不需要hook这里
    -- function Bagnon.Frame:Layout()
    --     print("layout...")
    --     TD.bagnonFrameLayout(self)
    --     TD:ResetTimer(true)
    -- end
end

local initCombuctor = function()
    -- TD.combuctorFrameNew = Combuctor.Frame.New

    -- function Combuctor.Frame:New(...)
    --     local f = TD.combuctorFrameNew(self, ...)

    --     local button = CreateFrame('Button', nil, f, 'UIPanelButtonTemplate')
    --     button:SetText("可易")
    --     button:SetScript("OnClick", function(self)
    --         TD:CheckAllBags()
    --     end)

    --     button:SetPoint('RIGHT', f.bagToggle, 'LEFT', 70, 0)
    --     return f
    -- end

    -- todo 对比来看，每次一打开就自动Update，不需要hook这里
    -- function Combuctor.Frame:Layout()
    --     print("layout...")
    --     TD.bagnonFrameLayout(self)
    --     TD:ResetTimer(true)
    -- end
end

function TD:Init()
    addon.allBagSlotsItems = {}

    if IsAddOnLoaded("Bagnon") then
        initDTooltip()
        initBagnon()
    end

    if IsAddOnLoaded("Combuctor") then
        initDTooltip()
        initCombuctor()
    end
end
 
local function OnTimerUpdate()
    local cur = GetTime()
    if cur - TD.updateResetTime >= 0.15 then
        TD:CheckAllBags()
        TD:CancelTimer()
    end
end

function TD:ResetTimer(imditely)
    TD:CancelTimer()

    if imditely and addon.isHasUpdateExtraText then
        TD:CheckAllBags()
    end

    if self.timerTickFrame == nil then
        self.timerTickFrame = CreateFrame("Frame")
    end
    --print("set timer")
    self.timerTickFrame:SetScript("OnUpdate", OnTimerUpdate)
end

function TD:CancelTimer()
    self.updateResetTime = GetTime()

    if self.timerTickFrame then
        self.timerTickFrame:SetScript("OnUpdate", nil)
        --print("cancel it")
    end
end