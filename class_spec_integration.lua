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
          k ~= "flashThresholdSeconds" then
        classSpecSettings[k] = v
      end
    end

    -- Initialize with filtered settings
    DotMasterDB.classProfiles[currentClass][currentSpecID] = {
      spells = DM.API:GetTrackedSpells(),
      combos = DM.API:GetCombinations(),
      settings = classSpecSettings
    }

    -- If no spells are configured yet, add appropriate test spells based on class
    local spells = DotMasterDB.classProfiles[currentClass][currentSpecID].spells
    if not spells or #spells == 0 then
      -- Add class-specific test spells
      if currentClass == "PRIEST" then
        table.insert(spells, {
          spellID = 34914, -- Vampiric Touch
          color = { r = 0.8, g = 0.1, b = 0.8, a = 1.0 },
          priority = 1,
          name = "Vampiric Touch",
          enabled = true,
        })

        table.insert(spells, {
          spellID = 589, -- Shadow Word: Pain
          color = { r = 0.5, g = 0.0, b = 0.5, a = 1.0 },
          priority = 2,
          name = "Shadow Word: Pain",
          enabled = true,
        })

        DM:PrintMessage("Added Priest test spells")
      elseif currentClass == "WARLOCK" then
        table.insert(spells, {
          spellID = 980, -- Agony
          color = { r = 0.4, g = 0.7, b = 0.0, a = 1.0 },
          priority = 1,
          name = "Agony",
          enabled = true,
        })

        table.insert(spells, {
          spellID = 146739, -- Corruption
          color = { r = 0.0, g = 0.5, b = 0.0, a = 1.0 },
          priority = 2,
          name = "Corruption",
          enabled = true,
        })

        DM:PrintMessage("Added Warlock test spells")
      elseif currentClass == "DRUID" then
        table.insert(spells, {
          spellID = 164812, -- Moonfire
          color = { r = 0.3, g = 0.5, b = 1.0, a = 1.0 },
          priority = 1,
          name = "Moonfire",
          enabled = true,
        })

        table.insert(spells, {
          spellID = 164815, -- Sunfire
          color = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
          priority = 2,
          name = "Sunfire",
          enabled = true,
        })

        DM:PrintMessage("Added Druid test spells")
      elseif currentClass == "HUNTER" then
        table.insert(spells, {
          spellID = 257284, -- Hunter's Mark
          color = { r = 1.0, g = 0.0, b = 0.0, a = 1.0 },
          priority = 1,
          name = "Hunter's Mark",
          enabled = true,
        })

        table.insert(spells, {
          spellID = 271788, -- Serpent Sting
          color = { r = 0.0, g = 0.8, b = 0.0, a = 1.0 },
          priority = 2,
          name = "Serpent Sting",
          enabled = true,
        })

        DM:PrintMessage("Added Hunter test spells")
      elseif currentClass == "MAGE" then
        table.insert(spells, {
          spellID = 205708, -- Chilled
          color = { r = 0.5, g = 0.5, b = 1.0, a = 1.0 },
          priority = 1,
          name = "Chilled",
          enabled = true,
        })

        table.insert(spells, {
          spellID = 12654, -- Ignite
          color = { r = 1.0, g = 0.3, b = 0.0, a = 1.0 },
          priority = 2,
          name = "Ignite",
          enabled = true,
        })

        DM:PrintMessage("Added Mage test spells")
      elseif currentClass == "DEATHKNIGHT" then
        table.insert(spells, {
          spellID = 191587, -- Virulent Plague
          color = { r = 0.3, g = 0.7, b = 0.3, a = 1.0 },
          priority = 1,
          name = "Virulent Plague",
          enabled = true,
        })

        table.insert(spells, {
          spellID = 55095, -- Frost Fever
          color = { r = 0.0, g = 0.5, b = 1.0, a = 1.0 },
          priority = 2,
          name = "Frost Fever",
          enabled = true,
        })

        DM:PrintMessage("Added Death Knight test spells")
      else
        -- For any other class, add a placeholder spell with class color
        local classColor = DM.classColors[currentClass] or DM.classColors["UNKNOWN"]
        table.insert(spells, {
          spellID = 2825, -- Bloodlust/Heroism (works for any class to track)
          color = { r = classColor.r, g = classColor.g, b = classColor.b, a = 1.0 },
          priority = 1,
          name = "Class Test Spell",
          enabled = true,
        })
        DM:PrintMessage("Added test spell for " .. currentClass)
      end
    end
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
function DM.ClassSpec:PushConfigToPlater()
  -- Debugging origin of settings
  print("DotMaster-DEBUG: PushConfigToPlater called (start of function)")
  if DotMasterDB then
    print("DotMaster-DEBUG: DotMasterDB.enabled = " .. (DotMasterDB.enabled and "true" or "false"))
  else
    print("DotMaster-DEBUG: DotMasterDB is nil!")
  end
  print("DotMaster-DEBUG: DM.enabled = " .. (DM.enabled and "true" or "false"))

  -- Throttle updates to prevent spamming when many settings change at once
  local now = GetTime()
  if self.lastPushTime and now - self.lastPushTime < 0.5 then
    -- Already pushed recently, schedule a delayed update
    if not self.pendingPush then
      self.pendingPush = C_Timer.NewTimer(0.5, function()
        self.pendingPush = nil
        self.lastPushTime = nil -- Reset timer to force update
        self:PushConfigToPlater()
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

  -- Debug: Print detailed config info
  DM:PrintMessage("Pushing config for " .. currentClass .. " spec #" .. currentSpecID)
  DM:PrintMessage("Spells: " .. (config.spells and #config.spells or 0) ..
    ", Combos: " .. (config.combos and #config.combos or 0))

  -- Print details of first spell if available
  if config.spells and #config.spells > 0 then
    local spell = config.spells[1]
    DM:PrintMessage("Sample spell: ID=" .. (spell.spellID or "nil") ..
      ", name=" .. (spell.name or "unnamed") ..
      ", enabled=" .. (spell.enabled == true and "true" or "false"))

    if spell.color then
      local colorInfo = "Color: "
      if spell.color.r then
        colorInfo = colorInfo .. "RGBA(" .. spell.color.r .. "," .. spell.color.g .. "," ..
            spell.color.b .. "," .. (spell.color.a or 1) .. ")"
      else
        colorInfo = colorInfo .. "Array[" .. table.concat(spell.color, ",") .. "]"
      end
      DM:PrintMessage(colorInfo)
    else
      DM:PrintMessage("No color defined for spell")
    end
  end

  -- Find the DotMaster Integration mod index
  local dotMasterIntegrationIndex = self:GetDotMasterIntegrationIndex()
  if not dotMasterIntegrationIndex then
    DM:PrintMessage("Error: 'DotMaster Integration' mod not found in Plater. Please ensure it's installed correctly.")
    return
  end

  -- Get Plater reference
  local Plater = _G["Plater"]
  if not Plater then
    DM:PrintMessage("Error: Plater not found.")
    return
  end

  -- Push configuration to DotMaster Integration
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
    print("DotMaster: Using global Force Threat Color setting: " ..
      (DotMasterDB.settings.forceColor and "ENABLED" or "DISABLED"))
  end

  -- Ensure there's at least one test spell if none exist
  if #configToPush.spells == 0 then
    table.insert(configToPush.spells, {
      spellID = 34914, -- Vampiric Touch for Priests
      color = { r = 0.8, g = 0.1, b = 0.8, a = 1.0 },
      priority = 1,
      name = "Test Spell",
      enabled = true
    })
    DM:PrintMessage("Added emergency test spell to DotMaster Integration config")
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

  print("DotMaster-Debug: PushConfigToPlater - Current DotMaster Integration state: " ..
    (Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled and "ENABLED" or "DISABLED") ..
    ", Target state: " .. (isEnabled and "ENABLED" or "DISABLED"))

  -- Only update the mod's enabled state if it differs from the global addon state
  if Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled ~= isEnabled then
    Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled = isEnabled
    DM:PrintMessage((isEnabled and "Enabled" or "Disabled") .. " DotMaster Integration Plater mod")
  end

  -- Verify the state after a small delay to ensure it has applied
  C_Timer.After(0.1, function()
    if Plater.db.profile.hook_data[dotMasterIntegrationIndex] then
      local currentState = Plater.db.profile.hook_data[dotMasterIntegrationIndex].Enabled
      if currentState ~= isEnabled then
        print("DotMaster: WARNING! State mismatch for DotMaster Integration mod after push. Re-asserting...")
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

  DM:PrintMessage("Saved " .. #(config.spells or {}) .. " spells and " .. #(config.combos or {}) ..
    " combinations to DotMaster Integration for " .. currentClass .. " spec #" .. currentSpecID)
end

-- Save current settings to class/spec profile
function DM.ClassSpec:SaveCurrentSettings()
  local currentClass, currentSpecID = self:GetCurrentClassAndSpec()

  -- Make sure class/spec profiles are initialized
  self:InitializeClassSpecProfiles()

  -- Get current settings
  local currentSettings = DM.API:GetSettings()

  -- Remove global settings that should not be saved per class/spec
  local classSpecSettings = {}
  for k, v in pairs(currentSettings) do
    -- Skip these settings as they are stored globally
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

  -- Update the class/spec profile with current settings
  DotMasterDB.classProfiles[currentClass][currentSpecID] = {
    spells = DM.API:GetTrackedSpells(),
    combos = DM.API:GetCombinations(),
    settings = classSpecSettings
  }

  -- Push updated configuration to Plater
  self:PushConfigToPlater()
end

-- Event handler
function DM.ClassSpec:OnEvent(event, ...)
  if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
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
