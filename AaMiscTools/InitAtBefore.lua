------init before anything
local _, addon = ... ; addon = addon or {}
addon.modFuncs = {}
addon.createUiFuncs = {}
addon.eventframe = CreateFrame('Frame')

------------------------------------------------
-------------------------------------------------
------------mod function-------------------
addon.registCategoryCreator = function(fun)
    table.insert(addon.createUiFuncs, fun)
end

--注册一个模块
addon.registLaterInit = function(func)
	if type(func) == "function" then
	    for _,v in pairs(addon.modFuncs) do
			if v == value then return end
   		end

		table.insert(addon.modFuncs, func)
	end
end

-- 注册一个消息，回调则通过notifyInitial的回调函数回调通知。
-- 通知消息，一般为内部使用
addon.notifyEvent = function(event, ...)
    for _, v in pairs(addon.modFuncs) do
        if v then v(event, ...) end
	end
end

-----开始一个计数器
--@param flag通过标记来存储
addon.startTimer = function(flag, onTimeUpdateFunc)
	if addon.timerFrames == nil then addon.timerFrames = {} end
	
	if addon.timerFrames[flag] then
		return
	end

	addon.timerFrames[flag] = CreateFrame('Frame')
	addon.timerFrames[flag]:SetScript("OnUpdate", onTimeUpdateFunc)
end

addon.stopTimer = function(flag)
	if addon.timerFrames == nil then return end
	
	local eventFrame = addon.timerFrames[flag]
	if eventFrame == nil then
		return
	end

	eventFrame:SetScript("OnUpdate", nil)
	addon.timerFrames[flag] = nil
end

MiscDB = {
	------------控制参数 改动后重载界面------
	----数字类型：就修改数字
	----开关类型：开就写true，关就写false

	-- [工会界面角色等级的数字字体大小控制]
	-- 工会和好友颜色显示
	["guildAndFreindColorEnable"] = true,
	-- 由于某些字体太大导致等级变成".." 这里直接限定。如果你觉得小就自己改大一点。
	["guildLevelFontSize"] = 14,

	-- [显示任务装备的一个字名字]
	["showQuestItemSubType"] = false, -- false
	-- [显示任务装备的装等]
	["showQuestItemLevel"] = true, -- false

	-- [和谐界面]
	["hasSkelet"] = true,
	-- true表示我不想要乱码；false表示让他乱码去吧
	["noLuanma"] = true,

	-- 血条41码最远距离. 如果不想设定就在最前面添加--
	["maxDistance"] = true, --"41"
	-- 最远视角
	["maxZoom"] = 2.6, --4, 

	-- [按照价格排序背包按钮]
	["showPriceSortBag"] = true,
	--支持珠宝每日染色需要的物品按钮
	["showZhubaoEveryDay"] = true,
	
	--左上角显示装等
	["showBagItemLevel"] = true,
	---------------------------------------------

	--[默认加载后，自动隐藏任务栏]
	["autoHideQuestWatchFrame"] = true,
	
	["observePvpDialog"] = true,
}