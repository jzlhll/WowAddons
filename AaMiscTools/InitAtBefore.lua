------init before anything
local _, addon = ...

addon.modFuncs = {}
addon.createUiFuncs = {}
addon.eventframe = CreateFrame('Frame')

--注册成为一个配置菜单，等到创建菜单的时候，调用你的函数。
function addon:registCategoryCreator(fun)
    table.insert(addon.createUiFuncs, fun)
end

--注册一个函数，如果func返回true则自动反注册这个函数。
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
