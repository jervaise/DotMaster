-- DotMaster settings.lua
-- Handles loading and saving configuration

local DM = DotMaster

-- Save settings to saved variables
function DM:SaveSettings()
  if not DotMasterDB then
    DotMasterDB = {}
  end

  -- Get settings from API
  local settings = DM.API:GetSettings()

  -- Update DotMasterDB with current settings
  DotMasterDB.enabled = settings.enabled
  DotMasterDB.version = "1.0.7"

  -- Save force threat color setting
  DotMasterDB.settings = DotMasterDB.settings or {}
  DotMasterDB.settings.forceColor = settings.forceColor
  DotMasterDB.settings.borderOnly = settings.borderOnly

  -- Explicitly save bokmaster enabled state to ensure it persists after reload
  -- This ensures the Plater integration state matches DotMaster's enabled state
  DotMasterDB.bokmasterEnabled = settings.enabled

  -- Keep existing borderThickness if it exists to avoid overwriting with old value
  -- This handles cases where the UI has been updated but settings object hasn't
  if not DotMasterDB.settings.borderThickness then
    DotMasterDB.settings.borderThickness = settings.borderThickness
    print("|cFFFF9900DotMaster-BorderDebug: INITIALIZED thickness value " ..
      settings.borderThickness .. " to DotMasterDB|r")
  else
    -- Only update if different
    if DotMasterDB.settings.borderThickness ~= settings.borderThickness then
      print("|cFFFF9900DotMaster-BorderDebug: UPDATED thickness from " .. DotMasterDB.settings.borderThickness ..
        " to " .. settings.borderThickness .. " in DotMasterDB|r")
      DotMasterDB.settings.borderThickness = settings.borderThickness
    else
      print("|cFFFF9900DotMaster-BorderDebug: SAVED thickness value " .. settings.borderThickness .. " to DotMasterDB|r")
    end
  end

  DotMasterDB.settings.flashExpiring = settings.flashExpiring
  DotMasterDB.settings.flashThresholdSeconds = settings.flashThresholdSeconds

  -- Save current settings to class/spec profile
  if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
    DM.ClassSpec:SaveCurrentSettings()
  end

  -- DIRECTLY reinstall the Plater mod with these settings
  -- Note: This may be temporarily disabled by AutoSave to prevent double-pushing
  if self.InstallPlaterMod then
    DM:PrintMessage("Embedding your current DotMaster configuration into bokmaster...")
    self:InstallPlaterMod()
  end
end

-- Load settings from saved variables
function DM:LoadSettings()
  -- First log if SavedVariables are available
  if not DotMasterDB then
    DotMasterDB = {}
  end

  -- Initialize API settings with defaults
  local settings = {
    enabled = (DotMasterDB.enabled ~= nil) and DotMasterDB.enabled or true,
    forceColor = false,
    borderOnly = false,
    borderThickness = 2,
    flashExpiring = false,
    flashThresholdSeconds = 3.0,
    minimapIcon = { hide = false }
  }

  -- Load settings from saved variables if available
  if DotMasterDB.settings then
    if DotMasterDB.settings.forceColor ~= nil then
      settings.forceColor = DotMasterDB.settings.forceColor
    end

    if DotMasterDB.settings.borderOnly ~= nil then
      settings.borderOnly = DotMasterDB.settings.borderOnly
    end

    if DotMasterDB.settings.borderThickness ~= nil then
      settings.borderThickness = DotMasterDB.settings.borderThickness
    end

    if DotMasterDB.settings.flashExpiring ~= nil then
      settings.flashExpiring = DotMasterDB.settings.flashExpiring
    end

    if DotMasterDB.settings.flashThresholdSeconds ~= nil then
      settings.flashThresholdSeconds = DotMasterDB.settings.flashThresholdSeconds
    end
  end

  -- Load minimap settings
  if DotMasterDB.minimap then
    settings.minimapIcon = DotMasterDB.minimap
  end

  -- Set the enabled state in both API and core for compatibility
  DM.enabled = settings.enabled

  -- Ensure the bokmaster enabled state is consistent with DotMaster's state
  -- If bokmasterEnabled exists in the DB, use that value, otherwise match DotMaster's state
  if DotMasterDB.bokmasterEnabled ~= nil then
    DM.bokmasterEnabled = DotMasterDB.bokmasterEnabled
  else
    DM.bokmasterEnabled = settings.enabled
    DotMasterDB.bokmasterEnabled = settings.enabled
  end

  -- Save to API
  DM.API:SaveSettings(settings)

  -- Initialize class/spec integration
  if DM.ClassSpec and DM.ClassSpec.Initialize then
    DM.ClassSpec:Initialize()
  end
