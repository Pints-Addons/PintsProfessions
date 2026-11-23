-- Pint's Professions: wow-professions.com's WoW Forever levelling guides (November 2026) - the recipe it picks for each
-- skill range, where some recipes are learned, and the recipes it says to leave out. Shown in the levelling guide: a star
-- on steps it agrees with, and its notes in the step's tooltip. Forever only.
-- picks[skillLine] = { { from, to, "Recipe name (or the start of it)" }, ... }
if type(issecretvalue) ~= "function" then return end      -- (WoW Forever only)
local ADDON, NS = ...
NS.WP = { picks = {
	[171] = { {1,10,"Elixir of Minor Force"}, {10,55,"Elixir of Minor Defense"}, {55,65,"Minor Mana Potion"}, {65,90,"Elixir of Minor Fortitude"}, {90,120,"Elixir of Wisdom"}, {120,130,"Lesser Mana Potion"}, {130,150,"Fire Oil"}, {150,165,"Elixir of Fire Power"}, {165,195,"Mana Potion"}, {195,235,"Nature Protection Potion"}, {235,250,"Elixir of Greater Intellect"}, {250,260,"Stonescale Oil"}, {260,265,"Elixir of Greater Intellect"}, {265,300,"Elixir of Greater Defense"}, {265,300,"Superior Mana Potion"} },
	[164] = { {1,25,"Rough Sharpening Stone"}, {25,50,"Rough Grinding Stone"}, {50,75,"Coarse Grinding Stone"}, {75,80,"Silver Rod"}, {80,95,"Rough Bronze Leggings"}, {95,100,"Patterned Bronze Bracers"}, {100,112,"Heavy Grinding Stone"}, {112,140,"Patterned Bronze Bracers"}, {125,140,"Bronze Shortsword"}, {140,175,"Green Iron Bracers"}, {175,180,"Solid Grinding Stone"}, {180,195,"Golden Scale Bracers"}, {195,210,"Mithril Plate Pants"}, {210,215,"Heavy Mithril Axe"}, {215,225,"Mithril Coif"}, {225,235,"Dense Sharpening Stone"}, {235,240,"Heavy Mithril Boots"}, {240,245,"Imperial Plate Belt"}, {215,225,"Mithril Spurs"}, {235,245,"Mithril Spurs"}, {245,270,"Imperial Plate Bracers"}, {270,290,"Imperial Plate Boots"}, {290,300,"Imperial Plate Leggings"} },
	[333] = { {1,2,"Runed Copper Rod"}, {2,20,"Enchant Bracer"}, {20,100,"Enchant Chest"}, {20,70,"Enchant Bracer"}, {85,100,"Enchant Bracer"}, {100,130,"Enchant Cloak"}, {109,110,"Runed Silver Rod"}, {110,125,"Greater Magic Wand"}, {125,150,"Enchant 2H Weapon"}, {125,150,"Enchant Boots"}, {130,150,"Enchant Bracer"}, {150,151,"Runed Golden Rod"}, {151,165,"Minor Mana Oil"}, {165,200,"Enchant Boots"}, {165,200,"Enchant Bracer"}, {200,201,"Runed Truesilver Rod"}, {201,220,"Lesser Wizard Oil"}, {220,225,"Enchant Cloak"}, {225,250,"Enchant Gloves"}, {250,270,"Lesser Mana Oil"}, {270,275,"Enchant Shield"}, {275,295,"Wizard Oil"}, {295,299,"Enchant Shield"}, {299,300,"Runed Arcanite Rod"} },
	[202] = { {1,35,"Rough Blasting Powder"}, {35,55,"Handful of Copper Bolts"}, {55,56,"Arclight Spanner"}, {56,75,"Rough Copper Bomb"}, {75,90,"Coarse Blasting Powder"}, {90,100,"Coarse Dynamite"}, {100,105,"Silver Contact"}, {100,105,"Flying Tiger Goggles"}, {105,125,"Bronze Tube"}, {125,135,"Standard Scope"}, {135,150,"Heavy Blasting Powder"}, {135,150,"Whirring Bronze Gizmo"}, {150,160,"Bronze Framework"}, {160,175,"Explosive Sheep"}, {175,194,"Solid Blasting Powder"}, {194,195,"Gyromatic Micro-Adjustor"}, {195,200,"Mithril Tube"}, {200,215,"Unstable Trigger"}, {215,238,"Mithril Casing"}, {238,250,"Hi-Explosive Bomb"}, {250,260,"Dense Blasting Powder"}, {260,280,"Thorium Widget"}, {260,280,"Thorium Grenade"}, {280,300,"Thorium Tube"}, {280,300,"Thorium Shells"} },
	[165] = { {1,30,"Light Leather"}, {30,50,"Cured Light Hide"}, {30,50,"Light Armor Kit"}, {30,80,"Embossed Leather Gloves"}, {60,80,"Embossed Leather Pants"}, {80,95,"Cured Medium Hide"}, {80,105,"Fine Leather Belt"}, {105,125,"Dark Leather Belt"}, {105,125,"Dark Leather Pants"}, {105,150,"Hillman's Leather Gloves"}, {125,130,"Heavy Leather"}, {130,143,"Cured Heavy Hide"}, {150,165,"Barbaric Shoulders"}, {150,165,"Barbaric Leggings"}, {165,175,"Guardian Gloves"}, {165,185,"Barbaric Harness"}, {175,185,"Thick Armor Kit"}, {185,205,"Nightscape Headband"}, {205,235,"Nightscape Pants"}, {235,265,"Wicked Leather Gauntlets"}, {235,265,"Blue Suede Shoes"}, {265,300,"Runic Leather Headband"}, {295,300,"Blue Suede Hat"} },
	[197] = { {1,30,"Bolt of Linen Cloth"}, {30,55,"Linen Belt"}, {55,80,"Bolt of Woolen Cloth"}, {80,95,"Woolen Cape"}, {95,100,"Double-stitched Woolen Shoulders"}, {100,120,"Bolt of Silk Cloth"}, {120,125,"Gloves of Meditation"}, {125,140,"Small Silk Pack"}, {140,150,"Bolt of Mageweave"}, {150,170,"Crimson Silk Vest"}, {170,185,"Crimson Silk Pantaloons"}, {185,200,"Black Mageweave Leggings"}, {200,205,"Black Mageweave Shoulders"}, {205,215,"Bolt of Runecloth"}, {215,225,"Red Mageweave Bag"}, {215,240,"Runecloth Belt"}, {240,260,"Runecloth Gloves"}, {240,250,"Brightcloth Cloak"}, {250,290,"Runecloth Cuffs"}, {260,300,"Runecloth Shoulders"}, {280,300,"Wizardweave Turban"}, {280,290,"Runecloth Headband"} },
	[129] = { {1,75,"Minor Healing Potion"}, {1,40,"Linen Bandage"}, {40,80,"Heavy Linen Bandage"}, {80,115,"Wool Bandage"}, {115,150,"Heavy Wool Bandage"}, {90,125,"Simple Poultice"}, {125,150,"Healing Potion"}, {150,180,"Silk Bandage"}, {180,210,"Heavy Silk Bandage"}, {210,240,"Mageweave Bandage"}, {240,260,"Heavy Mageweave Bandage"}, {260,290,"Runecloth Bandage"}, {260,290,"Major Healing Potion"}, {290,300,"Heavy Runecloth Bandage"} },
	[185] = { {285,300,"Nightfin Soup"} },
},
-- notes[recipe name (or its start)] = where to learn it, or why to leave it out
notes = {
	["Nature Protection Potion"] = "Recipe: Bronk or Logannas in Feralas, Glyx Brewright in Stranglethorn Vale (bind on pickup).",
	["Superior Mana Potion"] = "Recipe: Algernon in Undercity, Ulthir in Darnassus.",
	["Elixir of Superior Defense"] = "Recipe: Kor'geld in Orgrimmar, Soolie Berryfizz in Ironforge.",
	["Mithril Spurs"] = "Plans: a world drop.",
	["Mithril Coif"] = "Only the Artisan trainer teaches this one (not the Expert trainers in Orgrimmar and Ironforge).",
	["Enchant 2H Weapon - Lesser Intellect"] = "Formula: Enchanting supply vendors (Tilli Thistlefuzz in Ironforge).",
	["Minor Mana Oil"] = "Formula: Enchanting supply vendors (Tilli Thistlefuzz in Ironforge).",
	["Lesser Mana Oil"] = "Formula: Kania, upstairs in the inn in Silithus.",
	["Wizard Oil"] = "Formula: Kania in Silithus.",
	["Enchant Shield - Greater Stamina"] = "Formula: Daniel Bartlett in Undercity, Mythrin'dir in Darnassus (bind on pickup).",
	["Runed Arcanite Rod"] = "Formula: Lorelae Wintersong at Nighthaven, Moonglade.",
	["Thorium Widget"] = "Schematic: Sovik in Orgrimmar, Gearcutter Cogspinner in Ironforge.",
	["Thorium Grenade"] = "Schematic: Sovik in Orgrimmar, Gearcutter Cogspinner in Ironforge.",
	["Thorium Tube"] = "Schematic: Xizzer Fizzbolt at Everlook, Winterspring (bind on pickup on Forever).",
	["Thorium Shells"] = "Schematic: a world drop.",
	["Nightscape Pants"] = "Only the Artisan trainers teach this one (Camp Mojache, Feralas / Aerie Peak, The Hinterlands).",
	["Wicked Leather Gauntlets"] = "Pattern: Werg Thickblade in Tirisfal Glades (Horde), Leonard Porter in Western Plaguelands (Alliance).",
	["Runic Leather Headband"] = "Pattern: Jase Farlane at Light's Hope Chapel, Eastern Plaguelands.",
	["Black Mageweave Shoulders"] = "Only the Artisan trainers teach this one (Tarren Mill / Theramore Isle).",
	["Runecloth Gloves"] = "Pattern: Qia in Winterspring.",
	["Runecloth Cuffs"] = "Pattern: Pexmit in Mount Hyjal (bind on pickup), or the Horde quest Threading a Solution from Kal'tinzan in Elderwild.",
	["Runecloth Shoulders"] = "Pattern: a world drop (auction house).",
	["Runecloth Headband"] = "Pattern: a world drop (auction house).",
	["Wizardweave Turban"] = "Pattern: rare (auction house).",
	["Nightfin Soup"] = "Recipe: Gikkix in Steamwheedle Port, Tanaris.",
	["Swarmtender's"] = "Needs a Loom, which only a Tailoring 300 can make - left out (and Cenarion Circle reputation).",
	["Venomspew"] = "Needs a Loom, which only a Tailoring 300 can make - left out (and Cenarion Circle reputation).",
},
-- recipes it can't be levelled with right now (a Loom only a Tailoring 300 can make): left out with the cooldowns
station = { "^Swarmtender's", "^Venomspew" },
}
