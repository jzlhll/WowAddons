
------init before anything
local _, addon = ...

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