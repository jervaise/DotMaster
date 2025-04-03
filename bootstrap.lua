-- DotMaster bootstrap.lua
-- This is the initialization entry point that handles proper loading sequence

-- Create addon frame and namespace
DotMaster = CreateFrame("Frame")
local DM = DotMaster

-- Setup simple debugging (will be enhanced later)
function DM:SimplePrint(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Define minimal constants and defaults (only what's needed for bootstrap)
DM.addonName = "DotMaster"
DM.pendingInitialization = true
DM.initState = "bootstrap" -- Track initialization state
DM.defaults = {
  enabled = true,
  version = "0.8.0"
}

-- Debug categories (minimal initial setup)
DM.DEBUG_CATEGORIES = {
  general = true,
  database = true
}

-- By default, don't output debug messages to chat console
DM.DEBUG_CONSOLE_OUTPUT = false

-- Setup basic event handling for initialization sequence
DM:RegisterEvent("ADDON_LOADED")
DM:RegisterEvent("PLAYER_LOGIN")
DM:RegisterEvent("PLAYER_ENTERING_WORLD")
DM:RegisterEvent("PLAYER_LOGOUT")

-- Master initialization event handler
DM:SetScript("OnEvent", function(self, event, arg1, ...)
  if event == "ADDON_LOADED" and arg1 == DM.addonName then
    -- This is the critical point where SavedVariables become available
    DM.initState = "addon_loaded"

    -- First priority: Initialize the debug system if needed
    if DM.Debug and DM.Debug.Init and not DM.debugInitialized then
      DM.Debug:Init()
      DM.debugInitialized = true
    end

    -- Now use DebugMsg instead of SimplePrint
    DM:DebugMsg("ADDON_LOADED triggered - SavedVariables available")

    -- Load saved settings (will be implemented in LoadSettings)
    if DM.LoadSettings then
      DM:LoadSettings()
      DM:DebugMsg("Settings loaded")
    else
      DM:DebugMsg("WARNING: LoadSettings not available yet")
    end

    -- Load spell database (will be implemented in LoadDMSpellsDB)
    if DM.LoadDMSpellsDB then
      DM:LoadDMSpellsDB()
      DM:DebugMsg("Spell database loaded")
    else
      DM:DebugMsg("WARNING: LoadDMSpellsDB not available yet")
    end

    DM.pendingInitialization = false
  elseif event == "PLAYER_LOGIN" then
    DM.initState = "player_login"
    DM:DebugMsg("PLAYER_LOGIN triggered")

    -- Register debug slash commands if available
    if DM.InitializeDebugSlashCommands then
      DM:InitializeDebugSlashCommands()
      DM:DebugMsg("Debug slash commands initialized")
    end

    -- Register main slash commands if available
    if DM.InitializeMainSlashCommands then
      DM:InitializeMainSlashCommands()
      DM:DebugMsg("Main slash commands initialized")
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    DM.initState = "player_entering_world"
    DM:DebugMsg("PLAYER_ENTERING_WORLD triggered")

    -- Call main initialization (moved from core.lua)
    if DM.CompleteInitialization then
      DM:CompleteInitialization()
    end

    -- Create GUI if available
    if DM.CreateGUI then
      DM:CreateGUI()
      DM:DebugMsg("GUI created")
    end

    -- Initialize nameplate systems (currently disabled)
    wipe(DM.activePlates or {})
    wipe(DM.coloredPlates or {})
    wipe(DM.originalColors or {})

    -- Print final initialization message
    DM:DebugMsg("Initialization complete - v" .. (DM.defaults and DM.defaults.version or "unknown"))
  elseif event == "PLAYER_LOGOUT" then
    -- Save settings and database on logout
    if DM.SaveSettings then
      DM:SaveSettings()
    end

    if DM.SaveDMSpellsDB then
      DM:SaveDMSpellsDB()
    end
  end
end)

-- Implement a minimal debug message handler until the real one is loaded
function DM:DebugMsg(message)
  -- Store message for later display in debug console
  DM.oldDebugMessages = DM.oldDebugMessages or {}

  -- Format with timestamp for consistency
  local timestamp = date("|cFF888888[%H:%M:%S]|r ", GetServerTime())
  local prefix = "|cFFCC00FF[GENERAL]|r "
  local fullMessage = timestamp .. prefix .. message

  -- Save for debug console to display later
  table.insert(DM.oldDebugMessages, fullMessage)

  -- Also print to chat if needed during early initialization
  DM:SimplePrint(message)
end

-- Define a stub for database debug messages
function DM:DatabaseDebug(message)
  -- Store message for later display in debug console
  DM.oldDebugMessages = DM.oldDebugMessages or {}

  -- Format with timestamp for consistency
  local timestamp = date("|cFF888888[%H:%M:%S]|r ", GetServerTime())
  local prefix = "|cFFFFA500[DATABASE]|r "
  local fullMessage = timestamp .. prefix .. message

  -- Save for debug console to display later
  table.insert(DM.oldDebugMessages, fullMessage)

  -- Also print to chat during early initialization
  DM:SimplePrint("[DATABASE] " .. message)
end

-- CompleteInitialization will be called during PLAYER_ENTERING_WORLD
function DM:CompleteInitialization()
  DM:DebugMsg("Completing full initialization")

  -- Check if we have database data loaded
  if DM.dmspellsdb then
    local count = 0
    for _ in pairs(DM.dmspellsdb) do
      count = count + 1
    end
    DM:DebugMsg("Database contains " .. count .. " spells")
  else
    DM:DebugMsg("WARNING: Database not loaded or empty")
  end

  -- At this point we would initialize everything else
  DM:DebugMsg("Addon fully initialized")
end
