# Writing a OneForAll plugin

A step-by-step guide, from an empty folder to a published plugin. Every function is described in the [API reference](api-reference.md). A complete, working example is in [`examples/MyFirstPlugin`](../examples/MyFirstPlugin): copy it to start.

## Contents

1. [How a plugin works](#1-how-a-plugin-works)
2. [The folder and the .toc](#2-the-folder-and-the-toc)
3. [Checking the API and registering](#3-checking-the-api-and-registering)
4. [Reading OneForAll's data](#4-reading-oneforalls-data)
5. [Options](#5-options)
6. [Your part of the Plugins page](#6-your-part-of-the-plugins-page)
7. [Slash commands](#7-slash-commands)
8. [Callbacks and game events](#8-callbacks-and-game-events)
9. [Opening OneForAll on a page](#9-opening-oneforall-on-a-page)
10. [Texts and languages](#10-texts-and-languages)
11. [Saved data](#11-saved-data)
12. [Your own windows](#12-your-own-windows)
13. [Testing and debugging](#13-testing-and-debugging)
14. [Publishing](#14-publishing)
15. [Checklist](#15-checklist)

---

## 1. How a plugin works

- A plugin is an ordinary WoW addon in its own folder.
- Its `.toc` says `## Dependencies: OneForAll`. The game then loads it **after** OneForAll, and OneForAll lists it on its **Plugins** page.
- It reaches OneForAll **only** through the global `OneForAllAPI`, never through OneForAll's own tables:
  - It can **read** everything OneForAll knows.
  - It can **do** what the API offers: options, its part of the Plugins page, `/ofa` commands, callbacks, opening OneForAll on a page.
  - It can **never change** OneForAll. Everything the API hands out is read only.
- OneForAll and the plugin update separately. The API only ever *adds* functions (`API.VERSION` goes up), so a plugin keeps working with newer OneForAll versions.

## 2. The folder and the .toc

```
MyPlugin/
  MyPlugin.toc
  Locales.lua        (optional: your translations)
  MyPlugin.lua
```

```toc
## Interface: 16001
## Title: OneForAll - My Plugin
## Notes: What it does, in one line (shown on the Plugins page).
## Author: Your name
## Version: 1.0.0
## IconTexture: Interface\Icons\INV_Misc_Book_09
## Dependencies: OneForAll
## SavedVariables: MyPluginDB
## SavedVariablesPerCharacter: MyPluginCharDB

Locales.lua
MyPlugin.lua
```

- **`## Dependencies: OneForAll`** is what makes it a plugin: without it, it isn't listed on the Plugins page and may load before OneForAll.
- `## Notes` and `## Author` are shown on the plugin's page.
- **The folder's name is the plugin's name** in every API call (`"MyPlugin"`).
- Prefix the title with `OneForAll - ` so the plugin sits next to OneForAll in the AddOns list.
- `SavedVariables` lines are only needed for data of your own (see [section 11](#11-saved-data)). Options don't need them.

## 3. Checking the API and registering

```lua
local NAME = "MyPlugin"
local API = OneForAllAPI
if not (API and API.VERSION >= 2) then return end

API.RegisterPlugin(NAME, { title = "My Plugin", version = "1.0.0" })
```

- **Check the API first.** With an OneForAll without the API, or one too old, the plugin stops there quietly. Ask for the lowest version that has everything you use (see the *Since* column in the [reference](api-reference.md)).
- **`RegisterPlugin` comes before everything else.** `NewOptions`, `AddSettingsSection` and `AddPluginContent` only work for a registered plugin. Use the folder's name. A name already taken stays with its first plugin, and `RegisterPlugin` then returns `false`.
- **Do all of this while your addon loads**, at the top of your file, not in an event: the Plugins page is built when the player first opens it.

## 4. Reading OneForAll's data

`API.Data` holds all of OneForAll's data tables, by their name in capitals. `API.DataKeys()` lists them.

```lua
for _, d in API.ipairs(API.Data.DUNGEONS) do
  API.Print(API.DungeonName(d.name) .. ": " .. API.Count(d.bosses) .. " bosses")
end
```

Other examples: `API.Data.SETS`, `API.Data.BOOKS`, `API.Data.PROFESSION_RECIPES`. For dungeons, quests and books there are also functions: `GetDungeon(name)`, `FindCurrentDungeon()`, `IsQuestDone(id)`, `GetBookState(book)`…

### Read-only tables: the 3 rules

Every table the API returns is a **read-only view**. It reads like a normal table (`d.name`, `d.bosses[1].npcID`), with three differences:

1. **Iterate with `API.pairs` / `API.ipairs`, count with `API.Count`.** Lua 5.1's own `pairs`, `ipairs` and `#` can't see through a view: they find nothing, and `#t` is `0`.
2. **Writing raises an error.** `d.name = "x"` fails with *"this table is read only"*. For a table you can change, take a copy with `API.Copy(t)`: it's yours, and changing it changes nothing in OneForAll.
3. **No functions and no frames come out.** Data tables never carry code: a field holding a function or a frame reads as `nil`.

Views are cached: the same table always gives the same view, so `d == API.FindCurrentDungeon()` works.

> Lists the API builds for you are plain tables, not views: `GetDungeonsByInstanceID`, `GetPlugins`, `GetInstalledPlugins`, `GetTabs`, `DataKeys`. Lua's own `ipairs` works on those (their entries can still be views).

### Names in the player's language

OneForAll's data is in English: boss, dungeon, item and zone names are the keys. To show them:
- `API.DungeonName(d.name)` gives a dungeon's name in the language chosen in OneForAll;
- `API.Name(englishName)` does the same for a boss, an NPC, an item, a quest or a zone, when OneForAll knows the translation.

Keep the English name for comparisons and for API calls such as `OpenDungeon(d, bossName)`.

## 5. Options

```lua
local opts = API.NewOptions(NAME, { enabled = true, size = 12, sound = "none" })

opts:Get("enabled")                       --> true (the default until changed)
opts:Set("size", 14)
opts:OnChanged("size", function(value) MyPlugin.Resize(value) end)
```

- Options are saved in **OneForAll's profile** as `plugin.<name>.<key>`. They follow the profile and are exported and imported with it, and they can never collide with OneForAll's options or another plugin's.
- **Defaults** are simple values: booleans, numbers, strings. An option may also have no default (e.g. a window position: `opts:Set("pos", { x, y })`, then `opts:Get("pos")` is `nil` until set).
- `NewOptions` works once per plugin: keep the object it returns.
- OneForAll's own options are readable, never writable: `API.GetOption(key)` and `API.OnOptionChanged(key, fn)`.

## 6. Your part of the Plugins page

Each plugin gets its own page on the Plugins page. OneForAll fills the top: description, author, **Enabled** switch. You add **settings sections** and **content blocks** below it, in the order you add them.

### Settings sections

```lua
API.AddSettingsSection(NAME, {
  title = "My Plugin",
  icon = "Interface\\Icons\\INV_Misc_Book_09",
  build = function(s)
    local half = math.floor(s.width / 2)
    s:check("Show the window", "Opens it when you log in.",
      function() return opts:Get("enabled") end,
      function(v) opts:Set("enabled", v) end,
      0, true, half - 50)                        -- x, compact, label width
    s:check("Play a sound", nil,
      function() return opts:Get("sound") ~= "none" end,
      function(v) opts:Set("sound", v and "ding" or "none") end,
      half, true, half - 50)                     -- same row, right half
    s:nextRow()
    s:text("Changes apply at once.")
    s:button("Reset position", 160, function() opts:Set("pos", nil) end)
  end,
})
```

| Builder | What it adds |
|---|---|
| `s:check(label, hint, get, set[, x, compact, width])` | A switch. `get()` returns a boolean, `set(boolean)` stores it. `hint` is shown under the label, or only as a tooltip when `compact` is `true`. `x` moves it right (`0` = left edge). `width` is the label's width: long labels wrap. |
| `s:button(text, width, onClick[, x])` | A gold button. |
| `s:text(str)` | A line of grey text. It takes a row of its own. |
| `s:nextRow()` | Goes to the next row. Switches and buttons stay on the same row until you call it. |
| `s.width` | The section's width. It fills the page's right side and is at least 488. Use it to place two switches side by side: `x = 0` and `x = s.width / 2`. |

- Call `s:nextRow()` after each row of switches or buttons, except after `s:text`, which goes to the next row by itself.
- Switches show their current value whenever the page is shown: `get` is called again each time.
- `build` runs once, the first time the player opens your page. What you pass to `set` and `onClick` runs safely: an error goes to `/ofa errors`.

### Content blocks

For anything settings can't show (a list, a summary, statistics, a preview):

```lua
API.AddPluginContent(NAME, {
  title = "Statistics",
  icon = "Interface\\Icons\\INV_Misc_Note_01",
  height = 200,
  build = function(frame, width)
    local fs = API.Widgets.FontString(frame, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", 4, -4); fs:SetWidth(width - 8); fs:SetJustifyH("LEFT")
    fs:SetText("...")
  end,
})
```

- `frame` is yours: `width` × `height` (20 to 2000), built once. Keep references to what you create to update it later, e.g. from a callback.
- The page scrolls with the mouse wheel when everything doesn't fit, so a tall block is fine.

## 7. Slash commands

```lua
API.RegisterSlashCommand("bosses", function(rest)
  -- /ofa bosses ragefire chasm  ->  rest = "ragefire chasm"
end, "/ofa bosses <dungeon>: the bosses of a dungeon")
```

- The player types `/ofa <word> [rest]`, and your function gets `rest` (`""` when there is nothing after the word).
- OneForAll's own commands always come first. A word another plugin already took stays with it, and `RegisterSlashCommand` then returns `false`. Choose a word specific to your plugin.

## 8. Callbacks and game events

OneForAll tells plugins when something happened in it:

| Event | Arguments | When |
|---|---|---|
| `OPTION_CHANGED` | `key, value` | An option changed: OneForAll's, or a plugin's (`plugin.<name>.<key>`). |
| `TAB_SHOWN` | `key` | A page of the window was shown (`"dungeons"`, `"professions"`, `"plugins"`…). |
| `WINDOW_SHOWN` / `WINDOW_HIDDEN` | – | OneForAll's window opened / closed. |
| `DATA_REFRESHED` | – | OneForAll read the bags or bank again: book and item states may have changed. |

```lua
local function onTab(key) if key == "dungeons" then ... end end
API.RegisterCallback("TAB_SHOWN", onTab)
API.UnregisterCallback("TAB_SHOWN", onTab)   -- the same function
```

For **game events**, use a frame of your own, as in any addon:

```lua
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, event, ...) API.SafeCall("MyPlugin", MyPlugin.OnEvent, event, ...) end)
```

`API.SafeCall(tag, fn, ...)` runs `fn` and sends any error to OneForAll's error list (`/ofa errors`) instead of a Lua popup. It returns `true` when `fn` ran without error.

> WoW Forever doesn't let addons read the combat log (`COMBAT_LOG_EVENT_UNFILTERED`), and the client hides some values in combat ("secret" values): test them with `API.IsSecret(...)` before comparing or showing them.

## 9. Opening OneForAll on a page

```lua
API.OpenTab("books")                                       -- a page of the window
API.OpenDungeon("Ragefire Chasm", "Taragaman the Hungerer") -- a dungeon, on a boss
API.OpenDungeon(d, nil, "loot")                            -- a dungeon's loot
API.ShowBook(book)                                         -- the Library Books page on a book
API.ShowQuestStartOnMap({ id = 5723 })                     -- a quest's start on the world map
```

The first time, OneForAll builds its window and the page over a few frames: in combat, the game stops a script that runs too long. So the page may appear a moment after the call.

## 10. Texts and languages

The player chooses OneForAll's language in its settings (`API.GetLanguage()`: `"enUS"`, `"deDE"`, `"frFR"`, `"esES"` or `"ptBR"`). Changing it reloads the interface, so reading it once while loading is enough.

A simple pattern:
1. your own translations;
2. else OneForAll's translation of the same English text (`API.Translate`): many common words are already there;
3. else the English text.

```lua
local T = { frFR = { ["Bosses"] = "Boss" }, deDE = { ["Bosses"] = "Bosse" } }
local mine = T[API.GetLanguage()] or {}
local function L(text) return mine[text] or API.Translate(text) end
```

## 11. Saved data

- **Options:** use `API.NewOptions` (section 5). Nothing to declare.
- **Data of your own** (a history, statistics, a cache): declare it in your `.toc` (`## SavedVariables: MyPluginDB` for the account, `## SavedVariablesPerCharacter: MyPluginCharDB` per character), and name it after your plugin.
- **OneForAll's saved data** is readable with `API.GetCharacterData()` and `API.GetAccountData()`. It is read only and a snapshot of now: read it again when you need it.

Saved variables are loaded just before your addon's `ADDON_LOADED`. Read them in that event, or later, but not at the top of your file:

```lua
local function db()
  MyPluginDB = type(MyPluginDB) == "table" and MyPluginDB or {}
  return MyPluginDB
end
```

## 12. Your own windows

A plugin can create any frame, as in any addon. To make it look like OneForAll:

| Widget | Use |
|---|---|
| `API.Widgets.FramedPanel(frame)` | OneForAll's dark background with the gold frame. |
| `API.Widgets.CloseButton(parent, onClick)` | The square X button. |
| `API.Widgets.GoldButton(parent, text, width, height)` | A gold button. |
| `API.Widgets.Confirm(text, onYes)` | A Yes / No question. |
| `API.Widgets.FontString(parent, layer, template)` | A text in OneForAll's font. |
| `API.Widgets.SetTexture(texture, path, ...)` | Sets a texture, from the game or from an addon. |
| `API.Widgets.SkinColor(r, g, b)` | A color adapted to the skin chosen in OneForAll. |

Give your frames names that start with your plugin's name (`MyPluginFrame`), so they never meet OneForAll's.

## 13. Testing and debugging

- `/ofa plugins` lists the registered plugins, with their versions: is yours there?
- `/ofa errors` shows the errors of what OneForAll ran for you (settings, buttons, commands, callbacks), and `/ofa errors clear` empties the list.
- `/reload` after each change. After editing the `.toc`, restart the game: it is only read at startup.
- Test with **another language** (French or German in OneForAll's settings): labels get longer, and names come from the game in that language.
- Test **with your plugin turned off** on the Plugins page: OneForAll must work the same.
- Test **in a group and in combat** if your plugin does something there.

## 14. Publishing

- Zip **the plugin's folder** (not its contents): the player puts it into `Interface/AddOns`.
- Say clearly that it needs **OneForAll with the plugin API**, with a link to it.
- Give the version in the `.toc`. Players see it on the Plugins page.
- On GitHub, a workflow can build the zip and attach it to a release on each tag. The [Dungeon Tracker](https://github.com/Emzime/OneForAll-Plugin-DungeonTracker) repository has one (`.github/workflows/build.yml`) that you can copy.
- Licence: OneForAll is under GPL-3.0-or-later. Using the same licence for a plugin (as the Dungeon Tracker does) is the simplest choice. It is required for any part of OneForAll's code you copy into your plugin, rather than calling the API.

## 15. Checklist

- [ ] `## Dependencies: OneForAll` in the `.toc`
- [ ] `API.VERSION` checked, at the lowest version you need
- [ ] `RegisterPlugin` first, with the folder's name
- [ ] `API.ipairs` / `API.pairs` / `API.Count` on what the API returns
- [ ] Nothing written into OneForAll's tables (use `API.Copy` for a copy of your own)
- [ ] Options through `NewOptions`, saved data named after the plugin
- [ ] English names for comparisons, `DungeonName` / `Name` for display
- [ ] Tested in another language, turned off, after `/reload`
- [ ] The zip holds the plugin's folder, and the README links to OneForAll with the API
