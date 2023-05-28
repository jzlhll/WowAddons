local _, addon = ...
local updateFun, scanTimer, subUpdateFuncs
local DELTA_TS = 0.075

function addon:GlobalTimerStart(subUpdateFunc, mask)
    if subUpdateFuncs == nil then
        subUpdateFuncs = {}
    end
    if subUpdateFuncs[mask] then return end

    if updateFun == nil then
        updateFun = function()
            for _, subFunc in pairs(subUpdateFuncs) do
                subFunc()
            end
        end
    end

    if scanTimer == nil then
        scanTimer = addon.TimerClass.new()
        scanTimer:Init(DELTA_TS, self, updateFun, addon.eventframe)
    end

    local lastSize = #subUpdateFuncs
    subUpdateFuncs[mask] = subUpdateFunc

    if lastSize == 0 then
        scanTimer:StartTimer()
    end
end

function addon:GlobalTimerStop(mask)
    if subUpdateFuncs[mask] then
        local lastSize = #subUpdateFuncs
        subUpdateFuncs[mask] = nil
        if lastSize == 1 then --即现在为空
            scanTimer:StopTimer()
        end
    return end
end