-- Pint's Professions: small widgets (buttons, boxes, a sortable scrolling list, a pop-up menu) - the same ones Pint's Auctions uses.
local ADDON, NS = ...
local UI = {}
NS.UI = UI
local menu
function UI.Money(v, short)
	if not v then return "|cff888888-|r" end
	v = math.floor(v + 0.5)
	local neg = v < 0; v = math.abs(v)
	local g, s, c = math.floor(v / 10000), math.floor(v / 100) % 100, v % 100
	local G, S, C = "|cffffd700g|r", "|cffc7c7cfs|r", "|cffeda55fc|r"
	local t
	if short and g >= 100 then t = g .. G
	elseif g > 0 then t = ("%d%s %02d%s %02d%s"):format(g, G, s, S, c, C)
	elseif s > 0 then t = ("%d%s %02d%s"):format(s, S, c, C)
	else t = c .. C end
	return (neg and "-" or "") .. t
end
function UI.Ago(t)
	if not t then return "" end
	local d = time() - t
	if d < 3600 then return math.max(1, math.floor(d / 60)) .. " min ago" end
	if d < 86400 then return math.floor(d / 3600) .. " hr ago" end
	return math.floor(d / 86400) .. " days ago"
end
local function Btn(parent, text, w, h)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w or 80, h or 22); b:SetText(text)
	return b
end
UI.Btn = Btn
local function Edit(parent, w, numeric)
	local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	e:SetSize(w, 20); e:SetAutoFocus(false); if numeric then e:SetNumeric(true) end
	e:SetScript("OnEscapePressed", e.ClearFocus); e:SetScript("OnEnterPressed", e.ClearFocus)
	return e
end
UI.Edit = Edit
local function Label(parent, text, font)
	local f = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall"); f:SetText(text or "")
	return f
end
UI.Label = Label
local function Tip(frame, title, text)
	frame:HookScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(title); if text then GameTooltip:AddLine(text, 1, 1, 1, true) end; GameTooltip:Show() end)
	frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
