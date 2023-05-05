local _, addon = ...
----暂时将支持的东西设置到列表中。
local tabInsert = table.insert

addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan
local isScanning = false

local index, v, lastScanName

-- 扫描装备的参数, 默认为紫装200+
function AH:GetEquipsScanParams(page)
    QueryAuctionItems("", 200, nil, page, false, 4, false, false, nil)
end

function AH:ScanExactName(name, page)
    QueryAuctionItems(name, nil, nil, page, false, 0, false, true, nil)
end

function AH:DumpAuctions(view)
    local auctions = {}
    for index = 1, GetNumAuctionItems(view) do
        local auctionInfo = { GetAuctionItemInfo(view, index) }
        local itemLink = GetAuctionItemLink(view, index)
        local entry = {
            minBid = auctionInfo.minBid or 0,
            buyoutPrice = auctionInfo.buyoutPrice or 0,
            itemLink = itemLink,
            index = index,
        }
        tabInsert(auctions, entry)
    end
    return auctions
end

function AH:NextScan(scanId)
    if scanId ~= 0 then
        local auctions = self:DumpAuctions("list") -- 这是一个page
        self.scanningList[lastScanName] 
        addon:printTab(auctions, 1, 1)
    end

    for k,v in pairs(self.scanningList) do
        lastScanName = k
        self:ScanExactName(lastScanName, v)
    end
end

function AH:Init()
    AH.defaultScanList = {}
    local deflist = AH.defaultScanList
    -- 所有装绑的列表

    -- 附魔材料 扫描项
    tabInsert(deflist, "梦境碎片")
    tabInsert(deflist, "无限之尘")
    tabInsert(deflist, "强效宇宙精华")
    tabInsert(deflist, "深渊水晶")
    -- 其他扫描项
    tabInsert(deflist, "符文宝珠")
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