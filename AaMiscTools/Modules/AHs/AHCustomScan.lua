local _, addon = ...;addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan

----暂时将支持的东西设置到列表中。
local tabInsert, tabRemove = table.insert, table.remove

local algo --过滤算法
local AH_SCAN_DELTA = 0.48 -- 最小0.3 API要求

local function getAlgo()
    if algo then return algo end
    algo = addon.DataAlgoSimple.new()
    return algo
end

local function ScanExactName(name, page)
    QueryAuctionItems(name, nil, nil, page, false, 0, false, true, nil)
end

function AH:NextTimeUpdate()
    if self.isScanning == 1 then
        AH:NextScanOnce()
    elseif self.isScanning == 2 then
        print("扫描完成，开始保存")
        AH:AlgoAndSaveOnce()
    elseif self.isScanning == 3 then
        AH:EndScan(true)
    end
end

function AH:NextScanOnce()
    local canQuery, canQueryAll = CanSendAuctionQuery()
    if canQuery then
        local size = self:DumpAuctions("list") -- 这是一个page
        if size == 0 then
            tabRemove(self.scanningList, self.scanningListIndex) --一样东西扫描完成。
            self.scanningListCurPage = 0
            self.scanningListIndex = self.scanningListIndex - 1
        else
            self.scanningListCurPage = self.scanningListCurPage + 1 --下一页继续扫
        end
    
        if self.scanningListIndex == 0 then
            self.isScanning = 2
        else
            local name = self.scanningList[self.scanningListIndex]
            ScanExactName(name, self.scanningListCurPage)
        end
    end
end

function AH:AlgoAndSaveOnce()
    local price
    local totalCount = 0
    local currentItemID
    local curEntries
    for itemID, entries in pairs(self.scanResultList) do
        if itemID then
            currentItemID = itemID
            curEntries = entries
            break
        end
    end

    if currentItemID then
        getAlgo():Init()

        local itemLink1, itemLink2
        for _, entry in pairs(curEntries) do
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
            if itemLink2 == itemLink1 then itemLink2 = nil end
            MiscDB.AHPrices[currentItemID] = {
                s = showLog,
                d = tonumber(date("%Y%m%d"))
            }
        end
        getAlgo():Clear()
        
        self.scanResultList[currentItemID] = nil
    else
        self.isScanning = 3
    end
end

function AH:StartScan(isNew)
    if self.isScanning then return end
    self.isScanning = 1

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
    --print("StartScan: "..name.." page: "..self.scanningListCurPage)
    ScanExactName(name, v)

    self.scanTimer:StartTimer()
end

function AH:EndScan(suc)
    if self.isScanning then
        if suc then 
            print("扫描并保存结束!")
        else
            print("扫描中断!")
        end
        self.scanTimer:StopTimer()
        self.isScanning = nil
    end
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

function AH:Init()
    self.scanTimer = addon.TimerClass.new()
    self.scanTimer:Init(AH_SCAN_DELTA, self, self.NextTimeUpdate)

    AH.defaultScanList = {}
    for _, v in pairs(AH.Constants.ScanList) do
        tabInsert(AH.defaultScanList, v)
    end
end
local strlower, format, strmatch, gmatch = string.lower, string.format, string.match, string.gmatch;
function AH:ShowTipWithPricing(tip, itemLink)
    if self.isScanning then return end
    if not itemLink then return end
    local itemID = strmatch(itemLink, "item:(%d+)") or nil
    if not itemID then return end
    local tab = MiscDB.AHPrices and MiscDB.AHPrices[itemID]
    if tab then
        local showLog = tab.s
        local cutDay = tonumber(date("%Y%m%d")) - tab.d
        tip:AddLine("AaMisc拍卖"..cutDay.."天前  "..showLog, 1.0, 0.8, 1.0, 1)
        tip:Show();
    end
end
--[[
QueryAuctionItems(name, minLevel, maxLevel, page, isUsable, qualityIndex, getAll, exactMatch, filterData)
https://wowwiki-archive.fandom.com/wiki/API_QueryAuctionItems
--]]