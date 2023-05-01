-----延迟加载反和谐模块
local _, addon = ...

local getCfg = addon.getCfg
local setCfg = addon.setCfg

local maxZoomCheckBoxes

addon:registCategoryCreator(function()
    addon:initCategoryCheckBoxes(nil, {
        {
            name = "骷髅红血还原*",
            checked = getCfg("noOverride"),
            func = function(cb)
                local c = not getCfg("noOverride")
                setCfg("noOverride", c)
            end
        },
        {
            name = "中文语言乱码修正*",
            checked = getCfg("noLuanma"),
            func = function(cb)
                local c = not getCfg("noLuanma")
                setCfg("noLuanma", c)
            end
        }
    })

    addon:initCategoryCheckBox("最远距离41码血条显示", getCfg("maxDistance"), function(cb)
        local newMax = not getCfg("maxDistance")
		setCfg("maxDistance", newMax)
        if newMax then
            SetCVar("nameplateMaxDistance", "41")
        end
	end)

    addon:initCategoryCheckBox("进入游戏自动收起任务栏*", getCfg("autoHideQuestWatchFrame"), function(cb)
		local c = not getCfg("autoHideQuestWatchFrame")
        setCfg("autoHideQuestWatchFrame", c)
	end)

    local maxZoom = getCfg("maxZoom")
    local checkes = {
        {
            name = "远",
            checked = maxZoom == 2.6,
            func = function() 
                maxZoomCheckBoxes[1].checked = false
                maxZoomCheckBoxes[2].checked = true

                setCfg("maxZoom", 2.6)
                SetCVar("cameraDistanceMaxZoomFactor", 2.6)
            end
        },
        {
            name = "一般",
            checked = maxZoom == 1.8,
            func = function() 
                maxZoomCheckBoxes[2].checked = true
                maxZoomCheckBoxes[1].checked = false

                setCfg("maxZoom", 1.8)
                SetCVar("cameraDistanceMaxZoomFactor", 1.8)
            end
        },
    }
    addon:createCategoryLine()
    maxZoomCheckBoxes = addon:initCategoryCheckBoxes("视角距离：", checkes, true)
    addon:createCategoryLine()
end)

local function init()
    -------1 和谐--------
    local defFhx = GetCVar("overrideArchive")
    if getCfg("noOverride") then
        if defFhx ~= "0" then
            print("\124cFFE1FFFF您是第一次加载反和谐，需要重启。\124r")
            print("\124cFFE1FFFF您是第一次加载反和谐，需要重启。\124r")
            print("\124cFFE1FFFF您是第一次加载反和谐，需要重启。\124r")
            ConsoleExec("overrideArchive 0") -- 1 白板人；0 骷髅
        end
    else
        if defFhx ~= "1" then
            ConsoleExec("overrideArchive 1")
        end
    end

    -------2 远距离------
    if getCfg("maxDistance") then
        SetCVar("nameplateMaxDistance", "41")
    end

    if getCfg("maxZoom") then
        SetCVar("cameraDistanceMaxZoomFactor", getCfg("maxZoom"))
    end

    if getCfg("noLuanma") then
        ConsoleExec("portal TW")
        ConsoleExec("profanityFilter 0")
    end

    if getCfg("autoHideQuestWatchFrame") then
        local expandBtn = WatchFrameCollapseExpandButton
        if expandBtn then
            expandBtn:GetScript("OnClick")(expandBtn)
        end
    end
end

local receiveMainMsg = function(event, ...)
    if event == "later" then
        init()
        addon:unRegistGlobalEvent(receiveMainMsg)
    end
end
addon:registGlobalEvent(receiveMainMsg)