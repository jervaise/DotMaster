-- DotMaster settings.lua
-- Handles loading and saving configuration

local DM = DotMaster

-- Save settings to saved variables
function DM:SaveSettings()
  if not DotMasterDB then DotMasterDB = {} end
  if not DotMasterDB.settings then DotMasterDB.settings = {} end

  -- Make sure the enabled state is properly saved
  DotMasterDB.enabled = DM.enabled

  -- Ensure all settings are in the right format before saving
  DotMasterDB.settings.forceColor = DM.API:GetSettings().forceColor and true or false
  DotMasterDB.settings.borderOnly = DM.API:GetSettings().borderOnly and true or false
  DotMasterDB.settings.borderThickness = DM.API:GetSettings().borderThickness
  DotMasterDB.settings.flashExpiring = DM.API:GetSettings().flashExpiring and true or false
  DotMasterDB.settings.flashThresholdSeconds = DM.API:GetSettings().flashThresholdSeconds

  -- Save the minimap icon state
  DotMasterDB.minimap = DotMasterDB.minimap or {}
  DotMasterDB.minimap.hide = DM.API:GetSettings().minimapIcon.hide

  -- Save current settings to class/spec profile
  if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
    DM.ClassSpec:SaveCurrentSettings()
  end

  -- DIRECTLY reinstall the Plater mod with these settings
  -- Note: This may be temporarily disabled by AutoSave to prevent double-pushing
  if self.InstallPlaterMod then
    DM:PrintMessage("Embedding your current DotMaster configuration into DotMaster Integration...")
    self:InstallPlaterMod()
  end
end

-- Load settings from saved variables
function DM:LoadSettings()
  -- Initialize DB if needed
  if not DotMasterDB then
    DotMasterDB = {}
  end

  -- Explicitly make sure enabled is a boolean to prevent type errors
  if DotMasterDB.enabled == nil then
    DotMasterDB.enabled = false
  elseif type(DotMasterDB.enabled) ~= "boolean" then
    DotMasterDB.enabled = (DotMasterDB.enabled == true)
  end

  -- CRITICAL FIX: Remove 'enabled' setting from all class/spec profiles
  -- to prevent class-specific override of global enabled state
  if DotMasterDB.classProfiles then
    local fixedAny = false
    for className, classData in pairs(DotMasterDB.classProfiles) do
      for specID, specData in pairs(classData) do
        if specData.settings and specData.settings.enabled ~= nil then
          specData.settings.enabled = nil
          fixedAny = true
        end
      end
    end
  end

  -- Fix corrupted settings
  if DotMasterDB and DotMasterDB.enabled ~= nil then
    -- Ensure settings table exists
    if not DotMasterDB.settings then
      DotMasterDB.settings = {}
    end

    -- Check for specific missing/corrupted settings
    if DotMasterDB.settings.forceColor == nil then
      DotMasterDB.settings.forceColor = false
    elseif type(DotMasterDB.settings.forceColor) ~= "boolean" then
      DotMasterDB.settings.forceColor = (DotMasterDB.settings.forceColor == true)
    end

    if DotMasterDB.settings.borderOnly == nil then
      DotMasterDB.settings.borderOnly = false
    elseif type(DotMasterDB.settings.borderOnly) ~= "boolean" then
      DotMasterDB.settings.borderOnly = (DotMasterDB.settings.borderOnly == true)
    end

    if DotMasterDB.settings.flashExpiring == nil then
      DotMasterDB.settings.flashExpiring = false
    elseif type(DotMasterDB.settings.flashExpiring) ~= "boolean" then
      DotMasterDB.settings.flashExpiring = (DotMasterDB.settings.flashExpiring == true)
    end
  end

  -- Load the settings into the API's settings object
  local settings = {}

  -- Set default values
  settings.enabled = false
  settings.forceColor = false
  settings.borderOnly = false
  settings.borderThickness = 2
  settings.flashExpiring = false
  settings.flashThresholdSeconds = 3.0
  settings.extendPlaterColors = false
  settings.minimapIcon = { hide = false }

  -- CRITICAL: Explicitly set enabled state from DotMasterDB
  if DotMasterDB then
    settings.enabled = DotMasterDB.enabled
  end

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

    if DotMasterDB.settings.extendPlaterColors ~= nil then
      settings.extendPlaterColors = DotMasterDB.settings.extendPlaterColors
    end
  end

  -- Load minimap settings
  if DotMasterDB.minimap then
    settings.minimapIcon = DotMasterDB.minimap
  end

  -- CRITICAL: Set main enabled state to the DotMasterDB value
  -- This is the main variable that controls addon functionality
  DM.enabled = DotMasterDB.enabled

  -- CRITICAL: Double-check enabled state correctness
  if settings.enabled ~= DM.enabled then
    settings.enabled = DM.enabled -- Force them to match, with DM.enabled being the source of truth
  end

  -- Save to API
  DM.API.settings = settings

  return settings
end

