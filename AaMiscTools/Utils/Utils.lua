
------init before anything
local _, addon = ... ; addon = addon or {}

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
	printInner(table, level, maxLevel)
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