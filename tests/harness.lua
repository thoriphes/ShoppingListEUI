-- Offline smoke harness for Shopping List for EllesmereUI (Lua 5.4 standing in for 5.1): stubs
-- just enough of the client and EllesmereUI to load every file in TOC order and drive the
-- import, the list model, both tracking modes, merchant, AH, tooltip, the EllesmereUI
-- integration (sidebar group, options registration, element map, profile refresh) and both
-- options pages.
-- usage (from the addon folder): lua tests/harness.lua .
-- Prints HARNESS OK; a failing assert names the broken behaviour. Check the exit code, never pipe it.
local DIR = arg[1] or "."

local log = {}
local function note(...) log[#log + 1] = table.concat({ ... }, " ") end

---------------------------------------------------------------- generic mock
local function numberish(name)
    return name:match("^Get") or name == "GetFrameLevel"
end
local Mock
local mockMT = {}
mockMT.__index = function(self, k)
    if type(k) ~= "string" then return nil end
    local f
    if k == "IsShown" or k == "IsVisible" or k == "IsMouseOver" or k == "HasFocus" then
        f = function(s) return rawget(s, "_shown") and k ~= "IsMouseOver" and k ~= "HasFocus" or false end
    elseif k == "Show" then f = function(s) rawset(s, "_shown", true) end
    elseif k == "Hide" then f = function(s) rawset(s, "_shown", false) end
    elseif k == "SetShown" then f = function(s, v) rawset(s, "_shown", v and true or false) end
    elseif k == "SetScript" then f = function(s, n, fn) local sc = rawget(s, "_scripts") or {}; rawset(s, "_scripts", sc); sc[n] = fn end
    elseif k == "GetScript" then f = function(s, n) local sc = rawget(s, "_scripts"); return sc and sc[n] end
    elseif k == "HookScript" then f = function() end
    elseif k == "SetText" then f = function(s, t) rawset(s, "_text", t) end
    elseif k == "SetPoint" then f = function(s, ...) rawset(s, "_point", { ... }) end
    elseif k == "GetText" then f = function(s) return rawget(s, "_text") or "" end
    elseif k == "GetStatusBarTexture" or k:match("^Create") then f = function() return Mock() end
    elseif k == "GetWidth" then f = function(s) return rawget(s, "_w") or 300 end
    elseif k == "GetHeight" then f = function(s) return rawget(s, "_h") or 260 end
    elseif k == "SetSize" then f = function(s, w, h) rawset(s, "_w", w); rawset(s, "_h", h) end
    elseif k == "SetHeight" then f = function(s, h) rawset(s, "_h", h) end
    elseif k == "SetWidth" then f = function(s, w) rawset(s, "_w", w) end
    elseif k == "GetSize" then f = function(s) return rawget(s, "_w") or 300, rawget(s, "_h") or 260 end
    elseif k == "GetParent" then f = function(s) return rawget(s, "_parent") end
    elseif k == "SetParent" then f = function(s, p) rawset(s, "_parent", p) end
    elseif k == "GetID" then f = function(s) return rawget(s, "_id") or 1 end
    elseif k == "GetStringWidth" or k == "GetUnboundedStringWidth" then f = function() return 40 end
    elseif k == "GetScale" or k == "GetEffectiveScale" then f = function() return 1 end
    elseif numberish(k) then f = function() return 0 end
    else f = function() end end
    rawset(self, k, f)
    return f
end
Mock = function(t) return setmetatable(t or {}, mockMT) end

-------------------------------------------------------------------- client
_G.SlashCmdList = {}
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.tinsert = table.insert
_G.strsplit = function() end
_G.issecretvalue = function() return false end
_G.hooksecurefunc = function(a, b, c)
    if type(a) == "string" then
        local orig = _G[a]
        _G[a] = function(...) if orig then orig(...) end b(...) end
    else
        local orig = a[b]
        a[b] = function(...) if orig then orig(...) end c(...) end
    end
end
_G.InCombatLockdown = function() return false end
_G.GetBuildInfo = function() return "1.60.1", "70009", "", 16001 end
_G.IsLoggedIn = function() return true end
_G.IsAltKeyDown = function() return false end
_G.IsControlKeyDown = function() return false end
_G.IsShiftKeyDown = function() return false end
_G.GetServerTime = function() return 1000000 end
_G.GetTime = function() return 5000 end
_G.GetMoney = function() return 500000 end
_G.PlaySound = function() end
_G.PlaySoundFile = function() end
_G.UIParent = Mock({ _shown = true })
_G.GameTooltip = Mock()
_G.ItemRefTooltip = Mock()
_G.debugstack = function() return "" end
_G.loadstring = function(src, name) return load(src, "=" .. name) end
local postCalls = {}
_G.TooltipDataProcessor = { AddTooltipPostCall = function(_, fn) postCalls[#postCalls + 1] = fn end }
_G.Enum = { CraftingReagentType = { Basic = 1, Modifying = 0, Finishing = 2 },
    TooltipDataType = { Item = 0 }, TradeskillRelativeDifficulty = { Optimal = 0, Medium = 1, Easy = 2, Trivial = 3 } }
local frames = {}
_G.CreateFrame = function(kind, name, parent, template)
    local f = Mock({ _kind = kind, _parent = parent, _template = template })
    frames[#frames + 1] = f
    if name then _G[name] = f end
    if kind == "Frame" or kind == "Button" then
        -- the event hub
        f.RegisterEvent = function(s, e) rawset(s, "_events", rawget(s, "_events") or {}); s._events[e] = true end
        f.RegisterUnitEvent = f.RegisterEvent
        f.UnregisterEvent = function(s, e) if rawget(s, "_events") then s._events[e] = nil end end
        f.UnregisterAllEvents = function(s) rawset(s, "_events", {}) end
    end
    return f
end
local timers = {}
_G.C_Timer = {
    After = function(_, fn) timers[#timers + 1] = fn end,
    NewTimer = function(_, fn) local t = Mock(); timers[#timers + 1] = fn; return t end,
    NewTicker = function() return Mock() end,
}
local function RunTimers()
    for _ = 1, 10 do
        if #timers == 0 then return end
        local list = timers
        timers = {}
        for _, fn in ipairs(list) do fn() end
    end
end
_G.C_AddOns = { IsAddOnLoaded = function(n) return n == "Blizzard_AuctionHouseUI" or n == "Blizzard_Professions" end }
_G.EventUtil = { ContinueOnAddOnLoaded = function(name, fn) if C_AddOns.IsAddOnLoaded(name) then fn() end end }
_G.C_SpellBook = { IsSpellKnown = function() return true end }
_G.C_XMLUtil = { GetTemplateInfo = function(n) if n == "CheckboxWithLabelTemplate" then return {} end end }
_G.ChatFrameUtil = { InsertLink = function() end }
local formInfo = { recipeID = 9001, learned = true, relativeDifficulty = 0, numSkillUps = 2 }
-- Blizzard's checkbox: bottom-left of the form (WoW Forever); the retail spot is tested below.
local checkPoint = "BOTTOMLEFT"
local check = Mock({ _shown = true, Text = Mock(), GetPoint = function() return checkPoint end })
local form = Mock({ _shown = true, GetRecipeInfo = function() return formInfo end, Init = function() end, TrackRecipeCheckbox = check })
_G.ProfessionsFrame = Mock({ _shown = true, CraftingPage = { SchematicForm = form },
    GetRight = function() return 800 end, GetTop = function() return 600 end })

local searched
_G.AuctionHouseFrame = Mock({ _shown = true })
local filtersReset, categoryCleared
AuctionHouseFrame.SearchBar = Mock({ SetSearchText = function(_, t) searched = t end, StartSearch = function() end,
    FilterButton = Mock({ Reset = function() filtersReset = true end }) })
local catCalls, sentQuery = {}, nil
_G.AUCTION_HOUSE_DEFAULT_FILTERS = { [1] = true, [2] = false, [5] = true }
local tokenSelected = false
local catList = Mock({ GetSelectedCategory = function() return 3, 1, nil end,
    IsWoWTokenCategorySelected = function() return tokenSelected end,
    SetSelectedCategory = function(_, a, b) catCalls[#catCalls + 1] = tostring(a) .. "/" .. tostring(b) end })
AuctionHouseFrame.GetCategoriesList = function() return catList end
AuctionHouseFrame.SendBrowseQuery = function(_, text, lo, hi, filters)
    table.sort(filters)
    sentQuery = text .. " " .. lo .. "-" .. hi .. " [" .. table.concat(filters, ",") .. "] cat=" .. table.concat(catCalls, ",")
end
local counts = { [101] = 3, [102] = 0, [103] = 10, [201] = 1 }
_G.C_Item = {
    GetItemCount = function(id) return counts[id] or 0 end,
    GetItemNameByID = function(id) return "Item" .. id end,
    GetItemIconByID = function(id) return 1000 + id end,
    GetItemInfo = function(id) return "Item" .. id, "|Hitem:" .. id .. "|h" end,
    RequestLoadItemDataByID = function() end,
}
_G.C_CurrencyInfo = { GetCoinTextureString = function(c) return c .. "c" end }
blizz = {}
local recipes = {
    [9001] = { name = "Elixir", icon = 1, learned = true, recipeID = 9001, relativeDifficulty = 1, numSkillUps = 1 },
    [9002] = { name = "Bar", icon = 2, learned = true, recipeID = 9002 },
}
local schematics = {
    [9001] = { name = "Elixir", quantityMin = 1, reagentSlotSchematics = {
        { required = true, reagentType = 1, quantityRequired = 2, reagents = { { itemID = 101 } } },
        { required = true, reagentType = 1, quantityRequired = 1, reagents = { { itemID = 102 } } },
        { required = false, reagentType = 0, quantityRequired = 1, reagents = { { itemID = 999 } } },
    } },
    [9002] = { name = "Bar", quantityMin = 2, reagentSlotSchematics = {
        { required = true, reagentType = 1, quantityRequired = 3, reagents = { { itemID = 103 }, { itemID = 104 } } },
    } },
}
local allRecipeCalls = 0
local cooldownAfterCraft = false
_G.C_TradeSkillUI = {
    GetRecipeInfo = function(id) return recipes[id] end,
    GetRecipeSchematic = function(id) return schematics[id] end,
    GetRecipeLink = function(id) return "|Henchant:" .. id .. "|h" end,
    GetRecipeOutputItemData = function(id) return ({ [9001] = { itemID = 201 }, [9002] = { itemID = 102 } })[id] end,
    GetAllRecipeIDs = function() allRecipeCalls = allRecipeCalls + 1; return { 9001, 9002 } end,
    IsTradeSkillReady = function() return true end,
    IsTradeSkillLinked = function() return false end,
    IsTradeSkillGuild = function() return false end,
    IsNPCCrafting = function() return false end,
    GetRecipeCooldown = function(id)
        if id == 9002 then return 3600, true, 0, 1 end
        if id == 9001 and cooldownAfterCraft then return 600, true, 0, 1 end
        return nil
    end,
    SetRecipeTracked = function(id, on) blizz[id] = on or nil end,
    IsRecipeTracked = function(id) return blizz[id] == true end,
    GetRecipesTracked = function(recraft) local t = {} if not recraft then for id in pairs(blizz) do t[#t + 1] = id end end return t end,
    OpenRecipe = function() end,
    GetBaseProfessionInfo = function() return { professionID = 185 } end,
}
_G.C_Spell = { GetSpellName = function() return "Basic Campfire" end, GetSpellTexture = function() return 1 end }
local merchant = { { id = 102, price = 500, stack = 1 }, { id = 201, price = 1000, stack = 5 } }
local bought = {}
_G.C_MerchantFrame = { GetItemInfo = function(i) local m = merchant[i]; return m and { name = "M" .. m.id, texture = 1, price = m.price, stackCount = m.stack, numAvailable = -1, isPurchasable = true } end }
_G.GetMerchantNumItems = function() return #merchant end
_G.GetMerchantItemID = function(i) return merchant[i] and merchant[i].id end
_G.GetMerchantItemCostInfo = function() return 0 end
_G.GetMerchantItemMaxStack = function() return 20 end
_G.BuyMerchantItem = function(i, n) bought[#bought + 1] = i .. "x" .. tostring(n) end
_G.UnitName = function() return "Vendor Bob" end
_G.MERCHANT_ITEMS_PER_PAGE = 10
_G.MerchantFrame = Mock({ _shown = true, selectedTab = 1 })
_G.MerchantItem1ItemButton = Mock({ _shown = true, _id = 1 })
_G.MerchantItem2ItemButton = Mock({ _shown = true, _id = 2 })
_G.MerchantFrame_Update = function() end
_G.MerchantMoneyBg = Mock({ _shown = true })
_G.MerchantExtraCurrencyBg = Mock({ _shown = false })

----------------------------------------------------------------- EllesmereUI
local EUI = setmetatable({}, { __index = function(t, k)
    local f = function() end
    rawset(t, k, f)
    return f
end })
_G.EllesmereUI = EUI
EUI._ModuleNS = {}
EUI.L = function(s) return s end
EUI.PP = { Scale = function(v) return v end, mult = 1, Snap = function(v) return v end, Point = function() end,
    CreateBorder = function() return Mock() end, SetBorderColor = function() end }
EUI.ELLESMERE_GREEN = { r = 0.05, g = 0.82, b = 0.62 }
EUI.COLOR_CODES = { BRAND = "|cff0cd29d" }
EUI.BORDER_DEFAULTS_BARS = {}
EUI.Print = function(...) note("PRINT", ...) end
EUI.GetFontPath = function() return "font.ttf" end
EUI.GetFontOutlineFlag = function() return "" end
EUI.BuildBarTextureTables = function() return { atrocity = "x" }, { atrocity = "Atrocity" }, { "atrocity" } end
EUI.ResolveTexturePath = function() return "tex" end
EUI.EvalVisibilityExtended = function() return nil end
EUI.EvalVisibility = function() return true end
EUI.CheckVisibilityOptions = function() return false end
EUI.ContextMenuOwner = function() return nil end
EUI.MakeUnlockElement = function(o) return o end
EUI.BorderPx = function() return nil end
EUI.BuildAlertSoundTables = function() return { none = 1 }, { none = "None" }, { "none" } end
local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = DeepCopy(x) end
    return t
end
local newDBName
EUI.Lite = {
    NewAddon = function() return {} end,
    NewDB = function(name, defaults)
        newDBName = name
        local p = {}
        for k, v in pairs(defaults.profile) do p[k] = v end
        return { profile = p, ResetProfile = function() end }
    end,
    DeepCopy = DeepCopy,
}
-- EllesmereUI's sidebar + module registry, as the integration file finds them.
EUI._addonInfoByFolder = { EllesmereUIQoL = { folder = "EllesmereUIQoL" } }
EUI.ADDON_GROUPS = { { key = "core", members = {} }, { key = "qol", members = { "EllesmereUIQoL" } } }
EUI._modules = {}
EUI._ELEMENT_SETTINGS_MAP = {}
local registerSource
EUI.RegisterModule = function(_, key, cfg)
    -- EllesmereUI reads the caller's folder from the stack: it must not be one of our files.
    registerSource = debug.getinfo(2, "S").source
    EUI._modules[key] = cfg
end
EUI.RefreshAllAddons = function() end
local syncEx
EUI.RegisterSyncExclusions = function(folder, keys) syncEx = { folder = folder, keys = keys } end
-- The old suite module's settings in two profiles; a third already has ours.
_G.EllesmereUIDB = { profiles = {
    Default = { addons = { EllesmereUIShoppingList = { enabled = true, barHeight = 25, barColor = { r = 1 } } } },
    Alt = { addons = { EllesmereUIShoppingList = { barHeight = 30 }, ShoppingListEUI = { barHeight = 12 } } },
    Bare = {},
} }
local shown
EUI.ShowContextMenu = function(_, items) shown = items end
EUI.RefreshPage = function() end

--------------------------------------------------------------------- loading
local ns = {}
local function loadAddonFile(file)
    local chunk = assert(loadfile(DIR .. "/" .. file))
    chunk("ShoppingListEUI", ns)
end
local toc = io.open(DIR .. "/ShoppingListEUI.toc"):read("a")
for line in toc:gmatch("[^\r\n]+") do
    if line:match("%.lua$") then loadAddonFile(line) end
end
assert(syncEx and syncEx.folder == "ShoppingListEUI" and #syncEx.keys == 3, "sync exclusions under our folder")
ns.addon:OnInitialize()
assert(newDBName == "ShoppingListEUIDB", "NewDB name derives our folder key")

-- import: every profile with the old block and none of ours; old blocks kept; once
local profiles = EllesmereUIDB.profiles
local imported = profiles.Default.addons.ShoppingListEUI
assert(imported and imported.barHeight == 25 and imported.barColor.r == 1, "old settings copied")
assert(imported.barColor ~= profiles.Default.addons.EllesmereUIShoppingList.barColor, "deep copy")
assert(profiles.Default.addons.EllesmereUIShoppingList, "old block kept")
assert(profiles.Alt.addons.ShoppingListEUI.barHeight == 12, "existing plugin settings win")
assert(profiles.Bare.addons == nil, "profile without the module untouched")
assert(EllesmereUIDB.shoppingListEUIImported and ns.importedProfiles == 1, "flagged, one profile copied")
profiles.Default.addons.ShoppingListEUI = nil
ns.ImportFromModule()
assert(profiles.Default.addons.ShoppingListEUI == nil, "import runs once per account")

ns.addon:OnEnable()
assert(ns.active == true, "on by default (installing the plugin is the opt-in)")
RunTimers()
assert(ns.frame, "window built")

-- a profile swap re-applies through the RefreshAllAddons post-hook
ns.Set("enabled", false)
EUI.RefreshAllAddons()
assert(ns.active == false, "profile refresh reaches Apply")

-- switch on
ns.Set("enabled", true)
ns.Apply()
RunTimers()
assert(ns.frame, "window built")

-- track: 3 crafts of the elixir, then one bar
ns.TrackRecipe(9001, 3)
ns.TrackRecipe(9002, 1)
RunTimers()
local need = {}
for _, e in ipairs(ns.reagents) do need[e.itemID] = e end
assert(need[101].need == 6 and need[101].have == 3 and need[101].state == "partial", "101")
assert(need[102].need == 3 and need[102].state == "missing", "102")
assert(need[103].need == 3 and need[103].have == 10 and need[103].state == "complete", "103 (alts summed)")
assert(not need[999], "optional slot skipped")

local rows = {}
local cost = ns.BuildRows(rows)
local kinds = {}
for _, r in ipairs(rows) do kinds[#kinds + 1] = r.kind .. ":" .. tostring(r.key) end
note("rows", table.concat(kinds, " "))
for _, r in ipairs(rows) do
    if r.kind == "reagent" and r.key == 103 then assert(r.ready == true, "complete reagent ready") end
    if r.kind == "reagent" and r.key == 101 then assert(not r.ready, "partial reagent not ready") end
    if r.kind == "recipe" and r.key == 9002 then assert(r.ready == true, "recipe with covered reagents ready") end
    if r.kind == "recipe" and r.key == 9001 then assert(not r.ready, "recipe missing reagents not ready") end
end

-- craft decrement
local listFeature
for _, f in ipairs(ns.features) do if f.key == "list" then listFeature = f end end
listFeature.events.UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 9001)
RunTimers()
assert(ns.Char().recipes[9001].qty == 2, "decrement")
listFeature.events.UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 9002)
RunTimers()
assert(ns.Char().recipes[9002] == nil, "untracked at 0")
assert(blizz[9001] == true and blizz[9002] == nil, "blizzard set follows ours")

-- profession scan fills craftables; sub-craft for 102 (made by 9002, yield 2)
listFeature.events.TRADE_SKILL_SHOW("TRADE_SKILL_SHOW")
RunTimers()
assert(ns.Char().craftables[102] == 9002, "craftables")
if ns.Char().cooldowns then
    local cd = ns.Char().cooldowns[9002]
    assert(cd and cd.readyAt == 1000000 + 3600, "cooldown captured")
    assert(ns.Char().cooldowns[9001] == nil, "no-cooldown recipe not remembered")
end
ns.TrackSubRecipe(102)
RunTimers()
assert(ns.Char().recipes[9002] and ns.Char().recipes[9002].qty == 1, "sub-recipe crafts = ceil(2/2)")

-- A profession is scanned once per session; list updates (every craft) do not rescan.
local scans = allRecipeCalls
listFeature.events.TRADE_SKILL_SHOW("TRADE_SKILL_SHOW")
listFeature.events.TRADE_SKILL_LIST_UPDATE("TRADE_SKILL_LIST_UPDATE")
assert(allRecipeCalls == scans, "no rescan on list updates")
listFeature.events.NEW_RECIPE_LEARNED("NEW_RECIPE_LEARNED")
assert(allRecipeCalls == scans + 1, "a learned recipe rescans")
note("scans", allRecipeCalls)
RunTimers()

-- A craft's cooldown is read on the list update after the cast, no timer.
local cdFeature
for _, f in ipairs(ns.features) do if f.key == "cooldowns" then cdFeature = f end end
cooldownAfterCraft = true
local queued = #timers
cdFeature.events.UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 9001)
assert(#timers == queued, "no timer after a craft")
assert(ns.Char().cooldowns[9001] == nil, "not read at the cast")
cdFeature.events.TRADE_SKILL_LIST_UPDATE("TRADE_SKILL_LIST_UPDATE")
assert(ns.Char().cooldowns[9001] and ns.Char().cooldowns[9001].readyAt == 1000000 + 600, "cooldown read on the list update")
RunTimers()

-- Rebuilds reuse their tables (the list rebuilds on every bag update).
local e101 = ns.needByItem[101]
ns.Recompute()
assert(e101 and ns.needByItem[101] == e101, "reagent entries reused")
local ra, rb = {}, {}
ns.BuildRows(ra)
ns.BuildRows(rb)
assert(#ra > 1 and ra[2] == rb[2], "row entries reused")

if ns.TrackVendorItem then
    ns.TrackVendorItem(2, 7)   -- 7 of item 201 (have 1), sold in 5s at 1000 per 5
    RunTimers()
    for _, f in ipairs(ns.features) do if f.key == "merchant" then f.events.MERCHANT_SHOW("MERCHANT_SHOW") end end
    RunTimers()
    assert(ns.Char().vendor[201].copper == 200, "per-item price")
    assert(ns.Char().sources[102] and ns.Char().sources[102].copper == 500, "source recorded")
    assert(ns.StillNeeded(201) == 6, "vendor gap")
    local r2 = {}
    local cost = ns.BuildRows(r2)
    note("cost", cost)
    MerchantItem1ItemButton._shown = true
    MerchantFrame_Update()
    note("bought-before", #bought)
    for _, f in ipairs(frames) do
        if rawget(f, "_parent") == MerchantFrame and rawget(f, "_template") == "UIPanelButtonTemplate" then
            f._scripts.OnClick(f)
        end
    end
    note("bought", table.concat(bought, ","))
    assert(bought[1] == "1x2" and bought[2] == "2xnil" and bought[3] == "2xnil" and #bought == 3, "buy plan")
    rows = r2
end
if #postCalls > 0 then
    local tt = Mock()
    local added
    tt.AddDoubleLine = function(_, a, b) added = a .. "=" .. b end
    postCalls[1](tt, { id = 101 })
    note("tooltip", tostring(added))
    assert(added == "Shopping List=3/4", "tooltip line")
end
for _, f in ipairs(ns.features) do if f.key == "ah" then f.events.AUCTION_HOUSE_SHOW() end end
RunTimers()
for _, f in ipairs(frames) do
    if rawget(f, "_parent") == AuctionHouseFrame and rawget(f, "_template") == "UIPanelButtonTemplate" then
        f._scripts.OnClick(f, "LeftButton")
        note("ah-search", tostring(searched), f:GetText())
        assert(searched == "\"Item102\"", "ah searches the first missing reagent (quoted)")
        note("ah-query", tostring(sentQuery), "after:", table.concat(catCalls, ","))
        assert(sentQuery == "\"Item102\" 0-0 [1,5] cat=nil/nil", "query without user filters, category set aside")
        assert(catCalls[#catCalls] == "3/1", "category restored")
        assert(not filtersReset, "saved filters untouched")
    end
end
for _, f in ipairs(frames) do
    if rawget(f, "_parent") == AuctionHouseFrame and rawget(f, "_template") == "UIPanelButtonTemplate" then
        -- The WoW Token category is not re-selected (it would switch to the token view).
        tokenSelected = true
        f._scripts.OnClick(f, "LeftButton")
        assert(catCalls[#catCalls] == "nil/nil", "token category left unselected")
        tokenSelected = false
    end
end

form:Init()
local holder
for _, f in ipairs(frames) do
    if rawget(f, "_parent") == form and rawget(f, "_kind") == "Frame" and rawget(f, "_w") == 116 then holder = f end
end
assert(holder and holder._shown, "count box shown beside the checkbox")
assert(holder._point[1] == "LEFT" and holder._point[2] == check.Text, "WoW Forever: right of the checkbox label")
checkPoint = "TOPRIGHT"
form:Init()
assert(holder._point[1] == "RIGHT" and holder._point[2] == check, "retail: left of the checkbox")
checkPoint = "BOTTOMLEFT"
check._shown = false
form:Init()
assert(not holder._shown, "hidden where Blizzard hides its checkbox")
check._shown = true
form:Init()

local tool
for _, f in ipairs(frames) do
    if rawget(f, "_template") == "SecureActionButtonTemplate" then tool = f end
end
RunTimers()
assert(tool and tool._shown, "tool button shown with Cooking open")
-- Switched off in combat: hidden at combat end.
local hub
for _, f in ipairs(frames) do if rawget(f, "_events") and f:GetScript("OnEvent") then hub = hub or f end end
_G.InCombatLockdown = function() return true end
ns.Set("toolButtons", false); ns.Apply()
assert(tool._shown, "combat: left alone")
assert(hub._events.PLAYER_REGEN_ENABLED, "waits for combat end")
_G.InCombatLockdown = function() return false end
hub:GetScript("OnEvent")(hub, "PLAYER_REGEN_ENABLED")
assert(not tool._shown, "hidden at combat end")
assert(not hub._events.PLAYER_REGEN_ENABLED, "combat-end wait dropped")
ns.Set("toolButtons", true); ns.Apply(); RunTimers()
note("tools ok")
assert(SLASH_SHOPPINGLISTEUI1 == "/shoplist" and SLASH_SHOPPINGLISTEUI2 == "/eslist", "slash commands")
SlashCmdList.SHOPPINGLISTEUI("")
-- row clicks don't throw
for _, r in ipairs(rows) do
    if ns.rowClick[r.kind] then ns.rowClick[r.kind](Mock(), r, "RightButton") end
    if ns.rowTooltip[r.kind] then ns.rowTooltip[r.kind](Mock(), r) end
end

if ns.HarnessExtra then ns.HarnessExtra(RunTimers, note, Mock) end

for _, f in ipairs(ns.features) do
    if f.key == "blizzard" then
        blizz[9001] = nil
        f.events.TRACKED_RECIPE_UPDATE("TRACKED_RECIPE_UPDATE", 9001, false)
        assert(ns.Char().recipes[9001] == nil, "blizzard untick removes ours")
        blizz[9001] = true
        f.events.TRACKED_RECIPE_UPDATE("TRACKED_RECIPE_UPDATE", 9001, true)
        assert(ns.Char().recipes[9001] and ns.Char().recipes[9001].qty >= 1, "blizzard tick adds ours")
        note("blizzard-sync ok qty", ns.Char().recipes[9001].qty)
    end
end
-- Blizzard's tracking and ours are united once per character, not at every login.
local blizzFeature
for _, f in ipairs(ns.features) do if f.key == "blizzard" then blizzFeature = f end end
assert(ns.Char().blizzardSynced, "united on the first enable")
blizz[777] = true
blizzFeature.enable()   -- what a later login runs
assert(not ns.Char().recipes[777], "no re-import at a later login")
ns.Set("useBlizzardTrack", false); ns.Apply(); RunTimers()
assert(not ns.Char().blizzardSynced, "turning it off forgets the union")
ns.Set("useBlizzardTrack", true); ns.Apply(); RunTimers()
assert(ns.Char().recipes[777], "switching it back on unites again")
ns.UntrackRecipe(777); RunTimers()
note("sync-once ok")

-- Blizzard mode off: our cover checkbox tracks in our list only
ns.Set("useBlizzardTrack", false); ns.Apply(); RunTimers()
ns.UntrackRecipe(9001); RunTimers()
local coverCb
for _, f in ipairs(frames) do if rawget(f, "_kind") == "CheckButton" then coverCb = f end end
assert(coverCb, "cover checkbox built")
local before = blizz[9001]
coverCb.GetChecked = function() return true end
coverCb._scripts.OnClick(coverCb); RunTimers()
assert(ns.Char().recipes[9001], "cover tick tracks")
assert(blizz[9001] == before, "blizzard untouched in cover mode")
coverCb.GetChecked = function() return false end
coverCb._scripts.OnClick(coverCb); RunTimers()
assert(not ns.Char().recipes[9001], "cover untick untracks")
note("cover ok")
-- switch off: features off
ns.Set("enabled", false)
ns.Apply()
RunTimers()
for _, f in ipairs(ns.features) do assert(not ns.IsOn(f.key), "feature still on: " .. f.key) end

-- PLAYER_LOGIN: sidebar group, options registration, Unlock Mode element map
local loginFrame
for _, f in ipairs(frames) do
    if rawget(f, "_events") and f._events.PLAYER_LOGIN then loginFrame = f end
end
assert(loginFrame, "login frame")
EUI.Widgets = setmetatable({}, { __index = function() return function() return Mock({ _leftRegion = Mock(), _rightRegion = Mock() }), 30 end end })
EUI.BuildVisibilityRow = function() return Mock(), 30 end
EUI.GetBorderTextureDropdown = function() return { solid = "Solid", shadow = "Shadow" }, { "solid", "shadow" } end
loginFrame:GetScript("OnEvent")(loginFrame, "PLAYER_LOGIN")
local registered = EUI._modules.ShoppingListEUI
assert(registered, "module registered")
assert(registerSource and registerSource:sub(1, 1) ~= "@", "registered from the loadstring chunk, not a file: " .. tostring(registerSource))
local info = EUI._addonInfoByFolder.ShoppingListEUI
assert(info and info.folder == "ShoppingListEUI" and not info.alwaysLoaded, "sidebar row info (real folder)")
local groups = EUI.ADDON_GROUPS
assert(groups[#groups].key == "shoppingListEUI" and groups[#groups].members[1] == "ShoppingListEUI", "own group, appended")
for _, g in ipairs(groups) do
    if g.key ~= "shoppingListEUI" then
        for _, m in ipairs(g.members) do assert(m ~= "ShoppingListEUI", "not inside a suite group") end
    end
end
local em = EUI._ELEMENT_SETTINGS_MAP and EUI._ELEMENT_SETTINGS_MAP.ShoppingListEUI
assert(em and em.module == "ShoppingListEUI" and em.page == "Window", "element options entry")
for _, line in ipairs(log) do assert(not line:find("did not accept"), "no registration warning") end
ns.Set("enabled", true)
for _, page in ipairs(registered.pages) do
    local h = registered.buildPage(page, Mock(), 0)
    note("page", page, tostring(h))
end
registered.onReset()

print(table.concat(log, "\n"))
print("HARNESS OK")
