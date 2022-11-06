aura_env.beInit = false
aura_env.ssub = string.sub
aura_env.debug = true
aura_env.WID = 602
aura_env.NM = UnitName("player")
	
aura_env.init = function(env)
	if env.beInit then
		return
	end

	env.showMod = 0
	if env.debug then 
		env.CNL = "SAY"
	else
		env.CNL = "RAID"
	end
	
	env.MK = "ATSELLER"

	env.beInit = true

	env.ssplit = string.split
	env.slen = string.len
	env.sgsub = string.gsub
	env.tsort = table.sort
	env.trm = table.remove
	env.tinsert = table.insert
	env.mceil = math.ceil
	env.membs = {}
	env.randId = random(1000)
	--sync
	env.sellings = {}
	env.curPgIdx = 1
	env.sellCnt = 0
	--sync end

	env.Cmu = LibStub:GetLibrary("AceComm-3.0")
    env.Cmu:RegisterComm(env.MK, function(prefix, message, _, sname) end)
	env.spacePatten = string.format("([^%s]+)", ' ')
	
	--[[
	Table转化为string 
	--]]
	function TableToStr(t, bArry)
		if t == nil then
			return ""
		end
		local retstr = "{"

		local i = 1
		for key, value in pairs(t) do
			local signal = ","
			if i == 1 then
				signal = ""
			end

			if bArry then
				retstr = retstr .. signal .. ToStringEx(value)
			else
				if type(key) == "number" or type(key) == "string" then
					retstr = retstr .. signal .. "[" .. ToStringEx(key) .. "]=" .. ToStringEx(value)
				else
					if type(key) == "userdata" then
						retstr =
							retstr .. signal .. "*s" .. TableToStr(getmetatable(key)) .. "*e" .. "=" .. ToStringEx(value)
					else
						retstr = retstr .. signal .. key .. "=" .. ToStringEx(value)
					end
				end
			end
			i = i + 1
		end
		retstr = retstr .. "}"
		return retstr 
	end

	--[[
		String转画table
	--]]
	function StrToTable(str)
		if str == nil or type(str) ~= "string" or str == "" then
			return {}
		end
		return loadstring("return " .. str)()
	end

	--[[
		table与字符串转化	
	--]]
	function ToStringEx(value)
		if type(value) == "table" then
			return TableToStr(value)
		elseif type(value) == "string" then
			return '"' .. value .. '"'
		else
			return tostring(value)
		end
	end

	env._3split = function(e, str, stCnt)
		local r = {}
		e.sgsub(str, e.spacePatten,
			function(c)
				r[#r + 1] = c
			end
		)
		local sz = #r
		local ed = r[sz]
		local mid = ""
		for i = (stCnt + 1), (sz - 1) do
			mid = mid..r[i]
		end

		if stCnt == 2 then
			return r[1], r[2], mid, ed
		elseif stCnt == 3 then
			return r[1], r[2], r[3], mid, ed
		else
			return r[1], mid, ed
		end
	end

	env.styleBtn = function(btn) 
		local t = btn:CreateTexture(nil, "ARTWORK")
		t:SetColorTexture(0.3,0.3,0.3,1)
		t:SetAllPoints()
		btn:SetNormalTexture(t)
	end

	env.parse = function(e, cnt, link, pr)
        if pr == nil then return end
        e.randId = e.randId + 1
        local s = "publ"..e.randId.." "..pr.." "..link.." "..cnt
        e.Cmu:SendCommMessage(e.MK, s, e.CNL)
    end

	env.sell = function(e, sid, prs, cnt, link, puber)
        e.membs = {}
		if UnitInRaid("player") then
			local num = GetNumGroupMembers()
			for i = 1, num do
				local nm, rank, _, lvl, _, cls = GetRaidRosterInfo(i)
				local c = RAID_CLASS_COLORS[cls]
				e.membs[nm] = format("|cff%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, nm)
			end
		end
		
		local s = {}
		s.lnk = link
		s.pub = puber
		s.spr = prs
		s.cnt = cnt
		s.sid = sid
		s.idx = 0
		s.aus = {}
		s.inf = ""
		s.lck = 0
		e.tinsert(e.sellings, s)
		if e.showMod == 0 then
			e.showMod = 1
			e.showbs(e)
		end
		e.onCnt(e, 1)
		e.refreshc(e)
    end
	
	env.sync = function(e)
		e.Cmu:SendCommMessage(e.MK, s, e.CNL)
	end
	
	env.findSell = function(e, sid)
		local r = nil
		for _,t in pairs(e.sellings) do
			if t.sid == sid then
				r = t
				break
			end
		end
		return r
	end

	env.onCnt = function(e, dif)
		e.sellCnt = e.sellCnt + dif
		e.baseUI.cntTitle:SetText("在售"..e.sellCnt.."样")
	end

	env.findc = function(e, sid)
		local b = e.baseUI
		if b.cell1 and b.cell1.sid == sid then
			return b.cell1
		end
		
		if b.cell2 and b.cell2.sid == sid then
			return b.cell2
		end
		
		if b.cell3 and b.cell3.sid == sid then
			return b.cell3
		end

		return nil
	end

	env.upc = function(e, sid, buyer, info)
		if e.debug then buyer = buyer..random(30) end
		local s = e.findSell(e, sid)
		if s == nil then return end

		s.idx = s.idx + 1
		local ac = s.aus
		
		local have = false
		for _,v in pairs(ac) do
			if v.b == buyer then
				v.i = s.idx
				have = true
				v.v = info
				break
			end
		end
		if not have then
			e.tinsert(ac, {v=info, i=s.idx, b=buyer})
		end

		e.tsort(ac, function(a, b) return a.i > b.i end)

		local nor = ""
		local pas = ""
		local clrName
		
		for _, nc in pairs(ac) do
			clrName = e.membs[nc.b] or nc.b
			if nc.v == "p" or nc.v == "P" then
				pas = pas.."["..clrName.."]p".."  "
			else
				nor = nor.."["..clrName.."]"..nc.v.."  "
			end
		end
		s.inf = nor.."\n"..pas

		local c = e.findc(e, sid)
		if c then
			c.info:SetText(s.inf)
		else
			e.refreshc(e)
		end
    end

	env.stopc = function(e, sid)
		local i = nil
		for k,t in pairs(e.sellings) do
			if t.sid == sid then
				i = k
				break
			end
		end
		if i then
			e.trm(e.sellings, i)
			e.onCnt(e, -1)
			e.refreshc(e)
		end
	end

	env.pausec = function(e, sid)
		local s = e.findSell(e, sid)
		if s.lck == 0 then
			s.lck = 1
		else
			s.lck = 0
		end

        local c = e.findc(e, sid)
        if c then
            if c.auBtn:IsEnabled() then
                c.auBtn:SetEnabled(false)
                c.auEdit:SetEnabled(false)
                c.auPBtn:SetEnabled(false)
            else
                c.auBtn:SetEnabled(true)
                c.auEdit:SetEnabled(true)
                c.auPBtn:SetEnabled(true)
            end
        end
    end

	env.createc = function(e, id)
        local c = CreateFrame("Frame", nil, e.baseUI, BackdropTemplateMixin and "BackdropTemplate" or nil)
        c.env = e
        c:SetWidth(e.WID - 20)
        c:SetHeight(157)
        c:SetPoint("CENTER", 0, -15 - 165*(id - 2))
		local drop = {
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = true, tileSize = 16, edgeSize = 16,
		}
        c:SetBackdrop(drop)
		c:SetBackdropColor(0.25, 0.25, 0.25, 0.88)
        
        c.title = c:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        c.title:SetPoint("TOPLEFT", c, 10, -2)
		
        c.clsBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        c.clsBtn:SetWidth(70)
        c.clsBtn:SetHeight(28)
        c.clsBtn:SetText("关闭拍卖")
        c.clsBtn:SetPoint("LEFT", c, "RIGHT", -78, 60)
        c.clsBtn.par = c
        c.clsBtn:SetScript("OnClick", function(self)
                local p = self.par
                local msg = "stop"..p.sid
				local w = "结束拍卖"..p.slink
                if p.scount ~= "1" and p.scount ~= 1 then
					w = w.." X"..p.scount.."件"
                end
				SendChatMessage(w, p.env.CNL)
                p.env.Cmu:SendCommMessage(p.env.MK, msg, p.env.CNL)
            end)
		e.styleBtn(c.clsBtn)
        c.pauBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        c.pauBtn:SetWidth(55)
        c.pauBtn:SetHeight(28)
        c.pauBtn:SetText("锁定")
        c.pauBtn:SetPoint("LEFT", c, "RIGHT", -140, 60)
        c.pauBtn.par = c
        c.pauBtn:SetScript("OnClick", function(self)
                local p = self.par
                local msg = "paus"..p.sid
                p.env.Cmu:SendCommMessage(p.env.MK, msg, p.env.CNL)
            end)
		e.styleBtn(c.pauBtn)
		
		local iconFr = CreateFrame("Frame", nil, c, BackdropTemplateMixin and "BackdropTemplate" or nil)
		iconFr.par = c
		iconFr:SetWidth(e.WID - 20)
        iconFr:SetHeight(28)
        iconFr:SetPoint("TOPLEFT", 0, -28)
        c.icon = iconFr:CreateTexture()
        c.icon:SetTexCoord(0, 1, 0, 1)
        c.icon:Show()
        c.icon:SetPoint("TOPLEFT", iconFr, "TOPLEFT", 5, 0)
        c.icon:SetWidth(28)
        c.icon:SetHeight(28)

        c.text = iconFr:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        c.text:SetPoint("LEFT", c.icon, "RIGHT", 3, 0)
		
		iconFr:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self.par, "ANCHOR_RIGHT",0,-200)
                GameTooltip:SetHyperlink(self.par.slink)
                GameTooltip:Show()
        end)
        
        iconFr:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        end)
        
        c.info = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        c.info:SetPoint("LEFT", c.icon, "LEFT", 0, -35)
        c.info:SetWidth(e.WID - 40)
        c.info:SetHeight(80)

        local auText = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        auText:SetPoint("BOTTOM", c.icon, "BOTTOM", 2, -100)
        auText:SetWidth(70)
        auText:SetHeight(33)
        auText:SetText("出价:")
        
        c.auEdit = CreateFrame("EditBox", nil, c, "InputBoxTemplate")
        c.auEdit:SetWidth(120)
        c.auEdit:SetHeight(45)
        c.auEdit:SetPoint("RIGHT", auText, "RIGHT", 120, 0)
        c.auEdit:SetAutoFocus(false)
        c.auEdit:SetMaxLetters(20)
        c.auEdit:SetScript("OnEnterPressed", c.auEdit.ClearFocus)
        
        c.auBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        c.auBtn:SetWidth(52)
        c.auBtn:SetHeight(28)
        c.auBtn:SetText("发送")
        c.auBtn:SetPoint("RIGHT", c.auEdit, "RIGHT", 62, 0)
		e.styleBtn(c.auBtn)
        c.auBtn.par = c
		c.ts = time()
        c.auBtn:SetScript("OnClick", function(self)
                local p = self.par
				local cur = time()
				
				if cur - p.ts > .2 then
				    p.auEdit:ClearFocus()
					local ed = p.auEdit:GetText()
					if ed ~= "" then
						local msg = "buys"..p.sid.." "..p.auEdit:GetText()
						p.env.Cmu:SendCommMessage(p.env.MK, msg, p.env.CNL)
					end
					
					p.ts = cur
				end
            end)
            
        c.auPBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        c.auPBtn:SetWidth(33)
        c.auPBtn:SetHeight(28)
        c.auPBtn:SetText("P")
        c.auPBtn:SetPoint("RIGHT", c.auBtn, "RIGHT", 40, 0)
        c.auPBtn.par = c
        c.auPBtn:SetScript("OnClick", function(self)
                local p = self.par
				local cur = time()
				if cur - p.ts > .2 then
					p.auEdit:ClearFocus()
					local msg = "buys"..p.sid.." p"
					p.env.Cmu:SendCommMessage(p.env.MK, msg, p.env.CNL)
					p.ts = cur
				end
            end)
		e.styleBtn(c.auPBtn)

		local h = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        h:SetWidth(55)
        h:SetHeight(28)
        h:SetText("等等")
        h:SetPoint("LEFT", c, "RIGHT", -62, -60)
        h.par = c
        h:SetScript("OnClick", function(self)
                local p = self.par
                p.auEdit:ClearFocus()
				SendChatMessage(""..p.slink.." 请等等，容我三思。", p.env.CNL)
            end)
		e.styleBtn(h)
        return c
    end

	env.refreshc = function(e)
		local np = e.mceil(e.sellCnt / 3)
		if np == 0 then np = 1 end

		local cp = e.curPgIdx
		if np < e.curPgIdx then
			e.curPgIdx = np
			cp = np
		end

		e.baseUI.pageText:SetText(""..cp.."/"..np)

		e.baseUI.prevBtn:SetEnabled(cp ~= 1)
		e.baseUI.nextBtn:SetEnabled(cp ~= np)

		local stId = (cp - 1) * 3 + 1
		local t1, t2, t3
		local c1 = e.baseUI.cell1
		local c2 = e.baseUI.cell2
		local c3 = e.baseUI.cell3
		c1:Hide()
		c2:Hide()
		c3:Hide()
		for i,t in pairs(e.sellings) do
			local c = nil
			local ed = nil
			if i == stId then
				c = c1
			elseif (i - 1) == stId then
				c = c2
			elseif (i - 2) == stId then
				c = c3
				ed = 1
			end
			if c then
				c.sid = t.sid
				c.slink = t.lnk
				c.scount = t.cnt
				
				if t.cnt ~= "1" then
					c.title:SetText("由 ["..tostring(e.membs[t.pub]).."] 发布".."  X"..t.cnt.."件")
				else
					c.title:SetText("由 ["..tostring(e.membs[t.pub]).."] 发布")
				end

				c.auEdit:SetText("")
				c.info:SetText(t.inf)
				
				local isEn = true
				if t.lck == 1 then isEn = false end
				c.auBtn:SetEnabled(isEn)
				c.auEdit:SetEnabled(isEn)
				c.auPBtn:SetEnabled(isEn)

				local tex = GetItemIcon(t.lnk)
				local _, itemLink = GetItemInfo(t.lnk)
				if tex then
					c.icon:SetTexture(tex)
				else
					c.icon:SetTexture(nil)
				end
				if itemLink then
					c.text:SetText(tostring(t.spr).."起 "..tostring(itemLink))
				end

				if not c:IsShown() then c:Show() end

				if e.NM == t.pub then
					c.clsBtn:Show()
					c.pauBtn:Show()
				else
					c.clsBtn:Hide()
					c.pauBtn:Hide()
				end
			end
			if ed then
				break
			end
		end
    end
	
	env.showmin = function(e)
		if e.floatBase == nil then
			local base = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
			base.env = e
			base:SetSize(106, 40)
			base:SetPoint("Center", UIParent, 0, 50)
			local title = base:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			title:SetText("自动拍卖")
			title:SetPoint("TOPLEFT", base, 11, -12)
			base:SetBackdrop({                                                
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",  
					tile = true,                                               
					tileSize = 24,                                             
					edgeSize = 24,                                             
					insets = {left = 4, right = 4, top = 6, bottom = 6}      
			})		
			base:EnableMouse(true)                                            
			base:SetMovable(true)       
			base:SetScript("OnDragStart", base.StartMoving)
			base:SetScript("OnDragStop", base.StopMovingOrSizing)
			base:RegisterForDrag("LeftButton")
			
			e.floatBase = base
			
			base.floatBtn = CreateFrame("Button", nil, base, "UIPanelButtonTemplate")

			base.floatBtn:SetWidth(33)
			base.floatBtn:SetHeight(28)
			base.floatBtn:SetText("还原")
			base.floatBtn:SetPoint("LEFT", base, "RIGHT", -35, 0)
			base.floatBtn.par = base
			base.floatBtn:SetScript("OnClick", function(self)
					local p = self.par
					p:Hide()
					p.env.showbs(p.env)
				end)
		else
			e.floatBase:Show()
			if e.baseUI then e.baseUI:Hide() end
		end
	end
	
	env.showbs = function(e)
		if e.baseUI then
			if e.baseUI then e.baseUI:Show() end
			if e.floatBtn then e.floatBtn:Hide() end
			return
		end

		local base = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		base.env = e
		e.baseUI = base
		base:SetSize(e.WID, 530)
		base:SetPoint("Center", UIParent, 0, 50)
		local title = base:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetText("G团自动拍卖助手-by大川")
        title:SetPoint("TOPLEFT", base, 10, -10)
		
		local cntTitle = base:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        cntTitle:SetPoint("TOPLEFT", base, 220, -10)
		base.cntTitle = cntTitle

        base:SetBackdrop({                                                
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",  
                tile = true,                                               
                tileSize = 28,                                             
                edgeSize = 28,                                             
                insets = {left = 6, right = 6, top = 8, bottom = 8}      
        })
        base:EnableMouse(true)                                            
        base:SetMovable(true)       
        base:SetScript("OnDragStart", base.StartMoving)
        base:SetScript("OnDragStop", base.StopMovingOrSizing)
        base:RegisterForDrag("LeftButton")
		
		local sbtn = CreateFrame("Button", nil, base, "UIPanelButtonTemplate")
        sbtn:SetWidth(45)
        sbtn:SetHeight(30)
        sbtn:SetText("缩小")
		sbtn:SetPoint("TOPRIGHT", base, -8, -4)
        sbtn.par = base
        sbtn:SetScript("OnClick", function(self)
                local p = self.par
                p:Hide()
				p.env.showmin(p.env)
            end)
		base.smallBtn = sbtn
		
		local nxt = CreateFrame("Button", nil, base, "UIPanelButtonTemplate")
        nxt:SetWidth(30)
        nxt:SetHeight(30)
        nxt:SetText(">")
		nxt:SetPoint("TOPRIGHT", base, -52, -4)
        nxt.par = base
        nxt:SetScript("OnClick", function(self)
                local p = self.par
				p.env.curPgIdx = p.env.curPgIdx + 1
				p.env.refreshc(p.env)
            end)
		nxt:SetEnabled(false)
		base.nextBtn = nxt
		
		local page = base:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        page:SetWidth(30)
        page:SetHeight(30)
        page:SetText(""..e.curPgIdx)
		page:SetPoint("TOPRIGHT", base, -83, -4)
		base.pageText = page
		
		local prv = CreateFrame("Button", nil, base, "UIPanelButtonTemplate")
        prv:SetWidth(30)
        prv:SetHeight(30)
        prv:SetText("<")
		prv:SetPoint("TOPRIGHT", base, -120, -4)
        prv.par = base
        prv:SetScript("OnClick", function(self)
                local p = self.par
				p.env.curPgIdx = p.env.curPgIdx - 1
				p.env.refreshc(p.env)
            end)
		base.prevBtn = prv
		prv:SetEnabled(false)
		
		local syn = CreateFrame("Button", nil, base, "UIPanelButtonTemplate")
        syn:SetWidth(45)
        syn:SetHeight(30)
        syn:SetText("Syn")
		syn:SetPoint("TOPRIGHT", base, -170, -4)
        syn.par = base
        syn:SetScript("OnClick", function(self)
                local p = self.par
				p.env.sync(e.env)
            end)
		syn:SetEnabled(true)
		base.syncBtn = syn

		base:Show()

		base.cell1 = e.createc(e, 1)
		base.cell2 = e.createc(e, 2)
		base.cell3 = e.createc(e, 3)
		base.cell1:Hide()
		base.cell2:Hide()
		base.cell3:Hide()

		if e.floatBase then e.floatBase:Hide() end
	end
end
