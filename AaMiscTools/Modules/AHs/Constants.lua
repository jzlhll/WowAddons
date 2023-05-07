local _, addon = ...
addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan

AH.Constants = {}
AH.Constants.AuctionItemInfo = {
    Buyout = 10,
    Quantity = 3,
    Owner = 14,
    ItemID = 17,
    Level = 6,
    MinBid = 8,
    BidAmount = 11,
    Bidder = 12,
    SaleStatus = 16,
}

AH.Constants.ScanList = {
    -- 附魔材料
    "梦境碎片",
    "无限之尘",
    "强效宇宙精华", 
    "深渊水晶", 
    ---25奥杜尔
    "铁铆战盔",
    "生命熔炉胸铠",
    "始祖龙皮腿甲",
    "撼地者的徽记",
    "菲莉的萌芽外套",
    "石纹腿甲",
    "神灵兜帽",
    "北地屏障",
    "失落挚爱护腿",
    "仙子之心",
    "阿西莫夫的斗篷",
    "黑暗核心护腿",
    ---10奥杜尔
    "内燃护腕",
    "跃动烈焰臂甲",
    "窒息烈焰护腕",
    "构造体的臂甲",
    "钢铁议会披风",
    "碎裂巨人披风",
    "灵敏攀登者腰带",
    "寒冬徽记",
    "共鸣裹手",
    "机械侏儒的电缆",
    "深渊束腕",
    -- -- 其他扫描项
    "符文宝珠",
}