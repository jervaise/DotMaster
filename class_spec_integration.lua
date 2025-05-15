-- DotMaster class/spec integration with Plater
local DM = DotMaster
DM.ClassSpec = {}

-- Function to get current class and spec
function DM.ClassSpec:GetCurrentClassAndSpec()
  local currentClass = select(2, UnitClass("player"))
  local currentSpec = GetSpecialization()
  local currentSpecID = currentSpec and GetSpecializationInfo(currentSpec) or 0

  return currentClass, currentSpecID
end

-- Initialize class/spec profiles in saved variables if they don't exist
function DM.ClassSpec:InitializeClassSpecProfiles()
  -- Ensure the saved variable exists
  if not _G["DotMasterDB"] then
    _G["DotMasterDB"] = {}
  end

  if not DotMasterDB.classProfiles then
    DotMasterDB.classProfiles = {}
  end

  -- Initialize class colors if not defined yet
  if not DM.classColors then
    DM.classColors = {
      WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
      PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
      HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
      ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
      PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
      DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
      SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
      MAGE = { r = 0.41, g = 0.80, b = 0.94 },
      WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
      MONK = { r = 0.00, g = 1.00, b = 0.59 },
      DRUID = { r = 1.00, g = 0.49, b = 0.04 },
      DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
      EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
      UNKNOWN = { r = 0.70, g = 0.70, b = 0.70 }
    }
  end

  local currentClass, currentSpecID = self:GetCurrentClassAndSpec()

  -- Create class entry if it doesn't exist
  if not DotMasterDB.classProfiles[currentClass] then
    DotMasterDB.classProfiles[currentClass] = {}
  end

  -- Create spec entry if it doesn't exist
  if not DotMasterDB.classProfiles[currentClass][currentSpecID] then
    -- Get current settings for initialization, but filter out global ones
    local settings = DM.API:GetSettings()
    local classSpecSettings = {}

    -- Only copy settings that should be class-specific
    for k, v in pairs(settings) do
      -- Skip these settings as they are stored globally
      if k ~= "minimapIcon" and
          k ~= "enabled" and -- Explicitly exclude enabled - it's global only
          k ~= "forceColor" and
          k ~= "borderOnly" and
          k ~= "borderThickness" and
          k ~= "flashExpiring" and
          k ~= "flashThresholdSeconds" and
          k ~= "extendPlaterColors" then
        classSpecSettings[k] = v
      end
    end

    -- Initialize with filtered settings
    DotMasterDB.classProfiles[currentClass][currentSpecID] = {
      spells = {}, -- Initialize with empty arrays instead of API calls which might not be ready
      combos = {},
      settings = classSpecSettings
    }
  end
end

-- Function to find the DotMaster Integration mod index in Plater
function DM.ClassSpec:GetDotMasterIntegrationIndex()
  local Plater = _G["Plater"]
  if not (Plater and Plater.db and Plater.db.profile and Plater.db.profile.hook_data) then
    return nil
  end

  local data = Plater.db.profile.hook_data
  local modName = "DotMaster Integration"

  for i, mod in ipairs(data) do
    if mod.Name == modName then
      return i
    end
  end

  return nil
end

