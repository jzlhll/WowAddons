local _, addon = ...
----暂时将支持的东西设置到列表中。
local tabInsert = table.insert

addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan
local isScanning = false

local index, v, lastScanName

function AH:Init()
    AH.defaultScanList = {}
    local deflist = AH.defaultScanList
    -- 所有装绑的列表

    -- 附魔材料 扫描项
    tabInsert(deflist, "托尔塔的大号项圈")
    -- tabInsert(deflist, "梦境碎片")
    -- tabInsert(deflist, "无限之尘")
    -- tabInsert(deflist, "强效宇宙精华")
    -- tabInsert(deflist, "深渊水晶")
    -- -- 其他扫描项
    -- tabInsert(deflist, "符文宝珠")
end

local function ScanExactName(name, page)
    QueryAuctionItems(name, nil, nil, page, false, 0, false, true, nil)
end

function AH:DumpAuctions(view)
    local auctions = {}
    for index = 1, GetNumAuctionItems(view) do
        local _, _, count, quality, _, _, _, minBid, _, buyoutPrice = GetAuctionItemInfo(view, index)
        local link = GetAuctionItemLink(view, index)
        buyoutPrice = buyoutPrice or 0
        minBid = minBid or 0

        local entry = {
            minBid = minBid,
            buyoutPrice = buyoutPrice, 
            link = link,
            count = count
        }
        addon:printTabInALine(entry, 1, 1)
        tabInsert(auctions, entry)
    end
    return auctions
end

function AH:NextScan(scanId)
    if scanId > 1 then
        local auctions = self:DumpAuctions("list") -- 这是一个page

        local size = #auctions
        local scanningNum = self.scanningList[lastScanName]
        if scanningNum and size > 0 and scanningNum < 4 then --显示一样东西只扫描?页
            print("auctions: size: "..size)
            self.scanningList[lastScanName] = scanningNum + 1
        else
            print("auctions: size 0")
            if scanningNum then
                self.scanningList[lastScanName] = nil --一样东西扫描完成。
            end
        end
    end

    for k,v in pairs(self.scanningList) do
        lastScanName = k
        print("nextScan: "..lastScanName..", page: "..v)
        ScanExactName(lastScanName, v)
        return
    end

    AH:EndScan()
end

function AH:StartScan(isNew)
    if self.isScanning then return end
    self.isScanning = true

    if self.scanningList == nil then
        self.scanningList = {}
    end

    if isNew or (self.scanningList == nil) then
        self.scanningList = nil
        self.scanningList = {}
        for _,v in pairs(self.defaultScanList) do
            self.scanningList[v] = 0
        end
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