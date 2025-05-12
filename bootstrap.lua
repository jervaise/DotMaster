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

-- Stub for debug message handler (to be replaced with new debug system)
function DM:DebugMsg(message)
  -- Debug functionality removed, will be replaced with new system
end

-- Stub for database debug messages (to be replaced with new debug system)
function DM:DatabaseDebug(message)
  -- Debug functionality removed, will be replaced with new system
end

-- Define minimal constants and defaults
DM.addonName = "DotMaster"
DM.pendingInitialization = true
DM.initState = "bootstrap" -- Track initialization state
DM.defaults = {
  enabled = true,
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

    -- Load saved settings
    if DM.LoadSettings then
      DM:LoadSettings()
    end

    DM.pendingInitialization = false
  elseif event == "PLAYER_LOGIN" then
    DM.initState = "player_login"

    -- Register main slash commands if available
    if DM.InitializeMainSlashCommands then
      DM:InitializeMainSlashCommands()
    end

    -- Initialize minimap icon
    if DM.InitializeMinimapIcon then
      DM:InitializeMinimapIcon()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    DM.initState = "player_entering_world"

    -- Create GUI if available
    if DM.CreateGUI then
      DM:CreateGUI()
    end
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

-- Main slash command handler
SLASH_DOTMASTER1 = "/dm"
SlashCmdList["DOTMASTER"] = function(msg)
  if DM.SlashCommand then
    DM:SlashCommand(msg)
  else
    DM:PrintMessage("Still initializing... please try again in a moment.")
  end
end