-- Function to push current class/spec configuration to DotMaster Integration
function DM.ClassSpec:PushConfigToPlater(forcePush)
  -- Throttle updates to prevent spamming when many settings change at once
  local now = GetTime()
  if not forcePush and self.lastPushTime and now - self.lastPushTime < 0.5 then
    -- Already pushed recently, schedule a delayed update
    if not self.pendingPush then
      self.pendingPush = C_Timer.NewTimer(0.5, function()
        self.pendingPush = nil
        self.lastPushTime = nil -- Reset timer to force update
        self:PushConfigToPlater(forcePush)
      end)
    end
    return
  end
  self.lastPushTime = now

  local currentClass, currentSpecID = self:GetCurrentClassAndSpec()

  -- Make sure class/spec profiles are initialized
  self:InitializeClassSpecProfiles()

  -- Get the current class/spec profile
  local config = DotMasterDB.classProfiles[currentClass][currentSpecID]

  -- Find the DotMaster Integration mod index
  local dotMasterIntegrationIndex = self:GetDotMasterIntegrationIndex()
  if not dotMasterIntegrationIndex then
    -- Add a static flag to prevent showing the error message multiple times
    if not self.errorMessageShown then
      DM:PrintMessage("Error: 'DotMaster Integration' mod not found in Plater. Please ensure it's installed correctly.")
      self.errorMessageShown = true
    end
    return
  end

  -- Get Plater reference
  local Plater = _G["Plater"]
  if not Plater then
    -- Add a static flag to prevent showing the error message multiple times
    if not self.platerErrorMessageShown then
      DM:PrintMessage("Error: Plater not found.")
      self.platerErrorMessageShown = true
    end
    return
  end

  -- Reset error flags if we got this far
  self.errorMessageShown = nil
  self.platerErrorMessageShown = nil

  -- Push configuration to DotMaster Integration
  -- Only include spells and combos for the current class and spec
  local configToPush = {
    spells = config.spells or {},
    combos = config.combos or {},
    settings = config.settings
  }

  -- IMPORTANT: Always use the global Force Threat Color setting
  if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.forceColor ~= nil then
    if not configToPush.settings then
      configToPush.settings = {}
    end
    configToPush.settings.forceColor = DotMasterDB.settings.forceColor
  end

  -- Convert all color formats to array format which we know works
  for _, spell in ipairs(configToPush.spells) do
    if spell.color then
      -- Convert r/g/b/a table to array format if needed
      if spell.color.r then
        spell.color = { spell.color.r, spell.color.g, spell.color.b, spell.color.a or 1.0 }
      end
    end
  end

  -- Also convert combo colors
  for _, combo in ipairs(configToPush.combos or {}) do
    if combo.color then
      -- Convert r/g/b/a table to array format if needed
      if combo.color.r then
        combo.color = { combo.color.r, combo.color.g, combo.color.b, combo.color.a or 1.0 }
      end
    end
  end

  -- Update DotMaster Integration configuration
  Plater.db.profile.hook_data[dotMasterIntegrationIndex].config = configToPush

  -- Get the enabled state from DM.enabled which is the master switch
  local isEnabled = DM.enabled

  -- Only update the mod's enabled state if it differs from the global addon state
  if Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled ~= isEnabled then
    Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled = isEnabled
  end

  -- Verify the state after a small delay to ensure it has applied
  C_Timer.After(0.1, function()
    if Plater.db.profile.hook_data[dotMasterIntegrationIndex] then
      local currentState = Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled
      if currentState ~= isEnabled then
        Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled = isEnabled
      end
    end
  end)

  -- Debug message about what's happening
  if DM.DebugMsg then
    DM:DebugMsg("Pushed " .. #(config.spells or {}) .. " spells and " .. #(config.combos or {}) ..
      " combinations to DotMaster Integration for " .. currentClass .. " spec #" .. currentSpecID)
  end

  -- Refresh Plater
  if Plater.WipeAndRecompileAllScripts then
    Plater.WipeAndRecompileAllScripts("hook")
  end
  if Plater.FullRefreshAllPlates then
    Plater.FullRefreshAllPlates()
  end
end

-- Save current settings to class/spec profile
function DM.ClassSpec:SaveCurrentSettings()
  local currentClass, currentSpecID = self:GetCurrentClassAndSpec()

  -- Make sure class/spec profiles are initialized and we have a current profile reference
  self:InitializeClassSpecProfiles()
  local currentProfileRef = DM:GetCurrentSpecProfile() -- Ensures DM.currentProfile is set
  if not currentProfileRef then
    DM:DebugMsg("ERROR: SaveCurrentSettings - Could not get current profile reference.")
    return
  end

  -- Get current global settings from API
  local currentGlobalSettings = DM.API:GetSettings()

  -- Filter out global settings, keeping only spec-specific ones
  local classSpecSettings = {}
  for k, v in pairs(currentGlobalSettings) do
    if k ~= "minimapIcon" and
        k ~= "enabled" and
        k ~= "forceColor" and
        k ~= "borderOnly" and
        k ~= "borderThickness" and
        k ~= "flashExpiring" and
        k ~= "flashThresholdSeconds" then
      classSpecSettings[k] = v
    end
  end

  -- Update the DotMasterDB record for the current class/spec
  -- Use the direct references from DM.currentProfile for spells and combinations
  DotMasterDB.classProfiles[currentClass][currentSpecID] = {
    spells = DM.currentProfile.spells or {},
    combinations = DM.currentProfile.combinations or { data = {}, settings = {} },
    settings = classSpecSettings
  }

  DM:DebugMsg(string.format("Saved settings for %s - %s. Spells: %d, Combos: %d",
    currentClass, currentSpecID,
    DM.currentProfile.spells and DM:TableCount(DM.currentProfile.spells) or 0,
    DM.currentProfile.combinations and DM.currentProfile.combinations.data and
    DM:TableCount(DM.currentProfile.combinations.data) or 0
  ))

  -- Push updated configuration to Plater
  self:PushConfigToPlater()
