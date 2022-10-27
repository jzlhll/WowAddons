aura_env.beInit = false
aura_env.ssub = string.sub
aura_env.debug = true
	
aura_env.init = function(env)
	if env.beInit then
		return
	end

	env.baseShowMode = -1
	if env.debug then 
		env.CNL = "SAY"
	else
		env.CNL = "RAID"
	end

	env.beInit = true
	
	env.WID = 600
	
	env.cells = {}
	env.cellsNum = 0
	env.ssplit = string.split
	env.slen = string.len
	env.sgsub = string.gsub
	env.tsort = table.sort
	env.tinsert = table.insert
	env.members = nil
	env.randId = random(1000)
	env.sellings = {}
	
	env.pageIndex = 1
	e.sellCnt = 0
	
	env.Cmu = LibStub:GetLibrary("AceComm-3.0")
    env.Cmu:RegisterComm("AllanAtSell", function(prefix, message, _, sname) end)
	env.spacePatten = string.format("([^%s]+)", ' ')
	
	env.myStrSplit = function(e, str)
		local r = {}
		e.sgsub(str, e.spacePatten,
			function(c)
				r[#r + 1] = c
			end
		)
		return r
	end
	
	env.styleGray = function(btn) 
		local t = btn:CreateTexture(nil, "ARTWORK")
		t:SetColorTexture(0.3,0.3,0.3,1)
		t:SetAllPoints()
		btn:SetNormalTexture(t)
	end

	env.parse = function(e, msg)
		local r = e.myStrSplit(e, msg)
		local sz = #r
		local pre,link,pr
		if sz == 3 then
			pre = r[1]
			link = r[2]
			pr = r[3]
		elseif sz == 5 then
			pre = r[1]
			link = r[2]..r[3]..r[4]
			pr = r[5]
		elseif sz == 7 then
			pre = r[1]
			link = r[2]..r[3]..r[4]..r[5]..r[6]
			pr = r[7]
		end

        if pr == nil then return end
        e.randId = e.randId + 1

		local cnt = ""
		for i = e.slen(pre), 1, -1 do
			local c = e.ssub(pre, i , i)
			if c == 'l' then break end
			cnt = e.ssub(pre, i , i)..cnt
		end
		if cnt == "" then cnt = "1" end
        local s = "publish("..e.randId..") "..pr.." "..cnt.." "..link
        e.Cmu:SendCommMessage("AllanAtSell", s, e.CNL)
    end
	
	env.sell = function(e, msg, pubName)
		local r = e.myStrSplit(e, msg)
		local sz = #r
        local pub,prs,cnt,link
		if sz == 4 then
			pub = r[1]
			prs = r[2]
			cnt = r[3]
			link = r[4]
		elseif sz == 6 then
			pub = r[1]
			prs = r[2]
			cnt = r[3]
			link = r[4]..r[5]..r[6]
		elseif sz == 8 then
			pub = r[1]
			prs = r[2]
			cnt = r[3]
			link = r[4]..r[5]..r[6]..r[7]..r[8]
		end

        local sid = e.ssub(pub, 9, -2)

        e.members = {}
		if UnitInRaid("player") then
			local num = GetNumGroupMembers()
			for i = 1, num do
				local nm, rank, _, lvl, _, cls = GetRaidRosterInfo(i)
				local c = RAID_CLASS_COLORS[cls]
				e.members[nm] = format("|cff%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, nm)
			end
		end
		
		e.sellings[sid] = {
		}
		local s = e.sellings[sid]
		s.link = link
		s.publishName = pubName
		s.startPrice = prs
		s.count = cnt
        
		if e.baseShowMode == -1 then
			e.baseShowMode = 1
			e.showBase(e)
		end
		
		e.sellCnt = e.sellCnt + 1

		e.refreshCells(e)

		e.baseUI.cntTitle:SetText("在售"..e.sellCnt.."样")
    end

	env.findCell = function(e, sid)
		local it = nil
        for i=1,e.cellsNum do
			local c = e.cells[i]
            if c.sid ~= nil and c.sid == sid then
                it = c
                break
            end
        end
		return it
	end

	env.upCell = function(e, sid, buy, info)
		if e.debug then buy = buy..random(30) end
		local selling = e.sellings[sid]
		if selling == nil then return end
		if selling.auctions == nil then
			selling.auctions = {}
			selling.idx = 0
		end
		selling.idx = selling.idx + 1
		local ac = selling.auctions
		
		local have = false
		for _,v in pairs(ac) do
			if v.b == buy then
				v.i = selling.idx
				have = true
				v.v = info
				break
			end
		end
		if not have then
			e.tinsert(ac, {v=info, i=selling.idx, b=buy})
		end

		e.tsort(ac, function(a, b) return a.i > b.i end)

		local nor = ""
		local pass = ""
		local clrName
		
		for _, nc in pairs(ac) do
			clrName = e.members[nc.b] or nc.b
			if nc.v == "p" or nc.v == "P" then
				pass = pass.."["..clrName.."]p".."  "
			else
				nor = nor.."["..clrName.."]"..nc.v.."  "
			end
		end
		selling.infoText = nor.."\n"..pass

		local cell = e.findCell(e, sid)
		if cell then
			cell.info:SetText(selling.infoText)
		end
    end

	env.stopCell = function(e, sid)
		for i=1,e.cellsNum do
			local c = e.cells[i]
            if c.sid ~= nil then
                c:Hide()
				c.sid = nil
            end
        end
		
		print("after stop Cell and change it ")
		if e.sellCnt then
			e.sellCnt = e.sellCnt - 1
			print("todo page")
			e.baseUI.cntTitle:SetText("在售"..e.sellCnt.."件")
		end
	end
	
	env.pauseCell = function(e, sid)
        local it = e.findCell(e, sid)
        if it then
            if it.auBtn:IsEnabled() then
                it.auBtn:SetEnabled(false)
                it.auEdit:SetEnabled(false)
                it.auPBtn:SetEnabled(false)
            else
                it.auBtn:SetEnabled(true)
                it.auEdit:SetEnabled(true)
                it.auPBtn:SetEnabled(true)
            end
        end
    end
	
	env.createCell = function(e, id)
        local c = CreateFrame("Frame", nil, e.baseUI, BackdropTemplateMixin and "BackdropTemplate" or nil)
        c.env = e
        c:SetWidth(e.WID - 20)
        c:SetHeight(157)
        c:SetPoint("CENTER", 0, 0 - 165*(id - 1))
		local drop = {
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = true, tileSize = 16, edgeSize = 16,
		}
        c:SetBackdrop(drop)
		c:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
        
        c.title = c:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        c.title:SetPoint("TOPLEFT", c, 10, -2)
		
        c.ownClsBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        c.ownClsBtn:SetWidth(70)
        c.ownClsBtn:SetHeight(28)
        c.ownClsBtn:SetText("关闭拍卖")
        c.ownClsBtn:SetPoint("LEFT", c, "RIGHT", -78, 60)
        c.ownClsBtn.parent = c
        c.ownClsBtn:SetScript("OnClick", function(self)
                local p = self.parent
                local msg = "atstop("..p.sid..")"
                if p.scount == "1" or p.scount == 1 then
                    SendChatMessage("结束拍卖"..p.slink, p.env.CNL)
                else
                    SendChatMessage("结束拍卖"..p.slink.." X"..p.scount.."件", p.env.CNL)
                end
                p.env.Cmu:SendCommMessage("AllanAtSell", msg, p.env.CNL)
            end)
		e.styleGray(c.ownClsBtn)
        c.ownPauBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        c.ownPauBtn:SetWidth(55)
        c.ownPauBtn:SetHeight(28)
        c.ownPauBtn:SetText("锁定")
        c.ownPauBtn:SetPoint("LEFT", c, "RIGHT", -140, 60)
        c.ownPauBtn.parent = c
        c.ownPauBtn:SetScript("OnClick", function(self)
                local p = self.parent
                local msg = "atpause("..p.sid..")"
                p.env.Cmu:SendCommMessage("AllanAtSell", msg, p.env.CNL)
            end)
		e.styleGray(c.ownPauBtn)
		
		local iconFr = CreateFrame("Frame", nil, c, BackdropTemplateMixin and "BackdropTemplate" or nil)
		iconFr.parent = c
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
                GameTooltip:SetOwner(self.parent, "ANCHOR_RIGHT",0,-200)
                GameTooltip:SetHyperlink(self.parent.slink)
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
		e.styleGray(c.auBtn)
        c.auBtn.parent = c
		c.ts = time()
        c.auBtn:SetScript("OnClick", function(self)
                local p = self.parent
				local cur = time()
				
				if cur - p.ts > .2 then
				    p.auEdit:ClearFocus()
					local ed = p.auEdit:GetText()
					if ed ~= "" then
						local msg = "(sid"..p.sid..") "..p.auEdit:GetText()
						p.env.Cmu:SendCommMessage("AllanAtSell", msg, p.env.CNL)
					end
					
					p.ts = cur
				end
            end)
            
        c.auPBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        c.auPBtn:SetWidth(33)
        c.auPBtn:SetHeight(28)
        c.auPBtn:SetText("P")
        c.auPBtn:SetPoint("RIGHT", c.auBtn, "RIGHT", 40, 0)
        c.auPBtn.parent = c
        c.auPBtn:SetScript("OnClick", function(self)
                local p = self.parent
				local cur = time()
				
				if cur - p.ts > .2 then
					p.auEdit:ClearFocus()
					local msg = "(sid"..p.sid..") p"
					p.env.Cmu:SendCommMessage("AllanAtSell", msg, p.env.CNL)
					
					p.ts = cur
				end
            end)
		e.styleGray(c.auPBtn)

		local holdBtn = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
        holdBtn:SetWidth(55)
        holdBtn:SetHeight(28)
        holdBtn:SetText("等等")
        holdBtn:SetPoint("LEFT", c, "RIGHT", -62, -60)
        holdBtn.parent = c
        holdBtn:SetScript("OnClick", function(self)
                local p = self.parent
                p.auEdit:ClearFocus()
				SendChatMessage(""..p.slink.." 请等等，容我三思。", "RAID")
            end)
		e.styleGray(holdBtn)
        return c
    end
	
	env.refreshCells = function(e)
		local off = e.sellCnt % 3
		local pages = e.sellCnt / 3
		local upPage = false
		if off > 0 then
			pages = pages + 1
			upPage = true
		end
		
		local curPage = tonumber(e.baseUI.pageText:GetText())
		e.baseUI.pageText:SetText(""..pages)
		
		if e.pageIndex == pages then
			
		end
		
		local link, pubName, stPrice, count	= sidInfo.link, sidInfo.publishName, sidInfo.startPrice, sidInfo.count

        local cell = e.reuseCell(e)
        if cell == nil then
            cell = aura_env.createCell(e)
			local id = e.cellsNum + 1
			e.cells[id] = cell
			e.cellsNum = id
        end

        cell.sid = sid
        cell.slink = link
        cell.scount = count

        
		if count ~= "1" then
			cell.title:SetText("由 ["..tostring(e.members[pubName]).."] 发布".."  X"..count.."件")
		else
			cell.title:SetText("由 ["..tostring(e.members[pubName]).."] 发布")
		end

        cell.auEdit:SetText("")
        cell.info:SetText("")
        cell.text:SetText("")
        cell.auBtn:SetEnabled(true)
        cell.auEdit:SetEnabled(true)
        cell.auPBtn:SetEnabled(true)

        local tex = GetItemIcon(link)
        local _, itemLink = GetItemInfo(link)
        if tex then
            cell.icon:SetTexture(tex)
        else
            cell.icon:SetTexture(nil)
        end

        if itemLink then
            cell.text:SetText(tostring(itemLink).." 起价"..tostring(stPrice))
        end

        if not cell:IsShown() then cell:Show() end

        if UnitName("player") == pubName then
            cell.ownClsBtn:Show()
            cell.ownPauBtn:Show()
        else
            cell.ownClsBtn:Hide()
            cell.ownPauBtn:Hide()
        end
    end
	
	env.showSmall = function(e)
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
			base.floatBtn.parent = base
			base.floatBtn:SetScript("OnClick", function(self)
					local p = self.parent
					p:Hide()
					p.env.showBase(p.env)
				end)
		else
			e.floatBase:Show()
			if e.baseUI then e.baseUI:Hide() end
		end
	end
	
	env.showBase = function(e)
		if e.baseUI then
			if e.baseUI then e.baseUI:Show() end
			if e.floatBtn then e.floatBtn:Hide() end
			return
		end

		local base = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		base.env = e
		e.baseUI = base
		base:SetSize(e.WID, 520)
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
		sbtn:SetPoint("TOPRIGHT", base, -10, -4)
        sbtn.parent = base
        sbtn:SetScript("OnClick", function(self)
                local p = self.parent
                p:Hide()
				p.env.showSmall(p.env)
            end)
		base.smallBtn = sbtn
		
		local nxt = CreateFrame("Button", nil, base, "UIPanelButtonTemplate")
        nxt:SetWidth(30)
        nxt:SetHeight(30)
        nxt:SetText(">")
		nxt:SetPoint("TOPRIGHT", base, -44, -4)
        nxt.parent = base
        nxt:SetScript("OnClick", function(self)
                local p = self.parent
            end)
		nxt:SetEnabled(false)
		base.nextBtn = nxt
		
		local page = base:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        page:SetWidth(30)
        page:SetHeight(30)
        page:SetText(""..e.pageIndex)
		page:SetPoint("TOPRIGHT", base, -70, -4)
		base.pageText = page
		
		local prv = CreateFrame("Button", nil, base, "UIPanelButtonTemplate")
        prv:SetWidth(30)
        prv:SetHeight(30)
        prv:SetText(">")
		prv:SetPoint("TOPRIGHT", base, -100, -4)
        prv.parent = base
        prv:SetScript("OnClick", function(self)
                local p = self.parent
            end)
		base.prevBtn = prv
		prv:SetEnabled(false)

		base:Show()

		base.cell1 = e.createCell(e, 1)
		base.cell2 = e.createCell(e, 2)
		base.cell3 = e.createCell(e, 3)
		base.cell1:Hide()
		base.cell2:Hide()
		base.cell3:Hide()

		if e.floatBase then e.floatBase:Hide() end
	end
end
