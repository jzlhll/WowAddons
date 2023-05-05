local _, addon = ...
addon.AHCustomScan = addon.AHCustomScan or {}
local AH = addon.AHCustomScan

local SCAN_DELTA = 0.6

local function OnTimerUpdate()
    local cur = GetTime()
    if cur - AH.updateResetTime >= SCAN_DELTA then
        local canQuery, canQueryAll = CanSendAuctionQuery()
        if canQuery then
            AH.ScanId = AH.ScanId + 1
            AH:NextScan(AH.ScanId)
        end
    end
end

function AH:StartScanTimer()
    local eventFrame
    if AH.eventFrame then
        eventFrame = AH.eventFrame
    else
        eventFrame = CreateFrame("Frame")
        AH.eventFrame = eventFrame
    end

    AH.ScanId = 0
    AH.updateResetTime = GetTime()
    AH.eventFrame:SetScript("OnUpdate", OnTimerUpdate)
end

function AH:StopScanTimer()
    if AH.eventFrame then
        AH.eventFrame:SetScript("OnUpdate", nil)
    end
end
