# Shopping List for EllesmereUI

A profession shopping list, built as a plugin for [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI).
Track recipes (with a number of crafts) and see the reagents they need against what your character has.
The list window and its options look and behave like the rest of EllesmereUI.

Not made or supported by Ellesmere. Please report problems here, not to EllesmereUI.

## Features

- **Track recipes** from the profession window: a count box beside Blizzard's Track Recipe checkbox (or our
  own checkbox, if you keep Blizzard's tracking separate). Every craft of a tracked recipe takes one off.
- **Reagents** for all tracked crafts, summed, against bags + bank (+ warband bank on retail), with
  sub-crafts: reagents you can make yourself show an anvil tag and can track their own recipe.
- **Cooldowns** of tracked recipes (transmutes and the like), with an optional chat line / sound when ready.
- **Merchants**: a `+` on merchant items to add them to the list, a highlight on items the list needs,
  and a Buy Needed button (asks first above a gold limit you set).
- **Auction House**: a button that searches the next missing reagent by its exact name, ignoring your AH
  filters for that one search.
- **Tooltips**: "Shopping List: have / need" on any item the list needs.
- A window styled like EllesmereUI's Damage Meters: header, border, bar texture, fonts, lock, collapse,
  visibility rules, and a place in EllesmereUI's Unlock Mode.

Works on retail (12.x) and WoW Forever.

## Install

Requires EllesmereUI. Copy the `ShoppingListEUI` folder into `Interface/AddOns`. Its settings are in the
EllesmereUI options panel, under **Plugins > Shopping List**. `/shoplist` lists the slash commands.

Settings are stored per EllesmereUI profile (they follow profile swaps, sync and full-profile exports);
the list itself is per character.

## Development

Offline test harness (Lua 5.4 standing in for the client's 5.1), from this folder:

    lua tests/harness.lua .

It prints `HARNESS OK` and exits 0; any failure exits non-zero.

The options page uses EllesmereUI's sidebar, which has no public API for third-party addons:
`ShoppingListEUI_EUI.lua` registers the page the way other EllesmereUI companion addons do. If a future
EllesmereUI stops accepting it, the list keeps working and one chat line says the options page is missing.

## Credits

Inspired by [Profession Shopping List](https://github.com/Slackluster/ProfessionShoppingList) by Slackluster;
written from scratch (no code from it). Originally proposed to EllesmereUI as a module
([#2289](https://github.com/EllesmereGaming/EllesmereUI/pull/2289)); Ellesmere suggested a plugin instead.
EllesmereUI and its media belong to their authors; this addon ships none of them (the window's header icons
are read from your EllesmereUI install).

## License

MIT, see [LICENSE](LICENSE).
