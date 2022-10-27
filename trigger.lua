function(event, ...)    
    if event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_SAY" then
        local msg, _, _, _, sname = ...
        local e = aura_env

        if UnitName("player") == sname then
            if e.ssub(msg,1,8) == "autosell" or e.ssub(msg,1,6) == "atsell" then
				e.init(e)
                e.parse(e, msg)
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, _, sname = ...
        if prefix == "AllanAtSell" then
            local e = aura_env

            if e.ssub(msg,1,8) == "publish(" then
                e.sell(e, msg, sname)
            elseif e.ssub(msg,1,7) == "atstop(" then
                local sid = e.ssub(msg, 8, -2)
                e.stopCell(e, sid)
            elseif e.ssub(msg,1,8) == "atpause(" then
                local sid = e.ssub(msg, 9, -2)
                e.pauseCell(e, sid)
            elseif e.ssub(msg,1,4) == "(sid" then
                local sid, info = e.ssplit(" ", msg)
                sid = e.ssub(sid, 5, -2)
                e.upCell(e, sid, sname, info)
            end
        end
    end
end
