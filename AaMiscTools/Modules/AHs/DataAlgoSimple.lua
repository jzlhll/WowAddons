---这是一个类。每次使用请新建。现在只做一个纯数字，而不做obj的统计
--https://zhuanlan.zhihu.com/p/93855259
--https://mp.weixin.qq.com/s?__biz=MzU0MDQ1NjAzNg==&mid=2247544548&idx=3&sn=940de3fcf791c1d77d640a863c5a7109&chksm=fb3a8befcc4d02f9ec6deb9fb043d074b7ae81f2b230601f1067d88f891fc4b86b1888b6a899&scene=27
--https://blog.csdn.net/ChenVast/article/details/82791088 Q检测法的缺点

--[[
    拉依达准则法（3δ）：简单，无需查表。测量次数较多或要求不高时用。是最常用的异常值判定与剔除准则。但当测量次数《=10次时，该准则失效。
如果实验数据值的总体x是服从正态分布的，则
异常值（outlier）的判别与剔除(rejection)
式中，μ与σ分别表示正态总体的数学期望和标准差。此时，在实验数据值中出现大于μ＋3σ或小于μ—3σ数据值的概率是很小的。因此，根据上式对于大于μ＋3σ或小于μ—3σ的实验数据值作为异常值，予以剔除。具体计算方法参见http://202.121.199.249/foundrymate/lessons/data-analysis/13/131.htm
在这种情况下，异常值是指一组测定值中与平均值的偏差超过两倍标准差的测定值。与平均值的偏差超过三倍标准差的测定值，称为高度异常的异常值。在处理数据时，应剔除高度异常的异常值。异常值是否剔除，视具体情况而定。在统计检验时，指定为检出异常值的显著性水平α=0.05，称为检出水平；指定为检出高度异常的异常值的显著性水平α=0.01，称为舍弃水平，又称剔除水平(reject level)。
标准化数值（Z-score）可用来帮助识别异常值。Z分数标准化后的数据服从正态分布。因此，应用Z分数可识别异常值。我们建议将Z分数低于-3或高于3的数据看成是异常值。这些数据的准确性要复查，以决定它是否属于该数据集。
肖维勒准则法（Chauvenet）：经典方法，改善了拉依达准则，过去应用较多，但它没有固定的概率意义，特别是当测量数据值n无穷大时失效。
狄克逊准则法（Dixon）：对数据值中只存在一个异常值时，效果良好。担当异常值不止一个且出现在同侧时，检验效果不好。尤其同侧的异常值较接近时效果更差，易遭受到屏蔽效应。
罗马诺夫斯基（t检验）准则法：计算较为复杂。
格拉布斯准则法（Grubbs）：和狄克逊法均给出了严格的结果，但存在狄克逊法同样的缺陷。朱宏等人采用数据值的中位数取代平均值，改进得到了更为稳健的处理方法。有效消除了同侧异常值的屏蔽效应。

国际上常推荐采用格拉布斯准则法。
]]

local _, addon = ...
addon.DataAlgoSimple = addon.class_newInstance("DataAlgoSimple")
local DA = addon.DataAlgoSimple
local tabinsert = table.insert
local tabrm = table.remove

function DA:Add(num)
    tabinsert(self.dataTable, num)
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

local function GetMoneyStringL(money, separateThousands)
	local goldString, silverString, copperString;
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = mod(money, COPPER_PER_SILVER);

    if (separateThousands) then
        goldString = FormatLargeNumber(gold)..GOLD_AMOUNT_SYMBOL;
    else
        goldString = gold..GOLD_AMOUNT_SYMBOL;
    end
    silverString = silver..SILVER_AMOUNT_SYMBOL;
    copperString = copper..COPPER_AMOUNT_SYMBOL;

	local moneyString = "";
	local separator = "";
	if ( gold > 0 ) then
		moneyString = goldString;
		separator = " ";
	end

    if gold < 10 then
        if ( silver > 0 ) then
            moneyString = moneyString..separator..silverString;
            separator = " ";
        end
        if ( copper > 0 or moneyString == "" ) then
            moneyString = moneyString..separator..copperString;
        end
    end

	return moneyString, gold; --allan add
end

