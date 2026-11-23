-- Pint's Professions: the cheapest way to level a profession, and Flip - what to craft (or buy) and sell for a profit.
-- Works anywhere: prices come from your Pint's Auctions full scans (saved, so the guide is there away from the auction
-- house too), and after each new full scan everything is worked out again. Optionally uses up the reagents already in
-- your bags and bank first. /pprof
local ADDON, NS = ...
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo      -- (WoW Forever: the old one answers nothing)
local GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local GetSpellInfo = GetSpellInfo or function(id)
	local i = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
	if i then return i.name, nil, i.iconID end
end
local UI = NS.UI
local PROF = NS.PROF
local Money = UI.Money
local P = {}
_G.PintsProfessions = P
local function AH() return _G.PintsAuctions end            -- Pint's Auctions, when it's loaded
local function Print(m) print("|cffd4a017Pint's Professions:|r " .. m) end

local NAMES = { [171] = "Alchemy", [164] = "Blacksmithing", [333] = "Enchanting", [202] = "Engineering", [165] = "Leatherworking",
	[197] = "Tailoring", [185] = "Cooking", [129] = "First Aid", [186] = "Mining (smelting)", [40] = "Poisons" }
local ORDER = { 171, 164, 333, 202, 165, 197, 185, 129, 186, 40 }
local LINE_OF = {}
for id, n in pairs(NAMES) do LINE_OF[n] = id end
LINE_OF["Mining"] = 186; LINE_OF["Smelting"] = 186
-- training ranks: past these you need the next rank from a trainer (and the character level it asks for)
local RANKS = { { 75, "Journeyman", 10 }, { 150, "Expert", 20 }, { 225, "Artisan", 35 } }

-- reagents vendors sell (approximate prices; the real ones replace these as soon as you visit a vendor that sells them)
local VENDOR = {
	[2320] = 10, [2321] = 100, [4291] = 500, [8343] = 2000, [14341] = 5000,                  -- threads
	[2324] = 25, [2604] = 50, [6260] = 50, [2605] = 100, [4340] = 350, [4341] = 500, [2325] = 1000, [4342] = 2500, [10290] = 2500, -- bleach, dyes
	[3371] = 4, [3372] = 40, [8925] = 200, [18256] = 2000,                                    -- vials
	[2678] = 10, [2692] = 40, [3713] = 160, [2665] = 20, [159] = 25, [1179] = 125, [2596] = 50, [2894] = 50, -- cooking
	[4470] = 38, [2880] = 100, [3466] = 2000, [3857] = 500, [4289] = 50, [6217] = 124,       -- wood, flux, coal, salt, copper rod
	[4399] = 200, [4400] = 2000, [10647] = 2000, [10648] = 125,                               -- engineering
	[2928] = 20, [8924] = 100, [2930] = 20, [8923] = 300, [5140] = 25,                        -- poisons
}
-- WoW Forever: what vendors charge there (Wowhead's WoW Forever item pages, November 2026) - Forever raised some (vials, water,
-- spices) and stopped selling others (nil)
if type(issecretvalue) == "function" then
	for id, p in pairs({ [159] = 25, [1179] = 125, [2320] = 10, [2321] = 100, [2324] = 25, [2325] = 1000, [2596] = 120, [2604] = 50, [2605] = 100, [2665] = false, [2678] = 10, [2692] = 40, [2880] = 100, [2894] = 50, [3371] = 20, [3372] = 200, [3466] = 2000, [3713] = 168, [3857] = 500, [4289] = 50, [4291] = 500, [4340] = 350, [4341] = 500, [4342] = 2500, [4399] = 200, [4400] = 2000, [4470] = 38, [4536] = 25, [6260] = 50, [6261] = 1000, [6530] = 100, [8343] = 2000, [8925] = 2500, [10290] = 2500, [10647] = 2000, [10648] = 500, [14341] = 5000, [17034] = 200, [17035] = 400, [17194] = 10, [17196] = 50, [18256] = 30000 }) do VENDOR[id] = p or nil end
end

local function RF() return (GetRealmName() or "?") .. " " .. (UnitFactionGroup("player") or "") end
-- this add-on's own saved data (skill-up colours seen, vendor prices, skill-up log); prices come from Pint's Auctions'
local function DB()
	PintsProfessionsDB = PintsProfessionsDB or {}
	return PintsProfessionsDB
end
local function AHDB() return _G.PintsAuctionsDB end
local function CDB()
	PintsProfessionsCharDB = PintsProfessionsCharDB or {}
	local c = PintsProfessionsCharDB
	c.known = c.known or {}; c.skill = c.skill or {}; c.plan = c.plan or {}
	return c
end
-- first run: bring over what the planner saved while it lived inside Pint's Auctions
local function Migrate()
	local d, a = DB(), AHDB()
	if not d.migrated and a then
		for _, k in ipairs({ "colors", "skillups", "vendorBuy", "sellPrice" }) do
			if a[k] and not d[k] then d[k] = a[k] end
			a[k] = nil
		end
	end
	d.migrated = true
	local c, ac = CDB(), _G.PintsAuctionsCharDB
	if ac and not c.migrated then
		for _, k in ipairs({ "known", "skill", "plan" }) do
			if type(ac[k]) == "table" and not next(c[k]) then c[k] = ac[k] end
			ac[k] = nil
		end
	end
	c.migrated = true
end

---------------------------------------------------------------- prices
-- the latest lowest price of an item (Pint's Auctions' price list)
function P.Lowest(id)
	local A = AH()
	if A and A.Price and A.db then return (A.Price(id)) end
	local d = AHDB()
	local s = d and d.prices and d.prices[RF()]
	local e = s and s[tostring(id)]
	return e and e.m or nil
end
local function VendorBuy(id)
	local d = DB()
	local v = d and d.vendorBuy and d.vendorBuy[id]
	return v or VENDOR[id], v == nil and VENDOR[id] ~= nil
end
local function LastScan(id)
	local d = AHDB()
	local s = d and d.scans and d.scans[RF()]
	local h = s and s[tostring(id)]
	return type(h) == "table" and h[#h] or nil      -- { time, market price, lowest, how many listed }
end
-- the auction house price to BUY a pile: the market price of the last full scan (the lowest is often just one)
local function AHBuy(id)
	local e = LastScan(id)
	if e and e[2] and e[2] > 0 then return e[2], e[4] end
	return P.Lowest(id), nil
end
-- what you'd get SELLING one on the auction house if the market holds: the lowest listing, less the 5% the house keeps
local function AHSell(id)
	local p = P.Lowest(id)
	local e = LastScan(id)
	if e and e[3] and e[3] > 0 then p = e[3] end
	return p and math.floor(p * 0.95) or nil
end
-- what a vendor pays: remembered once known (account-wide), so lists don't keep changing while the game loads items
local asked, loading = {}, 0
local function VendorSell(id)
	local d = DB()
	local m = d and d.sellPrice
	if m and m[id] ~= nil then return m[id] > 0 and m[id] or nil end
	local sp = select(11, GetItemInfo(id))
	if sp then
		if d then d.sellPrice = d.sellPrice or {}; d.sellPrice[id] = sp end
		return sp > 0 and sp or nil
	end
	if not asked[id] then
		asked[id] = true; loading = loading + 1
		if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
	end
end
P.Loading = function() return loading end
P.AHBuy, P.AHSell, P.VendorBuy = AHBuy, AHSell, VendorBuy

---------------------------------------------------------------- what's in your bags and bank
-- With "use what I have" on, reagents you already own count at what a vendor would pay for them (what you'd get
-- otherwise), so the guide uses them up first - and frees the bag space.
local STOCK            -- while working something out with your own reagents: item -> how many are left to use
local function Have(id)
	local n = 0
	local ok, c = pcall(GetItemCount, id, true)         -- bags and bank (the game remembers your bank)
	if ok and type(c) == "number" then n = c end
	-- Pint's Alts' record of this character's bags and bank (a bank you haven't opened this session)
	local L = _G.PintsLedgerDB
	local rec = L and L.chars and L.chars[GetRealmName() or ""] and L.chars[GetRealmName() or ""][UnitName("player") or ""]
	local it = rec and rec.items
	if it then local a = ((it.bags or {})[id] or 0) + ((it.bank or {})[id] or 0); if a > n then n = a end end
	return n
end
local function Stock(id)
	if not STOCK then return 0 end
	local v = STOCK[id]
	if v == nil then v = Have(id); STOCK[id] = v end
	return v
end
P.Have = Have

