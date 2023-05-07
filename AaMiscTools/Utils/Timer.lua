local _, addon = ...

addon.TimerClass = addon.class_newInstance("AaMiscTimerClass")
local TC = addon.TimerClass

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

    self.eventFrame:SetScript("OnUpdate", function(me, elapsed)
        local last = me.updatedTime or 0
        if elapsed - last >= self.deltaTs then
            self.updatedTime = elapsed
            self.updateFunc(self.obj)
        end
    end)
end

function TC:StopTimer()
    if self.eventFrame then
        self.eventFrame:SetScript("OnUpdate", nil)
    end
end
