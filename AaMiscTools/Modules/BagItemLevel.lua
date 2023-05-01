
local _B_Enabled = true;

local geterrorhandler = geterrorhandler;
local xpcall = xpcall;
local next = next;
local strlower = string.lower;
local strgmatch = string.gmatch
local GetItemInfoInstant = GetItemInfoInstant;
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo;

local strsub = string.sub

local _M = {  };
local _B = {  };
local _F = CreateFrame('FRAME');

local TradeTab = {}
TradeTab.init = function()
	TradeTab.processedMatcher = string.gsub(BIND_TRADE_TIME_REMAINING,"%%s","(.-)")

	TradeTab.updateItem = function(itemLink)
		

if(DToolTip == nil) then
    local tip = DToolTip or CreateFrame("GAMETOOLTIP", "DToolTip")
    local L = tip:CreateFontString()
    local R = tip:CreateFontString()
    L:SetFontObject(GameFontNormal)
    R:SetFontObject(GameFontNormal)
    tip:AddFontStrings(L,R)
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
end
local processedMatcher = string.gsub(BIND_TRADE_TIME_REMAINING,"%%s","(.-)")
aura_env.lastUpdate = GetTime()
aura_env.lastText = ""
aura_env.EnumBagItems = function()
    local ret = ""
    for bag=0,4 do 
        for slot= 1,50 do
            local bagItemLink = C_Container.GetContainerItemLink(bag,slot)
            if(bagItemLink ~= nil and IsEquippableItem(bagItemLink)) then
                DToolTip:ClearLines()
                DToolTip:SetBagItem(bag,slot)
                for i=1,20 do 
                    local line = _G["DToolTipTextLeft"..i]
                    if(line) then
                        local text = line:GetText()
                        if(text ~= nil) then
                            local showText = string.gmatch(text,processedMatcher)()
                            if(showText ~= nil) then
                                -- check time
                                -- todo: global formatter replace
                                local hours = string.gmatch(showText,"(%w+)小时")()
                                local minutes = string.gmatch(showText,"(%w+)分钟")()
                                if(hours == nil) then 
                                    hours = 0
                                else
                                    hours = tonumber(hours)
                                end
                                if(minutes == nil) then 
                                    minutes = 0
                                else
                                    minutes = tonumber(minutes)
                                end
                                local timeLeft = 60 * hours + minutes
                                local minMinutes = aura_env.config.ignoreMinutes
                                local remindMinutes = aura_env.config.remindMinutes
                                if(minMinutes == 0 or timeLeft < minMinutes) then
                                    if(remindMinutes > 0 and timeLeft < remindMinutes) then
                                        ret = ret..bagItemLink.."|r|cffff0000剩余:"..showText.."|r\n"
                                    else
                                        ret = ret..bagItemLink.."剩余:"..showText.."\n"
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return ret
end
	end
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

local function OnEvent(self, event, addon)
	addon = strlower(addon);
	local method = _M[addon];
	if method ~= nil then
		xpcall(method, geterrorhandler());
		_M[addon] = nil;
		if next(_M) == nil then
			_F:SetScript("OnEvent", nil);
			_F:UnregisterEvent("ADDON_LOADED");
		end
	end
end

local function RegisterAddOnCallback(addon, method)
	if IsAddOnLoaded(addon) then
		xpcall(method, geterrorhandler());
	else
		_M[strlower(addon)] = method;
		_F:RegisterEvent("ADDON_LOADED");
		_F:SetScript("OnEvent", OnEvent);
	end
end

local function CreateItemlevelText(f)
	if f._ItemlevelText == nil then
		f._ItemlevelText = f:CreateFontString(nil, 'OVERLAY');
		f._ItemlevelText:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -1);
		f._ItemlevelText:SetFont(STANDARD_TEXT_FONT, 13, 'OUTLINE');
		_B[f] = 1;
	end
end

local function UpdateItemLevelText(f)
	local itemLink = f:GetItem();
	if itemLink then
		local itemId, _, _, _, _, type = GetItemInfoInstant(itemLink);
        local isTarget = isZhubaoFile(itemId)
        local nameText = nil
        if isTarget then
			local itemNam = GetItemInfo(itemLink)
            nameText = (itemNam and strsub(GetItemInfo(itemLink), 1, 6)) or ""
        end

		if type == 2 or type == 4 then
			local level = GetDetailedItemLevelInfo(itemLink);
			f._ItemlevelText:SetText(level);
		else
			f._ItemlevelText:SetText(nameText);
		end
	else
		f._ItemlevelText:SetText(nil);
	end
end

RegisterAddOnCallback("Bagnon", function()
    hooksecurefunc(Bagnon.Item, "Update", function(self)
		if _B_Enabled then
			CreateItemlevelText(self);
			UpdateItemLevelText(self);
		end
	end);
end);

RegisterAddOnCallback("Combuctor", function()
    hooksecurefunc(Combuctor.Item, "Update", function(self)
		if _B_Enabled then
			CreateItemlevelText(self);
			UpdateItemLevelText(self);
		end
	end);
end);

local function Toggle(enable)
	if enable then
		_B_Enabled = true;
		for b, _ in next, _B do
			UpdateItemLevelText(b);
		end
	else
		_B_Enabled = false;
		for b, _ in next, _B do
			b._ItemlevelText:SetText(nil);
		end
	end
end