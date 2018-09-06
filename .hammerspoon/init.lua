function array_concat(...)
    local t = {}
    for n = 1,select("#",...) do
        local arg = select(n,...)
        if type(arg)=="table" then
            for _,v in ipairs(arg) do
                t[#t+1] = v
            end
        else
            t[#t+1] = arg
        end
    end
    return t
end

-- Load Extensions
local application = require "hs.application"
local window = require "hs.window"
local hotkey = require "hs.hotkey"
local keycodes = require "hs.keycodes"
local fnutils = require "hs.fnutils"
local alert = require "hs.alert"
local screen = require "hs.screen"
local grid = require "hs.grid"
local hints = require "hs.hints"
local appfinder = require "hs.appfinder"
local tabs = require "hs.tabs"
local highlight = require "hs.window.highlight"

local definitions = nil
-- A global variable for the Hyper Mode
local hyperKey = nil
local hyperKeyStub = nil

local watchers = {}

-- window highlighting
-- highlight.ui.overlay = true
-- highlight.ui.overlayColor = {0, 0, 0, 0}
highlight.ui.isolateColor = {0.1, 0.1, 0.1, 0.85}
-- highlight.ui.windowShownFlashColor = {1, 0.6, 0, 0.5}
-- highlight.ui.flashDuration = 0.3
-- highlight.ui.frameWidth = 10
-- highlight.ui.frameColor = {1, 0.6, 0, 0.5}
highlight.start()

hs.application.enableSpotlightForNameSearches(true)

-- Allow saving focus, then restoring it later.
auxWin = nil
function saveFocus()
  auxWin = window.focusedWindow()
  alert.show("Window '" .. auxWin:title() .. "' saved.")
end
function focusSaved()
  if auxWin then
    auxWin:focus()
  end
end

--
-- Hotkeys
--
local hotkeys = {}
function createHotkeys()
  bindHyperKeyStub()

  for key, fun in pairs(definitions) do
    if key == "." then alert.show("Key bound to `.`, which is an internal OS X shortcut for sysdiagnose.") end
    local mod = hyper
    -- Any definitions ending with c are cmd defs
    if string.len(key) == 2 and string.sub(key,2,2) == "c" then
      key = string.sub(key,1,1)
      mod = {"cmd"}
    -- Ending with l are ctrl
    elseif string.len(key) == 2 and string.sub(key,2,2) == "l" then
      key = string.sub(key,1,1)
      mod = {"ctrl"}
    elseif string.len(key) == 4 and string.sub(key,2,4) == "raw" then
      key = string.sub(key,1,1)
      mod = {}
    end

    -- Sierra hack
    if mod == hyper then
      -- Bind to the existing F17 stub
      hyperKeyStub:bind({}, key, nil, fun)
    else
      local hk = hotkey.new(mod, key, fun)
      table.insert(hotkeys, hk)
      hk:enable()
    end
  end
  createOtherHotkeys(hyperKeyStub)
end

function rebindHotkeys()
  for i, hk in ipairs(hotkeys) do
    hk:disable()
  end
  hyperKey:delete()
  hyperKeyStub:delete()

  hotkeys = {}
  createHotkeys()
  alert.show("Rebound Hotkeys")
end

function bindHyperKeyStub()
  -- Create a new F17 global
  hyperKeyStub = hs.hotkey.modal.new({}, "F17")

  -- Enter Hyper Mode when F18 (Hyper/Capslock) is pressed
  pressedF18 = function()
    hyperKeyStub.triggered = false
    hyperKeyStub:enter()
  end

  -- Leave Hyper Mode when F18 (Hyper/Capslock) is pressed,
  --   send ESCAPE if no other keys are pressed.
  releasedF18 = function()
    hyperKeyStub:exit()
    if not hyperKeyStub.triggered then
      hs.eventtap.keyStroke({}, 'ESCAPE')
    end
  end

  -- Bind the Hyper key
  hyperKey = hs.hotkey.bind({}, 'F18', pressedF18, releasedF18)
end

--
-- Grid
--

-- HO function for automating moving a window to a predefined position.
local gridset = function(frame)
  return function()
    local win = window.focusedWindow()
    if win then
      grid.set(win, frame, win:screen())
    else
      alert.show("No focused window.")
    end
  end
end

function applyPlace(win, place)
  local scrs = screen.allScreens()
  local scr = scrs[place[1]]
  grid.set(win, place[2], scr)
end

function applyLayout(layout, name)
  return function()
    alert.show(string.format("Applying Layout %s", name))

    for i, item in ipairs(layout) do
      -- Two types we allow: table, which is {appName, windowTitle}, or just the app itself
      local appData = item["appData"]
      local place = item["place"]
      if type(appData) == 'table' then
        local parentAppName = appData["appName"]
        local windowPattern = appData["title"]
        local app = appfinder.appFromName(parentAppName)
        if app then
          local window = app:findWindow(windowPattern)
          if window then
            applyPlace(window, place)
          end
        end
      else
        local appName = appData
        local app = appfinder.appFromName(appName)
        if app then
          if item["onlyFocused"] then
            applyPlace(app:focusedWindow(), place)
          else
            for i, win in ipairs(app:allWindows()) do
              applyPlace(win, place)
            end
          end
        end
      end
    end
  end
end

--
-- Conf
--

--
-- Utility
--

function reloadConfig(files)
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end

-- Prints out a table like a JSON object. Utility
function serializeTable(val, name, skipnewlines, depth)
  skipnewlines = skipnewlines or false
  depth = depth or 0

  local tmp = string.rep(" ", depth)

  if name then tmp = tmp .. name .. " = " end

  if type(val) == "table" then
    tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

    for k, v in pairs(val) do
      tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
    end

    tmp = tmp .. string.rep(" ", depth) .. "}"
  elseif type(val) == "number" then
    tmp = tmp .. tostring(val)
  elseif type(val) == "string" then
    tmp = tmp .. string.format("%q", val)
  elseif type(val) == "boolean" then
    tmp = tmp .. (val and "true" or "false")
  else
    tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
  end

  return tmp
end

function string.starts(str,Start)
  return string.sub(str,1,string.len(Start))==Start
end

--
-- WiFi
--

-- local home = {["Lemonparty"] = TRUE, ["Lemonparty 5GHz"] = TRUE}
-- local lastSSID = hs.wifi.currentNetwork()

-- function ssidChangedCallback()
--   newSSID = hs.wifi.currentNetwork()

--   if newSSID == lastSSID then return end

--   if home[newSSID] and not home[lastSSID] then
--     -- We just joined our home WiFi network
--     hs.audiodevice.defaultOutputDevice():setVolume(25)
--   elseif not home[newSSID] and home[lastSSID] then
--     -- We just departed our home WiFi network
--     hs.audiodevice.defaultOutputDevice():setVolume(0)
--   end

--   local messages = appfinder.appFromName('Messages')
--   messages:selectMenuItem("Log In")

--   lastSSID = newSSID
-- end

-- local wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
-- wifiWatcher:start()

--
-- Sound
--

-- Mute on jack in/out
-- function audioCallback(uid, eventName, eventScope, channelIdx)
--   if eventName == 'jack' then
--     alert("Jack changed, muting.", 1)
--     hs.audiodevice.defaultOutputDevice():setVolume(0)
--   end
-- end
--
--
-- -- Watch device; mute when headphones unplugged.
-- local defaultDevice = hs.audiodevice.defaultOutputDevice()
-- defaultDevice:watcherCallback(audioCallback);
-- defaultDevice:watcherStart();

--
-- Battery / Power
--

-- Disable spotlight indexing while on battery.
--
-- In order for this to work, add this to a file in `/etc/sudoers.d/`:
-- <username> ALL=(root) NOPASSWD: /usr/bin/mdutil -i on /
-- <username> ALL=(root) NOPASSWD: /usr/bin/mdutil -i off /
-- Verify with `sudo -l`
--
--
-- Removing this for now, appears to just churn CPU
--
-- local currentPowerSource = nil;
-- function batteryWatchUnplugged()
--   newPowerSource = hs.battery.powerSource();
--   if newPowerSource ~= currentPowerSource then
--     alert(string.format("New power source: %s", newPowerSource), 1);

--     function taskCb(code, stdout, stderr)
--       if code ~= 0 then
--         alert("Failed, check console.");
--       end
--       print("stdout: "..stdout);
--       print("stderr: "..stderr)
--     end
--     if newPowerSource == 'Battery Power' then
--       alert("Disabling spotlight.", 1);
--       hs.task.new("/usr/bin/sudo", taskCb, {"/usr/bin/mdutil", "-i", "off", "/"}):start()
--     else
--       alert("Enabling spotlight.", 1);
--       hs.task.new("/usr/bin/sudo", taskCb, {"/usr/bin/mdutil", "-i", "on", "/"}):start()
--     end
--     currentPowerSource = newPowerSource;
--   end
-- end
-- local batteryWatcher = hs.battery.watcher.new(batteryWatchUnplugged):start();
-- batteryWatchUnplugged();

--
-- Application overrides
--


--
-- Fix Slack's channel switching.
-- This rebinds ctrl-tab and ctrl-shift-tab back to switching channels,
-- which is what they did before the Teams update.
--
-- Slack only provides alt+up/down for switching channels, (and the cmd-t switcher,
-- which is buggy) and have 3 (!) shortcuts for switching teams, most of which are
-- the usual tab switching shortcuts in every other app.
--
-- This basically turns the tab switching shortcuts into LimeChat shortcuts, which very smartly
-- uses the brackets to switch any channel, and ctrl-(shift)-tab to switch unreads.
-- local slackKeybinds = {
--   hotkey.new({"ctrl"}, "tab", function()
--     hs.eventtap.keyStroke({"alt", "shift"}, "Down")
--   end),
--   hotkey.new({"ctrl", "shift"}, "tab", function()
--     hs.eventtap.keyStroke({"alt", "shift"}, "Up")
--   end),
--   hotkey.new({"cmd", "shift"}, "[", function()
--     hs.eventtap.keyStroke({"alt"}, "Up")
--   end),
--   hotkey.new({"cmd", "shift"}, "]", function()
--     hs.eventtap.keyStroke({"alt"}, "Down")
--   end),
--   -- Disables cmd-w entirely, which is so annoying on slack
--   hotkey.new({"cmd"}, "w", function() return end)
-- }
-- local slackWatcher = hs.application.watcher.new(function(name, eventType, app)
--   if eventType ~= hs.application.watcher.activated then return end
--   local fnName = name == "Slack" and "enable" or "disable"
--   for i, keybind in ipairs(slackKeybinds) do
--     -- Remember that lua is weird, so this is the same as keybind.enable() in JS, `this` is first param
--     keybind[fnName](keybind)
--   end
-- end)
-- slackWatcher:start()

--
-- Fix Skype's channel switching.
--
-- local skypeKeybinds = {
--   hotkey.new({"ctrl"}, "tab", function()
--     hs.eventtap.keyStroke({"alt", "cmd"}, "Right")
--   end),
--   hotkey.new({"ctrl", "shift"}, "tab", function()
--     hs.eventtap.keyStroke({"alt", "cmd"}, "Left")
--   end)
-- }
-- local skypeWatcher = hs.application.watcher.new(function(name, eventType, app)
--   if eventType ~= hs.application.watcher.activated then return end
--   local fnName = name == "Skype" and "enable" or "disable"
--   for i, keybind in ipairs(skypeKeybinds) do
--     -- Remember that lua is weird, so this is the same as keybind.enable() in JS, `this` is first param
--     keybind[fnName](keybind)
--   end
-- end)
-- skypeWatcher:start()

--
-- INIT!
--

function init()
  -- Bind hotkeys.
  createHotkeys()
  -- If we hook up a keyboard, rebind.
  keycodes.inputSourceChanged(rebindHotkeys)
  -- Automatically reload config when it changes.
  hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

  -- Prevent system sleep, only if connected to AC power. (sleepType, shouldPrevent, batteryToo)
  hs.caffeinate.set('system', true, false)

  alert.show("Reloaded.", 1)
end

-- Grid config =================================

hs.window.animationDuration = 0;
-- hints.style = "vimperator"
-- Set grid size.
has4k = hs.screen('3840x2160')

grid.GRIDWIDTH  = has4k and 36 or 4
grid.GRIDHEIGHT = has4k and 18 or 4
grid.MARGINX = 0
grid.MARGINY = 0
local gw = grid.GRIDWIDTH
local gh = grid.GRIDHEIGHT

local goMiddle = {x = gw/4, y = gh/4, w = gw/2, h = gh/2}
local goLeft = {x = 0, y = 0, w = gw/2, h = gh}
local goRight = {x = gw/2, y = 0, w = gw/2, h = gh}
local goTop = {x = 0, y = 0, w = gw, h = gh/2}
local goBottom = {x = 0, y = gh/2, w = gw, h = gh/2}
local goTopLeft = {x = 0, y = 0, w = gw/2, h = gh/2}
local goTopRight = {x = gw/2, y = 0, w = gw/2, h = gh/2}
local goBottomLeft = {x = 0, y = gh/2, w = gw/2, h = gh/2}
local goBottomRight = {x = gw/2, y = gh/2, w = gw/2, h = gh/2}
local goBig = {x = 0, y = 0, w = gw, h = gh}

-- Saved layout. TODO
-- local layoutA = {
--   { appData = "Atom", place = {1, {x = 0, y = 0, h = 15, w = 22}} },
--   { appData = "iTerm2", place = {1, {x = 0, y = 15, h = 3, w = 36}} },
--   -- { appData = {appName = "iTerm2", title = "SIDE!!!!!*"}, place = {3, {x = 0, y = 0, h = 18, w = 36}} },
--   { appData = "Google Chrome", place = {2, {x = 12, y = 6, h = 12, w = 24}} },
--   { appData = "Google Chrome", place = {1, {x = 22, y = 0, h = 15, w = 14}}, onlyFocused = true},
--   { appData = {appName = "Google Chrome", title = "Google Calendar"}, place = {2, {x = 12, y = 0, h = 6, w = 12}} },
--   { appData = {appName = "Google Chrome", title = "Todo"}, place = {2, {x = 24, y = 0, h = 6, w = 12}} },
--   { appData = {appName = "Google Chrome", title = "Gmail"}, place = {2, {x = 0, y = 9, h = 9, w = 12}} },
--   { appData = "Slack", place = {2, {x = 0, y = 0, h = 9, w = 12}} },
-- }

local layoutMainCoding = {
  { appData = "Atom", place = {1, {x = 0, y = 0, h = 15, w = 28}} },
  { appData = "Atom Beta", place = {1, {x = 0, y = 0, h = 15, w = 28}} },
  { appData = "Code", place = {1, {x = 0, y = 0, h = 15, w = 28}} },
  { appData = "iTerm2", place = {1, {x = 0, y = 15, h = 3, w = 36}} },
  { appData = {appName = "iTerm2", title = "!!PRODUCTION*"}, place = {1, {x = 28, y = 0, h = 15, w = 8}} },
  { appData = {appName = "iTerm2", title = "!!DEPLOY*"}, place = {1, {x = 28, y = 0, h = 15, w = 8}} },
  { appData = {appName = "iTerm2", title = "SIDE*"}, place = {1, {x = 28, y = 0, h = 15, w = 8}} },
  -- { appData = "Google Chrome", place = {2, {x = 12, y = 6, h = 12, w = 24}} },
  -- { appData = "Google Chrome", place = {3, {x = 0, y = 0, h = 18, w = 36}}, onlyFocused = true},
}

local layoutMainCodingChrome = {
  { appData = "Atom", place = {1, {x = 0, y = 0, h = 15, w = 26}} },
  { appData = "Atom Beta", place = {1, {x = 0, y = 0, h = 15, w = 26}} },
  { appData = "Code", place = {1, {x = 0, y = 0, h = 15, w = 26}} },
  { appData = "iTerm2", place = {1, {x = 0, y = 15, h = 3, w = 36}} },
  { appData = "Google Chrome", place = {1, {x = 26, y = 0, h = 15, w = 10}}, onlyFocused = true },
}

local layoutLaptopCodingNativeRes = {
  { appData = {appName = "Google Chrome", title = "Google Calendar"}, place = {2, {x = 12, y = 0, h = 6, w = 12}} },
  { appData = {appName = "Google Chrome", title = "Gmail"}, place = {2, {x = 0, y = 9, h = 9, w = 12}} },
  { appData = "Slack", place = {2, {x = 0, y = 0, h = 9, w = 12}} },
}

local layoutLaptopCodingLowRes = {
  { appData = {appName = "Google Chrome", title = "Google Calendar"}, place = {2, {x = 0, y = gh*0.6, h = gh*0.4, w = gw/2}} },
  { appData = {appName = "Google Chrome", title = "Gmail"}, place = {2, {x = 0, y = 0, h = gh*0.6, w = gw/2}} },
  { appData = "Slack", place = {2, {x = gw/2, y = 0, h = gh, w = gw/2}} },
}

local layoutNonCoding = {
  { appData = "Atom", place = {2, {x = 0, y = 0, h = 15, w = 36}} },
  { appData = "Atom Beta", place = {2, {x = 0, y = 0, h = 15, w = 36}} },
  { appData = "Code", place = {2, {x = 0, y = 0, h = 15, w = 36}} },
  { appData = "iTerm2", place = {2, {x = 0, y = 15, h = 3, w = 36}} },
  -- { appData = "Google Chrome", place = {1, {x = 12, y = 9, h = 9, w = 12}} },
  -- { appData = "Google Chrome", place = {1, {x = 24, y = 0, h = 18, w = 12}}, onlyFocused = true},
  { appData = {appName = "Google Chrome", title = "Todo"}, place = {1, {x = 0, y = 0, h = 4.5, w = 12}} },
  { appData = {appName = "Google Chrome", title = "Google Calendar"}, place = {1, {x = 0, y = 0, h = 4.5, w = 12}} },
  { appData = {appName = "Google Chrome", title = "Gmail"}, place = {1, {x = 24, y = 0, h = 9, w = 12}} },
  { appData = "Slack", place = {1, {x = 12, y = 0, h = gh, w = 12}} },
}


-- Watch out, cmd-opt-ctrl-shift-period is an actual OS X shortcut for running sysdiagose
definitions = {
  r = hs.reload,
  -- Not using
  -- [";"] = saveFocus,
  -- a = focusSaved,

  -- h = gridset(godMiddle),
  Left = gridset(goLeft),
  Up = grid.maximizeWindow,
  Right = gridset(goRight),

  ['pad7'] = gridset(goTopLeft),
  ['pad8'] = gridset(goTop),
  ['pad9'] = gridset(goTopRight),
  ['pad5'] = gridset(goBig),
  ['pad1'] = gridset(goBottomLeft),
  ['pad2'] = gridset(goBottom),
  ['pad3'] = gridset(goBottomRight),
  ['pad4'] = gridset(goLeft),
  ['pad6'] = gridset(goRight),

  -- ["pad/"] = function() alert.show(serializeTable(grid.get(window.focusedWindow())), 5) end,
  a = applyLayout(array_concat(layoutMainCoding, layoutLaptopCodingNativeRes), "Main Coding"),
  q = applyLayout(array_concat(layoutMainCoding, layoutLaptopCodingLowRes), "Main Coding (Low-res Laptop)"),
  z = applyLayout(layoutMainCodingChrome, "Main Coding Chrome"),
  w = applyLayout(layoutNonCoding, "Non Coding"),

  [";"] = grid.pushWindowNextScreen,
  ["'"] = grid.pushWindowPrevScreen,
  ["\\"] = grid.show, -- way too fucked with our grid sizes
  -- q = function() hs.application.find("Hammerspoon"):kill() end,

  -- Shows all sublime windows
  -- e = function() hints.windowHints(hs.application.find("Sublime Text"):allWindows()) end,

  -- Show hints for all window
  f = function() hints.windowHints(nil) end,
  -- Shows all windows for current app
  v = function() hints.windowHints(window.focusedWindow():application():allWindows()) end,

  -- o = function() hs.execute(os.getenv("HOME") .. "/bin/subl ".. os.getenv("HOME") .."/.hammerspoon/init.lua") end,
  --
  -- GRID
  --

  -- move windows
  -- ['pad4'] = grid.pushWindowLeft,
  -- ['pad2'] = grid.pushWindowDown,
  -- ['pad6'] = grid.pushWindowRight,
  -- ['pad8'] = grid.pushWindowUp,

  -- resize windows
  ["pad+"] = grid.resizeWindowTaller,
  ["pad-"] = grid.resizeWindowShorter,
  ["pad/"] = grid.resizeWindowThinner,
  ["pad*"] = grid.resizeWindowWider,
  -- ["pad5"] = function() grid.resizeWindowWider() ; grid.resizeWindowTaller() end,
  -- ["pad0"] = function() grid.resizeWindowThinner() ; grid.resizeWindowShorter() end,

  -- m = grid.maximizeWindow,
  -- n = function() grid.snap(window.focusedWindow()) end,

  ['f12'] = highlight.toggleIsolate

  -- cmd+\ should run cmd-tab (keyboard symmetry)
  -- ["\\c"] = function() hs.eventtap.keyStroke({"cmd"},"tab") end
}


--
-- TABS
-- Currently crashes on sublime text.
--
-- for i=1,6 do
--   definitions[tostring(i)] = function()
--     local app = application.frontmostApplication()
--     tabs.focusTab(app,i)
--   end
-- end

overlay1Showing = false

function createOtherHotkeys(hyperKeyStub)
  hotkey.new({"ctrl-cmd-shift"}, "space", function() hs.application.find("iTerm2"):mainWindow():focus() end):enable()
  hotkey.new({"ctrl-cmd-shift"}, "a", function() hs.application.find("Atom"):mainWindow():focus() end):enable()
  hotkey.new({"ctrl-cmd-shift"}, "s", function() hs.application.find("Slack"):mainWindow():focus() end):enable()
  hotkey.new({"ctrl-cmd-shift"}, "\\", function() hs.application.find("Google Chrome"):mainWindow():focus() end):enable()

  hotkey.new({"ctrl-cmd-shift"}, "left", function() hs.window.filter.new():focusWindowWest() end):enable()
  hotkey.new({"ctrl-cmd-shift"}, "right", function() hs.window.filter.new():focusWindowEast() end):enable()
  hotkey.new({"ctrl-cmd-shift"}, "up", function() hs.window.filter.new():focusWindowNorth() end):enable()
  hotkey.new({"ctrl-cmd-shift"}, "down", function() hs.window.filter.new():focusWindowSouth() end):enable()

  local chromeSwitcher = hs.window.switcher.new{'Safari','Google Chrome'}
  hotkey.bind('alt', 'tab', function() chromeSwitcher:next() end)
  hotkey.bind('alt-shift', 'tab', function() chromeSwitcher:previous() end)

  hyperKeyStub:bind('', 'padenter', function() hs.caffeinate.systemSleep() end)

  hyperKeyStub:bind('', '1', function()
    local wf = hs.window.filter
    local itermApp = hs.appfinder.appFromName('iTerm2')
    local iterm_window_filter = wf.new(false):setAppFilter('iTerm2',{allowTitles='!!OVERLAY'})
    iterm_window_filter:unsubscribeAll()

    local itermOverlayWindows = iterm_window_filter:getWindows()
    local itermOverlayWindowCount = 0
    for i, v in pairs(itermOverlayWindows) do
      itermOverlayWindowCount = itermOverlayWindowCount + 1
    end
    local currentWinNum = 0
    for i, window in ipairs(itermOverlayWindows) do
      if overlay1Showing == false then
        applyPlace(window, {1, {x = currentWinNum*(24/itermOverlayWindowCount), y = 0, h = 15, w = (24/itermOverlayWindowCount)}})
        window:unminimize()
      else
        window:minimize()
        applyPlace(window, {2, {x = 0, y = 0, h = 15, w = 10}})
        -- window:setTopLeft{x=20000, y=20000}
        -- window:sendToBack()
      end
      currentWinNum = currentWinNum + 1
    end

    iterm_window_filter:subscribe(wf.windowNotOnScreen, function(window, appname, event)
      if overlay1Showing == true and not window:isMinimized() then
        hs.alert('overlay 1 hidden')
        overlay1Showing = false
      end
      -- iterm_window_filter:unsubscribe(wf.windowNotOnScreen)
      -- local app = hs.appfinder.appFromName(appname)
      -- app:hide()
      window:minimize()
      applyPlace(window, {2, {x = 0, y = 0, h = 15, w = 10}})
      -- app:unhide()
      -- window:setTopLeft{x=20000, y=20000}
      -- window:sendToBack()1
    end)
    if overlay1Showing == false then
      hs.alert('overlay 1 on')
      overlay1Showing = true
    else
      hs.alert('overlay 1 hidden')
      overlay1Showing = false
    end
  end)

end

init()
