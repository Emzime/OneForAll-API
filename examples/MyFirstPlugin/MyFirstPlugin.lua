-- MyFirstPlugin: a small, complete example of a OneForAll plugin.
-- It lists the dungeons (and raids, if wanted) for a level, adds two settings and a summary block to the Plugins page,
-- and an /ofa plugin_first command. Copy this folder, rename it (folder, .toc and the NAME below) and build from there.
local NAME = "MyFirstPlugin" -- the addon's folder name: the plugin's name everywhere in the API

-- 1. The API: present, and new enough for what this file uses ------------------------------------------------------
local API = OneForAllAPI
if not (API and API.VERSION >= 1) then return end -- OneForAll without the plugin API: the plugin stays quiet

API.RegisterPlugin(NAME, { title = "My First Plugin", version = "1.0.0" })

-- 2. Texts: our own translations, else OneForAll's, else the English text -------------------------------------------
local T = {
  frFR = {
    ["Dungeons for level %d:"] = "Donjons pour le niveau %d :",
    ["No dungeon for level %d."] = "Aucun donjon pour le niveau %d.",
    ["Include raids"] = "Inclure les raids",
    ["Raids are listed too."] = "Les raids sont aussi listés.",
    ["Greet on login"] = "Saluer à la connexion",
    ["A line in the chat when you log in."] = "Une ligne dans le chat à la connexion.",
    ["Dungeons for my level"] = "Donjons pour mon niveau",
    ["Summary"] = "Résumé",
    ["%d dungeons, %d raids in OneForAll."] = "%d donjons, %d raids dans OneForAll.",
    ["Library books: %d turned in, %d owned."] = "Livres de la bibliothèque : %d rendus, %d possédés.",
    ["My First Plugin is ready: /ofa plugin_first [level]."] = "My First Plugin est prêt : /ofa plugin_first [niveau].",
  },
}
local mine = T[API.GetLanguage()] or {}
local function L(text) return mine[text] or API.Translate(text) end

-- 3. Options: stored in OneForAll's profile as plugin.MyFirstPlugin.<key> -------------------------------------------
local opts = API.NewOptions(NAME, { includeRaids = false, greet = true })

-- 4. What the plugin does: reads OneForAll's data, never changes it -------------------------------------------------
-- the level range of a dungeon ("13-18" in d.level; d.minLevel when OneForAll has it)
local function range(d)
  local lo, hi = tostring(d.level or ""):match("(%d+)%-(%d+)")
  return tonumber(d.minLevel) or tonumber(lo), tonumber(d.maxLevel) or tonumber(hi)
end

local function dungeonsFor(level)
  local list = {}
  -- API.ipairs, not ipairs: API.Data and everything in it is read only (Lua 5.1's ipairs can't see through it)
  for _, d in API.ipairs(API.Data.DUNGEONS) do
    local lo, hi = range(d)
    if lo and hi and level >= lo and level <= hi and (not d.raid or opts:Get("includeRaids")) then
      list[#list + 1] = d
    end
  end
  return list
end

local function printFor(level)
  level = tonumber(level) or UnitLevel("player")
  local list = dungeonsFor(level)
  if #list == 0 then API.Print(string.format(L("No dungeon for level %d."), level)) return end
  API.Print(string.format(L("Dungeons for level %d:"), level))
  for _, d in ipairs(list) do -- a plain list of our own: Lua's ipairs is fine here
    API.Print(string.format("  %s (%s) - %d bosses", API.DungeonName(d.name), tostring(d.level), API.Count(d.bosses)))
  end
end

-- 5. A command: /ofa plugin_myfirstplugin [level], or its alias /ofa plugin_first [level] ------------------------------
-- (the word comes from the folder's name; every /ofa plugin_... word is the plugins', the others are OneForAll's)
API.RegisterSlashCommand(NAME, function(rest) printFor(rest ~= "" and rest or nil) end,
  "/ofa plugin_first [level]: the dungeons for a level", "first")

-- 6. Settings on the Plugins page -----------------------------------------------------------------------------------
API.AddSettingsSection(NAME, {
  title = "My First Plugin",
  icon = "Interface\\Icons\\INV_Misc_Book_09",
  build = function(s)
    local half = math.floor(s.width / 2)
    s:check(L("Include raids"), L("Raids are listed too."),
      function() return opts:Get("includeRaids") end, function(v) opts:Set("includeRaids", v) end, 0, true, half - 50)
    s:check(L("Greet on login"), L("A line in the chat when you log in."),
      function() return opts:Get("greet") end, function(v) opts:Set("greet", v) end, half, true, half - 50)
    s:nextRow() -- switches sit on the same row until nextRow
    s:button(L("Dungeons for my level"), 200, function() printFor() end)
  end,
})

-- 7. A block of our own under the settings: a summary --------------------------------------------------------------
local summary
API.AddPluginContent(NAME, {
  title = L("Summary"),
  icon = "Interface\\Icons\\INV_Misc_Note_01",
  height = 60,
  build = function(frame, width)
    summary = API.Widgets.FontString(frame, "OVERLAY", "GameFontHighlight")
    summary:SetPoint("TOPLEFT", 4, -4); summary:SetWidth(width - 8); summary:SetJustifyH("LEFT")
    local dungeons, raids = 0, 0
    for _, d in API.ipairs(API.Data.DUNGEONS) do
      if d.raid then raids = raids + 1 else dungeons = dungeons + 1 end
    end
    summary.head = string.format(L("%d dungeons, %d raids in OneForAll."), dungeons, raids)
    local done, owned = API.GetBookCounts()
    summary:SetText(summary.head .. "\n" .. string.format(L("Library books: %d turned in, %d owned."), done, owned))
  end,
})
-- OneForAll read the bags or bank again: the book counts may have changed
API.RegisterCallback("DATA_REFRESHED", function()
  if not summary then return end
  local done, owned = API.GetBookCounts()
  summary:SetText(summary.head .. "\n" .. string.format(L("Library books: %d turned in, %d owned."), done, owned))
end)

-- 8. Game events: an ordinary frame of our own ---------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  if opts:Get("greet") then API.Print(L("My First Plugin is ready: /ofa plugin_first [level].")) end
end)