-- Tracks if border thickness has been changed during this session
function DM:TrackBorderThicknessChange()
  -- Get current settings
  local settings = DM.API:GetSettings()
  local currentThickness = settings.borderThickness

  -- Initialize original values if not set
  if not DM.originalBorderThickness then
    -- Use DotMasterDB directly if available
    if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness then
      DM.originalBorderThickness = DotMasterDB.settings.borderThickness
    else
      DM.originalBorderThickness = currentThickness
    end

    return false
  end

  -- Check only border thickness
  -- Convert to number to ensure proper comparison
  local thicknessChanged = tonumber(DM.originalBorderThickness) ~= tonumber(currentThickness)

  -- Return true only if thickness has changed
  return thicknessChanged
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

  -- Do one more explicit check to avoid false positives
  if not DM.originalBorderThickness then
    return false
  end

  -- Double-check for actual changes using strict typing
  local currentThickness = tonumber(settings.borderThickness)
  local originalThickness = tonumber(DM.originalBorderThickness)

  local thicknessChanged = currentThickness ~= originalThickness

  -- Only proceed if thickness actually changed
  if not thicknessChanged then
    return false
  end

  -- Update popup text to be specific about border thickness
  StaticPopupDialogs["DOTMASTER_RELOAD_CONFIRM"].text =
      "Border thickness has changed from " ..
      originalThickness .. " to " .. currentThickness .. ".\n\nReload UI to fully apply this change?";

  -- Show the popup
  StaticPopup_Show("DOTMASTER_RELOAD_CONFIRM")
  return true
end

-- Force push settings to DotMaster Integration
function DM:ForcePushToDotMasterIntegration()
  -- Check if Plater and its integration are available
  if Plater and Plater.InstallMod and DM.InstallPlaterMod then
    DM:PrintMessage("Force pushing current settings to DotMaster Integration...")

    -- Use the main InstallPlaterMod function to push current settings
    DM:InstallPlaterMod(true) -- Pass true to indicate a force push
  else
    DM:PrintMessage("Error: DotMaster Integration installation function not found")
  end
end

-- Initialize the main slash commands
function DM:InitializeMainSlashCommands()
  SLASH_DOTMASTER1 = "/dm"
  SlashCmdList["DOTMASTER"] = function(msg)
    local command, arg = strsplit(" ", msg, 2)
    command = strtrim(command:lower())

    if command == "enable" then
      local settings = DM.API:GetSettings()
      settings.enabled = true
      DM.enabled = true
      DM:AutoSave()
      DM:PrintMessage("DotMaster enabled")
    elseif command == "disable" then
      local settings = DM.API:GetSettings()
      settings.enabled = false
      DM.enabled = false
      DM:AutoSave()
      DM:PrintMessage("DotMaster disabled")
    elseif command == "minimap" then
      -- Toggle minimap icon visibility
      if DM.API and DM.API.GetSettings and DM.LDBIcon then
        local settings = DM.API:GetSettings()
        if settings.minimapIcon then
          settings.minimapIcon.hide = not settings.minimapIcon.hide
          if settings.minimapIcon.hide then
            DM.LDBIcon:Hide("DotMaster")
            DM:PrintMessage("Minimap icon hidden")
          else
            DM.LDBIcon:Show("DotMaster")
            DM:PrintMessage("Minimap icon shown")
          end
          DM:AutoSave()
        end
      else
        DM:PrintMessage("Error: Minimap icon functionality not available")
      end
    else
      -- Default: Show the config panel
      if DM.GUI and DM.GUI.frame then
        DM.GUI.frame:Show()
      else
        DM:PrintMessage("Configuration panel not available")
      end
    end
  end
end

-- Auto-save wrapper that sets a flag to suppress saved variables duplication
function DM:AutoSave()
  DM.autoSaving = true

  -- Update settings
  if self.ClassSpec and self.ClassSpec.PushConfigToPlater then
    if not DM.disablePush then
      self.ClassSpec:PushConfigToPlater()
    end
  end

  -- Try to apply settings immediately
  if DM.ApplySettings then DM:ApplySettings() end

  DM.saveNeeded = false
  DM.autoSaving = false
end

-- Set background auto-save timer
function DM:InitAutoSave()
  C_Timer.After(60, function()
    -- Periodically push settings to Plater to ensure consistency
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      if not DM.disablePush then
        DM.ClassSpec:PushConfigToPlater()
      end
    end
    DM:InitAutoSave() -- Set the timer again
  end)
end

-- Debugging output: "Need to save settings due to frame closing"
function DM:GetSaveNeeded()
  return DM.saveNeeded
end

-- Toggle the enabled state
function DM:Toggle()
  DM.enabled = not DM.enabled

  -- Store the enabled state in saved vars
  if DotMasterDB then
    DotMasterDB.enabled = DM.enabled
  end

  -- Update settings when toggling
  if self.ApplySettings then self:ApplySettings() end
end

-- Toggle with message - for slash command
function DM:ToggleWithMessage()
  self:Toggle()
end
