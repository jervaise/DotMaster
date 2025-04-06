-- DotMaster bootstrap.lua
-- This is the initialization entry point that handles proper loading sequence

-- Create addon frame and namespace
DotMaster = CreateFrame("Frame")
local DM = DotMaster

-- Setup basic message printing
function DM:SimplePrint(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Basic message function
function DM:PrintMessage(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Implement a simplified debug message handler for development
function DM:DebugMsg(message)
  -- Only print to console in development mode
  if DM.DEBUG_MODE then
    DM:SimplePrint(message)
  end
end

-- Define a stub for database debug messages for API compatibility
function DM:DatabaseDebug(message)
  -- Only print to console in development mode
  if DM.DEBUG_MODE then
    DM:SimplePrint("[DATABASE] " .. message)
  end
end

-- Define minimal constants and defaults
DM.addonName = "DotMaster"
DM.pendingInitialization = true
DM.initState = "bootstrap" -- Track initialization state
DM.defaults = {
  enabled = true,
  debug = false,
  version = "1.0.3",
  flashExpiring = false,
  flashThresholdSeconds = 3.0
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
    DM:DebugMsg("ADDON_LOADED triggered - SavedVariables available")

    -- Load saved settings
    if DM.LoadSettings then
      DM:LoadSettings()
      DM:DebugMsg("Settings loaded")
    else
      DM:DebugMsg("WARNING: LoadSettings not available yet")
    end

    DM.pendingInitialization = false
  elseif event == "PLAYER_LOGIN" then
    DM.initState = "player_login"
    DM:DebugMsg("PLAYER_LOGIN triggered")

    -- Register main slash commands if available
    if DM.InitializeMainSlashCommands then
      DM:InitializeMainSlashCommands()
      DM:DebugMsg("Main slash commands initialized")
    end

    -- Initialize minimap icon
    if DM.InitializeMinimapIcon then
      DM:InitializeMinimapIcon()
      DM:DebugMsg("Minimap icon initialized")
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    DM.initState = "player_entering_world"
    DM:DebugMsg("PLAYER_ENTERING_WORLD triggered")

    -- Create GUI if available
    if DM.CreateGUI then
      DM:CreateGUI()
      DM:DebugMsg("GUI created")
    end

    -- Print final initialization message
    DM:DebugMsg("Initialization complete - v" .. (DM.defaults and DM.defaults.version or "unknown"))
  elseif event == "PLAYER_LOGOUT" then
    -- Save settings on logout
    if DM.SaveSettings then
      DM:SaveSettings()
    end
  end
end)

-- Utility function for table size
function DM:TableCount(table)
  local count = 0
  if table then
    for _ in pairs(table) do
      count = count + 1
    end
  end
  return count
end
