function(event, ...)    
    if event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_SAY" then
        local msg, _, _, _, sname = ...
        local e = aura_env
        if e.NM == sname then
            if e.ssub(msg,1,8) == "autosell" or e.ssub(msg,1,6) == "atsell" then
				e.init(e)
				local pre,link,pr = e._3split(e, msg, 1)
				local cnt = ""
				for i = e.slen(pre), 1, -1 do
					local c = e.ssub(pre,i,i)
					if c == 'l' then break end
					cnt = c..cnt
				end
				if cnt == "" then cnt = "1" end

                e.parse(e,cnt,link,pr)
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, _, nm = ...
        if prefix == aura_env.MK then
            local e = aura_env
			local s = e.ssub(msg,1,4)

            if s == "publ" then
				local pub,prs,link,cnt = e._3split(e, msg, 2)
				local sid = e.ssub(pub, 5, -1)
                e.sell(e, sid, prs, cnt, link, nm)
            elseif s == "stop" then
                local sid = e.ssub(msg, 5, -1)
                e.stopc(e, sid)
            elseif s == "paus" then
                local sid = e.ssub(msg, 5, -1)
                e.pausec(e, sid)
            elseif s == "buys" then
                local sid, info = e.ssplit(" ", msg)
                sid = e.ssub(sid, 5, -1)
                e.upc(e, sid, nm, info)
            end
        end
    end
end
