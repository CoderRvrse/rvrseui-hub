-- UniversalHub v2 -- key gate
--
-- What this does: opens the key window, and once a key checks out it loads
-- the hub. That is all it does.
--
-- It is public on purpose. There is no key, no token and no secret in this
-- file -- the only address it talks to is the licence endpoint below, which
-- every copy of the hub already calls.
--
-- Help: https://discord.gg/FJxrnAcawn

local HUB_URL = "https://raw.githubusercontent.com/CoderRvrse/rvrseui-hub/main/UniversalHub_v2.lua"
local RVRSEUI_URL = "https://raw.githubusercontent.com/CoderRvrse/RvrseUI/main/RvrseUI.lua"
local ENDPOINT = "https://luavm-rvrse-license-production.up.railway.app/api/v1/licensing/validate"

local BUILD_ID = "b2ef1950afd7edca"

local g = (getgenv and getgenv()) or _G or {}
HUB_URL = g.UNIVERSALHUB_URL or HUB_URL
RVRSEUI_URL = g.RVRSEUI_SOURCE or RVRSEUI_URL
BUILD_ID = g.UNIVERSALHUB_BUILD_ID or BUILD_ID

local function say(...)
	if g.LUAVM_DEBUG then
		print("[KEYGATE]", ...)
	end
end

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

			Endpoint = ENDPOINT,
			BuildId = BUILD_ID,
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

	say("no key -- not loading the hub")
	return
end

if getgenv then
	getgenv().LUAVM_LICENSE_KEY = theKey
else
	_G.LUAVM_LICENSE_KEY = theKey
end

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
