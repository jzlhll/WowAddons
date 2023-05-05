---这是一个类。每次使用请新建。现在只做一个纯数字，而不做obj的统计

local _, addon = ...
addon.DataAlgoSimple = addon.class_newInstance("DataAlgoSimple")
local DA = addon.DataAlgoSimple

function DA:Add(num)
  table.insert(self.dataTable, num)
end

function DA:Init()
  self.dataTable = self.dataTable or {}
end

function DA:Clear()
  self.dataTable = nil
end

function log(...)
  if false then print(...) end
end

-- 3σ规则算法函数
function DA:SimpleCalute()
    log("simpleCalute dataSize "..#self.dataTable)
    addon:QuickSort(self.dataTable)

    --循环使用3sigma算法来去除不合理数据，直到完美
    local hasRemoved
    for i=1,10 do
        log("simpleCalute dataSize"..i.." "..#self.dataTable)
        hasRemoved = self:judge(3)
        if not hasRemoved then
            break
        end
    end

    local res = {}
    for _, v in pairs(self.dataTable) do
        if res[v] then
            res[v] = res[v] + 1
        else
            res[v] = 1
        end
    end

    for k, v in addon:pairsByKeys(res) do
        log("res: "..k.." count:"..v)
    end
end

function DA:average()    --原始数组的算数平均值方法
    local sum = 0
    local size = #self.dataTable
    for i = 1, size do
        sum = sum + self.dataTable[i]
    end
    local r = sum / size
    --log("average: "..r)
    return r
end

function DA:standardVariance() --原始数组的标准方差值计算方法
    local sum = 0
    local size = #self.dataTable
    local av = self:average()
    local pow = math.pow

    for i = 1, size do
        sum = sum + pow(self.dataTable[i] - av, 2);
    end
        
    local r = math.sqrt(sum / (size-1))
    --log("standardVariance: "..r)
    return r, av
end

-- 删除table表中符合conditionFunc的数据
-- @param tb 要删除数据的table
-- @param conditionFunc 符合要删除的数据的条件函数
function DA:removeTableData(tb, conditionFunc)
  if tb ~= nil and next(tb) ~= nil then
      for i = #tb, 1, -1 do
          if conditionFunc(tb[i]) then
              table.remove(tb, i)
          end
      end
  end
end

function DA:judge(lvl) --判断异常值方法，若异常，则输出
    --log("judge...")
    local sum = 0
    local size = #self.dataTable
    local abs = math.abs

    local sv, av = self:standardVariance()
    local sv3 = lvl * sv

    local hasRemoved = false
    local lastRm, tmp
    for i=#self.dataTable, 1, -1 do
        tmp = self.dataTable[i]
        if abs(tmp - av) > sv3 then
            if tmp ~= lastRm then
                lastRm = tmp
                log("judge rm: "..tmp)
            end
            table.remove(self.dataTable, i)
            hasRemoved = true
        end
    end
    return hasRemoved
end