end

-- Tracks if border thickness has been changed during this session
function DM:TrackBorderThicknessChange()
  -- Initialize original thickness if not set
  if not DM.originalBorderThickness then
    -- Use DotMasterDB directly if available
    if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness then
      DM.originalBorderThickness = DotMasterDB.settings.borderThickness
    else
      local settings = DM.API:GetSettings()
      DM.originalBorderThickness = settings.borderThickness
    end
    print("|cFFFF9900DotMaster-Debug: Original thickness initialized to " .. DM.originalBorderThickness .. "|r")
    return false
  end

  -- Check if current thickness differs from original
  -- Use DotMasterDB directly for most accurate value
  local currentThickness
  if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness then
    currentThickness = DotMasterDB.settings.borderThickness
    print("|cFFFF9900DotMaster-Debug: Using thickness from DotMasterDB: " .. currentThickness .. "|r")
  else
    local settings = DM.API:GetSettings()
    currentThickness = settings.borderThickness
    print("|cFFFF9900DotMaster-Debug: Using thickness from API: " .. currentThickness .. "|r")
  end

  local changed = DM.originalBorderThickness ~= currentThickness
  print("|cFFFF9900DotMaster-Debug: Thickness check - Original: " .. DM.originalBorderThickness ..
    " Current: " .. currentThickness .. " Changed: " .. tostring(changed) .. "|r")

  return changed
end

-- Shows reload UI popup for border thickness changes
function DM:ShowReloadUIPopupForBorderThickness()
  -- Force creation of popup dialog template
  if not StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"] then
    StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"] = {
      text = "Border thickness has changed.\n\nReload UI to fully apply this change?",
      button1 = "Reload Now",
      button2 = "Later",
      OnAccept = function()
        ReloadUI()
      end,
      OnCancel = function()
        DM:PrintMessage("Remember to reload your UI to fully apply border thickness changes.")
        -- Update the stored original value to prevent repeated prompts
        local settings = DM.API:GetSettings()
        DM.originalBorderThickness = settings.borderThickness
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
  end

  local settings = DM.API:GetSettings()

  if DM:TrackBorderThicknessChange() then
    -- Update text with current values
    StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"].text =
        "Border thickness has changed from " .. DM.originalBorderThickness ..
        " to " .. settings.borderThickness ..
        ".\n\nReload UI to fully apply this change?";

    print("|cFFFF9900DotMaster-Debug: Showing reload popup for thickness change|r")

    -- Show the popup
    StaticPopup_Show("DOTMASTER_RELOAD_CONFIRM")
    return true
  else
    print("|cFFFF9900DotMaster-Debug: No thickness change detected, not showing popup|r")
  end

  return false
end

-- Force push settings to bokmaster
function DM:ForcePushToBokmaster()
  if DM.InstallPlaterMod then
    DM:PrintMessage("Force pushing current settings to bokmaster...")
    DM:InstallPlaterMod()
    return true
  else
    DM:PrintMessage("Error: bokmaster installation function not found")
    return false
  end
end

