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
  version = "0.6.8"
}

-- Debug categories (minimal initial setup)
DM.DEBUG_CATEGORIES = {
  general = true,
  database = true
}

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
    DM:SimplePrint("ADDON_LOADED triggered - SavedVariables available")

    -- Load saved settings (will be implemented in LoadSettings)
    if DM.LoadSettings then
      DM:LoadSettings()
      DM:SimplePrint("Settings loaded")
    else
      DM:SimplePrint("WARNING: LoadSettings not available yet")
    end

    -- Load spell database (will be implemented in LoadDMSpellsDB)
    if DM.LoadDMSpellsDB then
      DM:LoadDMSpellsDB()
      DM:SimplePrint("Spell database loaded")
    else
      DM:SimplePrint("WARNING: LoadDMSpellsDB not available yet")
    end

    DM.pendingInitialization = false
  elseif event == "PLAYER_LOGIN" then
    DM.initState = "player_login"
    DM:SimplePrint("PLAYER_LOGIN triggered")

    -- Register debug slash commands if available
    if DM.InitializeDebugSlashCommands then
      DM:InitializeDebugSlashCommands()
      DM:SimplePrint("Debug slash commands initialized")
    end

    -- Register main slash commands if available
    if DM.InitializeMainSlashCommands then
      DM:InitializeMainSlashCommands()
      DM:SimplePrint("Main slash commands initialized")
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    DM.initState = "player_entering_world"
    DM:SimplePrint("PLAYER_ENTERING_WORLD triggered")

    -- Call main initialization (moved from core.lua)
    if DM.CompleteInitialization then
      DM:CompleteInitialization()
    end

    -- Create GUI if available
    if DM.CreateGUI then
      DM:CreateGUI()
      DM:SimplePrint("GUI created")
    end

    -- Initialize nameplate systems (currently disabled)
    wipe(DM.activePlates or {})
    wipe(DM.coloredPlates or {})
    wipe(DM.originalColors or {})

    -- Print final initialization message
    DM:SimplePrint("Initialization complete - v" .. (DM.defaults and DM.defaults.version or "unknown"))
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
  DM:SimplePrint(message)
end

-- Define a stub for database debug messages
function DM:DatabaseDebug(message)
  DM:SimplePrint("[DATABASE] " .. message)
end

-- CompleteInitialization will be called during PLAYER_ENTERING_WORLD
function DM:CompleteInitialization()
  DM:SimplePrint("Completing full initialization")

  -- Check if we have database data loaded
  if DM.dmspellsdb then
    local count = 0
    for _ in pairs(DM.dmspellsdb) do
      count = count + 1
    end
    DM:SimplePrint("Database contains " .. count .. " spells")
  else
    DM:SimplePrint("WARNING: Database not loaded or empty")
  end

  -- At this point we would initialize everything else
  DM:SimplePrint("Addon fully initialized")
end