---------------------------------------------------------------- what each recipe costs to make
local madeBy = {}               -- item -> { spell, ... } (to make a reagent yourself when that's cheaper)
for sp, r in pairs(PROF) do if r[2] > 0 then madeBy[r[2]] = madeBy[r[2]] or {}; table.insert(madeBy[r[2]], sp) end end

local cache, missing = {}, {}
-- cheapest way to get one of an item: { price, "ah" | "vendor" | "craft", spell }
local Cost
local function CraftCost(sp, depth)
	local r = PROF[sp]
	local total = 0
	local regs = r[7]
	for i = 1, #regs, 2 do
		local c = Cost(regs[i], depth + 1)
		if not c then missing[regs[i]] = true; return nil end
		total = total + c[1] * regs[i + 1]
	end
	return total
end
Cost = function(id, depth)
	depth = depth or 0
	local hit = cache[id]
	if hit ~= nil then return hit or nil end
	local best
	if STOCK and Stock(id) > 0 then best = { VendorSell(id) or 0, "have" } end
	local v = VendorBuy(id)
	if v and (not best or v < best[1]) then best = { v, "vendor" } end
	local a = AHBuy(id)
	if a and (not best or a < best[1]) then best = { a, "ah" } end
	if depth < 3 and madeBy[id] then
		cache[id] = false                     -- (no loops)
		for _, sp in ipairs(madeBy[id]) do
			local c = CraftCost(sp, depth)
			if c then
				c = c / math.max(1, PROF[sp][3])
				if not best or c < best[1] then best = { c, "craft", sp } end
			end
		end
	end
	cache[id] = best or false
	return best
end
P.Cost = function(id) return Cost(id, 0) end
local adj = {}                  -- recipe -> its skill-up colour points, fitted to what you've seen
local function Reset() wipe(cache); wipe(missing); wipe(adj) end

---------------------------------------------------------------- what this character knows and their skill
local function ScanSkills()
	local c = CDB()
	if GetNumSkillLines then
		for i = 1, GetNumSkillLines() do
			local name, header, _, rank, _, _, max = GetSkillLineInfo(i)
			local line = name and not header and LINE_OF[name]
			if line then c.skill[line] = { rank, max } end
		end
	end
	if GetProfessions and GetProfessionInfo then
		for _, ix in ipairs({ GetProfessions() }) do
			if ix then
				local name, _, rank, max, _, _, line = GetProfessionInfo(ix)
				line = (line and NAMES[line] and line) or (name and LINE_OF[name])
				if line then c.skill[line] = { rank, max } end
			end
		end
	end
end
-- the skill-up colours each recipe really shows in your profession window, at the skill you had (account-wide).
-- WoW Forever changed some of them (Bolt of Silk Cloth goes grey far earlier than in Classic), so what you've seen wins.
local COL = { optimal = "o", medium = "y", easy = "g", trivial = "x", [0] = "o", [1] = "y", [2] = "g", [3] = "x" }
local function Observe(sp, kind, rank)
	local c = COL[kind]
	local d = DB()
	if not (c and rank and sp and PROF[sp] and d) then return end
	d.colors = d.colors or {}
	local o = d.colors[sp] or {}
	o[c .. "1"] = math.min(o[c .. "1"] or rank, rank)
	o[c .. "2"] = math.max(o[c .. "2"] or rank, rank)
	d.colors[sp] = o
end
-- orange from, yellow from, grey from for a recipe: the built-in numbers, moved to fit what you've seen
local function T(sp)
	local hit = adj[sp]
	if hit then return hit end
	local r = PROF[sp]
	local o, y, g = r[4], r[5], r[6]
	local seen = DB() and DB().colors and DB().colors[sp]
	if seen then
		o = math.min(o, seen.o1 or o, seen.y1 or o, seen.g1 or o)       -- learnable earlier than the built-in number
		if seen.o2 then y = math.max(y, seen.o2 + 1) end                -- still orange at this skill
		if seen.y1 then y = math.min(y, seen.y1) end                    -- already yellow here
		local notGrey = math.max(seen.o2 or 0, seen.y2 or 0, seen.g2 or 0)
		if seen.x1 and seen.x1 > notGrey then g = math.min(g, seen.x1) end   -- grey here
		g = math.max(g, notGrey + 1)
		if seen.g1 then y = math.min(y, seen.g1) end
		y = math.max(o, math.min(y, g - 1))
	end
	hit = { nil, nil, nil, o, y, g }
	adj[sp] = hit
	return hit
end
P.T = T
local function SpellFromLink(l) return l and tonumber(l:match("enchant:(%d+)") or l:match("spell:(%d+)")) end
local function ScanBook()
	local c = CDB()
	local function save(name, n, linkFn)
		local line = name and LINE_OF[name]
		if not line or not n or n == 0 then return end
		local k = c.known[line] or {}
		for i = 1, n do
			local ok, l = pcall(linkFn, i)
			local sp = ok and SpellFromLink(l)
			if sp then k[sp] = true end
		end
		c.known[line] = k
	end
	if GetTradeSkillLine and GetNumTradeSkills and GetTradeSkillRecipeLink then
		local name, rank, max = GetTradeSkillLine()
		local line = name and LINE_OF[name]
		if line and rank then c.skill[line] = { rank, max } end
		save(name, GetNumTradeSkills(), GetTradeSkillRecipeLink)
		if line and rank and GetTradeSkillInfo then
			for i = 1, GetNumTradeSkills() do
				local _, kind = GetTradeSkillInfo(i)
				local ok, l = pcall(GetTradeSkillRecipeLink, i)
				if ok then Observe(SpellFromLink(l), kind, rank) end
			end
		end
	elseif C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
		-- WoW Forever: the modern profession window
		local info = C_TradeSkillUI.GetChildProfessionInfo and C_TradeSkillUI.GetChildProfessionInfo()
		if not (info and info.professionName and info.professionName ~= "") then info = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo() end
		local name = info and (info.parentProfessionName or info.professionName)
		local line = name and LINE_OF[name]
		if not line and name then for n, id in pairs(LINE_OF) do if name:find(n, 1, true) or n:find(name, 1, true) then line = id; break end end end
		local rank = info and info.skillLevel
		if line and rank and rank > 0 then
			c.skill[line] = { rank, info.maxSkillLevel }
			local k = c.known[line] or {}
			for _, id in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
				local r = C_TradeSkillUI.GetRecipeInfo(id)
				if r and r.learned then k[id] = true; Observe(id, r.relativeDifficulty, rank) end
			end
			c.known[line] = k
		end
	end
	if GetCraftDisplaySkillLine and GetNumCrafts and GetCraftRecipeLink then
		local name, rank, max = GetCraftDisplaySkillLine()
		local line = name and LINE_OF[name]
		if line and rank then c.skill[line] = { rank, max } end
		save(name, GetNumCrafts(), GetCraftRecipeLink)
		if line and rank and GetCraftInfo then
			for i = 1, GetNumCrafts() do
				local _, _, kind = GetCraftInfo(i)
				local ok, l = pcall(GetCraftRecipeLink, i)
				if ok then Observe(SpellFromLink(l), kind, rank) end
			end
		end
	end
end
local function Knows(line, sp) local k = CDB().known[line]; return k and k[sp] end
local function KnowsAny(line) local k = CDB().known[line]; return k and next(k) ~= nil end

---------------------------------------------------------------- the levelling guide
-- chance one craft gives a skill point: orange always, yellow to grey falls off, grey never
-- The game's rule is (grey - skill) / (grey - yellow). Your own crafts are also logged (see "skill-up log" below), and once
-- there are enough of them at a point in the yellow-green range, what really happened is blended in.
local BUCKETS = 10
local function Bucket(r, s) return math.min(BUCKETS - 1, math.floor((s - r[5]) / (r[6] - r[5]) * BUCKETS)) end
local function Chance(r, s)
	if s < r[4] or s >= r[6] then return 0 end
	if s < r[5] then return 1 end
	local f = (r[6] - s) / (r[6] - r[5])
	local log = DB() and DB().skillups
	local b = log and log[Bucket(r, s)]
	if b and b[1] >= 30 then f = (b[2] + f * 20) / (b[1] + 20) end      -- (20 crafts' worth of the rule keeps a short run honest)
	return math.max(0.02, math.min(1, f))
end
P.Chance = Chance
-- what you get back for what you make (vendor: for sure; auction house: if the market holds)
local function Back(r, opt)
	if r[2] == 0 then return 0 end
	local best = 0
	if opt.backVendor then best = math.max(best, (VendorSell(r[2]) or 0) * r[3]) end
	if opt.backAH then best = math.max(best, (AHSell(r[2]) or 0) * r[3]) end
	return best
end
local function Usable(line, sp, r, opt)
	if Knows(line, sp) then return true, 0 end
	if r[8] == "t" then return true, r[9] or 0 end
	if r[8] == "v" and opt.vendorRecipes then return true, r[9] or 0 end
	-- a drop or quest recipe someone's selling: what it went for at your last scan
	if opt.ahRecipes and (r[10] or 0) > 0 then
		local price = AHBuy(r[10])
		if price and price > 0 then return true, price, "ah" end
	end
	return false
end
-- recipes the guide leaves out: ones you've right-clicked away, and cooldown recipes (Mooncloth, transmutes) unless asked
local COOLDOWN = { [18560] = true }        -- Mooncloth (a 4-day cooldown on Forever)
local function IsCooldown(sp) return COOLDOWN[sp] or ((GetSpellInfo(sp) or ""):find("^Transmute") and true) or false end
P.IsCooldown = IsCooldown
-- wow-professions.com's Forever guides (WowProfGuide.lua): recipes that need a Loom only a Tailoring 300 can make
local WP = NS.WP
local function NeedsStation(sp)
	if not (WP and WP.station) then return false end
	local n = GetSpellInfo(sp) or ""
	for _, pat in ipairs(WP.station) do if n:find(pat) then return true end end
	return false
end
local function Skipped(sp, opt)
	if opt.skip and opt.skip[sp] then return true end
	return opt.skipCD ~= false and (IsCooldown(sp) or NeedsStation(sp))
end
local function Starts(n, k) return n and k and n:sub(1, #k) == k end
local function WPNote(n)
	if not (WP and n) then return end
	for k, v in pairs(WP.notes) do if Starts(n, k) then return v end end
end
-- their picks for skill a-b: does this recipe agree, and what they'd make there
local function WPPicks(line, n, a, b)
	local list = WP and WP.picks[line]
	if not list then return end
	local agree, names, seen = false, {}, {}
	for _, pk in ipairs(list) do
		if pk[1] < b and pk[2] > a then
			if Starts(n, pk[3]) then agree = true end
			if not seen[pk[3]] then seen[pk[3]] = true; names[#names + 1] = pk[3] .. " (" .. pk[1] .. "-" .. pk[2] .. ")" end
		end
	end
	return agree, names
end
-- plan from skill `from` to `to`: steps { spell, from, to, crafts, cost }, shopping, totals
-- use up `n` of an item from what you have; returns how many are still needed
local function UseUp(id, n, depth, used)
	local h = Stock(id)
	local u = math.min(h, n)
	if u > 0 then
		STOCK[id] = h - u
		if used then used[id] = (used[id] or 0) + u end
		if STOCK[id] <= 0.0001 then STOCK[id] = 0; wipe(cache) end      -- (now it costs what buying it does)
		n = n - u
	end
	return n
end
function P.Plan(line, from, to, opt)
	Reset()
	STOCK = opt.useStock and {} or nil
	local list = {}
	for sp, r in pairs(PROF) do if r[1] == line then list[#list + 1] = sp end end
	local learned, steps, gaps = {}, {}, {}
	local total, train, back = 0, 0, 0
	local cur
	for s = from, to - 1 do
		local best, bestEff, bestP, bestC, bestOne, bestHow
		for _, sp in ipairs(list) do
			local r = PROF[sp]
			local t = T(sp)
			local p = Chance(t, s)
			if p > 0 and not Skipped(sp, opt) then
				local ok, one, how = Usable(line, sp, r, opt)
				if ok then
					local c = CraftCost(sp, 0)
					if c then
						c = c - Back(r, opt)
						one = learned[sp] and 0 or one
						-- a recipe's training is spread over the levels it can still give points for
						local eff = c / p + one / math.max(1, math.min(t[6], to) - s)
						if not bestEff or eff < bestEff then best, bestEff, bestP, bestC, bestOne, bestHow = sp, eff, p, c, one, how end
					end
				end
			end
		end
		if best then
			if not learned[best] then learned[best] = true; train = train + bestOne end
			if STOCK then
				-- what this point uses of your own reagents (and of what they're made of, when you'd make them)
				local r = PROF[best]
				local function Use(id, n, depth)
					n = UseUp(id, n, depth)
					local c = n > 0 and depth < 3 and Cost(id, depth)
					if c and c[2] == "craft" then
						local rr = PROF[c[3]]
						for j = 1, #rr[7], 2 do Use(rr[7][j], n / math.max(1, rr[3]) * rr[7][j + 1], depth + 1) end
					end
				end
				for i = 1, #r[7], 2 do Use(r[7][i], r[7][i + 1] / bestP, 1) end
			end
			-- crafts for this point: on average 1 / chance, give or take (1 - chance) / chance^2 (bad luck adds up over a step)
			local var = (1 - bestP) / (bestP * bestP)
			if cur and cur.spell == best then cur.to = s + 1; cur.crafts = cur.crafts + 1 / bestP; cur.var = cur.var + var; cur.cost = cur.cost + bestC / bestP
			else cur = { spell = best, from = s, to = s + 1, crafts = 1 / bestP, var = var, cost = bestC / bestP, unit = bestC, learn = bestOne, how = bestHow }; steps[#steps + 1] = cur end
		else
			gaps[#gaps + 1] = s; cur = nil
		end
	end
	-- shopping list: every reagent each step needs - from your bags and bank first (when that's on), then made yourself
	-- where that's cheaper (then what goes into it), else bought
	local shop, used = {}, {}
	STOCK = opt.useStock and {} or nil
	wipe(cache)
	local function Need(id, n, depth)
		if STOCK then n = UseUp(id, n, depth, used) end
		if n <= 0.0001 then return end
		local c = Cost(id, depth)
		if c and c[2] == "craft" and depth < 3 then
			local r = PROF[c[3]]
			local times = n / math.max(1, r[3])
			for i = 1, #r[7], 2 do Need(r[7][i], times * r[7][i + 1], depth + 1) end
		else
			shop[id] = (shop[id] or 0) + n
		end
	end
	for _, st in ipairs(steps) do
		-- how many to plan for: the average, plus extra for bad luck (85% sure by default: 1 step in 7 might need more)
		st.avg = st.crafts
		local z = (opt.safety == 0 and 0) or (opt.safety == 95 and 1.645) or 1.04
		st.crafts = math.ceil(st.avg + z * math.sqrt(st.var or 0) - 0.05)
		st.extra = math.max(0, st.crafts - math.ceil(st.avg - 0.05))
		local r = PROF[st.spell]
		for i = 1, #r[7], 2 do Need(r[7][i], st.crafts * r[7][i + 1], 1) end
		total = total + st.cost
		back = back + Back(r, opt) * st.crafts
	end
	STOCK = nil
	wipe(cache)
	return { steps = steps, shop = shop, used = used, total = total, train = train, back = back, gaps = gaps, missing = missing }
end

---------------------------------------------------------------- Flip: craft for a profit
function P.Flips(opt)
	Reset()
	STOCK = opt.flipStock and {} or nil
	local out = {}
	local onlyKnown = opt.flipKnown
	-- buy the mats, craft, sell: only with "Craft and sell" on (and somewhere to sell it)
	local craft = opt.flipCraft ~= false and (opt.flipVendor or opt.flipAH)
	for sp, r in pairs(craft and PROF or {}) do
		if r[2] > 0 and (not onlyKnown or Knows(r[1], sp)) and (onlyKnown or r[8] ~= "o" or Knows(r[1], sp)) then
			local c = CraftCost(sp, 0)
			if c and c > 0 then
				local n = r[3]
				local v = opt.flipVendor and VendorSell(r[2])
				local a = opt.flipAH and AHSell(r[2])
				local pv = v and (v * n - c)
				local pa = a and (a * n - c)
				local best = math.max(pv or -1e12, pa or -1e12)
				if best > 0 then out[#out + 1] = { kind = "craft", spell = sp, item = r[2], n = n, cost = c, vend = v and v * n, ah = a and a * n, pv = pv, pa = pa, best = best } end
			end
		end
	end
	-- no crafting at all: listed for less than a vendor pays for it
	if opt.flipBuyVendor then
		local s = AHDB() and AHDB().prices and AHDB().prices[RF()]
		for key, e in pairs(s or {}) do
			local id = tonumber(key)
			if id and e.m and e.m > 0 then
				local v = VendorSell(id)
				if v and v > e.m then
					local ls = LastScan(id)
					out[#out + 1] = { kind = "buy", item = id, n = 1, cost = e.m, vend = v, pv = v - e.m, best = v - e.m, qty = ls and ls[4] }
				end
			end
		end
	end
	table.sort(out, function(x, y) if x.best ~= y.best then return x.best > y.best end return x.item < y.item end)
	STOCK = nil
	wipe(cache)
	return out
end

---------------------------------------------------------------- buying from here: open it in the auction house's Buy view
-- (the purchase itself is always the game's own Buy button - add-ons may not buy on their own)
local function BuyItem(id, name)
	if not id then return end
	local A = AH()
	if AuctionHouseFrame and AuctionHouseFrame:IsShown() and C_AuctionHouse and C_AuctionHouse.MakeItemKey then
		if A and A.OpenInBuy then A.OpenInBuy(C_AuctionHouse.MakeItemKey(id), name) return true end
	elseif AuctionFrame and AuctionFrame:IsShown() and A and A.SelectTab then
		A.SelectTab("shop"); C_Timer.After(0, function() if A.OpenItem then A.OpenItem({ name = name, key = tostring(id) }) end end)
		return true
	end
	Print("open the auction house to buy.")
end

---------------------------------------------------------------- the window
local win
local function IName(id)
	local name, link, q, _, _, _, _, _, _, tex = GetItemInfo(id)
	if not name and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
	if not tex then tex = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)) or (GetItemIcon and GetItemIcon(id)) end
	if not name and C_Item and C_Item.GetItemNameByID then name = C_Item.GetItemNameByID(id) end
	local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	return (c and c.hex or "|cffffffff") .. (name or ("item " .. id)) .. "|r", link, tex, name
end
local function SName(sp) return (GetSpellInfo(sp)) or ("recipe " .. sp) end
local function Opt()
	local o = CDB().plan
	if o.backVendor == nil then o.backVendor = true end
	if o.vendorRecipes == nil then o.vendorRecipes = true end
	if o.flipVendor == nil then o.flipVendor = true end
	if o.flipAH == nil then o.flipAH = true end
	if o.flipBuyVendor == nil then o.flipBuyVendor = true end
	if o.flipCraft == nil then o.flipCraft = true end
	if o.safety == nil then o.safety = 85 end
	if o.skipCD == nil then o.skipCD = true end
	if o.ahRecipes == nil then o.ahRecipes = true end
	return o
end
local function Check(parent, label, key, onChange, tip)
	local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"); c:SetSize(22, 22)
	local t = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t:SetPoint("LEFT", c, "RIGHT", 0, 1); t:SetText(label)
	c:SetScript("OnShow", function(self) self:SetChecked(Opt()[key] and true or false) end)
	c:SetScript("OnClick", function(self) Opt()[key] = self:GetChecked() and true or false; onChange() end)
	if tip then UI.Tip(c, label, tip) end
	c.label = t
	return c
end
local function ScanAge()
	if not AHDB() then return "|cffff8040no auction prices - Pint's Auctions isn't on (vendor prices only)|r" end
	local t = AHDB().lastAll and AHDB().lastAll[RF()]
	return t and ("prices from the full scan " .. UI.Ago(t)) or "|cffff8040no full scan yet - do one at the auction house (/pah scan)|r"
end

local function BuildLevel(p)
	local Label, Btn, List, Edit = UI.Label, UI.Btn, UI.List, UI.Edit
	local o = Opt()
	o.line = o.line or 197
	local profBtn = Btn(p, "", 170, 22); profBtn:SetPoint("TOPLEFT", 4, -4)
	local fl = Label(p, "From skill", "GameFontNormalSmall"); fl:SetPoint("LEFT", profBtn, "RIGHT", 12, 0)
	local fromBox = Edit(p, 36, true); fromBox:SetPoint("LEFT", fl, "RIGHT", 8, 0); fromBox:SetMaxLetters(3)
	local tl = Label(p, "to", "GameFontNormalSmall"); tl:SetPoint("LEFT", fromBox, "RIGHT", 6, 0)
	local toBox = Edit(p, 36, true); toBox:SetPoint("LEFT", tl, "RIGHT", 8, 0); toBox:SetMaxLetters(3)
	local mine = Btn(p, "Mine", 50, 22); mine:SetPoint("LEFT", toBox, "RIGHT", 6, 0)
	UI.Tip(mine, "Start from your skill", "Uses this character's current skill (open the profession once if it isn't known yet).")
	local go = Btn(p, "Work it out", 100, 22); go:SetPoint("LEFT", mine, "RIGHT", 6, 0)
	local c0 = Check(p, "Use what's in my bags & bank first", "useStock", function() p.OnOpen() end,
		"Reagents you already have count at what a vendor would pay for them (what you'd get for them otherwise), so the guide "
		.. "uses them up first and frees your bag space. The shopping list shows what comes from your bags and what to buy.")
	c0:SetPoint("LEFT", go, "RIGHT", 12, 0)
	local c1 = Check(p, "Count what I can vendor what I make for", "backVendor", function() p.OnOpen() end,
		"Takes off what a vendor pays for everything you make - money you're sure to get back.")
	c1:SetPoint("TOPLEFT", 0, -30)
	local c2 = Check(p, "...or auction it", "backAH", function() p.OnOpen() end,
		"Takes off what it sells for on the auction house instead, when that's more - only if the market holds.")
	c2:SetPoint("LEFT", c1.label, "RIGHT", 14, -1)
	local c3 = Check(p, "Vendor recipes", "vendorRecipes", function() p.OnOpen() end,
		"Also use recipes you can buy from a vendor (their price counts). Drop and quest recipes are used once you know them, "
		.. "or (with Auction recipes) when one is for sale.")
	c3:SetPoint("LEFT", c2.label, "RIGHT", 14, -1)
	local c4 = Check(p, "Auction recipes", "ahRecipes", function() p.OnOpen() end,
		"Also use drop and quest recipes someone is selling on the auction house (what the recipe went for at your last full "
		.. "scan counts, like training does). The step says to buy the recipe there.")
	c4:SetPoint("LEFT", c3.label, "RIGHT", 14, 0)
	-- yellow and green recipes miss sometimes: buy enough that bad luck doesn't leave you short
	local SAFE = { { 0, "Average only" }, { 85, "85% sure" }, { 95, "95% sure" } }
	local safe = Btn(p, "", 150, 22); safe:SetPoint("LEFT", c4.label, "RIGHT", 16, 1)
	UI.Tip(safe, "Extra for bad luck", "Yellow and green recipes don't always give a point. Average only plans for typical luck (half the time you'd need more); "
		.. "85% sure buys enough for all but about 1 run in 7; 95% sure for all but 1 in 20. The extra shows as (+n) in Times.")
	safe:SetScript("OnClick", function()
		local i = 1; for k, v in ipairs(SAFE) do if v[1] == o.safety then i = k end end
		o.safety = SAFE[i % #SAFE + 1][1]; p.OnOpen()
	end)
	p.safe, p.SAFE = safe, SAFE
	local info = Label(p, "", "GameFontHighlightSmall"); info:SetPoint("TOPLEFT", 4, -56); info:SetWidth(770); info:SetJustifyH("LEFT")

	local W = 480
	local steps = List(p, W, 15, 18, {
		{ 70, "LEFT", "Skill" }, { W - 300, "LEFT", "Craft" }, { 50, "RIGHT", "Times" }, { 90, "RIGHT", "Cost" }, { 70, "RIGHT", "Each point" },
	}, function(item, b)
		if item.link and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then ChatEdit_InsertLink(item.link); return end
		if b == "RightButton" and item.spell then
			o.skip = o.skip or {}; o.skip[item.spell] = true
			Print("left out " .. SName(item.spell) .. " - the guide works it out again without it (Put back to undo).")
			p.OnOpen(true)
		end
	end)
	steps:SetPoint("TOPLEFT", 0, -92)
	-- what's left out: right-clicked recipes (Put back returns them) and cooldown recipes
	local back = Btn(p, "Put back", 120, 20); back:SetPoint("TOPLEFT", steps, "BOTTOMLEFT", 0, -4)
	back:SetScript("OnClick", function() if o.skip then wipe(o.skip) end; p.OnOpen(true) end)
	back:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:AddLine("Recipes left out")
		GameTooltip:AddLine("Right-click a step to leave its recipe out of the guide. Click here to put them all back.", 1, 1, 1, true)
		local any
		for sp, v in pairs(o.skip or {}) do if v then GameTooltip:AddLine("  " .. SName(sp), 0.8, 0.8, 0.8); any = true end end
		if not any then GameTooltip:AddLine("  (none)", 0.6, 0.6, 0.6) end
		GameTooltip:Show()
	end)
	back:SetScript("OnLeave", function() GameTooltip:Hide() end)
	p.back = back
	local cd = Check(p, "Leave out cooldown recipes", "skipCD", function() p.OnOpen(true) end,
		"Mooncloth and transmutes can only be made once every few days, so the guide doesn't count on them. On WoW Forever "
		.. "this also leaves out the Cenarion Circle tailoring patterns, which need a Loom only a Tailoring 300 can make.")
	cd:SetPoint("LEFT", back, "RIGHT", 8, 0)
	local SW = 288
	local shop = List(p, SW, 15, 18, { { SW - 190, "LEFT", "Shopping list" }, { 42, "RIGHT", "Have" }, { 42, "RIGHT", "Buy" }, { 84, "RIGHT", "Cost" } },
		function(item, b, row)
			if item.link and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then ChatEdit_InsertLink(item.link); return end
			BuyItem(tonumber(item.key), item.name)
		end)
	shop:SetPoint("TOPLEFT", steps, "TOPRIGHT", 10, 0)
	-- the auction-house part of the shopping list as a Pint's Auctions shopping list (named after the levels it covers)
	p.listBtn = Btn(p, "Build shopping list", 150, 20); p.listBtn:SetPoint("TOPRIGHT", shop, "BOTTOMRIGHT", 0, -4)
	p.listBtn:SetScript("OnClick", function()
		local A = _G.PintsAuctions
		if not (A and A.db and A.db.lists) then Print("the shopping list goes into Pint's Auctions - it isn't loaded."); return end
		if not (p.buyList and #p.buyList > 0) then Print("nothing to buy at the auction house for this."); return end
		local terms = {}
		for _, b in ipairs(p.buyList) do terms[#terms + 1] = { text = b[1], exact = true, qty = b[2] } end
		A.db.lists[p.buyName] = terms
		local parts = {}
		for i, b in ipairs(p.buyList) do if i <= 6 then parts[#parts + 1] = b[2] .. " " .. b[1] end end
		Print(("shopping list \"%s\" made in Pint's Auctions: %s%s."):format(p.buyName, table.concat(parts, ", "), #p.buyList > 6 and (" and " .. (#p.buyList - 6) .. " more") or ""))
		if A.OpenList then A.OpenList(p.buyName) end
		if A.ShowLists and not ((AuctionHouseFrame and AuctionHouseFrame:IsShown()) or (AuctionFrame and AuctionFrame:IsShown())) then A.ShowLists(p.buyName) end
	end)
	local view = Btn(p, "View shopping lists", 150, 20); view:SetPoint("RIGHT", p.listBtn, "LEFT", -6, 0)
	view:SetScript("OnClick", function()
		local A = _G.PintsAuctions
		if A and A.ToggleLists then A.ToggleLists() else Print("the shopping lists are Pint's Auctions' - it isn't loaded (or needs a restart after updating).") end
	end)
	UI.Tip(view, "View shopping lists", "Your Pint's Auctions shopping lists, anywhere: what each wants, what you already have, add or take items off.")
	UI.Tip(p.listBtn, "Build shopping list", "Puts what this plan needs from the auction house into a Pint's Auctions shopping list, named after the levels (\"Level Tailoring 177-200\"). At the auction house it opens straight away; otherwise find it on the Shopping tab. Building it again replaces it with the current plan."
		.. " (Vendor reagents - thread, dyes - aren't on it: buy those from a trades supplier.)")
	local total = Label(p, "", "GameFontHighlight"); total:SetPoint("TOPLEFT", steps, "BOTTOMLEFT", 4, -30); total:SetWidth(770); total:SetJustifyH("LEFT")
	local note = Label(p, "Each step uses the cheapest way to earn every point at the prices from your last full scan: what the reagents cost "
		.. "(bought, or made yourself when that's cheaper), less what you get back, divided by the chance of a point (yellow and green recipes miss "
		.. "sometimes - the Times column allows for that). Training costs count once. It's worked out again after every full scan.", "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", total, "BOTTOMLEFT", 0, -6); note:SetWidth(770); note:SetJustifyH("LEFT")

	local function Range()
		local line = o.line
		local sk = CDB().skill[line]
		local from = tonumber(fromBox:GetText() or "") or (o.from and o.from[line]) or (sk and sk[1]) or 1
		local to = tonumber(toBox:GetText() or "") or 300
		from = math.max(1, math.min(299, from)); to = math.max(from + 1, math.min(300, to))
		return from, to
	end
	profBtn:SetScript("OnClick", function(self)
		local items = {}
		for _, line in ipairs(ORDER) do
			local sk = CDB().skill[line]
			items[#items + 1] = { text = (line == o.line and "|cff40ff40" or "") .. NAMES[line] .. "|r" .. (sk and ("  |cff909090(" .. sk[1] .. ")|r") or ""),
				fn = function() o.line = line; fromBox:SetText(""); toBox:SetText(""); p.OnOpen() end }
		end
		UI.Menu(self, items)
	end)
	mine:SetScript("OnClick", function() ScanSkills(); o.from = o.from or {}; o.from[o.line] = nil; fromBox:SetText(""); p.OnOpen() end)
	go:SetScript("OnClick", function()
		fromBox:ClearFocus(); toBox:ClearFocus()
		o.from = o.from or {}; o.from[o.line] = tonumber(fromBox:GetText() or "")
		p.OnOpen()
	end)
	fromBox:SetScript("OnEnterPressed", function() go:Click() end); toBox:SetScript("OnEnterPressed", function() go:Click() end)
	-- Tab moves between the two boxes (selecting what's there, so you can type straight over it)
	local function Hop(to) to:SetFocus(); to:HighlightText() end
	fromBox:SetScript("OnTabPressed", function() Hop(toBox) end)
	toBox:SetScript("OnTabPressed", function() Hop(fromBox) end)
	fromBox:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
	toBox:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)

	p.OnOpen = function(keep)
		p.keepNext = keep
		ScanSkills()
		for _, v in ipairs(p.SAFE) do if v[1] == o.safety then p.safe:SetText("Buy: " .. v[2]) end end
		local line = o.line
		profBtn:SetText(NAMES[line] .. "  |cffaaaaaav|r")
		local from, to = Range()
		if not fromBox:HasFocus() then fromBox:SetText(tostring(from)) end
		if not toBox:HasFocus() then toBox:SetText(tostring(to)) end
		local plan = P.Plan(line, from, to, o)
		local data = {}
		for _, st in ipairs(plan.steps) do
			local r = PROF[st.spell]
			local name, link, tex
			if r[2] > 0 then name, link, tex = IName(r[2])
			else name = "|cffffffff" .. SName(st.spell) .. "|r"; tex = select(3, GetSpellInfo(st.spell)) end
			local learn = ""
			if st.learn and st.learn > 0 and st.how == "ah" then learn = "  |cffffd100(AH " .. (st.learn >= 10000 and (math.floor(st.learn / 10000 + 0.5) .. "g") or (math.floor(st.learn / 100 + 0.5) .. "s")) .. ")|r"
			elseif st.learn and st.learn > 0 then learn = "  |cff80c0ff(learn: " .. Money(st.learn) .. ")|r"
			elseif not Knows(line, st.spell) then learn = (r[8] == "v") and "  |cff80c0ff(vendor recipe)|r" or "  |cff80c0ff(trainer)|r" end
			-- the colour it is when you start it
			local t = T(st.spell)
			local sn = SName(st.spell)
			local agree, picks = WPPicks(line, sn, st.from, st.to)
			local note = WPNote(sn)
			local wpTip
			if picks then
				wpTip = (agree and "|cffffd100wow-professions.com picks this one too.|r" or "|cff80c0ffwow-professions.com makes:|r " .. (#picks > 0 and table.concat(picks, ", ") or "nothing listed here"))
			end
			if note then wpTip = (wpTip and (wpTip .. "\n") or "") .. "|cff80c0ff" .. note .. "|r" end
			if st.how == "ah" and st.learn and st.learn > 0 then
				wpTip = "|cffffd100Buy the recipe at the auction house: about " .. Money(st.learn) .. " at your last scan.|r" .. (wpTip and ("\n" .. wpTip) or "")
			end
			if agree then name = "|TInterface\\Common\\FavoritesIcon:14:14:0:0|t" .. name end
			local col = (st.from < t[5] and "|cffff8040") or (st.from < (t[5] + t[6]) / 2 and "|cffffff00") or "|cff40bf40"
			data[#data + 1] = { col .. st.from .. " - " .. st.to .. "|r", name .. learn, st.crafts .. (st.extra > 0 and (" |cff909090(+" .. st.extra .. ")|r") or ""), Money(math.max(0, st.cost)) .. (st.cost < 0 and " |cff40ff40profit|r" or ""),
				Money(math.max(0, math.floor(st.cost / math.max(1, st.to - st.from)))), texture = tex, link = link, name = name, spell = st.spell, note = (wpTip and (wpTip .. "\n") or "") .. "|cff909090Right-click: leave this recipe out.|r",
				tip = (not link) and SName(st.spell) or nil }
		end
		-- the training ranks you'll need on the way
		for _, rk in ipairs(RANKS) do
			if from < rk[1] and to > rk[1] then
				for i, d in ipairs(data) do
					local a = tonumber((d[1]:gsub("|c%x%x%x%x%x%x%x%x", ""):match("^(%d+)")))
					if a and a >= rk[1] then table.insert(data, i, { "|cff80c0ff" .. rk[1] .. "|r", "|cff80c0ffTrain " .. rk[2] .. " " .. (NAMES[line]:gsub(" %(.*", "")) .. " (character level " .. rk[3] .. ")|r", "", "", "" }); break end
				end
			end
		end
		steps:Set(data, p.keepNext)
		local nskip = 0; for _, v in pairs(o.skip or {}) do if v then nskip = nskip + 1 end end
		p.back:SetText(nskip > 0 and ("Put back (" .. nskip .. ")") or "Put back"); p.back:SetEnabled(nskip > 0)
		local sd, buy, usedN, slots = {}, 0, 0, 0
		local ids = {}
		for id in pairs(plan.shop) do ids[id] = true end
		for id in pairs(plan.used) do ids[id] = true end
		for id in pairs(ids) do
			local c = Cost(id, 9)
			local name, link, tex, plain = IName(id)
			local need = math.ceil((plan.shop[id] or 0) - 0.01)
			local have = math.floor((plan.used[id] or 0) + 0.5)
			local cost = (need > 0 and c) and c[1] * need or 0
			local _, listed = AHBuy(id)
			local warn = (need > 0 and c and c[2] == "ah" and listed and listed < need) and (" |cffff8040(" .. listed .. " listed)|r") or ""
			if need > 0 or have > 0 then
				sd[#sd + 1] = { name .. ((need > 0 and c and c[2] == "vendor") and " |cff909090v|r" or "") .. warn,
					have > 0 and ("|cff40ff40" .. have .. "|r") or "", need > 0 and need or "", need > 0 and Money(cost) or "|cff40ff40yours|r",
					texture = tex, link = link, name = plain, key = tostring(id), sk = { (plain or ""):lower(), have, need, cost } }
			end
			buy = buy + cost
			if have > 0 then
				usedN = usedN + have
				-- bag slots this frees: whole stacks used up
				local stack = select(8, GetItemInfo(id)) or 20
				local own = Have(id)
				slots = slots + (have >= own and math.ceil(own / math.max(1, stack)) or math.floor(have / math.max(1, stack)))
			end
		end
		shop.sortCol, shop.sortDesc = 4, true
		shop:Set(sd, p.keepNext)
		-- what to buy at the auction house, for the shopping-list button
		p.buyList, p.buyName = {}, ("Level %s %d-%d"):format((NAMES[line]:gsub(" %(.*", "")), from, to)
		for id in pairs(plan.shop) do
			local need = math.ceil((plan.shop[id] or 0) - 0.01)
			local c = Cost(id, 9)
			if need > 0 and c and c[2] == "ah" then
				local _, _, _, plain = IName(id)
				if plain then p.buyList[#p.buyList + 1] = { plain, need } end
			end
		end
		-- recipes to buy at the auction house go on the list too
		for _, st in ipairs(plan.steps) do
			if st.how == "ah" then
				local _, _, _, plain = IName(PROF[st.spell][10])
				if plain then p.buyList[#p.buyList + 1] = { plain, 1 } end
			end
		end
		table.sort(p.buyList, function(a, b) return a[1] < b[1] end)
		p.listBtn:SetEnabled(#p.buyList > 0)
		local nmiss = 0; for _ in pairs(plan.missing) do nmiss = nmiss + 1 end
		info:SetText(("%s %d to %d - %s%s%s"):format(NAMES[line], from, to, ScanAge(),
			usedN > 0 and ("  |cff40ff40Uses %d of your own reagents, freeing about %d bag slot%s.|r"):format(usedN, slots, slots == 1 and "" or "s") or "",
			(nmiss > 0) and ("  |cff909090(" .. nmiss .. " reagents have no price yet, so recipes that need them are left out)|r") or ""))
		local gap = ""
		if #plan.gaps > 0 then gap = ("  |cffff8040No priced recipe for %d level%s (from %d) - scan again, or check those reagents.|r"):format(#plan.gaps, #plan.gaps == 1 and "" or "s", plan.gaps[1]) end
		total:SetText(("Reagents about %s%s%s, training %s - total |cffffd100%s|r%s"):format(Money(buy),
			o.safety ~= 0 and " |cff909090(with extra for bad luck)|r" or "",
			plan.back > 0 and (", less about " .. Money(math.floor(plan.back)) .. " back for what you make") or "",
			Money(plan.train), Money(math.max(0, buy - math.floor(plan.back)) + plan.train), gap))
	end
end

local function BuildFlip(p)
	local Label, Btn, List = UI.Label, UI.Btn, UI.List
	-- what to do: buy the mats and craft, or just buy and vendor - then where crafts are sold
	local c0 = Check(p, "Craft and sell (buy the mats)", "flipCraft", function() p.OnOpen() end,
		"Recipes whose reagents cost less than what the result sells for: buy the mats, craft it, sell it. Cost = the mats at their market price (or a vendor's, if cheaper); "
		.. "Profit = what it sells for less the mats. Tick where it sells: Vendor, Auction house or both.")
	c0:SetPoint("TOPLEFT", 0, -2)
	local c4 = Check(p, "Buy and vendor (no crafting)", "flipBuyVendor", function() p.OnOpen() end, "Listed on the auction house for less than a vendor pays for it.")
	c4:SetPoint("LEFT", c0.label, "RIGHT", 14, -1)
	local sellTo = Label(p, "Sell crafts:", "GameFontNormalSmall"); sellTo:SetPoint("LEFT", c4.label, "RIGHT", 22, 0)
	local c1 = Check(p, "Vendor", "flipVendor", function() p.OnOpen() end, "Sell what you craft to a vendor. A sure thing: vendors always pay the same.")
	c1:SetPoint("LEFT", sellTo, "RIGHT", 6, -1)
	local c2 = Check(p, "Auction house", "flipAH", function() p.OnOpen() end,
		"Sell what you craft on the auction house - if the market holds: the lowest listing from your last scan, less the 5% the auction house keeps. It may sell slowly, or be undercut.")
	c2:SetPoint("LEFT", c1.label, "RIGHT", 14, -1)
	local c3 = Check(p, "Only recipes I know", "flipKnown", function() p.OnOpen() end,
		"Off: every trainer and vendor recipe (learn it to use it). Open a profession once on each character so its recipes are known.")
	c3:SetPoint("TOPLEFT", 0, -24)
	local c5 = Check(p, "Use what's in my bags & bank", "flipStock", function() p.OnOpen() end,
		"Reagents you already have count at what a vendor would pay for them - turn your mats into something worth more, and free bag space.")
	c5:SetPoint("LEFT", c3.label, "RIGHT", 14, -1)
	local info = Label(p, "", "GameFontHighlightSmall"); info:SetPoint("TOPLEFT", 4, -50); info:SetWidth(770); info:SetJustifyH("LEFT")
	local W = 778
	local list = List(p, W, 17, 18, {
		{ W - 540, "LEFT", "Item", sort = "asc" }, { 120, "LEFT", "How" }, { 80, "RIGHT", "Cost", sort = true }, { 85, "RIGHT", "Vendor", sort = true },
		{ 85, "RIGHT", "Profit", sort = true }, { 85, "RIGHT", "Auction", sort = true }, { 85, "RIGHT", "Profit", sort = true },
	}, function(item, b)
		if item.link and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then ChatEdit_InsertLink(item.link); return end
		-- click: pick it; the Buy button (or a double look) opens it to buy
		list.selected = item; list.selectedKey = item.key; list:Refresh()
		p.buy:Enable()
	end)
	p.buy = Btn(p, "Buy selected", 120, 22); p.buy:SetPoint("TOPRIGHT", list, "BOTTOMRIGHT", 0, -4); p.buy:Disable()
	p.buy:SetScript("OnClick", function()
		local it = list.selected
		if not it then return end
		-- crafting: the reagents, one at a time (the first now - click again for the next); buy & vendor: the item
		if it.buyList and #it.buyList > 0 then
			it.buyAt = (it.buyAt or 0) % #it.buyList + 1
			local r = it.buyList[it.buyAt]
			BuyItem(r[1], r[2])
			p.buy:SetText(("Buy %d/%d: next"):format(it.buyAt, #it.buyList))
		else BuyItem(tonumber(it.key), it.name) end
	end)
	UI.Tip(p.buy, "Buy at the auction house", "Opens it in the auction house's Buy view, where the game's Buy button buys it. "
		.. "For a craft, each click opens the next reagent to buy.")
	list:SetPoint("TOPLEFT", 0, -80)
	list.sortCol, list.sortDesc = nil, true
	local note = Label(p, "Cost = the reagents at their market price from your last full scan (or a vendor's price), or what you pay for it. "
		.. "Vendor profit is certain; auction profit holds only if the market does. Prices may have moved since the scan - check before buying a lot.", "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 4, -20); note:SetWidth(770); note:SetJustifyH("LEFT")
	local function M(v, profit)
		if not v then return "|cff606060-|r" end
		if profit then return (v > 0 and "|cff40ff40" or "|cffff6060") .. (v < 0 and "-" or "") .. Money(math.abs(math.floor(v))) .. "|r" end
		return Money(math.floor(v))
	end
	p.OnOpen = function(keep)
		local o = Opt()
		local flips = P.Flips(o)
		local data = {}
		for i, f in ipairs(flips) do
			if i > 300 then break end
			local name, link, tex, plain = IName(f.item)
			local how
			if f.kind == "buy" then how = "|cffffd100buy & vendor|r" .. (f.qty and ("  |cff909090x" .. f.qty .. "|r") or "")
			else
				local r = PROF[f.spell]
				local mine = 0
				if o.flipStock then for k = 1, #r[7], 2 do if Have(r[7][k]) >= r[7][k + 1] then mine = mine + 1 end end end
				how = (NAMES[r[1]] or "?"):gsub(" %(.*", "") .. " " .. r[4] .. ((not Knows(r[1], f.spell)) and " |cff80c0ff(learn)|r" or "")
					.. (mine > 0 and " |cff40ff40(have mats)|r" or "")
					.. (SName(f.spell):find("^Transmute") and " |cffff8040(cooldown)|r" or "")
			end
			data[#data + 1] = { name .. (f.n > 1 and (" |cff909090x" .. f.n .. "|r") or ""), how, M(f.cost), M(f.vend), M(f.pv, true), M(f.ah), M(f.pa, true),
				texture = tex, link = link, name = plain, key = tostring(f.item),
				sk = { (plain or ""):lower(), how, f.cost, f.vend or -1, f.pv or -1e12, f.ah or -1, f.pa or -1e12 } }
			if f.kind == "craft" then
				-- what to buy for it: the reagents the auction house is the cheapest place for
				local bl, r = {}, PROF[f.spell]
				for k = 1, #r[7], 2 do
					local c = Cost(r[7][k], 1)
					if c and c[2] == "ah" then local _, _, _, pl = IName(r[7][k]); bl[#bl + 1] = { r[7][k], pl } end
				end
				data[#data].buyList = bl
			end
		end
		list:Set(data, keep)
		-- keep what you picked picked
		local selKey = list.selectedKey
		list.selected = nil
		if selKey then for _, d in ipairs(data) do if d.key == selKey then list.selected = d end end end
		if not list.selected then list.selectedKey = nil; p.buy:Disable(); p.buy:SetText("Buy selected") end
		list:Refresh()
		if o.flipCraft ~= false and not (o.flipVendor or o.flipAH) then info:SetText("|cffff8040Craft and sell: tick where crafts sell - Vendor, Auction house or both.|r")
		elseif o.flipCraft == false and not o.flipBuyVendor then info:SetText("|cffff8040Tick Craft and sell, Buy and vendor, or both.|r")
		else info:SetText(("%d ways to make money - %s. Click one, then Buy selected (at the auction house).%s"):format(#flips, ScanAge(),
			P.Loading() > 0 and ("  |cffffd100Loading %d items' prices...|r"):format(P.Loading()) or "")) end
	end
end

function P.Open(which)
	if not win then
		win = CreateFrame("Frame", "PintsProfessionsFrame", UIParent, "BackdropTemplate")
		win:SetSize(810, 520); win:SetPoint("CENTER"); win:SetFrameStrata("HIGH"); win:SetToplevel(true); win:SetClampedToScreen(true)
		win:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
		win:EnableMouse(true); win:SetMovable(true); win:RegisterForDrag("LeftButton")
		win:SetScript("OnDragStart", win.StartMoving); win:SetScript("OnDragStop", win.StopMovingOrSizing)
		tinsert(UISpecialFrames, "PintsProfessionsFrame")
		local title = UI.Label(win, "|cffd4a017Pint's|r Professions", "GameFontNormal"); title:SetPoint("TOPLEFT", 16, -12)
		-- (the game's own close button goes through its panel code, which won't act in a fight: just hide it)
		local close = CreateFrame("Button", nil, win, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -2, -2)
		close:SetScript("OnClick", function() win:Hide() end)
		-- out of the way when a fight starts
		win:RegisterEvent("PLAYER_REGEN_DISABLED")
		win:SetScript("OnEvent", function(self) if self:IsShown() and Opt().combatClose ~= false then self:Hide() end end)
		win.pages, win.tabs = {}, {}
		local x = 230
		for _, d in ipairs({ { "level", "Cheapest levelling" }, { "flip", "Flip for profit" } }) do
			local pg = CreateFrame("Frame", nil, win); pg:SetPoint("TOPLEFT", 14, -40); pg:SetPoint("BOTTOMRIGHT", -14, 12); pg:Hide()
			win.pages[d[1]] = pg
			local t = UI.Btn(win, d[2], 140, 22); t:SetPoint("TOPLEFT", x, -8); x = x + 144
			t:SetScript("OnClick", function() P.Open(d[1]) end)
			win.tabs[d[1]] = t
		end
		BuildLevel(win.pages.level); BuildFlip(win.pages.flip)
	end
	which = which or win.cur or "level"
	win.cur = which
	for k, pg in pairs(win.pages) do pg:SetShown(k == which) end
	for k, t in pairs(win.tabs) do if k == which then t:LockHighlight() else t:UnlockHighlight() end end
	win:Show()
	win.pages[which].OnOpen()
end
function P.Toggle(which) if win and win:IsShown() and (not which or which == win.cur) then win:Hide() else P.Open(which) end end
function P.Refresh(keep) if win and win:IsShown() then win.pages[win.cur].OnOpen(keep) end end

---------------------------------------------------------------- keeping things up to date
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE", "CRAFT_SHOW", "CRAFT_UPDATE", "SKILL_LINES_CHANGED", "MERCHANT_SHOW", "GET_ITEM_INFO_RECEIVED" }) do
	pcall(ev.RegisterEvent, ev, e)
end
local wait
ev:SetScript("OnEvent", function(_, e)
	if e == "MERCHANT_SHOW" then
		-- what vendors charge for what they sell (the reagents' real prices)
		local d = DB(); if not d then return end
		d.vendorBuy = d.vendorBuy or {}
		for i = 1, (GetMerchantNumItems and GetMerchantNumItems() or 0) do
			local ok, _, _, price, qty = pcall(GetMerchantItemInfo, i)
			local link = GetMerchantItemLink and GetMerchantItemLink(i)
			local id = link and tonumber(link:match("item:(%d+)"))
			if ok and id and price and price > 0 then d.vendorBuy[id] = math.floor(price / math.max(1, qty or 1) + 0.5) end
		end
		return
	end
	if e == "GET_ITEM_INFO_RECEIVED" then
		if loading > 0 then loading = loading - 1 end
		if not (win and win:IsShown()) or wait then return end
		wait = true
		C_Timer.After(3, function() wait = false; P.Refresh(true) end)
		return
	end
	if e == "PLAYER_LOGIN" then C_Timer.After(5, function() pcall(ScanSkills) end); return end
	C_Timer.After(0.3, function() pcall(ScanBook); pcall(ScanSkills) end)
end)
---------------------------------------------------------------- skill-up log: how often yellow and green crafts really give a point
-- Every craft you make in the yellow-green range is counted (account-wide), by how far it is from yellow to grey;
-- each tenth of that range needs 30 crafts before what really happened starts to count. /pprof skillups shows it.
local pend
local SKILLUP = (SKILL_RANK_UP or "Your skill in %s has increased to %d."):gsub("%.", "%%."):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
local function Settle()
	if not pend then return end
	local d = DB()
	if d then
		d.skillups = d.skillups or {}
		local b = d.skillups[pend.b] or { 0, 0 }
		b[1] = b[1] + 1; if pend.up then b[2] = b[2] + 1 end
		d.skillups[pend.b] = b
	end
	pend = nil
end
local log = CreateFrame("Frame")
pcall(log.RegisterEvent, log, "UNIT_SPELLCAST_SUCCEEDED"); pcall(log.RegisterEvent, log, "CHAT_MSG_SKILL")
log:SetScript("OnEvent", function(_, e, a1, _, a3)
	if e == "UNIT_SPELLCAST_SUCCEEDED" then
		if a1 ~= "player" then return end
		local sp = a3
		if type(issecretvalue) == "function" and issecretvalue(sp) then return end
		local r = sp and PROF[sp]
		if not r then return end
		Settle()
		local sk = CDB().skill[r[1]]
		local s = sk and sk[1]
		local t = T(sp)
		if s and s >= t[5] and s < t[6] then
			pend = { line = r[1], b = Bucket(t, s) }
			C_Timer.After(2, function() if pend and pend.line == r[1] and not pend.up then Settle() end end)
		end
	elseif e == "CHAT_MSG_SKILL" then
		if type(issecretvalue) == "function" and issecretvalue(a1) then return end
		local name, val = tostring(a1 or ""):match(SKILLUP)
		local line = name and LINE_OF[name]
		if not line then return end
		local c = CDB(); c.skill[line] = c.skill[line] or { 0, 0 }; c.skill[line][1] = tonumber(val) or c.skill[line][1]
		if pend and pend.line == line then pend.up = true; Settle() end
	end
end)
function P.SkillupReport()
	local d = DB() and DB().skillups or {}
	Print("skill-ups on yellow and green crafts (0% = just turned yellow, 90% = nearly grey):")
	local any = false
	for b = 0, BUCKETS - 1 do
		local x = d[b]
		if x and x[1] > 0 then
			any = true
			local mid = (b + 0.5) / BUCKETS
			Print(("  %d-%d%%: %d crafts, %d points - %.0f%% (the rule says ~%.0f%%)%s"):format(b * 10, b * 10 + 10, x[1], x[2], x[2] / x[1] * 100,
				(1 - mid) * 100, x[1] >= 30 and "" or " |cff909090(needs 30 to count)|r"))
		end
	end
	if not any then Print("  nothing yet - it counts as you craft yellow and green recipes.") end
end

-- after every full scan: work it all out again (the scan's last step records each item's market price)
local hooked
local function HookScan()
	local A = AH()
	if hooked or not (A and type(A.RecordScan) == "function") then return end
	hooked = true
	hooksecurefunc(A, "RecordScan", function()
		C_Timer.After(0.5, function()
			P.Refresh()
			Print("levelling guide and Flip list updated with the new prices - /pprof")
		end)
	end)
end
-- /pprof (and /pah level, /pah flip from Pint's Auctions)
SLASH_PINTSPROFESSIONS1 = "/pprof"
SLASH_PINTSPROFESSIONS2 = "/professions"
SlashCmdList.PINTSPROFESSIONS = function(msg)
	local m = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if m == "flip" then P.Toggle("flip")
	elseif m == "skillups" then P.SkillupReport()
	elseif m == "minimap" then P.ToggleMinimap()
	elseif m == "tooltip" then P.ToggleCraftTip()
	elseif m == "help" or m == "?" then Print("/pprof - levelling guide   /pprof flip - craft (or buy) and sell for a profit   /pprof skillups - your skill-up log   /pprof minimap - hide or show the button   /pprof tooltip - cost to craft on item tooltips")
	else P.Toggle("level") end
end
local function HookAHSlash()
	local prev = SlashCmdList.PINTSAUCTIONS
	if not prev or SlashCmdList.PINTSAUCTIONS_PROF then return end
	SlashCmdList.PINTSAUCTIONS_PROF = true
	SlashCmdList.PINTSAUCTIONS = function(msg)
		local m = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
		if m == "level" or m == "plan" or m == "planner" or m == "professions" then P.Toggle("level")
		elseif m == "flip" then P.Toggle("flip")
		else prev(msg) end
	end
end
-- buttons: on Pint's Auctions' panel at the auction house, and in the profession window
local function AddButton(parent, point, rel, rpoint, x, y, w, text)
	if not parent or parent.pintsProf then return end
	local b = UI.Btn(parent, text or "Professions", w or 110, 18)
	b:SetPoint(point, rel or parent, rpoint or point, x, y)
	b:SetFrameLevel(parent:GetFrameLevel() + 30)
	b:SetScript("OnClick", function() P.Toggle() end)
	UI.Tip(b, "Pint's Professions", "Cheapest way to level a profession, and what to craft and sell for a profit, at the prices from your full scans.")
	parent.pintsProf = b
end
local function PlaceAH(tries)
	if _G.PintsAuctionsSide then AddButton(_G.PintsAuctionsSide, "TOPRIGHT", nil, nil, -76, -6, 110)          -- WoW Forever: left of Options
	elseif _G.PintsAuctionsFrame then AddButton(_G.PintsAuctionsFrame, "TOPRIGHT", nil, nil, -110, -8)    -- Classic Era: left of Options
	elseif tries < 10 then C_Timer.After(0.3, function() PlaceAH(tries + 1) end) end
end
-- the profession window's own button: under the window, beside Recipe Sources' "Learnable" (or where it would be). It
-- opens the levelling guide for the profession that window is showing.
local function WindowLine(host)
	local name
	if host == _G.CraftFrame and GetCraftDisplaySkillLine then name = GetCraftDisplaySkillLine()
	elseif GetTradeSkillLine then name = GetTradeSkillLine()
	elseif C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
		local info = C_TradeSkillUI.GetChildProfessionInfo and C_TradeSkillUI.GetChildProfessionInfo()
		if not (info and info.professionName and info.professionName ~= "") then info = C_TradeSkillUI.GetBaseProfessionInfo() end
		name = info and (info.parentProfessionName or info.professionName)
	end
	if not name then return end
	if LINE_OF[name] then return LINE_OF[name] end
	for n, id in pairs(LINE_OF) do if name:find(n, 1, true) or n:find(name, 1, true) then return id end end
end
local function Learnable(host)
	for _, c in ipairs({ host:GetChildren() }) do
		if c.GetText and c:IsObjectType("Button") and c:GetText() == "Learnable" then return c end
	end
end
local function ProfButton(host)
	if not host then return end
	local b = host.pintsProfBtn
	if not b then
		b = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
		b:SetSize(130, 22); b:SetText("Pint's Professions")
		b:SetScript("OnClick", function()
			ScanSkills()
			local line = WindowLine(host)
			if line and NAMES[line] then Opt().line = line end
			if win and win:IsShown() and win.cur == "level" then win:Hide() else P.Open("level") end
		end)
		UI.Tip(b, "Pint's Professions", "The cheapest way to level this profession from where you are, at your auction house's prices. Right-click: Flip for profit.")
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b:SetScript("OnMouseUp", function(_, btn) if btn == "RightButton" then P.Toggle("flip") end end)
		host.pintsProfBtn = b
	end
	b:ClearAllPoints()
	local l = Learnable(host)
	if l then b:SetPoint("RIGHT", l, "LEFT", -4, 0)
	elseif _G.ProfessionsFrame and host == _G.ProfessionsFrame then b:SetPoint("TOPRIGHT", host, "BOTTOMRIGHT", -104, -2)
	else b:SetPoint("TOPRIGHT", host, "BOTTOMRIGHT", -144, 76) end
	local line = WindowLine(host)
	b:SetShown(line ~= nil and NAMES[line] ~= nil)
end
local function PlaceTrade()
	ProfButton(_G.ProfessionsFrame or _G.TradeSkillFrame)
	if _G.CraftFrame and _G.CraftFrame:IsShown() then ProfButton(_G.CraftFrame) end
	-- (again in a moment: Recipe Sources makes its Learnable button when the window first opens)
	C_Timer.After(0.5, function()
		ProfButton(_G.ProfessionsFrame or _G.TradeSkillFrame)
		if _G.CraftFrame and _G.CraftFrame:IsShown() then ProfButton(_G.CraftFrame) end
	end)
end
local hook = CreateFrame("Frame")
for _, e in ipairs({ "AUCTION_HOUSE_SHOW", "TRADE_SKILL_SHOW", "CRAFT_SHOW", "PLAYER_LOGIN" }) do pcall(hook.RegisterEvent, hook, e) end
hook:SetScript("OnEvent", function(_, e)
	if e == "AUCTION_HOUSE_SHOW" then C_Timer.After(0.2, function() PlaceAH(0) end)
	elseif e == "PLAYER_LOGIN" then Migrate(); HookScan(); HookAHSlash(); P.BuildMinimap()
	else C_Timer.After(0.2, PlaceTrade) end
end)

---------------------------------------------------------------- minimap button
-- (LibDBIcon when another add-on brings it, so it sits with your other buttons; otherwise a button of its own)
do
	local NAME, ICON, ANGLE = "PintsProfessions", "Interface\\Icons\\Trade_BlackSmithing", 160
	local btn
	local function Tip(tt)
		tt:AddLine("Pint's Professions")
		tt:AddLine(ScanAge(), 1, 1, 1, true)
		tt:AddLine("Click: levelling guide   Right-click: Flip for profit", 0.5, 0.5, 0.5, true)
		tt:AddLine("Drag to move   /pprof minimap to hide", 0.5, 0.5, 0.5)
	end
	local function Click(_, button) if button == "RightButton" then P.Toggle("flip") else P.Toggle("level") end end
	function P.BuildMinimap()
		local d = DB(); d.minimap = d.minimap or {}
		local store = d.minimap
		local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
		local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
		if LDB and Icon then
			local obj = LDB:NewDataObject(NAME, { type = "launcher", text = "Pint's Professions", icon = ICON, OnClick = Click, OnTooltipShow = Tip })
			Icon:Register(NAME, obj, store); btn = { lib = Icon }; return
		end
		local b = CreateFrame("Button", NAME .. "MinimapButton", Minimap)
		b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
		local ic = b:CreateTexture(nil, "BACKGROUND"); ic:SetTexture(ICON); ic:SetSize(20, 20); ic:SetPoint("CENTER", 0, 1); ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		local border = b:CreateTexture(nil, "OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(53, 53); border:SetPoint("TOPLEFT")
		local function Place() local a = math.rad(store.angle or ANGLE); b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a)) end
		Place()
		b:RegisterForDrag("LeftButton")
		b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter(); local px, py = GetCursorPosition(); local sc = Minimap:GetEffectiveScale()
			store.angle = math.deg(math.atan2(py / sc - my, px / sc - mx)); Place() end) end)
		b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
		b:SetScript("OnClick", Click)
		b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); Tip(GameTooltip); GameTooltip:Show() end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		b:SetShown(not store.hide); btn = b
	end
	function P.ToggleMinimap()
		local store = DB().minimap; store.hide = not store.hide
		if btn and btn.lib then if store.hide then btn.lib:Hide(NAME) else btn.lib:Show(NAME) end elseif btn then btn:SetShown(not store.hide) end
		Print(store.hide and "minimap button hidden (/pprof minimap to show it again)." or "minimap button shown.")
	end
end

---------------------------------------------------------------- item tooltips: what it costs to make
-- On anything a recipe makes (and on the recipe itself): the cheapest it can be made for, each reagent at the cheapest of
-- your latest Pint's Auctions full scan, a vendor, or making it yourself. Hold Shift for the reagents. /pprof tooltip
do
	local teaches = {}            -- recipe item -> what it teaches
	for sp, r in pairs(PROF) do if (r[10] or 0) > 0 then teaches[r[10]] = sp end end
	local HOW = { ah = "auction", vendor = "vendor", craft = "made", have = "yours" }
	local done = setmetatable({}, { __mode = "k" })
	local cleared = {}
	local function Tip(tt)
		local d = DB()
		if not d or d.craftTip == false or not tt.GetItem then return end
		local _, link = tt:GetItem()
		local id = link and tonumber(link:match("item:(%d+)"))
		if not id then return end
		if not cleared[tt] and tt.HookScript then cleared[tt] = true; tt:HookScript("OnTooltipCleared", function(t) done[t] = nil end) end
		if done[tt] == link then return end
		local sps, made = madeBy[id], nil
		if not sps and teaches[id] then sps = { teaches[id] }; made = PROF[teaches[id]][2] end
		if not sps then return end
		done[tt] = link
		wipe(cache); wipe(missing)
		local best, bestSp
		for _, sp in ipairs(sps) do
			local c = CraftCost(sp, 0)
			if c then c = c / math.max(1, PROF[sp][3]); if not best or c < best then best, bestSp = c, sp end end
		end
		local t = AHDB() and AHDB().lastAll and AHDB().lastAll[RF()]
		local age = t and ("|cff888888 (scan " .. UI.Ago(t) .. ")|r") or "|cff888888 (no full scan)|r"
		local label = "Cost to craft" .. ((made and made > 0) and (" " .. (select(4, IName(made)) or "")) or "")
		if not best then
			tt:AddDoubleLine(label, "|cff888888a reagent has no price|r", 0.4, 0.8, 1, 1, 1, 1)
		else
			local per = PROF[bestSp][3] or 1
			tt:AddDoubleLine(label .. age, Money(math.floor(best + 0.5)) .. (per > 1 and ("|cff888888 each (" .. per .. " per craft)|r") or ""), 0.4, 0.8, 1, 1, 1, 1)
			if IsShiftKeyDown() then
				local regs = PROF[bestSp][7]
				for i = 1, #regs, 2 do
					local c = Cost(regs[i], 1)
					local nm = select(4, IName(regs[i])) or ("item " .. regs[i])
					tt:AddDoubleLine("   " .. regs[i + 1] .. " x " .. nm, c and (Money(math.floor(c[1] * regs[i + 1] + 0.5)) .. "|cff888888 " .. (HOW[c[2]] or "") .. "|r") or "?", 0.75, 0.75, 0.75, 1, 1, 1)
				end
			end
		end
		tt:Show()
	end
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt) if tt == GameTooltip or tt == ItemRefTooltip then pcall(Tip, tt) end end)
	else
		GameTooltip:HookScript("OnTooltipSetItem", function(tt) pcall(Tip, tt) end)
		if ItemRefTooltip then ItemRefTooltip:HookScript("OnTooltipSetItem", function(tt) pcall(Tip, tt) end) end
	end
	function P.ToggleCraftTip()
		local d = DB(); d.craftTip = (d.craftTip == false)
		Print("cost to craft on item tooltips " .. (d.craftTip and "on." or "off."))
	end
end
