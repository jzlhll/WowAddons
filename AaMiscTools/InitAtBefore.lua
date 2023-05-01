------init before anything
local _, addon = ...

addon.modFuncs = {}
addon.createUiFuncs = {}
addon.eventframe = CreateFrame('Frame')

--注册成为一个配置菜单，等到创建菜单的时候，调用你的函数。
function addon:registCategoryCreator(fun)
    table.insert(addon.createUiFuncs, fun)
end

--注册一个模块
function addon:registGlobalEvent(func)
	if type(func) == "function" then
	    for _,v in pairs(addon.modFuncs) do
			if v == value then return end
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

local key = ""
function addon:printTab(table, level, maxLvl)
	local indent = ""
	for i = 1, level do
	indent = indent.."  "
	end

	if key ~= "" then
	print(indent..key.." ".."=".." ".."{")
	else
	print(indent .. "{")
	end

	key = ""
	for k,v in pairs(table) do
		if type(v) == "table" and level <= maxLvl then
			key = k
			addon:printTab(v, level + 1, maxLvl)
		else
			local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
			print(content)  
		end
	end
	print(indent .. "}")
end