UI.Tip = Tip
local QCOL = { [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd", [4] = "a335ee", [5] = "ff8000" }
local function QName(name, q) return "|cff" .. (QCOL[q or 1] or "ffffff") .. (name or "?") .. "|r" end
UI.QName = QName
local function Box(parent)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
	f:SetBackdropColor(0, 0, 0, 0.35); f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
	return f
end

-- a scrolling list; cols = { {width, justify, header}, ... }; data = { { text1, text2, ..., texture = , link = } }
local function List(parent, w, rows, rowH, cols, onClick, noIcon)
	local f = Box(parent)
	f:SetSize(w, rows * rowH + 4)
	f.data, f.offset, f.rows = {}, 0, {}
	local x0 = noIcon and 4 or rowH + 2
	local hx = x0 + 2
	f.heads = {}
	for c, col in ipairs(cols) do
		if col[3] then
			local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); h:SetText(col[3])
			h:SetPoint("BOTTOMLEFT", f, "TOPLEFT", hx, 2); h:SetWidth(col[1] - 4); h:SetJustifyH(col[2] or "LEFT")
			f.heads[c] = h
			-- sortable column: click the header to sort, click again to flip the order
			if col.sort then
				local hb = CreateFrame("Button", nil, f)
				hb:SetPoint("BOTTOMLEFT", f, "TOPLEFT", hx, 0); hb:SetSize(col[1] - 2, 16)
				hb:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
				hb:SetScript("OnClick", function()
					if f.sortCol == c then f.sortDesc = not f.sortDesc else f.sortCol, f.sortDesc = c, (col.sort ~= "asc") end
					if f.onSort then f.onSort(f.sortCol, f.sortDesc) end
					f:Set(f.data)
				end)
				hb:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:AddLine("Click to sort by " .. col[3]); GameTooltip:Show() end)
				hb:SetScript("OnLeave", function() GameTooltip:Hide() end)
			end
		end
		hx = hx + col[1]
	end
	f.cols = cols
	for i = 1, rows do
		local r = CreateFrame("Button", nil, f)
		r:SetSize(w - 4, rowH); r:SetPoint("TOPLEFT", 2, -2 - (i - 1) * rowH)
		r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 0.82, 0, 0.12)
		r.sel = r:CreateTexture(nil, "BACKGROUND"); r.sel:SetAllPoints(); r.sel:SetColorTexture(1, 0.82, 0, 0.22); r.sel:Hide()
		r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(rowH - 2, rowH - 2); r.icon:SetPoint("LEFT", 1, 0)
		r.cells = {}
		local x = x0
		for c, col in ipairs(cols) do
			local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			fs:SetPoint("LEFT", x, 0); fs:SetWidth(col[1] - 4); fs:SetJustifyH(col[2] or "LEFT"); fs:SetWordWrap(false)
			r.cells[c] = fs; x = x + col[1]
		end
		r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		r:SetScript("OnClick", function(self, b) if self.item and onClick then onClick(self.item, b, self) end end)
		r:SetScript("OnEnter", function(self)
			local it = self.item
			if it and it.link then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(it.link); GameTooltip:Show()
			elseif it and it.tip then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(it.tip, 1, 1, 1, true); GameTooltip:Show() end
		end)
		r:SetScript("OnLeave", function() GameTooltip:Hide() end)
		f.rows[i] = r
	end
	f.more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); f.more:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -2, -2)
	f:EnableMouseWheel(true)
	f:SetScript("OnMouseWheel", function(self, d) self.offset = math.max(0, math.min(#self.data - rows, self.offset - d * 3)); self:Refresh() end)
	function f:Refresh()
		for i, r in ipairs(self.rows) do
			local item = self.data[i + self.offset]
			r.item = item
			if item then
				r.icon:SetTexture(item.texture); r.icon:SetShown(item.texture ~= nil)
				for c, fs in ipairs(r.cells) do fs:SetText(item[c] or "") end
				r.sel:SetShown(item == self.selected or (self.selectedKey ~= nil and item.key == self.selectedKey))
				r:Show()
			else r:Hide() end
		end
		self.more:SetText(#self.data > rows and (("%d-%d of %d  (scroll)"):format(self.offset + 1, math.min(#self.data, self.offset + rows), #self.data)) or "")
	end
	function f:Sort()
		local c = self.sortCol
		for i, h in pairs(self.heads) do
			local t = cols[i][3]
			if i == c then t = (cols[i][2] == "RIGHT") and ((self.sortDesc and "v " or "^ ") .. t) or (t .. (self.sortDesc and " v" or " ^")) end
			h:SetText(t)
		end
		if not c then return end
		local desc = self.sortDesc
		local function v(it) local k = it.sk and it.sk[c]; if k == nil then k = it[c] end; return k end
		table.sort(self.data, function(a, b)
			local x, y = v(a), v(b)
			if type(x) ~= type(y) then x, y = tostring(x), tostring(y) end
			if x == y then return (a.name or "") < (b.name or "") end
			if desc then return x > y else return x < y end
		end)
	end
	function f:Set(data, keep) self.data = data or {}; self:Sort(); if not keep then self.offset = 0 else self.offset = math.max(0, math.min(self.offset, #self.data - rows)) end; self:Refresh() end
	return f
end
UI.List = List



-- a small pop-up menu
local menu
local function Menu(anchor, items)
	if not menu then
		menu = CreateFrame("Frame", "PintsProfessionsMenu", UIParent, "BackdropTemplate")
		menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetClampedToScreen(true); menu:EnableMouse(true)
		menu:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
		menu:SetBackdropColor(0, 0, 0, 0.95); menu.b = {}
		tinsert(UISpecialFrames, "PintsProfessionsMenu")
	end
	for i, it in ipairs(items) do
		local b = menu.b[i]
		if not b then
			b = CreateFrame("Button", nil, menu); b:SetSize(240, 16); b:SetPoint("TOPLEFT", 8, -6 - (i - 1) * 16)
			b.t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.t:SetPoint("LEFT", 4, 0)
			local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 0.82, 0, 0.18)
			b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			menu.b[i] = b
		end
		b.t:SetText(it.text); b:EnableMouse(it.fn ~= nil)
		b:SetScript("OnClick", function(_, btn) menu:Hide(); if it.fn then it.fn(btn) end end)
		b:Show()
	end
	for i = #items + 1, #menu.b do menu.b[i]:Hide() end
	menu:SetSize(256, #items * 16 + 12)
	menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2); menu:Show()
end
UI.Menu = Menu
