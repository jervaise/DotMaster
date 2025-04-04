-- DotMaster bootstrap.lua
-- This is the initialization entry point that handles proper loading sequence

-- Create addon frame and namespace
DotMaster = CreateFrame("Frame")
local DM = DotMaster

-- Setup simple print function
function DM:PrintMessage(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Define minimal constants and defaults (only what's needed for bootstrap)
DM.addonName = "DotMaster"
DM.pendingInitialization = true
DM.initState = "bootstrap" -- Track initialization state
DM.defaults = {
  enabled = true,
  version = "1.0.0",
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

    -- Load saved settings (will be implemented in LoadSettings)
    if DM.LoadSettings then
      DM:LoadSettings()
    end

    -- Load spell database (will be implemented in LoadDMSpellsDB)
    if DM.LoadDMSpellsDB then
      DM:LoadDMSpellsDB()
    end

    DM.pendingInitialization = false
  elseif event == "PLAYER_LOGIN" then
    DM.initState = "player_login"

    -- Register main slash commands if available
    if DM.InitializeMainSlashCommands then
      DM:InitializeMainSlashCommands()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    DM.initState = "player_entering_world"

    -- Call main initialization (moved from core.lua)
    if DM.CompleteInitialization then
      DM:CompleteInitialization()
    end

    -- Make sure database is fully loaded before creating GUI
    if DM.LoadDMSpellsDB and (not DM.dmspellsdb or next(DM.dmspellsdb) == nil) then
      DM:LoadDMSpellsDB()
    end

    -- Create GUI if available
    if DM.CreateGUI then
      DM:CreateGUI()
    end

    -- Print initialization message
    DM:PrintMessage("Loaded v" .. (DM.defaults and DM.defaults.version or "unknown"))
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

-- CompleteInitialization will be called during PLAYER_ENTERING_WORLD
function DM:CompleteInitialization()
  -- Check for Plater dependency
  if not _G["Plater"] then
    -- Create an error popup
    StaticPopupDialogs["DOTMASTER_MISSING_PLATER"] = {
      text =
      "|cFFFF0000DotMaster requires Plater Nameplates to function.|r\n\nPlease install and enable Plater from CurseForge, WoWInterface, or Wago.",
      button1 = "OK",
      timeout = 0,
      whileDead = true,
      hideOnEscape = false,
      preferredIndex = 3,
    }
    StaticPopup_Show("DOTMASTER_MISSING_PLATER")

    -- Print error message to chat
    DM:PrintMessage("|cFFFF0000DotMaster requires Plater Nameplates to function.|r")
    DM:PrintMessage("Please install Plater from CurseForge, WoWInterface, or Wago.")

    -- Disable the addon - don't proceed with initialization
    DM.enabled = false
    DM.platerMissing = true

    -- We're done here, don't initialize anything else
    return
  end

  -- Initialize nameplate handling
  if DM.InitializeNameplates then
    DM:InitializeNameplates()
  end

  -- Create Find My Dots window if enabled
  if DM.CreateFindMyDotsWindow then
    DM:CreateFindMyDotsWindow()
  end
end

DM.Meta = {
  addonName = "DotMaster",
  displayName = "|cFFB54AC9DotMaster|r",
  version = "1.0.0",
  author = "Your Name",
  website = "https://github.com/yourusername/DotMaster",
  slash = "/dm"
}
