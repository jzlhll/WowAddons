local _, addon = ...

--代码初始化之前注册: 等合适创建界面的时候，会调用fun来生成界面。
function addon:registCategoryCreator(fun)
	addon.createUiFuncs = addon.createUiFuncs or {}
    table.insert(addon.createUiFuncs, fun)
end

--代码初始化之前注册: 等合适创建界面的时候，会用来生成menu
function addon:registCategoryMenuName(name, index)
	addon.createUiMenuNames = addon.createUiMenuNames or {}
	addon.createUiMenuNames[index] = name
end

----------------addon categories-----------------------------
--- 采用多frame替换假装为多菜单模式。
local categoryContents, menuButtons = {}, {}

local START_X, START_Y, NORMAL_OFF_X         = 20, -78, 35   --每一行的起始位置; 一页的起始位置；一行每个控件之间的x间隔
local NORMAL_OFF_Y, SPLIT_OFF_Y              = 22, 15       --每行之间增加偏移; 分割线的高度
local TOTAL_HEIGHT, MENU_HEIGHT, PAGE_HEIGHT = 800, 50, 750 --高度；菜单高度；一页的高度
local TOTAL_WIDTH                            = 1000         --整个宽度

-- 返回 {frame=, currentY=}
local function GetCategoryContent(index)
    if categoryContents[index] then
        return categoryContents[index]
    end

    categoryContents[index] = {}
    local t = categoryContents[index]
    t.frame = CreateFrame("Frame", nil, addon.categoryContentHost)
    t.currentY = START_Y

    t.frame:SetPoint("TOPLEFT")
	t.frame:SetPoint("TOPRIGHT")
	t.frame:SetHeight(PAGE_HEIGHT)
	t.frame:SetWidth(TOTAL_WIDTH)

	if index == 1 then
		t.frame:Show()
	else
		t.frame:Hide()
	end
    return t
end

local function menuButtonFuncClick(btn)
	local mid = btn.menuId
	for j=1, #categoryContents do
		if mid == j then --本按钮选中并显示对应的frame
			GetCategoryContent(j).frame:Show()
			menuButtons[j]:GetNormalTexture():SetVertexColor(1, 1, 1, .55)
		else 			 --非按钮不选中并隐藏
			GetCategoryContent(j).frame:Hide()
			menuButtons[j]:GetNormalTexture():SetVertexColor(1, 1, 1, .25)
		end
	end
end

local function createMenuBtn(host, isSelected, btnText, width)
	local button = CreateFrame('BUTTON', nil, host);
	button:SetHeight(25)
	button:SetNormalTexture([[Interface\TargetingFrame\UI-StatusBar]])
	button:SetHighlightTexture([[Interface\TargetingFrame\UI-StatusBar]])
	button:GetHighlightTexture():SetVertexColor(1, 1, 1, .25)
	if isSelected then
		button:GetNormalTexture():SetVertexColor(1, 1, 1, .55)
	else
		button:GetNormalTexture():SetVertexColor(1, 1, 1, .25)
	end
	local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetJustifyH("CENTER")
	text:SetPoint("CENTER", 2, 0)
	text:SetTextColor(1.0, 1.0, 1.0, 1.0)
	text:SetText(btnText)

	button:SetWidth(width)

	return button
end

local function onShow()
	if addon.createUiFuncs == nil then return end
	local host = addon.categoryContentHost
	local y = -10
	do
		local text = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("TOPLEFT", START_X, y)
		text:SetJustifyH("LEFT")
		text:SetText("AaMiscTools: 需要重载界面的配置有*号")
	end

	do
		local b = CreateFrame("Button", nil, host, "GameMenuButtonTemplate")
		b:SetWidth(90)
		b:SetHeight(35)
		b:SetPoint("TOPLEFT", START_X + 400, 0)
		b:SetText("重载UI")
		b:SetScript("OnClick", function() ReloadUI() end)
	end

	y = y - 20
	local x = 15

	local menuSize = #addon.createUiMenuNames + 1--要求不为空，即必须已经registCategory MenuName
	
	local endWidth = TOTAL_WIDTH
	local tmpx, btnWidth
	for i=1, menuSize do
		if i == menuSize then
			btnWidth = endWidth
		else
			btnWidth = 85
		end
		tmpx = x + (87 * (i - 1))
		endWidth = endWidth - tmpx

		local button = createMenuBtn(host, (i == 1), addon.createUiMenuNames[i] or "", btnWidth)
		button:SetPoint("TOPLEFT", tmpx, y)
		button:SetScript("OnClick", menuButtonFuncClick)
		button.menuId = i
		menuButtons[i] = button
	end

    -- 通知module创建ui
    for _, v in pairs(addon.createUiFuncs) do
        v()
	end
	addon.createUiFuncs = nil
end

