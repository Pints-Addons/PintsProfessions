-- Pint's Professions: WoW Forever's Mining - every recipe as Forever has it (skill colours, reagents, how it's learned and
-- what that costs), from Wowhead's WoW Forever database (November 2026). Classic and Season of Discovery mining
-- recipes Forever doesn't have aren't suggested (unless a character of yours knows one). Recipes bought with something
-- other than gold count as "other".
-- [spellID] = { skillLine, madeItem, howMany, orange, yellow, grey, { reagent, count, ... }, how, cost, recipeItem }
if type(issecretvalue) ~= "function" then return end      -- (WoW Forever only)
local ADDON, NS = ...
local P = NS.PROF
if not P then return end
local F = {
[2657]={186,2840,1,25,25,70,{2770,1},"t",0,0},
[2658]={186,2842,1,75,100,125,{2775,1},"t",200,0},
[2659]={186,2841,2,65,65,115,{2840,1,3576,1},"t",200,0},
[3304]={186,3576,1,75,75,75,{2771,1},"t",50,0},
[3307]={186,3575,1,125,130,140,{2772,1},"t",500,0},
[3308]={186,3577,1,155,170,185,{2776,1},"t",2500,0},
[3569]={186,3859,1,165,165,165,{3575,1,3857,1},"t",2500,0},
[10097]={186,3860,1,175,175,175,{3858,1},"t",5000,0},
[10098]={186,6037,1,230,230,230,{7911,1},"t",10526,0},
[14891]={186,11371,1,230,230,230,{11370,8},"o",0,0},
[16153]={186,12359,1,250,250,250,{10620,1},"t",20000,0},
[22967]={186,17771,1,310,310,320,{18562,1,12360,10,17010,1,18567,3},"o",0,0},
[1230161]={186,279960,1,20,20,20,{2835,1,2840,1},"t",105,0},
[1249637]={186,249726,1,275,275,275,{249426,2,3857,1},"t",52631,0},
[1262975]={186,279948,1,140,140,140,{2838,2,2772,1,2842,1},"o",0,0},
[1263071]={186,279952,1,300,300,300,{12359,5,12365,2,6037,1},"o",0,0},
[1306126]={186,251291,1,300,300,315,{248815,1},"t",52631,0},
}
for id, r in pairs(P) do if r[1] == 186 and not F[id] then r[8] = "o"; r[9] = 0 end end
for id, r in pairs(F) do P[id] = r end
