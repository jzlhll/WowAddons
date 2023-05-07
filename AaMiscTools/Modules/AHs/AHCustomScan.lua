local _, addon = ...
----暂时将支持的东西设置到列表中。
local tabInsert, tabRemove = table.insert, table.remove

addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan
local algo --过滤算法
local scanTimer, saveTimer -- 时间间隔辅助类

local function getAlgo()
    if algo then return algo end
    algo = addon.DataAlgoSimple.new()
    return algo
end

local function nextScan(me)
    
end

local function getScanTimer(me)
    if scanTimer then return scanTimer end
    scanTimer = addon.TimerClass.new()
    scanTimer:Init(0.6, me, nextScan)
end

function AH:Init()

    AH.defaultScanList = {}
    for _, v in pairs(AH.Constants.ScanList) do
        tabInsert(AH.defaultScanList, v)
    end
end

local function ScanExactName(name, page)
    QueryAuctionItems(name, nil, nil, page, false, 0, false, true, nil)
end

function AH:DumpAuctions(view)
    local size = GetNumAuctionItems(view)
    for index = 1, size do
        local _, _, count, quality, _, _, _, minBid, _, buyoutPrice = GetAuctionItemInfo(view, index)
        local link = GetAuctionItemLink(view, index)
        local itemID = link:match('|Hitem:(%d+)')

        self.scanResultList[itemID] = self.scanResultList[itemID] or {}

        local entry = {
            minBid = minBid or 0,
            buyoutPrice = buyoutPrice or 0, 
            count = count,
            link = link
        }
        --addon:printTabInALine(entry, 1, 1)
        tabInsert(self.scanResultList[itemID], entry)
    end
    return size
end

function AH:NextScan(scanId)
    local size = self:DumpAuctions("list") -- 这是一个page
    if size == 0 then
        tabRemove(self.scanningList, self.scanningListIndex) --一样东西扫描完成。
        self.scanningListCurPage = 0
        self.scanningListIndex = self.scanningListIndex - 1
    else
        self.scanningListCurPage = self.scanningListCurPage + 1 --下一页继续扫
    end

    if self.scanningListIndex == 0 then
        print("End Scan")
        AH:AlgoAndSave()
        AH:EndScan()
    else
        local name = self.scanningList[self.scanningListIndex]
        print("Scan: "..name..", page: "..self.scanningListCurPage)
        ScanExactName(name, self.scanningListCurPage)
    end
end

function AH:AlgoAndSave() --todo本函数会卡。
    local price
    local totalCount = 0
    for itemID, entries in pairs(self.scanResultList) do
        getAlgo():Init()

        local itemLink1, itemLink2
        for _, entry in pairs(entries) do
            if itemLink1 == nil then
                itemLink1 = entry.link
                itemLink2 = entry.link
            end

            if entry.link ~= itemLink1 then
                itemLink2 = entry.link
            end

            if entry.buyoutPrice > entry.minBid then
                price = entry.buyoutPrice / entry.count
            else
                price = entry.minBid / entry.count
            end

            for i = 1, entry.count do
                getAlgo():Add(price)
                totalCount = totalCount + 1
            end
        end
        
        local showLog = getAlgo():AlgoTest()
        if showLog then
            MiscDB.AHPrices = MiscDB.AHPrices or {}
            MiscDB.AHPrices[itemID] = {
                data = showLog,
                link1 = itemLink1,
                link2 = itemLink2,
                time = date("%Y-%m-%d"),
            }
        end
        getAlgo():Clear()
    end
    --print("ScanCalucate time="..(GetTime() - startTime))
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
            tabInsert(self.scanningList, v)
        end
    end

    self.scanningListIndex = #self.scanningList
    self.scanningListCurPage = 0
    local name = self.scanningList[self.scanningListIndex]
    print("StartScan: "..name.." page: "..self.scanningListCurPage)
    ScanExactName(name, v)

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