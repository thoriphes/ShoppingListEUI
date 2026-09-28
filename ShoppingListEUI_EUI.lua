if EUI_CLIENT_BLOCKED then return end -- EllesmereUI's client gate: dormant wherever EllesmereUI is
-------------------------------------------------------------------------------
--  ShoppingListEUI_EUI.lua
--  Everything that ties the plugin into EllesmereUI, kept in one file because
--  most of it is not a supported API:
--    * public calls: RegisterSyncExclusions, the unlock element (Window file)
--    * supported late inserts: _ELEMENT_SETTINGS_MAP (DataBars writes its keys
--      the same way), a post-hook on RefreshAllAddons for profile swaps
--    * the options page: EllesmereUI has no API for third-party pages.
--      RegisterModule only accepts callers from its own folders (read from
--      debugstack), so the call is made from a loadstring chunk, whose frame
--      carries no folder; our own sidebar group (never inside Core / QoL /
--      Reskin: Ellesmere's plugin rules) is appended to ADDON_GROUPS. The same
--      technique as NaowhUI_EUI and ItruliaQoL. If it stops working the rest
--      of the plugin keeps running and one chat line says so.
--    * the one-time import of the old suite module's settings.
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local EUI = ns.EUI

local OLD_FOLDER = "EllesmereUIShoppingList"   -- the suite module this replaces (PR #2289)
local GROUP_KEY = "shoppingListEUI"
local GROUP_LABEL = "Plugins"
local DISPLAY = "Shopping List"

-------------------------------------------------------------------------------
--  Import. The old module's profile lived at
--  EllesmereUIDB.profiles[<profile>].addons.EllesmereUIShoppingList; copied to
--  our key in every profile that has one and none of ours yet, once per
--  account (flag in EllesmereUIDB). The old blocks stay where they are.
--  Called from OnInitialize (EllesmereUI's saved variables are live by then),
--  before NewDB fills in the defaults. The per-character list lives in its own
--  saved-variables file, which a plugin cannot read: tools/shoppinglist-migrate.py
--  copies that one on disk.
-------------------------------------------------------------------------------
function ns.ImportFromModule()
    local sv = EllesmereUIDB
    if type(sv) ~= "table" or sv.shoppingListEUIImported then return end
    local copied = 0
    if type(sv.profiles) == "table" then
        for _, pdata in pairs(sv.profiles) do
            local addons = type(pdata) == "table" and pdata.addons
            if type(addons) == "table" and type(addons[OLD_FOLDER]) == "table"
                and addons[ADDON_NAME] == nil then
                addons[ADDON_NAME] = EUI.Lite.DeepCopy(addons[OLD_FOLDER])
                copied = copied + 1
            end
        end
    end
    sv.shoppingListEUIImported = true
    ns.importedProfiles = copied
end

-------------------------------------------------------------------------------
--  Public registrations, at load.
-------------------------------------------------------------------------------
EUI.RegisterSyncExclusions(ADDON_NAME, {
    "position",  -- drag / unlock-mode window position
    "width",     -- drag-resize width
    "height",    -- drag-resize height
})

-- A profile swap, import or sync re-points db.profile (every Lite db is
-- re-pointed by the swap itself); re-apply afterwards.
if EUI.RefreshAllAddons then
    hooksecurefunc(EUI, "RefreshAllAddons", function()
        if ns.DB() then ns.Apply() end
    end)
end

-------------------------------------------------------------------------------
--  Sidebar + options page, at PLAYER_LOGIN (before any panel can be built:
--  the sidebar rows are created once, on the first open).
-------------------------------------------------------------------------------
local function InjectSidebar()
    local infoByFolder = EUI._addonInfoByFolder
    local groups = EUI.ADDON_GROUPS
    if type(infoByFolder) ~= "table" or type(groups) ~= "table" then return false end
    -- A real folder, not alwaysLoaded: the row gets EllesmereUI's power toggle
    -- (enable / disable this addon + reload) and sync icon like any module.
    infoByFolder[ADDON_NAME] = infoByFolder[ADDON_NAME] or {
        folder = ADDON_NAME,
        display = DISPLAY,
        search_name = "Shopping List for EllesmereUI",
    }
    for _, group in ipairs(groups) do
        if group.key == GROUP_KEY then return true end
    end
    -- Appended: a plugin sits below the suite's own groups.
    groups[#groups + 1] = { key = GROUP_KEY, label = GROUP_LABEL, members = { ADDON_NAME } }
    return true
end

local registerChunk = loadstring and loadstring(
    "local key, config = ...\nEllesmereUI:RegisterModule(key, config)", "ShoppingListEUI-register")

local function RegisterOptions()
    if not ns.optionsConfig then return false end
    if registerChunk then pcall(registerChunk, ADDON_NAME, ns.optionsConfig) end
    -- A rejected caller returns silently: the registry is the only proof.
    return EUI._modules ~= nil and EUI._modules[ADDON_NAME] ~= nil
end

local function OnLogin()
    local ok = InjectSidebar() and RegisterOptions()
    if not ok then
        ns.Say(EUI.L("EllesmereUI did not accept the options page; the list itself works. /shoplist for commands."), true)
    end
    -- Unlock Mode's cog: "Element Options" opens the Window tab.
    EUI._ELEMENT_SETTINGS_MAP = EUI._ELEMENT_SETTINGS_MAP or {}
    EUI._ELEMENT_SETTINGS_MAP[ns.UNLOCK_KEY] = {
        module = ADDON_NAME, page = "Window", sectionName = "WINDOW", highlightText = "Border Style",
    }
    if (ns.importedProfiles or 0) > 0 then
        ns.Say(EUI.L("Settings carried over from the EllesmereUI Shopping List module."))
    end
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    OnLogin()
end)