end

-- Event handler
function DM.ClassSpec:OnEvent(event, unit, ...)
  if event == "PLAYER_SPECIALIZATION_CHANGED" then
    -- Only handle if it's the player's spec that changed
    if unit == "player" then
      DM:DebugMsg("Player specialization changed, updating profile...")

      -- Switch to the new spec profile
      if self.SwitchSpecProfile then
        self:SwitchSpecProfile()
      end

      -- Force reinstall/push with current settings when spec changes (simulates GUI closing)
      if DM.InstallPlaterMod then
        DM:InstallPlaterMod()
      end

      -- Force update the status in footer if it exists
      if DM.UpdatePlaterStatusFooter then
        DM:UpdatePlaterStatusFooter()
      end

      -- Also explicitly push current profile to Plater
      self:PushConfigToPlater(true) -- true = force push

      DM:DebugMsg("Spec change complete - profile updated and pushed to Plater")
    end
  elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
    -- Initialize profile and push to Plater
    if DM.InitializeCurrentProfile then
      DM:InitializeCurrentProfile()
    end
    self:PushConfigToPlater()
  end
end

-- Initialize and register events
function DM.ClassSpec:Initialize()
  -- Create event frame if it doesn't exist
  if not self.eventFrame then
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
  end

  -- Register events
  self.eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  self.eventFrame:RegisterEvent("PLAYER_LOGIN")

  -- Initialize class/spec profiles
  self:InitializeClassSpecProfiles()
end

-- Function to switch to the current spec profile
function DM.ClassSpec:SwitchSpecProfile()
  local currentClass, currentSpecID = self:GetCurrentClassAndSpec()

  -- Make sure class/spec profiles are initialized
  self:InitializeClassSpecProfiles()

  -- Get or create the current spec's profile
  local currentProfile
  if DM.InitializeCurrentProfile then
    currentProfile = DM:InitializeCurrentProfile()
  else
    currentProfile = DM:GetCurrentSpecProfile()
  end

  if not currentProfile then
    DM:DebugMsg("ERROR: Failed to get current spec profile during spec switch")
    return
  end

  -- Load settings from the profile
  if currentProfile.settings then
    for key, value in pairs(currentProfile.settings) do
      -- Update API settings
      if DM.API and DM.API.settings then
        DM.API.settings[key] = value
      end
    end
  end

  -- Update spells reference
  DM.dmspellsdb = currentProfile.spells or {}

  -- Update combinations reference
  DM.combinations = currentProfile.combinations or {
    data = {},
    settings = {
      enabled = true,
      priorityOverIndividual = true
    }
  }

  DM:DebugMsg(string.format("Switched to %s spec #%d profile", currentClass, currentSpecID))

  -- Push the profile to Plater
  self:PushConfigToPlater()

  -- Update the UI if the GUI exists
  C_Timer.After(0.3, function()
    if DM.GUI then
      if DM.GUI.RefreshDatabaseTabList then
        DM.GUI:RefreshDatabaseTabList()
      end
      if DM.GUI.RefreshTrackedSpellTabList then
        DM.GUI:RefreshTrackedSpellTabList()
      end
      if DM.GUI.UpdateCombinationsList then
        DM.GUI:UpdateCombinationsList()
      end
    end
  end)
end
