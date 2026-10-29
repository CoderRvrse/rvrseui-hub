--[[
	UniversalHub v2 -- KEY GATE
	===========================

	This is the file players run. It is small, public and unprotected on
	purpose: its only job is to get a key into the player's hands and then
	hand over to the real hub.

	WHY IT HAS TO EXIST
	-------------------
	The hub itself is a FULL-LOCK build. The licence wrapper reads
	getgenv().LUAVM_LICENSE_KEY *before a single line of hub code runs*, so a
	key window living inside the hub could never be shown to somebody who does
	not have a key yet. Chicken and egg: the only people who could press
	"Get a free key" are the ones who no longer need to.

	That is exactly what shipped. The public README promised "press Get a free
	key in the key window" while the published file contained no key window at
	all (checked 2026-10-29: KeySystem, free/start and "Get a free key" each
	appear ZERO times in it). A new player pasted the documented line, had no
	key set, and the licence gate refused them before anything was drawn.

	So the key window moves OUT of the locked file and in front of it:

	    player runs this  ->  key window (with the free-key button)
	                      ->  getgenv().LUAVM_LICENSE_KEY = <their key>
	                      ->  loadstring the full-lock hub

	Full lock still protects the hub's source; the player still gets the free
	key flow the README describes. Nothing here is secret -- there is no token,
	no admin endpoint and no key in this file, only the public licence endpoint
	every hub already calls.
]]

local HUB_URL = "https://raw.githubusercontent.com/CoderRvrse/rvrseui-hub/main/UniversalHub_v2.lua"
local RVRSEUI_URL = "https://raw.githubusercontent.com/CoderRvrse/RvrseUI/main/RvrseUI.lua"
local ENDPOINT = "https://luavm-rvrse-license-production.up.railway.app/api/v1/licensing/validate"

-- A loader can point these somewhere else to test a change before it is live.
local g = (getgenv and getgenv()) or _G or {}
HUB_URL = g.UNIVERSALHUB_URL or HUB_URL
RVRSEUI_URL = g.RVRSEUI_SOURCE or RVRSEUI_URL

local function say(...)
	if g.LUAVM_DEBUG then
		print("[KEYGATE]", ...)
	end
end

-- Fetch with whichever name this executor uses. game:HttpGet is the one every
-- executor has; the others are tried first only because they report failures
-- more usefully.
local function fetch(url)
	local fns = { syn and syn.request, http and http.request, http_request, request }
	for _, fn in ipairs(fns) do
		if type(fn) == "function" then
			local ok, res = pcall(fn, { Url = url, Method = "GET" })
			if ok and type(res) == "table" and res.StatusCode == 200 and res.Body then
				return res.Body
			end
		end
	end
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end
	return nil
end

local function run(source, chunkName)
	local fn, err = loadstring(source, chunkName)
	if not fn then
		return nil, err
	end
	local ok, result = pcall(fn)
	if not ok then
		return nil, result
	end
	return result or true
end

-- ── RvrseUI ────────────────────────────────────────────────────────
say("fetching RvrseUI")
local uiSource = fetch(RVRSEUI_URL)
if not uiSource then
	warn("[KEYGATE] could not download RvrseUI -- check your internet and try again")
	return
end
local RvrseUI, uiErr = run(uiSource, "=RvrseUI")
if type(RvrseUI) ~= "table" then
	warn("[KEYGATE] RvrseUI did not load: " .. tostring(uiErr))
	return
end
say("RvrseUI", RvrseUI.Version and RvrseUI.Version.Full or "?")

-- ── the key window ─────────────────────────────────────────────────
--
-- CreateWindow does not return until the key is settled, so `unlocked` is set
-- from inside OnKeyValid rather than guessed from what comes back. A window
-- object comes back either way -- a real one when the key was good, a stand-in
-- when the player closed the window -- and loading a 2.5 MB protected hub on a
-- guess is not something to get wrong.
local unlocked, theKey = false, nil

local Window = RvrseUI:CreateWindow({
	Name = "UniversalHub v2",
	Icon = "lucide://key-round",
	Theme = "Dark",
	KeySystem = true,
	KeySettings = {
		Title = "UniversalHub v2",
		Subtitle = "Free key -- 24 hours, one device",
		Note = "Press 'Get a free key' below, or use /getkey in the Discord.",

		License = {
			-- No BuildId on purpose. A free key is issued unbound, and an
			-- unbound key opens any hub; naming a build here would make a
			-- perfectly good free key come back as WRONG_HUB, which the player
			-- reads as "invalid key".
			Endpoint = ENDPOINT,
		},

		SaveKey = true,
		FileName = "UniversalHubKey",
		MaxAttempts = 5,

		OnKeyValid = function(key)
			unlocked = true
			theKey = key
		end,
	},
})

if not unlocked or type(theKey) ~= "string" or theKey == "" then
	-- Closed, or out of attempts. RvrseUI has already told them why, and in
	-- 4.8.2 closing the key window fires the close hook, so nothing is left
	-- running behind this.
	say("no key -- not loading the hub")
	return
end

-- ── hand the key to the full-lock hub ──────────────────────────────
--
-- This is the whole point of the file. The licence wrapper inside the hub
-- reads exactly this global, and RvrseUI's own one-key bridge reads it too, so
-- the player never types a key twice.
if getgenv then
	getgenv().LUAVM_LICENSE_KEY = theKey
else
	_G.LUAVM_LICENSE_KEY = theKey
end

-- The gate has done its job. Take its window away before the hub draws its
-- own, so the player is never looking at two.
pcall(function()
	if type(Window) == "table" and type(Window.Destroy) == "function" then
		Window:Destroy()
	end
end)

say("key accepted, loading the hub")
local hubSource = fetch(HUB_URL)
if not hubSource then
	warn("[KEYGATE] could not download the hub -- check your internet and try again")
	return
end
say("fetched " .. #hubSource .. " bytes")

-- Coming back after a server hop: the hub hands this to queue_on_teleport, so
-- the player arrives already keyed instead of being asked again. It carries a
-- key, so it is never printed.
pcall(function()
	local env = (getgenv and getgenv()) or _G
	env.LUAVM_RELOAD = ("getgenv().LUAVM_LICENSE_KEY=%q loadstring(game:HttpGet(%q))()"):format(theKey, HUB_URL)
end)

local ok, err = run(hubSource, "=UniversalHub_v2")
if not ok then
	warn("[KEYGATE] the hub did not start: " .. tostring(err))
	return
end
say("hub started")
