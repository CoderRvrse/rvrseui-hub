# RvrseUI — UniversalHub v2

This repository holds **only the small key gate**. The source lives in a
private repository, and the hub itself is not here at all: it is served by the
licence server, and only to a key that checks out. Nothing here is
hand-written.

## Run it

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/CoderRvrse/rvrseui-hub/main/KeyGate.lua"))()
```

Paste that line into your executor **while you are in a Roblox game**, and run it.
A key window opens. Get a key, and the hub loads by itself.

**Do not paste the hub file itself.** A pasted file over 512 KB silently does
nothing on Delta — no window, no error. Always use the `loadstring` line above.

## Keys

The hub asks for a key on launch. Keys are **free** and last **24 hours** —
press *Get a free key* in the key window, or use `/getkey` in the Discord.

A key locks to **the first device that runs it** and to **the first hub it
opens**, and refuses everything else. So a shared key just stops working for
both people, and a key earned here does not open somebody else's script. Get
your own — it's free.

If the ad page offers you a long wait instead of ads, it hands over nothing on
its own: **open the same link again when the timer ends**.

**Nobody will ever ask you for your Roblox password.** Anyone who does is
scamming you.

## Hide and show

Press **Right Ctrl** to hide and show the hub.

## Files here

| File | What it is |
|---|---|
| `KeyGate.lua` | What you run. Shows the key window, then loads the hub. |

The hub used to sit here as a file anyone could download. It is encrypted, so
what they got was a locked box — but handing a locked box to every passer-by is
still a choice, and it is not one we make any more. The gate now asks the
licence server for a one-time download link, which lasts about a minute and
works once. Without a key there is nothing to download.
