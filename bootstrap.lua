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

-- Empty stub for debug message handler
function DM:DebugMsg(message)
  -- Debug messages disabled
end

-- Empty stub for database debug messages
function DM:DatabaseDebug(message)
  -- Debug messages disabled
end

-- Define minimal constants and defaults
DM.addonName = "DotMaster"
DM.pendingInitialization = true
DM.initState = "bootstrap" -- Track initialization state
DM.defaults = {
  enabled = true,          -- Default to enabled for new installations
  version = "2.0.0",
  flashExpiring = false,
  flashThresholdSeconds = 3.0
}

-- Define CONFIG with test spell ID
DM.CONFIG = {
  TEST_SPELL_ID = 589 -- Shadow Word: Pain as a default test spell
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
    -- Load legacy databases
    if DM.LoadSpellDatabase then DM:LoadSpellDatabase() end
    if DM.LoadDMSpellsDB then DM:LoadDMSpellsDB() end
    DM.initState = "addon_loaded"

    -- Load saved settings
    if DM.LoadSettings then
      DM:LoadSettings()

      -- Initialize border thickness tracking with proper type checking
      if DM.API and DM.API.GetSettings then
        local settings = DM.API:GetSettings()
        DM.originalBorderThickness = tonumber(settings.borderThickness)
        DM.originalBorderOnly = settings.borderOnly and true or false
        DM.originalEnabled = settings.enabled and true or false -- Track the enabled state too
      end
    end

    DM.pendingInitialization = false

    -- Check if we need to restore Plater's original border thickness (if border-only mode was just disabled)
    if DotMasterDB and DotMasterDB.shouldRestorePlaterThickness and DotMasterDB.originalPlaterBorderThickness then
      local Plater = _G["Plater"]
      if Plater and Plater.db and Plater.db.profile then
        Plater.db.profile.border_thickness = DotMasterDB.originalPlaterBorderThickness

        -- Update all nameplates
        if Plater.UpdateAllPlatesBorderThickness then
          Plater.UpdateAllPlatesBorderThickness()
        end

        -- Clear the flag so we don't do this again
        DotMasterDB.shouldRestorePlaterThickness = nil
      end
    end

    -- Force check for PlaterDB and ensure mod state matches settings
    if DotMasterDB and Plater and Plater.db and Plater.db.profile and Plater.db.profile.hook_data then
      -- Important startup task - make sure DotMaster Integration is in the right state
      local modIndex
      for i, mod in ipairs(Plater.db.profile.hook_data) do
        if mod.Name == "DotMaster Integration" then
          modIndex = i
          break
        end
      end

      if modIndex and DotMasterDB.enabled ~= nil then
        if Plater.db.profile.hook_data[modIndex].Enabled ~= DotMasterDB.enabled then
          Plater.db.profile.hook_data[modIndex].Enabled = DotMasterDB.enabled
        end
      end
    end
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

    -- Display welcome message
    C_Timer.After(2.0, function()
      DM:DisplayWelcomeMessage()
      DM:CheckPlaterInstallation()
    end)

    -- Create GUI if available
    if DM.CreateGUI then
      DM:CreateGUI()
    end

    -- Add a delayed refresh of the combinations list
    C_Timer.After(1.0, function()
      if DM.GUI and DM.GUI.UpdateCombinationsList then
        DM.GUI:UpdateCombinationsList()

        -- Add a single refresh to ensure colors are properly applied
        C_Timer.After(0.5, function()
          if DM.RefreshCombinationColors then
            DM:RefreshCombinationColors()
          end
        end)
      end
    end)

    -- Make sure DotMaster Integration mod is up to date with our latest code
    C_Timer.After(2.0, function()
      if DM.InstallPlaterMod then
        -- Make sure we don't override the saved enabled state
        -- print("DotMaster: Ensuring Plater mod state matches saved settings (" ..
        --   (DotMasterDB and DotMasterDB.enabled and "ENABLED" or "DISABLED") .. ")")

        -- For safety, manually verify that settings.enabled matches DotMasterDB.enabled
        if DM.API and DM.API.GetSettings then
          local settings = DM.API:GetSettings()
          if DotMasterDB and DotMasterDB.enabled ~= nil and settings.enabled ~= DotMasterDB.enabled then
            -- print("DotMaster: CRITICAL - Settings enabled mismatch detected during startup! Fixing...")
            settings.enabled = DotMasterDB.enabled
            DM.enabled = DotMasterDB.enabled
          end
        end

        DM:InstallPlaterMod()
        -- DM:PrintMessage("Reinstalled DotMaster Integration mod with latest code.")

        -- Force push config with test spell
        C_Timer.After(0.5, function()
          if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
            DM.ClassSpec:PushConfigToPlater()
            -- DM:PrintMessage("Force pushed configuration to DotMaster Integration.")
          end
        end)
      end
    end)

    -- Force reload Plater UI after initialization
    C_Timer.After(1.5, function()
      -- Only force reinstall/push in these cases
      if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
        -- Reinstall the mod explicitly after Plater initializes
        DM.ClassSpec:PushConfigToPlater()
      end
    end)

    -- More forceful push after 3 seconds (last resort)
    C_Timer.After(3.0, function()
      if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
        DM.ClassSpec:PushConfigToPlater(true) -- Force push
      end
    end)
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

-- Function to display welcome message
function DM:DisplayWelcomeMessage()
  print("|cFFCC00FF==== DotMaster ====|r")
  print("|cFFCC00FFWelcome to DotMaster!|r")
  print("|cFFCC00FFAvailable commands:|r")
  print("|cFF88FFFF/dm|r - Open configuration panel")
  print("|cFF88FFFF/dm enable|r - Enable DotMaster")
  print("|cFF88FFFF/dm disable|r - Disable DotMaster")
  print("|cFF88FFFF/dm minimap|r - Toggle minimap icon visibility")
  print("|cFFCC00FF===================|r")
end

-- Check for Plater installation
function DM:CheckPlaterInstallation()
  local Plater = _G["Plater"]
  if not Plater then
    DM:PrintMessage("Warning: Plater Nameplates not detected. DotMaster requires Plater Nameplates to function.")
    return false
  end
  return true
end
