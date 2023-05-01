-----延迟加载反和谐模块
local _, addon = ...
addon.registCategoryCreator(function()
	addon.initCategoryCheckBox("骷髅架子*", MiscDB.hasOverride, function(cb)
		MiscDB.hasOverride = not MiscDB.hasOverride
	end)

    addon.initCategoryCheckBox("最远距离41码血条显示", MiscDB.maxDistance, function(cb)
		MiscDB.maxDistance = not MiscDB.maxDistance
        if MiscDB.maxDistance then
            SetCVar("nameplateMaxDistance", "41")
        end
	end)

    if MiscDB.maxZoom == 1.8 then
        txt = "视角距离：一般"
    end
    if MiscDB.maxZoom == 2.6 then
        txt = "视角距离：远"
    end
    addon.initCategoryCheckBox(txt, true, function(cb)
        local is1 = MiscDB.maxZoom == 1.8
        local is2 = MiscDB.maxZoom == 2.6
        if is1 then
            cb.msg:SetText("视角距离：一般")
            MiscDB.maxZoom = 2.6
        end
        if is2 then
            cb.msg:SetText("视角距离：远")
            MiscDB.maxZoom = 1.8
        end
        SetCVar("cameraDistanceMaxZoomFactor", MiscDB.maxZoom)

        cb:SetChecked(true)
	end)

    addon.initCategoryCheckBox("中文语言乱码修正*", MiscDB.noLuanma, function(cb)
		MiscDB.noLuanma = not MiscDB.noLuanma
	end)
end)

local zhubaoAutoColor = function()

end

local receiveMainMsg = function(event, ...)
    local c = MiscDB
    if event == "later" then
        -------1 和谐--------
        local defFhx = GetCVar("overrideArchive")
        if c.hasSkelet then
            print("1")
            if defFhx ~= "0" then
                print("\124cFFE1FFFF您是第一次加载反和谐，需要重启。\124r")
                print("\124cFFE1FFFF您是第一次加载反和谐，需要重启。\124r")
                print("\124cFFE1FFFF您是第一次加载反和谐，需要重启。\124r")
                --和谐国服  1:我就要白板人      0:我需要骷髅架子
                ConsoleExec("overrideArchive 0")
            end
        else
            print("2 "..tostring(defFhx))
            if defFhx ~= "1" then
                ConsoleExec("overrideArchive 1")
            end
        end

        -------2 远距离------
        if c.maxDistance then
            SetCVar("nameplateMaxDistance", "41")
        end

        if c.maxZoom then
            SetCVar("cameraDistanceMaxZoomFactor", c.maxZoom)
        end

        if c.noLuanma then
            ConsoleExec("portal TW")
            ConsoleExec("profanityFilter 0")
        end
    elseif event == "later2" then
        if c.autoHideQuestWatchFrame then
            local expandBtn = WatchFrameCollapseExpandButton
            if expandBtn then
                expandBtn:GetScript("OnClick")(expandBtn)
            end
        end
    end
end
addon.registLaterInit(receiveMainMsg)
