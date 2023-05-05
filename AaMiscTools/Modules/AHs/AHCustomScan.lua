local _, addon = ...
----暂时将支持的东西设置到列表中。
local tabInsert = table.insert

addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan
local isScanning = false

local index, v, lastScanName

local algo = addon.DataAlgoSimple.new()

local totalSize = 0
local startTime = 0

function AH:Init()
    AH.defaultScanList = {}
    local deflist = AH.defaultScanList
    -- 所有装绑的列表

    -- 附魔材料 扫描项
    --tabInsert(deflist, "托尔塔的大号项圈")
    --tabInsert(deflist, "梦境碎片")
    tabInsert(deflist, "无限之尘")
    --tabInsert(deflist, "强效宇宙精华")
    --tabInsert(deflist, "深渊水晶")
    -- -- 其他扫描项
    -- tabInsert(deflist, "符文宝珠")
end

local function ScanExactName(name, page)
    QueryAuctionItems(name, nil, nil, page, false, 0, false, true, nil)
end

function AH:DumpAuctions(view)
    local size = GetNumAuctionItems(view)
    for index = 1, size do
        local _, _, count, quality, _, _, _, minBid, _, buyoutPrice = GetAuctionItemInfo(view, index)
        local link = GetAuctionItemLink(view, index)

        self.scanResultList[link] = self.scanResultList[link] or {}

        local entry = {
            minBid = minBid or 0,
            buyoutPrice = buyoutPrice or 0, 
            count = count
        }
        --addon:printTabInALine(entry, 1, 1)
        tabInsert(self.scanResultList[link], entry)
        totalSize = totalSize + count
    end
    return size
end

function AH:NextScan(scanId)
    local size = self:DumpAuctions("list") -- 这是一个page

    local scanningNum = self.scanningList[lastScanName]
    if scanningNum and size > 0 then --显示一样东西只扫描?页  and scanningNum < 5
        self.scanningList[lastScanName] = scanningNum + 1
    else
        self.scanningList[lastScanName] = nil --一样东西扫描完成。
    end

    for k,v in pairs(self.scanningList) do
        lastScanName = k
        print("nextScan: "..lastScanName..", page: "..v)
        ScanExactName(lastScanName, v)
        return --如果有的话，就return掉不做后面的EndScan了。
    end

    print("End Scan")
    AH:EndScan()
    AH:ScanCalucate()
end

function AH:ScanCalucate()
    startTime = GetTime()
    print("ScanCalucate total1: "..totalSize)
    algo:Clear()
    algo:Init()
    local bigPrice
    local totalCount = 0
    for link, entries in pairs(self.scanResultList) do
        for _, entry in pairs(entries) do
            if entry.buyoutPrice > entry.minBid then
                bigPrice = entry.buyoutPrice / entry.count
            else
                bigPrice = entry.minBid / entry.count
            end

            for i = 1, entry.count do
                algo:Add(bigPrice)
                totalCount = totalCount + 1
            end
        end
    end
    print("ScanCalucate total2: "..totalCount..", time="..(GetTime() - startTime))

    algo:SimpleCalute()

    -- if true then
    --     local t = ""..(GetTime() - startTime)
    --     print(t.." 1Range", result.range1[1], "-", result.range1[2], ", percent:", result.percent1)
    --     print(t.." 2Range", result.range2[1], "-", result.range2[2], ", percent:", result.percent2)
    --     print(t.." 3Range", result.range3[1], "-", result.range3[2], ", percent:", result.percent3)
    -- end

    algo:Clear()
end

function AH:StartScan(isNew)
    if self.isScanning then return end
    self.isScanning = true

    if isNew or (self.scanningList == nil) then
        self.scanningList = nil
        self.scanningList = {}

        self.scanResultList = nil
        self.scanResultList = {}

        for _,v in pairs(self.defaultScanList) do
            self.scanningList[v] = 0
        end
    end

    for k,v in pairs(self.scanningList) do
        lastScanName = k
        print("nextScan: "..lastScanName..", page: "..v)
        ScanExactName(lastScanName, v)
    end

    AH:StartScanTimer()
end

function AH:EndScan()
    AH:StopScanTimer()
    self.isScanning = false
end

--[[
QueryAuctionItems(name, minLevel, maxLevel, page, isUsable, qualityIndex, getAll, exactMatch, filterData)
https://wowwiki-archive.fandom.com/wiki/API_QueryAuctionItems
--]]