-- 使用BoxplotFilter算法或者使用ThreeSigma算法过滤异常数据
function DA:AlgoTest()
    local origSize = #self.dataTable
    log("AlgoTest size "..origSize)
    if origSize == 0 then return "--" end
    if origSize == 1 then return ""..self.dataTable[1] end

    --1. 排序
    addon:QuickSort(self.dataTable)

    --算法1：BoxplotFilter过滤
    self:BoxplotFilter(self.dataTable, 1.8, 2.2)
    log("AlgoTest after BoxplotFilter size: "..#self.dataTable)

    --算法2: 3-sigma 循环使用3sigma算法来去除不合理数据，直到完美
    self:ThreeSigmaFilter(2)
    log("AlgoTest after ThreeSigmaFilter size: "..#self.dataTable)

    local res = {}
    for _, v in pairs(self.dataTable) do
        if res[v] then
            res[v] = res[v] + 1
        else
            res[v] = 1
        end
    end

    local count = 0
    local showLog = ""
    for k, v in addon:pairsByKeys(res) do
        count = count + 1
        if count < 3 then
            showLog = showLog..GetMoneyStringL(k, true).."*"..v..", "
        elseif count == 3 then
            showLog = showLog..GetMoneyStringL(k, true).."*"..v
            break
        end
    end
    log(showLog)
    return showLog
end

------------------------------------------------
--------------------- 算法 ---------------------

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

function DA:ThreeSigmaRule(lvl) --判断异常值方法，若异常，则输出
    local sum = 0
    local size = #self.dataTable
    local abs = math.abs

    local sv, av = self:standardVariance()
    local sv3 = lvl * sv

    local hasRemoved = false
    local lastRm, tmp
    local removeList = ""
    for i=#self.dataTable, 1, -1 do
        tmp = self.dataTable[i]
        if abs(tmp - av) > sv3 then
            if tmp ~= lastRm then
                lastRm = tmp
                removeList = removeList..", "..lastRm
            end
            tabrm(self.dataTable, i)
            hasRemoved = true
        end
    end
    log("ThreeSigma rm: "..removeList)
    return hasRemoved
end

function DA:ThreeSigmaFilter(circles, level)
    --循环使用3sigma算法来去除不合理数据，直到完美
    if circles == nil then circles = 10 end
    if level == nil then level = 3 end
    local hasRemoved
    for i=1, circles do
        --log("ThreeSigma dataSize"..i.." "..#self.dataTable)
        hasRemoved = self:ThreeSigmaRule(level)
        if not hasRemoved then
            break
        end
    end
end

local function median(sortedList)
    local j = 0

    local size = #sortedList
    if size % 2 == 1 then
        j = sortedList[(size-1)/2 + 1]
    else
        j = (sortedList[size/2] + sortedList[size/2+1] + 0.0) / 2
    end
    return j
end

local function compareTo(d1, d2)
    if d1 < d2 then
        return -1 -- Neither val is NaN, thisVal is smaller
    elseif d1 > d2 then
        return 1
    else
        return 0
    end
end

---由于我们是AH拍卖行，期待数据是靠前的。
function DA:BoxplotFilter(data, multiplierMax, multiplierMin)
    if #data < 4 then
        return
    end
    
    local dataSize = #data
    local cut4Size = math.floor(dataSize / 4)

    -- 下四分位数
    local q1 = data[cut4Size] / 4 + data[cut4Size + 1] * 3 / 4
    -- 中位数
    local q2 = median(data)
    -- 上四分位数
    local q3 = data[dataSize - cut4Size] * 3 / 4 + data[dataSize - cut4Size + 1] / 4
    -- 计算四分位距IQR
    local iqr = q3 - q1
    -- 默认乘1.5，剔除过多正常值后改成1.7
    if multiplierMax == nil then
        multiplierMax = 1.7
    end
    -- 默认乘1.5
    if multiplierMin == nil then
        multiplierMin = 1.5
    end
    local max = q3 + multiplierMax * iqr
    local min = q1 - multiplierMin * iqr
    --log("BoxPlot q1: ", q1, " median: ", q2, " q3: ", q3, " \nmax: ", max, " min:", min)

    local i = #data
    local zero = 0.00

    local isMinEqualMax = compareTo(min, max)
    local isQ1EqualQ2 = compareTo(q1, q2)
    local isQ2Is0 = compareTo(q2, zero)

    if isMinEqualMax == 0 or isQ1EqualQ2 == 0 or isQ2Is0 == 0 then
        log("BoxPlot: isMinEqualMax "..tostring(isMinEqualMax))
        log("BoxPlot: isQ1EqualQ2 "..tostring(isQ1EqualQ2))
        log("BoxPlot: isQ2Is0 "..tostring(isQ2Is0))
        return
    end

    local lastVo = nil
    local removeList = ""
    while i >= 1 do
        local vo = data[i]
        if compareTo(vo, min) < 0 or compareTo(vo, max) > 0 then
            --[[
            --忽略零比较多的情况
            local compTo1 = compareTo(min, max) == 0 and compareTo(min, zero) == 0
            local compTo2 = compareTo(q1, q2) == 0 and compareTo(q2, zero) == 0
            if not (compTo1 or compTo2) then
                tabinsert(errorData, vo)
            end]]--
            if lastVo ~= vo then
                lastVo = vo
                removeList = removeList..", "..vo
            end
            tabrm(data, i)
        end
        i = i - 1
    end
    log("BoxPlot: remove "..removeList)
end