-- Initialize the main slash commands
function DM:InitializeMainSlashCommands()
  SLASH_DOTMASTER1 = "/dm"
  SlashCmdList["DOTMASTER"] = function(msg)
    local command, arg = strsplit(" ", msg, 2)
    command = strtrim(command:lower())

    if command == "on" or command == "enable" then
      local settings = DM.API:GetSettings()
      settings.enabled = true
      DM.enabled = true
      DM:AutoSave()
      DM:PrintMessage("Enabled")
    elseif command == "off" or command == "disable" then
      local settings = DM.API:GetSettings()
      settings.enabled = false
      DM.enabled = false
      DM:AutoSave()
      DM:PrintMessage("Disabled")
    elseif command == "show" and DM.GUI and DM.GUI.frame then
      DM.GUI.frame:Show()
    elseif command == "reload" then
      ReloadUI()
    elseif command == "push" or command == "bokmaster" then
      -- Force push to bokmaster
      DM:ForcePushToBokmaster()
    elseif command == "bokmaster-on" or command == "bok-on" then
      -- Enable just bokmaster
      DM.API:EnableBokmaster(true)
      DM:PrintMessage("bokmaster integration enabled")
    elseif command == "bokmaster-off" or command == "bok-off" then
      -- Disable just bokmaster
      DM.API:EnableBokmaster(false)
      DM:PrintMessage("bokmaster integration disabled")
    elseif command == "reset" then
      -- Create confirmation dialog
      if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs["DOTMASTER_RESET_CONFIRM"] = {
          text =
          "Are you sure you want to reset all DotMaster settings? This will delete all your saved spells and configurations.",
          button1 = "Yes",
          button2 = "No",
          OnAccept = function()
            -- Explicitly clear each component of DotMasterDB
            if DotMasterDB then
              DotMasterDB.spellConfig = nil
              DotMasterDB.dmspellsdb = nil
              DotMasterDB.spellDatabase = nil
            end
            DotMasterDB = nil

            -- Reset settings to defaults
            local defaultSettings = {
              enabled = true,
              forceColor = false,
              borderOnly = false,
              borderThickness = 2,
              flashExpiring = false,
              flashThresholdSeconds = 3.0,
              minimapIcon = { hide = false }
            }

            DM.enabled = defaultSettings.enabled
            DM:AutoSave()
            DM:PrintMessage("Settings reset to defaults")
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show("DOTMASTER_RESET_CONFIRM")
      else
        DM:PrintMessage("Cannot show reset confirmation dialog.")
      end
    elseif command == "save" then
      DM:SaveSettings()
      DM:PrintMessage("Settings saved")
    else
      -- Try to toggle main GUI if available, otherwise print help
      if DM.GUI and DM.GUI.frame then
        if DM.GUI.frame:IsShown() then
          DM.GUI.frame:Hide()
        else
          DM.GUI.frame:Show()
        end
      elseif command == "show" and DM.GUI and DM.GUI.frame then
        DM.GUI.frame:Show()
      elseif command == "reload" then
        ReloadUI()
      else
        DM:PrintMessage("Available commands:")
        DM:PrintMessage("  /dm on - Enable addon")
        DM:PrintMessage("  /dm off - Disable addon")
        DM:PrintMessage("  /dm show - Show GUI (if loaded)")
        DM:PrintMessage("  /dm push - Force push settings to bokmaster")
        DM:PrintMessage("  /dm bokmaster-on - Enable just bokmaster")
        DM:PrintMessage("  /dm bokmaster-off - Disable just bokmaster")
        DM:PrintMessage("  /dm reset - Reset to default settings")
        DM:PrintMessage("  /dm save - Force save settings")
        DM:PrintMessage("  /dm reload - Reload UI")
      end
    end
  end
end

-- Create a function that automatically saves after config changes
function DM:AutoSave()
  -- Create a timer to save settings after a short delay (to avoid excessive saving)
  if DM.saveTimer then
    DM.saveTimer:Cancel()
  end

  -- Update status message if it exists
  if DM.GUI and DM.GUI.statusMessage then
    DM.GUI.statusMessage:SetText("Auto-saving: Pending...")
    DM.GUI.statusMessage:SetTextColor(1, 0.82, 0) -- Gold color for pending
  end

  DM.saveTimer = C_Timer.NewTimer(0.5, function() -- Reduced from 1s to 0.5s for more responsive feel
    -- First update the saved variables with current settings
    -- but don't push to Plater from inside SaveSettings to avoid double-pushing
    -- Store the current InstallPlaterMod function
    local originalInstallPlaterMod = DM.InstallPlaterMod
    DM.InstallPlaterMod = nil -- Temporarily disable so SaveSettings doesn't call it

    -- Save settings
    DM:SaveSettings()

    -- Restore the original function
    DM.InstallPlaterMod = originalInstallPlaterMod

    -- Now push to Plater with a slight delay to ensure settings are fully saved
    C_Timer.After(0.1, function()
      -- Push to Plater with more reliable call
      if DM.InstallPlaterMod then
        DM:PrintMessage("Auto-save: Pushing settings to bokmaster...")
        DM:InstallPlaterMod()
      end

      -- Update class/spec specific settings
      if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
        DM.ClassSpec:SaveCurrentSettings()
      end
    end)

    -- Update status message if it exists
    if DM.GUI and DM.GUI.statusMessage then
      DM.GUI.statusMessage:SetText("Auto-saved & Pushed to Plater")
      DM.GUI.statusMessage:SetTextColor(0.2, 1, 0.2) -- Green for success

      -- Reset back to default message after 2 seconds
      C_Timer.After(2, function()
        if DM.GUI and DM.GUI.statusMessage then
          DM.GUI.statusMessage:SetText("Auto-saving: Enabled")
          DM.GUI.statusMessage:SetTextColor(0.7, 0.7, 0.7)
        end
      end)
    end
  end)
end
