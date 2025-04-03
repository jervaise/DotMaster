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
  version = "0.9.1"
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

    -- Make sure database is fully loaded before creating GUI
    if DM.LoadDMSpellsDB and (not DM.dmspellsdb or next(DM.dmspellsdb) == nil) then
      DM:DatabaseDebug("Ensuring database is loaded before GUI creation")
      DM:LoadDMSpellsDB()
    end

    -- Create GUI if available
    if DM.CreateGUI then
      DM:CreateGUI()
      DM:DebugMsg("GUI created")
    end

    -- Initialize nameplate systems (now enabled in CompleteInitialization)
    -- The initialization is now handled in CompleteInitialization

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

    -- Try loading the database again if it's empty
    if DM.LoadDMSpellsDB then
      DM:LoadDMSpellsDB()
      DM:DebugMsg("Attempted to reload database")
    end
  end

  -- Initialize nameplate tables properly
  DM.activePlates = DM.activePlates or {}
  DM.coloredPlates = DM.coloredPlates or {}
  DM.originalColors = DM.originalColors or {}

  -- Register nameplate related events
  DM:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  DM:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  DM:RegisterEvent("UNIT_AURA")

  -- Hook our OnEvent handler to handle nameplate events
  local existingOnEvent = DM:GetScript("OnEvent")
  DM:SetScript("OnEvent", function(self, event, arg1, ...)
    -- Call the existing event handler for all events first
    if existingOnEvent then
      existingOnEvent(self, event, arg1, ...)
    end

    -- Handle nameplate events after other handlers
    if event == "NAME_PLATE_UNIT_ADDED" and self.NameplateAdded then
      self:NameplateAdded(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" and self.NameplateRemoved then
      self:NameplateRemoved(arg1)
    elseif event == "UNIT_AURA" and self.UnitAuraChanged then
      self:UnitAuraChanged(arg1)
    end
  end)

  DM:DebugMsg("Nameplate events registered successfully")

  -- At this point we would initialize everything else
  DM:DebugMsg("Addon fully initialized")
end
