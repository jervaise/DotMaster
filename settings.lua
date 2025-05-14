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
    DotMasterDB.enabled = true -- Default to enabled on first load/new profile
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

-- Initialize original critical settings tracker
DM.originalCriticalSettings = {
  borderThickness = nil,
  extendPlaterColors = nil,
  borderOnly = nil
}

-- Tracks if critical Plater settings have changed during this session
function DM:TrackCriticalSettingsChange()
  local settings = DM.API:GetSettings()

  -- Initialize original values if not set for this session
  local initialSetup = false
  if DM.originalCriticalSettings.borderThickness == nil then
    DM.originalCriticalSettings.borderThickness = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness) or
        settings.borderThickness
    initialSetup = true
  end
  if DM.originalCriticalSettings.extendPlaterColors == nil then
    DM.originalCriticalSettings.extendPlaterColors = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.extendPlaterColors ~= nil) and
        DotMasterDB.settings.extendPlaterColors or settings.extendPlaterColors
    initialSetup = true
  end
  if DM.originalCriticalSettings.borderOnly == nil then
    DM.originalCriticalSettings.borderOnly = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderOnly ~= nil) and
        DotMasterDB.settings.borderOnly or settings.borderOnly
    initialSetup = true
  end

  if initialSetup then
    -- If we just initialized, no change has occurred yet relative to the start of this tracking
    return false
  end

  -- Check for changes
  local thicknessChanged = tonumber(DM.originalCriticalSettings.borderThickness) ~= tonumber(settings.borderThickness)
  local extendColorsChanged = DM.originalCriticalSettings.extendPlaterColors ~= settings.extendPlaterColors
  local borderOnlyChanged = DM.originalCriticalSettings.borderOnly ~= settings.borderOnly

  return thicknessChanged or extendColorsChanged or borderOnlyChanged
end

-- Shows reload UI popup for critical Plater settings changes
function DM:ShowReloadUIPopupForCriticalChanges()
  local settings = DM.API:GetSettings()

  -- Ensure original settings have been initialized for comparison
  if DM.originalCriticalSettings.borderThickness == nil or DM.originalCriticalSettings.extendPlaterColors == nil or DM.originalCriticalSettings.borderOnly == nil then
    -- This typically means TrackCriticalSettingsChange hasn't run or initialized properly
    -- Initialize them now to prevent errors, though a prompt might be missed if this is the first check.
    DM.originalCriticalSettings.borderThickness = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderThickness) or
        settings.borderThickness
    DM.originalCriticalSettings.extendPlaterColors = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.extendPlaterColors ~= nil) and
        DotMasterDB.settings.extendPlaterColors or settings.extendPlaterColors
    DM.originalCriticalSettings.borderOnly = (DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.borderOnly ~= nil) and
        DotMasterDB.settings.borderOnly or settings.borderOnly
    -- No changes to report yet if we just initialized here
    return false
  end

  local currentBorderThickness = tonumber(settings.borderThickness)
  local originalBorderThickness = tonumber(DM.originalCriticalSettings.borderThickness)
  local currentExtendColors = settings.extendPlaterColors
  local originalExtendColors = DM.originalCriticalSettings.extendPlaterColors
  local currentBorderOnly = settings.borderOnly
  local originalBorderOnly = DM.originalCriticalSettings.borderOnly

  local thicknessChanged = originalBorderThickness ~= currentBorderThickness
  local extendColorsChanged = originalExtendColors ~= currentExtendColors
  local borderOnlyChanged = originalBorderOnly ~= currentBorderOnly

  if not (thicknessChanged or extendColorsChanged or borderOnlyChanged) then
    return false -- No actual changes detected
  end

  if not StaticPopupDialogs["DOTMASTER_CRITICAL_RELOAD_CONFIRM"] then
    StaticPopupDialogs["DOTMASTER_CRITICAL_RELOAD_CONFIRM"] = {
      text = "You have to reload UI to apply these changes.",
      button1 = "Reload Now",
      button2 = "Later",
      OnAccept = function()
        ReloadUI()
      end,
      OnCancel = function()
        DM:PrintMessage("Remember to reload your UI to fully apply critical Plater settings changes.")
        -- Update stored original values to current values to prevent repeated prompts for this set of changes
        local currentSettings = DM.API:GetSettings()
        DM.originalCriticalSettings.borderThickness = currentSettings.borderThickness
        DM.originalCriticalSettings.extendPlaterColors = currentSettings.extendPlaterColors
        DM.originalCriticalSettings.borderOnly = currentSettings.borderOnly
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
  end

  -- Construct a more dynamic message if desired, or keep it generic
  -- Example for a more dynamic message (optional):
  -- local changedItems = {}
  -- if thicknessChanged then table.insert(changedItems, string.format("Border Thickness (%s -> %s)", originalBorderThickness, currentBorderThickness)) end
  -- if extendColorsChanged then table.insert(changedItems, "Extend Plater Colors") end
  -- if borderOnlyChanged then table.insert(changedItems, "Use Borders for DoT Tracking") end
  -- StaticPopupDialogs["DOTMASTER_CRITICAL_RELOAD_CONFIRM"].text = "The following Plater appearance settings have changed:\\n - " .. table.concat(changedItems, "\\n - ") .. "\\n\\nReload UI to fully apply these changes?"

  StaticPopup_Show("DOTMASTER_CRITICAL_RELOAD_CONFIRM")
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
