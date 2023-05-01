local _, addon = ...
local notifyEvent   = addon.notifyEvent

-----------------init codes---------------
local INIT_ADDON = "init"
local INIT_ADDON_LATER = "later"
local INIT_ADDON_LATER_X2 = "later2"
local INIT_ADDON_CREATE_CATEGORY = "createOpts"

local GetTime = GetTime
local DELAY_TIME, DELAY_TIME_X2 = 4, 8
local lastEnterTime
local isLaterNotified = 0

----------------addon categories-----------------------------
local categoryCurrentY = -10
local categoryStartX = 10

local function categoryFrameInit()
	if addon.categoryFrame then return end
	addon.categoryFrame = CreateFrame("ScrollFrame", nil, UIParent)
	addon.categoryContent = CreateFrame("Frame", nil, addon.categoryFrame)
	addon.categoryContent:SetPoint("TOPLEFT")
	addon.categoryContent:SetPoint("TOPRIGHT")
	addon.categoryContent:SetHeight(800)
	addon.categoryContent:SetWidth(1000)
	addon.categoryFrame:SetScrollChild(addon.categoryContent)
	addon.categoryFrame:Hide()

	local text = addon.categoryContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOPLEFT", check, "TOPRIGHT", 1, 0)
	text:SetPoint("TOPLEFT", addon.categoryContent, categoryStartX, categoryCurrentY)
	text:SetJustifyH("LEFT")
	text:SetText("需要重载界面的配置有*号")
	categoryCurrentY = categoryCurrentY - 50
end

local createCategoryLine = function()
	local f = addon.categoryContent
	local l = f:CreateLine(nil, "BACKGROUND")
	l:SetThickness(2)
	l:SetColorTexture(0.6, 0.5, 0.3, 1.0)
	l:SetStartPoint("BOTTOMLEFT", categoryStartX, categoryCurrentY)
	l:SetEndPoint("BOTTOMLEFT", categoryStartX + 500, categoryCurrentY)
	categoryCurrentY = categoryCurrentY - 5
end

addon.setButtonItemIcon = function(button, itemId)

end

-- 配置一个按钮到category里面
addon.initCategoryButton = function(title, btnText, btnWidth, btnHeight, onClick)
	local f = addon.categoryContent

	local text = f:CreateFontString(nil,"OVERLAY","GameFontWhite")
	text:SetPoint("TOPLEFT", check, "TOPRIGHT", 1, 0)
	text:SetPoint("TOPLEFT", f, categoryStartX, categoryCurrentY)
	text:SetJustifyH("LEFT")
	text:SetText(title)
	categoryCurrentY = categoryCurrentY - 25

	local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    b:SetWidth(btnWidth)
    b:SetHeight(btnHeight)
    b:SetPoint("TOPLEFT", categoryStartX, categoryCurrentY)
    b:SetText(btnText)
    b:SetScript("OnClick", onClick)
	categoryCurrentY = categoryCurrentY - btnHeight - 10

	createCategoryLine()
end

-- 配置一个checkBox里面
-- @param changeCheckFun传入一个函数，改变当前的check；并返回新的check状态
addon.initCategoryCheckBox = function(title, initChecked, changeCheckFun)
    local f = addon.categoryContent

    local checkBox = CreateFrame("CheckButton", nil, f, "OptionsCheckButtonTemplate")
	checkBox:SetPoint("TOPLEFT", categoryStartX, categoryCurrentY)
	categoryCurrentY = categoryCurrentY - 24 - 10
	checkBox:SetSize(24, 24)

	checkBox.msg = checkBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	checkBox.msg:SetPoint("LEFT", 24, 0)
	checkBox.msg:SetText(title)

	checkBox:SetHitRectInsets(0, 0 - checkBox.msg:GetWidth(), 0, 0)
	checkBox:SetChecked(initChecked)
	checkBox:SetScript("OnClick", function(box)
		changeCheckFun(box)
	end)

	createCategoryLine()
end

addon.initCategoryCheckBoxes = function(title, checks)
	local f = addon.categoryContent

	local text = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
	text:SetPoint("TOPLEFT", check, "TOPRIGHT", 1, 0)
	text:SetPoint("TOPLEFT", f, categoryStartX, categoryCurrentY)
	text:SetJustifyH("LEFT")
	text:SetText(title)
	categoryCurrentY = categoryCurrentY - 25
	local curX = categoryStartX
	for i, v in pairs(checks) do 
		local checkBox = CreateFrame("CheckButton", nil, f, "OptionsCheckButtonTemplate")
		checkBox:SetPoint("TOPLEFT", curX, categoryCurrentY)
		checkBox:SetSize(24, 24)
		checkBox.msg = checkBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		checkBox.msg:SetPoint("LEFT", 24, 0)
		checkBox.msg:SetText(v.name)
		checkBox:SetHitRectInsets(0, 0 - checkBox.msg:GetWidth(), 0, 0)
		checkBox:SetChecked(v.checked)
		checkBox:SetScript("OnClick", v.func)
		curX = curX + checkBox.msg:GetWidth() + checkBox:GetWidth() + 10
	end
	
	categoryCurrentY = categoryCurrentY - 24 - 10

	createCategoryLine()
end

local function categoriesUi()
    categoryFrameInit()
    -- 通知module创建ui
    for _, v in pairs(addon.createUiFuncs) do
        v()
	end

    local f = addon.categoryFrame
    f.name = "AaMiscTools"
    InterfaceOptions_AddCategory(f)
end

local function OnTimerUpdate()
    local cur = GetTime()
    if isLaterNotified == 0 and (cur - lastEnterTime) >= DELAY_TIME then
        isLaterNotified = 1
        notifyEvent(INIT_ADDON_LATER)
		return
    end

    if isLaterNotified == 1 and (cur - lastEnterTime) >= DELAY_TIME_X2 then
        isLaterNotified = 2
        categoriesUi()
        notifyEvent(INIT_ADDON_LATER_X2)
        addon.eventframe:SetScript("OnUpdate", nil)
    end
end

function addon.OnEvent(frame, event, ...)
	if event == 'LOADING_SCREEN_DISABLED' then
		lastEnterTime = GetTime()

		notifyEvent(INIT_ADDON)

		addon.eventframe:SetScript("OnUpdate", OnTimerUpdate)
		addon.eventframe:UnregisterEvent("LOADING_SCREEN_DISABLED")
    else
        notifyEvent(event, ...)
    end
end

addon.eventframe:SetScript('OnEvent', addon.OnEvent)
addon.eventframe:RegisterEvent("LOADING_SCREEN_DISABLED")