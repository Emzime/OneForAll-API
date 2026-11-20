# OneForAllAPI reference

`OneForAllAPI` is the only door between a plugin and OneForAll. It is itself read only: no plugin can replace or remove one of its functions.

```lua
local API = OneForAllAPI
if not (API and API.VERSION >= 2) then return end
```

**Since** is the first `API.VERSION` with the function. Ask for the highest *Since* among the functions you use.

| `VERSION` | OneForAll | Added |
|---|---|---|
| 2 | 6.2.11-api1 | The first published API. |
| 3 | 6.2.12-api1 | `GetQuestInfo`, `IsQuestForMe`, `IsRaidOpen`. Opening a page now uses OneForAll's step-by-step window build. |

A function never changes once published. Anything new comes as a new function in a higher version.

**Conventions on this page:**
- *view*: a read-only table (see [Read-only tables](#read-only-tables)).
- *name*: the plugin's name, i.e. its addon folder's name, as given to `RegisterPlugin`.
- Dungeon, boss, item, quest and zone names are **English**: they are the keys of OneForAll's data.

## Contents

- [Read-only tables](#read-only-tables)
- [About OneForAll](#about-oneforall)
- [Plugins](#plugins)
- [Window and pages](#window-and-pages)
- [Dungeons and raids](#dungeons-and-raids)
- [Quests](#quests)
- [Library books](#library-books)
- [Items, recipes, map](#items-recipes-map)
- [Saved data](#saved-data)
- [Options](#options)
- [Plugins page](#plugins-page)
- [Slash commands](#slash-commands)
- [Callbacks](#callbacks)
- [Widgets](#widgets)

---

## Read-only tables

| Function | Returns | Since |
|---|---|---|
| `API.Data` | A view of every OneForAll data table, by name in capitals: `Data.DUNGEONS`, `Data.SETS`, `Data.BOOKS`, `Data.PROFESSION_RECIPES`… | 2 |
| `API.DataKeys()` | A sorted plain list of the names in `API.Data`. | 2 |
| `API.pairs(t)` | Like `pairs`, for views and plain tables. | 2 |
| `API.ipairs(t)` | Like `ipairs`, for views and plain tables. | 2 |
| `API.Count(t)` | Like `#t`, for views and plain tables. | 2 |
| `API.IsReadOnly(t)` | `true` for a view. | 2 |
| `API.Copy(t)` | A plain, writable deep copy, yours to change. Functions and frames are left out. | 2 |

What a view does:
- **Reading** works as usual, and tables inside come out as views too.
- **Writing** raises *"OneForAll: this table is read only"*.
- **Functions and frames never come out:** such a field reads as `nil`.
- **Lua 5.1's `pairs`, `ipairs` and `#`** see an empty table: use `API.pairs`, `API.ipairs` and `API.Count`.
- **The same table always gives the same view**, so `==` compares them.

---

## About OneForAll

| Function | Returns | Since |
|---|---|---|
| `API.VERSION` | The API's version (number). | 2 |
| `API.GetVersion()` | OneForAll's version from its `.toc`, e.g. `"6.2.12-api1"`. | 2 |
| `API.GetLanguage()` | The language chosen in OneForAll: `"enUS"`, `"deDE"`, `"frFR"`, `"esES"` or `"ptBR"`. Changing it reloads the interface. | 2 |
| `API.Translate(text)` | OneForAll's translation of an English text, or the text itself. | 2 |
| `API.Name(englishName)` | A boss, NPC, item, quest or zone name in the chosen language when OneForAll knows it, else the English name. | 2 |
| `API.Print(text)` | Prints a line in the chat with OneForAll's prefix. | 2 |
| `API.IsSecret(...)` | `true` when one of the values is a "secret" the client hides in combat. Such a value can't be compared or shown. | 2 |
| `API.SafeCall(tag, fn, ...)` | Runs `fn(...)`. An error goes to OneForAll's error list (`/ofa errors`) under `tag`, not to a Lua popup. Returns `true` when `fn` ran without error. | 2 |

---

## Plugins

| Function | Returns | Since |
|---|---|---|
| `API.RegisterPlugin(name, info)` | `true`, or `false` when the name is taken or invalid. `info = { title = "My Plugin", version = "1.0.0" }`. Call it first: options, settings and content need a registered plugin. | 2 |
| `API.GetPlugins()` | The registered plugins, sorted by name: a plain list of `{ name, title, version }`. | 2 |
| `API.GetInstalledPlugins()` | Every addon with `## Dependencies: OneForAll`, loaded or not: a plain list of `{ name, title, version, notes, author, loaded, enabled }`. | 2 |

---

## Window and pages

Page keys: `"dungeons"`, `"professions"`, `"qol"`, `"talents"`, `"books"`, `"pets"`, `"settings"`, `"plugins"`… `GetTabs()` gives the current list.

| Function | Returns | Since |
|---|---|---|
| `API.OpenTab(key)` | Opens the window on a page. With `nil`, opens it as it was. | 2 |
| `API.ToggleWindow()` | Opens or closes the window. | 2 |
| `API.IsWindowShown()` | `true` when the window is open. | 2 |
| `API.GetActiveTab()` | The key of the page shown, or `nil`. | 2 |
| `API.GetTabs()` | The pages in their order: a plain list of `{ key, label, shown }`. `label` is translated; `shown` is `false` when the player hid that tab. | 2 |

The first time the window or a page opens, OneForAll builds it over a few frames (since 3), so the page may appear a moment after the call.

---

## Dungeons and raids

A dungeon (view) has, among others:

| Field | Content |
|---|---|
| `name` | English name, the key: `"Ragefire Chasm"`. |
| `level` | Level range: `"13-18"`. |
| `minLevel`, `maxLevel` | Numbers, when known. |
| `raid`, `size` | Raid flag and size. |
| `instanceID` | When known. |
| `area` | Where it is. |
| `bosses` | In the dungeon's order: `{ name, npcID, rare, aliases, loot, ... }`. |
| `quests` | The dungeon's quests. |
| `trashLoot` | Loot from non-boss enemies. |

| Function | Returns | Since |
|---|---|---|
| `API.GetDungeons()` | A view of every dungeon and raid. | 2 |
| `API.GetDungeon(name)` | The dungeon (view) by its English name, or `nil`. | 2 |
| `API.GetDungeonsByInstanceID(id)` | A plain list of the dungeons (views) using an instance ID (`GetInstanceInfo`'s 8th value). Several where wings share an instance: Scarlet Monastery, Dire Maul, Blackrock Spire. | 2 |
| `API.FindCurrentDungeon()` | `d, sure`: the dungeon the player is in (view), or `nil`. `sure` is `false` when OneForAll only guesses the wing. | 2 |
| `API.DungeonName(name)` | A dungeon's name in the chosen language. | 2 |
| `API.IsSummonedBoss(npcID)` | `true` for a boss that only appears when summoned. | 2 |
| `API.OpenDungeon(d, bossName, mode, questID)` | Opens OneForAll on a dungeon (view or English name), on a boss when `bossName` (English) is given. `mode`: `"bosses"` (default), `"loot"` or `"quests"`. `questID` shows a quest (with `"quests"`). Returns `true` when the dungeon exists. | 2 |
| `API.IsRaidOpen(d)` | `false` while a raid isn't open on the server yet (Onyxia's Lair, Hyjal Summit, Barrow Deeps), else `true`. `d`: a dungeon (view) or its English name. | 3 |

---

## Quests

| Function | Returns | Since |
|---|---|---|
| `API.IsQuestDone(questID)` | `true` when this character completed it. | 2 |
| `API.IsQuestGrey(questID[, level])` | `true` when it gives no more XP at the player's level, or at `level`. | 2 |
| `API.GetQuestInfo(questID)` | A view `{ id, name, lvl, req, side, cls, races, giver, loc = { mapID, x, y }, ... }`, or `nil`. | 3 |
| `API.IsQuestForMe(questID)` | `true` when the quest is for the player's faction, class and race. | 3 |
| `API.GetQuestStart(questID)` | Where it starts: a view `{ mapID, x, y, ... }`, or `nil`. | 2 |
| `API.GetQuestEnd(questID)` | Where it is turned in, same format. | 2 |
| `API.ShowQuestStartOnMap(quest)` | Puts a quest's start on the world map. `quest`: from `API.Data`, or `{ id = questID }`. | 2 |

---

## Library books

| Function | Returns | Since |
|---|---|---|
| `API.FindBookByQuestID(questID)` | The book (view) a quest belongs to, or `nil`. | 2 |
| `API.GetBookState(book)` | For this character: `"done"`, `"manual"`, `"bag"`, `"bank"`, `"questflag"` or `"missing"`. | 2 |
| `API.GetBookCounts()` | `turnedIn, owned`. `owned` counts books turned in plus those in the bags or bank. | 2 |
| `API.ShowBook(book)` | Opens the Library Books page on a book. | 2 |
| `API.ShowBookOnMap(book)` | Puts a book on the world map. | 2 |

---

## Items, recipes, map

| Function | Returns | Since |
|---|---|---|
| `API.GetItemStorageState(itemID)` | Where an item is for this character, as OneForAll last saw it: `"bag"`, `"bank"`, `"missing"` or `"unknown"`. | 2 |
| `API.GetRecipeFullName(recipe)` | A recipe's full name (`"Recipe: ..."`). `recipe` comes from `API.Data.PROFESSION_RECIPES` and similar tables. | 2 |
| `API.GetRecipeItemLink(recipe)` | The recipe's item link. | 2 |
| `API.FindMapID(zone)` | A zone's map ID from its English name, or `nil`. | 2 |

---

## Saved data

Read only, as it is now: read it again when you need it.

| Function | Returns | Since |
|---|---|---|
| `API.GetCharacterKey()` | This character's key in OneForAll's data (the player's GUID). | 2 |
| `API.GetCharacterData()` | A view of what OneForAll saved for this character. | 2 |
| `API.GetAccountData()` | A view of what OneForAll saved for the account. | 2 |

---

## Options

| Function | Returns | Since |
|---|---|---|
| `API.GetOption(key)` | One of OneForAll's options; a table comes out as a view. | 2 |
| `API.OnOptionChanged(key, fn)` | Calls `fn(value)` after one of OneForAll's options changed. | 2 |
| `API.NewOptions(name, defaults)` | The plugin's own options object, or `nil` when the plugin isn't registered or already has one. `defaults` holds simple values (boolean, number, string). | 2 |
| `opts:Get(key)` | The value, or its default. | 2 |
| `opts:Set(key, value)` | Stores it. Tables are allowed, functions aren't. Returns `true` when stored. | 2 |
| `opts:OnChanged(key, fn)` | Calls `fn(value)` after it changed. | 2 |

A plugin's options are saved in OneForAll's profile as `plugin.<name>.<key>`. They follow the profile and are exported and imported with it.

---

## Plugins page

| Function | Returns | Since |
|---|---|---|
| `API.AddSettingsSection(name, def)` | `true` when added. `def = { title, icon, build = function(s) ... end }`. Several sections stack in the order added. | 2 |
| `API.AddPluginContent(name, def)` | `true` when added. `def = { title, icon, height, build = function(frame, width) ... end }`. `height` is 20 to 2000 (default 120). | 2 |

The section builder `s`:

| Member | What it does |
|---|---|
| `s:check(label, hint, get, set[, x, compact, width])` | A switch. `get()` returns a boolean, `set(boolean)` stores it. `hint` is shown under the label, or only as a tooltip with `compact = true`. `x` is the offset from the left. `width` is the label's width; long labels wrap. Returns the check button. |
| `s:button(text, width, onClick[, x])` | A gold button. Returns it. |
| `s:text(str)` | A line of grey text, on a row of its own. |
| `s:nextRow()` | The next row. Switches and buttons share a row until it is called. |
| `s.width` | The section's width. It fills the right side of the page and is at least 488. |

`build` runs once, the first time the player opens the plugin's page. `get` runs again each time the page is shown. Errors in `set`, `onClick` and `build` go to `/ofa errors`.

---

## Slash commands

| Function | Returns | Since |
|---|---|---|
| `API.RegisterSlashCommand(word, fn, help)` | `true`, or `false` when `word` is taken. `/ofa <word> [rest]` calls `fn(rest)`, with `rest` `""` when nothing follows. OneForAll's own commands come first. | 2 |

---

## Callbacks

| Function | Returns | Since |
|---|---|---|
| `API.RegisterCallback(event, fn)` | `true`, or `false` for an unknown event. | 2 |
| `API.UnregisterCallback(event, fn)` | `true` when `fn` was registered for `event`. | 2 |

| Event | Arguments | When |
|---|---|---|
| `OPTION_CHANGED` | `key, value` | An option changed: OneForAll's, or a plugin's (`plugin.<name>.<key>`). |
| `TAB_SHOWN` | `key` | A page of the window was shown. |
| `WINDOW_SHOWN` | – | OneForAll's window opened. |
| `WINDOW_HIDDEN` | – | OneForAll's window closed. |
| `DATA_REFRESHED` | – | OneForAll read the bags or bank again. |

Callbacks run through `SafeCall`: an error in one doesn't stop the others.

---

## Widgets

OneForAll's look, on frames of your own: `API.Widgets.<name>`.

| Function | What it does | Since |
|---|---|---|
| `FramedPanel(frame)` | OneForAll's dark background with the gold frame. | 2 |
| `CloseButton(parent, onClick)` | The square X button. Returns it. | 2 |
| `GoldButton(parent, text[, width, height])` | A gold button (default 120 × 24). Returns it. | 2 |
| `Confirm(text, onYes)` | A Yes / No question. `onYes()` runs on Yes. | 2 |
| `FontString(parent[, layer, template])` | A font string in OneForAll's font. | 2 |
| `SetTexture(texture, path, ...)` | Sets a texture, from the game or from an addon. | 2 |
| `SkinColor(r, g, b)` | The color adapted to the skin chosen in OneForAll: returns `r, g, b`. | 2 |
