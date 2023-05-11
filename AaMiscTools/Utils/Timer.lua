local _, addon = ...

addon.TimerClass = addon.class_newInstance("AaMiscTimerClass")
local TC = addon.TimerClass
local GetTime = GetTime

-- 传入的第二参数，是第三个参数的table对象
-- 这样：您的外部对象，可以使用obj:updateFunc()直接接收，可以使用self。因为已经传入。
function TC:Init(deltaTs, obj, updateFunc)
    self.deltaTs = deltaTs
    self.obj = obj
    self.updateFunc = updateFunc
end

function TC:StartTimer()
    local eventFrame = self.eventFrame or CreateFrame("Frame")
    if self.eventFrame == nil then
        self.eventFrame = eventFrame
    end

    self.updatedTime = GetTime()

    self.eventFrame:SetScript("OnUpdate", function()
        local curTs = GetTime()
        if curTs - self.updatedTime > self.deltaTs then
            self.updatedTime = curTs
            self.updateFunc(self.obj)
        end
    end)
end

function TC:StopTimer()
    if self.eventFrame then
        self.eventFrame:SetScript("OnUpdate", nil)
    end
end
