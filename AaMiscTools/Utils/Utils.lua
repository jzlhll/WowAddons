
------init before anything
local _, addon = ... ; addon = addon or {}

function addon:tabContains(tab, item)
	for _, v in pairs(tab) do
		if v == item then return true end
	end
	return false
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

local aline
local function printInner(table, level, maxLvl)
	local indent = ""
	for i = 1, level do
		indent = indent.."  "
	end

	if key ~= "" then
		aline = aline..(indent..key.." ".."=".." ".."{")
	else
		aline = aline..(indent .. "{")
	end

	key = ""
	for k,v in pairs(table) do
		if type(v) == "table" and level <= maxLvl then
			key = k
			addon:printTab(v, level + 1, maxLvl)
		else
			local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
			aline = aline..(content)  
		end
	end
	aline = aline..(indent .. "}")
end

function addon:printTabInALine(table, level, maxLvl)
	aline = ""
	printInner(table, level, maxLvl)
	print(aline)
end

local function _quickSort(sortList, left, right)
	if left > right then
		return
	end

	local i = left
	local j = right
	local guard = sortList[left]
	while i ~= j do
		while sortList[j] >= guard and i < j do
			j = j - 1
		end

		while sortList[i] <= guard and i < j do
			i = i + 1
		end

		if i < j then
			sortList[i], sortList[j] = sortList[j], sortList[i]
		end
 	end

	sortList[left], sortList[i] = sortList[i], sortList[left]
	_quickSort(sortList, left, i-1)
	_quickSort(sortList, i+1, right)
end

function addon:QuickSort(list)
	_quickSort(list, 1, #list)
end

function addon:InsertSort(tab)
-- 插入排序
    local len = #tab
    for i=1,len-1 do
		local j = i+1
		while(j > 1)  do
			if (tab[j] < tab[j-1]) then
				tab[j],tab[j-1] = tab[j-1],tab[j]
			end
			j = j -1
		end 
    end
    return tab
end

function addon:pairsByKeys(t)
    local a = {}
    for n in pairs(t) do a[#a + 1] = n end
    table.sort(a)
    local i = 0
    return function ()
        i = i + 1
        return a[i], t[a[i]]
    end
end

function addon:RemoveRepetition(TableData)
    local bExist = {}
    for v, k in pairs(TableData) do
        bExist[k] = true
    end
    local result = {}
    for v, k in pairs(bExist) do
        table.insert(result, v)
	end
    return result
end

------------mouse over=========

local function CoreUIMakeMovable_OnMouseDown(self)
	local target = self._moveTarget
	if target:IsMovable() then
		target:StartMoving()
	end
end

local function CoreUIMakeMovable_OnMouseUp(self)
	local target = self._moveTarget
	target:StopMovingOrSizing()
	local func = target._moveTarget._EndOfMovingFunc
	if func then func() end
end

function addon:SetUiMoveable(frame, target, EndOfMovingFunc)
	if target ~= nil then
		frame._moveTarget = target
		target:SetMovable(true)
		target:SetClampedToScreen(true)
	else
		frame._moveTarget = frame
		frame:SetMovable(true)
		frame:SetClampedToScreen(true)
	end

	frame._moveTarget._EndOfMovingFunc = EndOfMovingFunc

	frame:EnableMouse(true)
	frame:SetScript("OnMouseDown", CoreUIMakeMovable_OnMouseDown)
	frame:SetScript("OnMouseUp", CoreUIMakeMovable_OnMouseUp)
end

-----------------end of move over

function addon:tabLength(t)
    local len=0
    for k,v in pairs(t) do
        len=len+1
    end
    return len
end