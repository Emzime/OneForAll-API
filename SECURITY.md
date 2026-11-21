# Security policy

## Supported versions

Only the latest release gets fixes. A fix comes as a new build (`-api2`, `-api3`…) of the same OneForAll version, or as a build on the next OneForAll version.

| Version | Supported |
|---|---|
| Latest release (`6.2.13-api1`) | ✅ |
| Earlier releases | ❌ |

## What counts as a security issue here

The plugin API promises that **a plugin can read OneForAll but never change it**. A security issue is anything that breaks that promise through the API, for example:
- a table, a function or a widget returned by `OneForAllAPI` that lets a plugin write into OneForAll's data, saved variables, options or functions;
- a way to replace or remove a function of `OneForAllAPI`, another plugin's options, settings or `/ofa` command, or one of OneForAll's commands;
- a way to run code in OneForAll's name from data (a string, a saved variable) without the player doing it.

Out of scope:
- **An addon that changes OneForAll without the API.** In WoW, all addons share one Lua space, so any addon can edit global saved variables or frames directly. The API can't prevent that, and doesn't claim to.
- **Issues in OneForAll itself**, outside `API.lua` and the files listed in the README: report them to OneForAll's author on the [OneForAll Discord](https://discord.gg/JSPUqw4g).
- **Issues in a plugin:** report them to that plugin's repository.

## Reporting

**Please don't open a public issue for a security problem.**

Use GitHub's private reporting: **Security and quality** tab → **Report a vulnerability**. Please include:
- the OneForAll and API versions (`/ofa plugins`, or `API.GetVersion()` and `API.VERSION`);
- a minimal plugin, or a few lines of Lua, that shows the problem;
- what the code manages to change.

You'll get an answer within a week. Once the fix is released, the report is published with credit to you, unless you'd rather stay anonymous.
