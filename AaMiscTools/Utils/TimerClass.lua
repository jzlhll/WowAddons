local _, addon = ...

addon.TimerClass = addon.class_newInstance("AaMiscTimerClass")
local TC = addon.TimerClass
local GetTime = GetTime

-- 传入的第二参数，是第三个参数的table对象
-- 这样：您的外部对象，可以使用obj:updateFunc()直接接收，可以使用self。因为已经传入。
function TC:Init(deltaTs, obj, updateFunc, eventFrame)
    self.deltaTs = deltaTs
    self.obj = obj
    self.timerEventFrame = eventFrame
    self.updateFunc = updateFunc
end

function TC:StartTimer()
    self.timerEventFrame = self.timerEventFrame or CreateFrame("Frame")
    self.lastTime = GetTime()

    self.timerEventFrame:SetScript("OnUpdate", function()
        local curTs = GetTime()
        if curTs - self.lastTime > self.deltaTs then
            self.lastTime = curTs
            self.updateFunc(self.obj)
        end
    end)
end

function TC:ChangeDeltaTs(newDeltaTs)
	self.deltaTs = newDeltaTs
end

function TC:StopTimer()
    if self.timerEventFrame then
        self.timerEventFrame:SetScript("OnUpdate", nil)
    end
end

--[[
   用例1：
    Host = {}

    function Host:NextTimeUpdate()
        --你可以在这里调用self,self则是你的host
    end

    function Host:Init()
        self.scanTimer = addon.TimerClass.new()
        self.scanTimer:Init(DELTA_TS, self, self.NextTimeUpdate)
    end

    某些代码函数中可以执行如下：
    Host.scanTimer.StartTimer()
    或者Host:函数中，self.scanTimer.StartTimer()

    用例2：
    local function NextTimeUpdate()
    end
    local scanTimer = addon.TimerClass.new()
    scanTimer:Init(DELTA_TS, self, NextTimeUpdate)

--]]