function addon:categoriesUi()
    addon.categoryFrame = CreateFrame("ScrollFrame", nil, UIParent)
    local f = addon.categoryFrame

	addon.categoryContentHost = CreateFrame("Frame", nil, f)
    local host = addon.categoryContentHost
	host:SetPoint("TOPLEFT")
	host:SetPoint("TOPRIGHT")
	host:SetHeight(TOTAL_HEIGHT)
	host:SetWidth(TOTAL_WIDTH)

	f:SetScrollChild(host)
	f:Hide()

	f:SetScript("OnShow", onShow)

    f.name = "AaMiscTools"
    InterfaceOptions_AddCategory(f)
end

----------------------
---调用方：创建一条空行
function addon:createCategoryLine(index)
    local t = GetCategoryContent(index)
	t.currentY = t.currentY - SPLIT_OFF_Y
end

--调用方：创建一行文字
function addon:initCategoryFont(index, title)
    local t = GetCategoryContent(index)
	local f = t.frame

	local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("TOPLEFT", START_X, t.currentY)
	text:SetJustifyH("LEFT")
	text:SetText(title)
	t.currentY = t.currentY - 20
end

-- 调用方：配置一个按钮到category里面
function addon:initCategoryEdit(index, title, words, editWidth, editHeight)
    local t = GetCategoryContent(index)
	local f = t.frame

	if title then
		local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("TOPLEFT", START_X, t.currentY)
		text:SetJustifyH("LEFT")
		text:SetText(title)
		t.currentY = t.currentY - SPLIT_OFF_Y
	end

	-- local editBox = CreateFrame("EditBox", nil, f)
	-- editBox:SetWidth(editWidth)
	-- editBox:SetHeight(editHeight)
	-- editBox:SetPoint("TOPLEFT", START_X, t.currentY)
	-- editBox:SetMultiLine(true)
	-- editBox:SetEnabled(true)
	-- editBox:SetMaxLetters(99999)
	-- editBox:EnableMouse(true)
	-- editBox:SetText("words")

	t.currentY = t.currentY - editHeight - 10
end

-- 调用方：配置一个按钮到category里面
function addon:initCategoryButton(index, title, btnText, btnWidth, btnHeight, onClick)
    local t = GetCategoryContent(index)
	local f = t.frame

	if title then
		local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("TOPLEFT", START_X, t.currentY)
		text:SetJustifyH("LEFT")
		text:SetText(title)
		t.currentY = t.currentY - NORMAL_OFF_Y
	end

	local b = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    b:SetWidth(btnWidth)
    b:SetHeight(btnHeight)
    b:SetPoint("TOPLEFT", START_X, t.currentY)
    b:SetText(btnText)
    b:SetScript("OnClick", onClick)
	t.currentY = t.currentY - btnHeight - 10
end

-- 调用方：配置一个checkBox
-- @param changeCheckFun传入一个函数，改变当前的check；并返回新的check状态
function addon:initCategoryCheckBox(index, title, initChecked, changeCheckFun)
    local t = GetCategoryContent(index)
	local f = t.frame

    local checkBox = CreateFrame("CheckButton", nil, f, "OptionsCheckButtonTemplate")
	checkBox:SetPoint("TOPLEFT", START_X, t.currentY)
	t.currentY = t.currentY - 24 - 10
	checkBox:SetSize(24, 24)

	checkBox.msg = checkBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	checkBox.msg:SetPoint("LEFT", 24, 0)
	checkBox.msg:SetText(title)

	checkBox:SetHitRectInsets(0, 0 - checkBox.msg:GetWidth(), 0, 0)
	checkBox:SetChecked(initChecked)
	checkBox:SetScript("OnClick", function(box)
		changeCheckFun(box)
	end)
end

--调用方：配置一行一组checkbox。
-- local checks = { {name=, checked=, func=}, {name=, checked=, func=}}
--	第4个参数表示是否缩进一个横向偏移
function addon:initCategoryCheckBoxes(index, title, checks, isTabIn)
    local t = GetCategoryContent(index)
	local f = t.frame

	local curX = START_X
	if isTabIn then
		curX = curX + NORMAL_OFF_X
	end

	if title then
		local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("TOPLEFT", START_X, t.currentY)
		text:SetJustifyH("LEFT")
		text:SetText(title)
		t.currentY = t.currentY - NORMAL_OFF_Y
	end

	local checkBoxes = {}
	local checkBoxesCount = 0
	for i, v in pairs(checks) do 
		checkBoxesCount = checkBoxesCount + 1
		local checkBox = CreateFrame("CheckButton", nil, f, "OptionsCheckButtonTemplate")
		checkBox:SetPoint("TOPLEFT", curX, t.currentY)
		checkBox:SetSize(24, 24)
		checkBox.msg = checkBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		checkBox.msg:SetPoint("LEFT", 24, 0)
		checkBox.msg:SetText(v.name)
		checkBox:SetHitRectInsets(0, 0 - checkBox.msg:GetWidth(), 0, 0)
		checkBox:SetChecked(v.checked)
		checkBox:SetScript("OnClick", v.func)
		curX = curX + checkBox.msg:GetWidth() + checkBox:GetWidth() + 10

		checkBoxes[checkBoxesCount] = checkBox
	end
	
	t.currentY = t.currentY - 24 - 10

	return checkBoxes
end