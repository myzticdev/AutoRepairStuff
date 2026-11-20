# Auto Repair

Auto Repair repairs equipped items and repairable items in your bags when
you open a repair vendor. Install the same addon folder for WoW Retail and WoW Forever.

## Install

Copy the inner `AutoRepairStuff` folder into `Interface/AddOns/` for each
client you play. The folder should directly contain `AutoRepairStuff.toc` and
`AutoRepairStuff.lua`. Enable Auto Repair on the character selection AddOns screen.

| Client | WoW folder | Interface |
| --- | --- | --- |
| Retail | `_retail_` | 120105, 120107 |
| Forever | `_forever_` | 16001 |

## Settings

Open **Esc → Options → AddOns → Auto Repair** and choose a **Repair mode**.
Pick **Your gold**, **Guild gold when available**, or **Off**.

## Chat commands

| Command | What it does |
| --- | --- |
| `/autorepair` | Show the current mode. |
| `/autorepair personal` | Use your own gold. This is the default. |
| `/autorepair guild` | Use guild funds when your rank permits it and your daily allowance covers the bill. Otherwise, use personal gold if you have enough. |
| `/autorepair off` | Disable automatic repairs. |

The mode is saved per character. If the server rejects a guild repair, use
the vendor's repair button or switch to personal mode and reopen the vendor.
The addon makes one repair request per vendor-open event. After the vendor
updates to show the repair is complete, your chat displays a green message
with the cost and payment source. Keep the vendor window open until the message appears.

## Maintenance

`AutoRepairStuff.lua` contains the event handler, repair rules, and slash
command. There are no library dependencies. For a client update, run
`/run print(select(4, GetBuildInfo()))` in the target client to get its interface
number. Update that client's interface number on the shared TOC line after
checking the addon at a vendor.
