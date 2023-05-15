--163里面爬的：做任务显示任务装备的金币, 并且我追加了装等显示
local _, addon = ...

--字
local typeTexts = {
    ["INVTYPE_NECK"] = "项",
    ["INVTYPE_BODY"] = "衬",
    ["INVTYPE_FINGER"] = "戒",
    ["INVTYPE_TRINKET"] = "饰",
    ["INVTYPE_CLOAK"] = "披",
    ["INVTYPE_WEAPON"] = "单",
    ["INVTYPE_SHIELD"] = "盾",
    ["INVTYPE_2HWEAPON"] = "双",
    ["INVTYPE_WEAPONMAINHAND"] = "主",
    ["INVTYPE_WEAPONOFFHAND"] = "副",
    ["INVTYPE_HOLDABLE"] = "副",
    ["INVTYPE_RANGED"] = "远",
    ["INVTYPE_THROWN"] = "远",
    ["INVTYPE_RANGEDRIGHT"] = "远",
    ["INVTYPE_RELIC"] = "圣",
}

local CLASS_AMOR_TYPE = {
    ["WARRIOR"]     = '板',
    ["MAGE"]        = '布',
    ["ROGUE"]       = '皮',
    ["DRUID"]       = '皮',
    ["HUNTER"]      = '锁',
    ["SHAMAN"]      = '锁',
    ["PRIEST"]      = '布',
    ["WARLOCK"]     = '布',
    ["PALADIN"]     = '板',
    ["DEATHKNIGHT"] = '板',
}
local player_class = select(2, UnitClass('player'))
------------------------------------------------------------
-- QuestPrice.lua
--
-- Abin
-- 2010/12/10
------------------------------------------------------------
local _G = _G
local GetQuestLogItemLink = GetQuestLogItemLink
local GetQuestItemLink = GetQuestItemLink
local select = select
local GetItemInfo = GetItemInfo
local MoneyFrame_SetType = MoneyFrame_SetType
local MoneyFrame_Update = MoneyFrame_Update
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo
local getCfg = addon.getCfg
local setCfg = addon.setCfg

local function SetLevelText(link, button)
    local showQuestItemLevel = getCfg("showQuestItemLevel")
    if showQuestItemLevel then
        local itemLevel = link and GetDetailedItemLevelInfo(link)
        if itemLevel and itemLevel > 1 then
            button.levelText:SetText(tostring(itemLevel))
        end
    end
end

local function SetTypeText(link, button)
    local subTypeText = button.subTypeText
    local showQuestItemSubType = getCfg("showQuestItemSubType")
    if link then
        local class, subclass, _, slot = select(6, GetItemInfo(link))
        if class=="护甲" and subclass and slot~="INVTYPE_CLOAK" then
            subclass = subclass:sub(1,3)
            if subclass=="布" or subclass=="皮" or subclass=="锁" or subclass=="板" then
                if showQuestItemSubType then subTypeText:SetText(subclass) end
                SetLevelText(link, button)
                if(subclass == CLASS_AMOR_TYPE[player_class]) then
                    subTypeText:SetTextColor(.1,.8,.1)
                else
                    subTypeText:SetTextColor(1, 1, 1)
                end
                return
            end
        end
        if slot and typeTexts[slot] then
            SetLevelText(link, button)
            if showQuestItemSubType then subTypeText:SetText(typeTexts[slot]) end
            subTypeText:SetTextColor(.1,.7,1)
            return
        end
    end
    subTypeText:SetText("")
end

local function QuestPriceFrame_OnUpdate(self)
    local button = self:GetParent()
    button.subTypeText:SetText("")
    self = _G[button:GetName().."QuestPriceFrame"]
    if not button.rewardType or button.rewardType == "item" then
        local func = QuestInfoFrame.questLog and GetQuestLogItemLink or GetQuestItemLink
        local link = func(button.type, button:GetID())
        SetTypeText(link, button)
        local price = link and select(11, GetItemInfo(link))
        if price and price > 0 then
            MoneyFrame_Update(self, price)
            local _, _, _, offsetx, _ = _G[self:GetName().."CopperButtonText"]:GetPoint()
            _G[self:GetName().."GoldButtonText"]:SetPoint("RIGHT", offsetx, 0);
            _G[self:GetName().."SilverButtonText"]:SetPoint("RIGHT", offsetx, 0);
            _G[self:GetName().."CopperButtonText"]:SetPoint("RIGHT", offsetx, 0);
            self:Show()
        else
            self:Hide()
        end
    end
end

local function CreatePriceFrame(name)
    local button = _G[name]
    if button then
        local frame = CreateFrame("Frame", name.."QuestPriceFrame", button, "SmallMoneyFrameTemplate")
        frame:SetPoint("BOTTOMRIGHT", 10, 3)
        frame:Raise()
        frame:SetScale(0.85)
        MoneyFrame_SetType(frame, "STATIC")
        frame.button = button
        local text = _G[button:GetName().."Name"]
        text:SetPoint("LEFT", _G[button:GetName().."NameFrame"], 15, -3);
        text:SetJustifyV("TOP")
        hooksecurefunc(text, "SetText", QuestPriceFrame_OnUpdate)

        local ft = button:CreateFontString()
        ft:SetFont(ChatFontNormal:GetFont(), 12, "OUTLINE")
        ft:SetTextColor(.5,1,.5)
        ft:SetPoint("BOTTOMLEFT", 0, 4)

        local ft2 = button:CreateFontString()
        ft2:SetFont(ChatFontNormal:GetFont(), 14, "OUTLINE")
        ft2:SetTextColor(.2,1,.2)
        ft2:SetPoint("TOPLEFT", 0, 0)

        button.subTypeText = ft
        button.levelText = ft2
    end
end

local function initSelf()
    local showQuestItemSubType = getCfg("showQuestItemSubType")
    local showQuestItemLevel = getCfg("showQuestItemLevel")
    if showQuestItemLevel == false and showQuestItemSubType == false then
        return
    end

    --6.0是后创建的按钮
    hooksecurefunc("QuestInfo_GetRewardButton", function(rewardsFrame, index)
        local rewardButtons = rewardsFrame == QuestInfoRewardsFrame and rewardsFrame.RewardButtons or nil; --or MapQuestInfoRewardsFrame, but we don't create text on those.
        if (rewardButtons and rewardButtons[index] and not rewardButtons[index].subTypeText) then
            CreatePriceFrame(rewardButtons[index]:GetName()) --"QuestInfoRewardsFrameQuestInfoItem"..index
        end
    end)
end

local receiveMainMsg
receiveMainMsg = function(event, ...)
    if event == "later" then
        initSelf()
        return true
    end
    return false
end
addon:registGlobalEvent(receiveMainMsg)

addon:registCategoryCreator(function()
    local checks = {
        {
            name = "显示任务物品类型",
            checked = getCfg("showQuestItemSubType"),
            func = function()
                local c = not getCfg("showQuestItemSubType")
                setCfg("showQuestItemSubType", c)
            end
        },
        {
            name = "显示任务物品等级",
            checked = getCfg("showQuestItemLevel"),
            func = function()
                local c = not getCfg("showQuestItemLevel")
                setCfg("showQuestItemLevel", c)
            end
        }
    }
	addon:initCategoryCheckBoxes(1, nil, checks)
end)