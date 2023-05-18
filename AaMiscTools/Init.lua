------init before anything
local _, addon = ... ; addon = addon or {}
addon.eventframe = CreateFrame('Frame')

local defaultCfg = {
	-- [显示任务装备的一个字名字]
	["showQuestItemSubType"] = true,
	-- [显示任务装备的装等]
	["showQuestItemLevel"] = true,

	-- [工会界面角色等级的数字字体大小控制]
	-- 工会和好友颜色显示
	["guildAndFreindColorEnable"] = true,
	-- 由于某些字体太大导致等级变成".." 这里直接限定。如果你觉得小就自己改大一点。
	["guildLevelFontSize"] = 14,

	-- [和谐界面]
	["noOverride"] = true, -- true表示和谐；false表示就要白皮人绿血
	-- [语言乱码] 
	["noLuanma"] = true, --true表示我不想要乱码；false表示让他乱码去吧
	-- 血条41码最远距离
	["maxDistance"] = true,
	-- 最远视角
	["maxZoom"] = 2.6, --4, 1.8

	-- [按照价格排序背包按钮]
	["showPriceSortBag"] = true,
	--显示珠宝绿色石头的名字，方便找到
	["showBagGreenZhubao"] = true,
	--背包左上角显示装等
	["showBagItemLevel"] = true,
	--显示可交易装备
	["showBagTrade"] = true,

	--[默认加载后，自动隐藏任务栏]
	["autoHideQuestWatchFrame"] = false,
	["observePvpDialog"] = true,

	--扫描AH
	["scanAH"] = true,

	--团队技能
	["raidAbilityWatcher"] = false,

	--combatTime
	["combatTime"] = true,
}

-- 在初始化完成后，检查
function addon.getCfg(name)
	MiscDB = MiscDB or {}
	local c = MiscDB[name]
	if c == nil then
		MiscDB[name] = defaultCfg[name]
		c = defaultCfg[name]
	end

	return c
end

function addon.getCfgWithDefault(name, defValue)
	MiscDB = MiscDB or {}
	local c = MiscDB[name]
	if c == nil then
		c = defaultCfg[name]
		if c == nil then
			MiscDB[name] = defValue
			return defValue
		end
	end

	return c
end

function addon.setCfg(name, value)
	MiscDB = MiscDB or {}
	MiscDB[name] = value
end

----------------------------------------------------
--注册一个函数func，如果func返回true则自动反注册这个函数。
addon.modFuncs = {}

function addon:registGlobalEvent(func)
	if type(func) == "function" then
	    for _,v in pairs(addon.modFuncs) do
			if v == func then return end
   		end

		table.insert(addon.modFuncs, func)
	end
end

function addon:unRegistGlobalEvent(func)
	-- 倒序遍历：在for循环中进行删除的正确遍历方式
	for i = #addon.modFuncs, 1, -1 do
		if addon.modFuncs[i] == func then
			table.remove(addon.modFuncs, i)
		end
	end
end
