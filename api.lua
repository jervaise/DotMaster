-- DotMaster api.lua
-- API layer that isolates the GUI from backend implementation

local DM = DotMaster
DM.API = {}

-- Helper function to create a deep copy of a table (in case CopyTable is not available)
local function DeepCopyTable(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[DeepCopyTable(orig_key)] = DeepCopyTable(orig_value)
    end
    setmetatable(copy, DeepCopyTable(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- Version info
function DM.API:GetVersion()
  -- Use C_AddOns API for Dragonflight+ with fallback to legacy API
  local version
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    version = C_AddOns.GetAddOnMetadata("DotMaster", "Version")
  elseif GetAddOnMetadata then
    version = GetAddOnMetadata("DotMaster", "Version")
  else
    version = "2.2.8" -- Hardcoded fallback version
  end
  return version or "Unknown"
end

-- Debug function to print out DotMasterDB contents
function DM.API:PrintDotMasterDB()
  if not DotMasterDB then
    print("DotMaster: DotMasterDB is nil!")
    return
  end

  print("DotMaster: DotMasterDB contents:")
  print("  enabled: " .. tostring(DotMasterDB.enabled))

  if DotMasterDB.settings then
    print("  settings:")
    for key, value in pairs(DotMasterDB.settings) do
      if type(value) ~= "table" then
        print("    " .. key .. ": " .. tostring(value))
      else
        print("    " .. key .. ": [table]")
      end
    end
  else
    print("  settings: nil")
  end

  if DotMasterDB.classProfiles then
    local currentClass, currentSpecID
    if DM.ClassSpec then
      currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()
    end

    print("  classProfiles: " .. tostring(currentClass) .. "/" .. tostring(currentSpecID))
    if currentClass and currentSpecID and
        DotMasterDB.classProfiles[currentClass] and
        DotMasterDB.classProfiles[currentClass][currentSpecID] and
        DotMasterDB.classProfiles[currentClass][currentSpecID].settings then
      print("  Current class/spec settings:")
      local settings = DotMasterDB.classProfiles[currentClass][currentSpecID].settings
      for key, value in pairs(settings) do
        if type(value) ~= "table" then
          print("    " .. key .. ": " .. tostring(value))
        else
          print("    " .. key .. ": [table]")
        end
      end
    end
  else
    print("  classProfiles: nil")
  end
end

-- Spell tracking functions
function DM.API:GetTrackedSpells()
  local spells = {}
  -- Use the tracked spells database
  for id, entry in pairs(DotMaster.dmspellsdb or {}) do
    -- Convert numeric enabled values to proper boolean (0 = false, 1 = true)
    local isEnabled = false
    if entry.enabled then
      -- Check if it's a number (0 or 1) or already a boolean
      if type(entry.enabled) == "number" then
        isEnabled = (entry.enabled ~= 0)
      else
        isEnabled = (entry.enabled == true)
      end
    end

    -- Also check tracked status (numeric 0/1 or boolean)
    local isTracked = false
    if entry.tracked then
      -- Check if it's a number (0 or 1) or already a boolean
      if type(entry.tracked) == "number" then
        isTracked = (entry.tracked ~= 0)
      else
        isTracked = (entry.tracked == true)
      end
    end

    -- Only include spells that are both enabled AND tracked
    if isEnabled and isTracked then
      table.insert(spells, {
        spellID = tonumber(id),
        color = entry.color,
        priority = entry.priority,
        name = entry.spellname,
        enabled = true, -- Always true boolean for Plater integration
        tracked = true, -- Always true boolean for consistency
      })
    end
  end
  return spells
end

function DM.API:TrackSpell(spellID, spellName, spellIcon, color, priority)
  -- Stub for adding a spell to tracking

  -- Push changes to Plater after a short delay
  C_Timer.After(0.2, function()
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      DM.ClassSpec:PushConfigToPlater()
      print("API: Pushed changes after tracking spell: " .. (spellName or spellID))
    end
  end)

  return true
end

function DM.API:UntrackSpell(spellID)
  -- Stub for removing a spell from tracking

  -- Push changes to Plater after a short delay
  C_Timer.After(0.2, function()
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      DM.ClassSpec:PushConfigToPlater()
      print("API: Pushed changes after untracking spell ID: " .. spellID)
    end
  end)

  return true
end

function DM.API:UpdateSpellSettings(spellID, enabled, priority, color)
  -- Stub for updating spell settings

  -- Push changes to Plater after a short delay
  C_Timer.After(0.2, function()
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      DM.ClassSpec:PushConfigToPlater()
      print("API: Pushed changes after updating spell ID: " .. spellID)
    end
  end)

  return true
end

-- Combination functions
function DM.API:GetCombinations()
  local combos = {}
  -- Use the combinations database
  if DotMaster.combinations and DotMaster.combinations.data then
    for id, combo in pairs(DotMaster.combinations.data) do
      -- Convert numeric enabled values to proper boolean (0 = false, 1 = true)
      local isEnabled = false
      if combo.enabled then
        -- Check if it's a number (0 or 1) or already a boolean
        if type(combo.enabled) == "number" then
          isEnabled = (combo.enabled ~= 0)
        else
          isEnabled = (combo.enabled == true)
        end
      end

      if isEnabled then
        table.insert(combos, {
          comboID = id,
          spellList = combo.spells,
          color = combo.color,
          priority = combo.priority,
          name = combo.name,
          enabled = true,         -- Always true boolean for Plater integration
          spec = combo.spec or 0, -- Include spec field with fallback
        })
      end
    end
  end
  return combos
end

function DM.API:CreateCombination(name, color, spells)
  -- Try to use the backend implementation
  if DM.CreateCombination then
    return DM:CreateCombination(name, spells or {}, color)
  end

  -- Fallback implementation if the backend function is not available
  -- This implements the full functionality directly in the API layer

  -- Ensure DotMasterDB and combinations structure exist
  if not DotMasterDB then DotMasterDB = {} end
  if not DotMasterDB.combinations then
    DotMasterDB.combinations = {
      settings = { enabled = true, priorityOverIndividual = true },
      data = {}
    }
  end
  if not DotMasterDB.combinations.data then DotMasterDB.combinations.data = {} end

  -- Create a reference in the addon table
  DM.combinations = DotMasterDB.combinations

  -- Generate a unique ID using timestamp
  local id = "combo_" .. time()

  -- Find the highest priority and increment by 1
  local priority = 1
  if DM.combinations.data then
    for _, combo in pairs(DM.combinations.data) do
      if combo and combo.priority and combo.priority >= priority then
        priority = combo.priority + 1
      end
    end
  end

  -- Create the new combination
  DM.combinations.data[id] = {
    name = name or "New Combination",
    spells = spells or {},
    color = color or { r = 1, g = 0, b = 0, a = 1 },
    priority = priority,
    enabled = true,
    threshold = "all", -- "all" or numeric value
    isExpanded = false -- ALWAYS start collapsed
  }

  -- Save changes to DotMasterDB
  DotMasterDB.combinations = DM.combinations

  -- Debug message if available
  if DM.DebugMsg then
    DM:DebugMsg("API Layer: Created new combination with ID: " .. id)
  end

  -- Push changes to Plater after a short delay
  C_Timer.After(0.2, function()
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      DM.ClassSpec:PushConfigToPlater()
      print("API: Pushed changes after creating combination: " .. (name or "New Combo"))
    end
  end)

  return id
end

function DM.API:UpdateCombination(comboID, name, enabled, color)
  -- Try to use the backend implementation if it exists
  if DM.UpdateCombination then
    -- Convert parameters to an updates table as expected by the backend
    local updates = {
      name = name,
      enabled = enabled,
      color = color
    }
    return DM:UpdateCombination(comboID, updates)
  end

  -- Fallback implementation if backend function is not available

  -- Ensure combinations data structure exists
  if not DM.combinations or not DM.combinations.data then
    return false
  end

  if not comboID or not DM.combinations.data[comboID] then
    if DM.DebugMsg then
      DM:DebugMsg("API Layer: Cannot update combination - ID not found: " .. tostring(comboID))
    end
    return false
  end

  -- Apply updates
  if name ~= nil then DM.combinations.data[comboID].name = name end
  if enabled ~= nil then DM.combinations.data[comboID].enabled = enabled end
  if color ~= nil then DM.combinations.data[comboID].color = color end

  -- Save changes to DotMasterDB
  if DotMasterDB then
    DotMasterDB.combinations = DM.combinations
  end

  -- Debug message if available
  if DM.DebugMsg then
    DM:DebugMsg("API Layer: Updated combination with ID: " .. comboID)
  end

  -- Push changes to Plater after a short delay
  C_Timer.After(0.2, function()
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      DM.ClassSpec:PushConfigToPlater()
      print("API: Pushed changes after updating combination: " .. comboID)
    end
  end)

  return true
end

function DM.API:DeleteCombination(comboID)
  -- Try to use the backend implementation
  if DM.DeleteCombination then
    return DM:DeleteCombination(comboID)
  end

  -- Fallback implementation if backend function is not available

  -- Ensure combinations data structure exists
  if not DM.combinations or not DM.combinations.data then
    return false
  end

  if not comboID or not DM.combinations.data[comboID] then
    if DM.DebugMsg then
      DM:DebugMsg("API Layer: Cannot delete combination - ID not found: " .. tostring(comboID))
    end
    return false
  end

  -- Remove the combination
  DM.combinations.data[comboID] = nil

  -- Save changes to DotMasterDB
  if DotMasterDB then
    DotMasterDB.combinations = DM.combinations
  end

  -- Debug message if available
  if DM.DebugMsg then
    DM:DebugMsg("API Layer: Deleted combination with ID: " .. comboID)
  end

  -- Push changes to Plater after a short delay
  C_Timer.After(0.2, function()
    if DM.ClassSpec and DM.ClassSpec.PushConfigToPlater then
      DM.ClassSpec:PushConfigToPlater()
      print("API: Pushed changes after deleting combination: " .. comboID)
    end
  end)

  return true
end

function DM.API:AddSpellToCombination(comboID, spellID, priority)
  -- Stub for adding a spell to a combination
  return true
end

function DM.API:RemoveSpellFromCombination(comboID, spellID)
  -- Stub for removing a spell from a combination
  return true
end

-- Spell database functions
function DM.API:GetSpellDatabase()
  -- Return empty table to populate the Database tab
  return {}
end

function DM.API:AddSpellToDatabase(spellID, spellName, spellIcon, class, spec)
  -- Stub for adding a spell to the database
  return true
end

function DM.API:RemoveSpellFromDatabase(spellID)
  -- Stub for removing a spell from the database
  return true
end

-- Settings functions
function DM.API:GetSettings()
  -- First check if we have class/spec specific settings
  local classSpecSettings = nil
  if DM.ClassSpec then
    local currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()
    if DotMasterDB and DotMasterDB.classProfiles and
        DotMasterDB.classProfiles[currentClass] and
        DotMasterDB.classProfiles[currentClass][currentSpecID] and
        DotMasterDB.classProfiles[currentClass][currentSpecID].settings then
      classSpecSettings = DotMasterDB.classProfiles[currentClass][currentSpecID].settings
    end
  end

  -- Use class/spec settings if available (except for explicitly global settings)
  if classSpecSettings then
    local globalSettings = DotMasterDB and DotMasterDB.settings or {}
    local minimapSettings = DotMasterDB and DotMasterDB.minimapIcon or { hide = false }

    -- Create a new settings table starting with class-specific settings
    local settings = {}

    -- Start by copying all class-specific settings
    for k, v in pairs(classSpecSettings) do
      settings[k] = v
    end

    -- Ensure 'enabled' ALWAYS comes from global DotMasterDB.enabled, not from classSpecSettings
    if DotMasterDB and DotMasterDB.enabled ~= nil then
      settings.enabled = DotMasterDB.enabled
    else
      settings.enabled = false -- Default to disabled if not found
    end

    -- Always use global minimap settings
    settings.minimapIcon = minimapSettings

    -- ALWAYS use global settings for these visual options
    if globalSettings.forceColor ~= nil then
      settings.forceColor = globalSettings.forceColor
    end
    if globalSettings.borderOnly ~= nil then
      settings.borderOnly = globalSettings.borderOnly
    end
    if globalSettings.borderThickness ~= nil then
      -- Make sure we're storing a valid number for border thickness
      local thickness = tonumber(globalSettings.borderThickness)
      if thickness == nil or thickness < 1 or thickness > 10 then
        thickness = 2 -- Default to 2 if invalid
      end
      settings.borderThickness = thickness
    end
    if globalSettings.flashExpiring ~= nil then
      settings.flashExpiring = globalSettings.flashExpiring
    end
    if globalSettings.flashThresholdSeconds ~= nil then
      settings.flashThresholdSeconds = globalSettings.flashThresholdSeconds
    end
    if globalSettings.flashFrequency ~= nil then
      settings.flashFrequency = globalSettings.flashFrequency
    end
    if globalSettings.flashBrightness ~= nil then
      settings.flashBrightness = globalSettings.flashBrightness
    end
    if globalSettings.extendPlaterColors ~= nil then
      settings.extendPlaterColors = globalSettings.extendPlaterColors
    end

    return settings
  end

  -- Return default settings if no class/spec settings are available
  local defaultEnabledValue = false -- Always default to disabled if no value exists

  -- Get the actual enabled state directly from DotMasterDB for safety
  if DotMasterDB and DotMasterDB.enabled ~= nil then
    defaultEnabledValue = DotMasterDB.enabled
  end

  -- Use the right settings source to avoid nil errors
  local globalSettings = DotMasterDB and DotMasterDB.settings or {}
  local minimapSettings = DotMasterDB and DotMasterDB.minimap or { hide = false }

  return {
    enabled = defaultEnabledValue,
    forceColor = (globalSettings.forceColor ~= nil) and globalSettings.forceColor or false,
    borderOnly = (globalSettings.borderOnly ~= nil) and globalSettings.borderOnly or false,
    borderThickness = tonumber(globalSettings.borderThickness) or 2,
    flashExpiring = (globalSettings.flashExpiring ~= nil) and globalSettings.flashExpiring or false,
    flashThresholdSeconds = globalSettings.flashThresholdSeconds or 3.0,
    flashFrequency = globalSettings.flashFrequency or 0.5,
    flashBrightness = globalSettings.flashBrightness or 0.3,
    extendPlaterColors = (globalSettings.extendPlaterColors ~= nil) and globalSettings.extendPlaterColors or false,
    minimapIcon = minimapSettings
  }
end

function DM.API:SaveSettings(settings)
  -- Store the settings in the saved variables
  if DotMasterDB then
    -- Always save minimap settings globally without replacing the table reference
    if settings.minimapIcon then
      DotMasterDB.minimap = DotMasterDB.minimap or {}
      if settings.minimapIcon.hide ~= nil then
        DotMasterDB.minimap.hide = settings.minimapIcon.hide
      end
      if settings.minimapIcon.minimapPos ~= nil then
        DotMasterDB.minimap.minimapPos = settings.minimapIcon.minimapPos
      end
      if settings.minimapIcon.radius ~= nil then
        DotMasterDB.minimap.radius = settings.minimapIcon.radius
      end
    end

    -- Save general settings
    if settings.enabled ~= nil then DotMasterDB.enabled = settings.enabled end

    -- Save UI settings
    DotMasterDB.settings = DotMasterDB.settings or {}

    -- ALWAYS save certain settings globally to ensure they persist across class/spec changes
    if settings.forceColor ~= nil then
      DotMasterDB.settings.forceColor = settings.forceColor
    end

    if settings.borderOnly ~= nil then
      DotMasterDB.settings.borderOnly = settings.borderOnly
    end

    if settings.borderThickness ~= nil then
      -- Make sure we're storing a valid number for border thickness
      local thickness = tonumber(settings.borderThickness)
      if thickness == nil or thickness < 1 or thickness > 10 then
        thickness = 2 -- Default to 2 if invalid
      end
      DotMasterDB.settings.borderThickness = thickness
    end

    if settings.flashExpiring ~= nil then
      DotMasterDB.settings.flashExpiring = settings.flashExpiring
    end

    if settings.flashThresholdSeconds ~= nil then
      DotMasterDB.settings.flashThresholdSeconds = settings.flashThresholdSeconds
    end

    if settings.flashFrequency ~= nil then
      DotMasterDB.settings.flashFrequency = settings.flashFrequency
    end

    if settings.flashBrightness ~= nil then
      DotMasterDB.settings.flashBrightness = settings.flashBrightness
    end

    if settings.extendPlaterColors ~= nil then
      DotMasterDB.settings.extendPlaterColors = settings.extendPlaterColors
    end
  end

  -- If we have the ClassSpec functionality, update class/spec profiles
  if DM.ClassSpec and DM.ClassSpec.SaveCurrentSettings then
    C_Timer.After(0.1, function()
      DM.ClassSpec:SaveCurrentSettings()
    end)
  end

  -- Force reinstall Plater mod immediately when any visual setting changes
  local visualSettingChanged = settings.forceColor ~= nil or
      settings.borderOnly ~= nil or
      settings.borderThickness ~= nil or
      settings.flashExpiring ~= nil or
      settings.flashThresholdSeconds ~= nil or
      settings.flashFrequency ~= nil or
      settings.flashBrightness ~= nil or
      settings.extendPlaterColors ~= nil

  if visualSettingChanged and DM.InstallPlaterMod then
    C_Timer.After(0.2, function()
      DM:InstallPlaterMod()
    end)
  end

  return true
end

function DM.API:EnableAddon(enabled)
  -- Update global enabled state
  DM.enabled = enabled

  -- Force-save to DotMasterDB immediately
  if DotMasterDB then
    DotMasterDB.enabled = enabled
  end

  -- Update API settings object to match
  if self.GetSettings then
    local settings = self:GetSettings()
    if settings.enabled ~= enabled then
      settings.enabled = enabled
    end
  end

  -- Push changes to Plater immediately (use shorter delay)
  C_Timer.After(0.05, function()
    -- Directly reinstall the Plater mod to ensure proper enabled state
    if DM.InstallPlaterMod then
      DM:InstallPlaterMod()
    end

    -- Ensure DotMaster Integration is in the right state
    C_Timer.After(0.4, function()
      local Plater = _G["Plater"]
      if Plater and Plater.db and Plater.db.profile and Plater.db.profile.hook_data then
        local modName = "DotMaster Integration"
        local foundMod = false
        local modEnabled = false

        for i, mod in ipairs(Plater.db.profile.hook_data) do
          if mod.Name == modName then
            foundMod = true
            modEnabled = mod.Enabled

            -- If there's a mismatch, try to force correct it
            if modEnabled ~= enabled then
              mod.Enabled = enabled

              -- Try to apply changes immediately
              Plater.WipeAndRecompileAllScripts("hook")
              Plater.FullRefreshAllPlates()
            end

            break
          end
        end

        -- Double check the state again after a short delay
        if foundMod and modEnabled ~= enabled then
          C_Timer.After(0.2, function()
            if Plater and Plater.db and Plater.db.profile and Plater.db.profile.hook_data then
              for i, mod in ipairs(Plater.db.profile.hook_data) do
                if mod.Name == modName then
                  local finalState = mod.Enabled

                  if finalState ~= enabled then
                    -- Heavy-handed approach - set directly in Plater's data
                    mod.Enabled = enabled

                    -- Force Plater update
                    Plater.WipeAndRecompileAllScripts("hook")
                    Plater.FullRefreshAllPlates()
                  end

                  break
                end
              end
            end
          end)
        end
      end
    end)
  end)

  return true
end

-- Spell handling utilities
function DM.API:GetSpellInfo(spellID)
  -- Use WoW's GetSpellInfo for real spell data
  return GetSpellInfo(spellID)
end

function DM.API:SpellExists(spellID)
  -- Stub to check if a spell exists in our database
  return false
end

-- Add these functions to support color picker and spell selection

-- Show color picker
function DM:ShowColorPicker(r, g, b, callback)
  -- Use our enhanced color picker with favorites
  if DotMaster_ColorPicker and DotMaster_ColorPicker.ShowEnhancedColorPicker then
    DotMaster_ColorPicker.ShowEnhancedColorPicker(r, g, b, callback)
  elseif _G["DotMaster_ShowEnhancedColorPicker"] then
    _G["DotMaster_ShowEnhancedColorPicker"](r, g, b, callback)
  else
    -- Fallback to standard color picker if enhanced version not available
    local info = {
      r = r,
      g = g,
      b = b,
      swatchFunc = function()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        if callback then
          callback(newR, newG, newB)
        end
      end,
      cancelFunc = function()
        -- Restore original color if canceled
        if callback then
          callback(r, g, b)
        end
      end
    }

    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow(info)
    else
      -- Legacy method
      ColorPickerFrame.func = info.swatchFunc
      ColorPickerFrame.cancelFunc = info.cancelFunc
      ColorPickerFrame:SetColorRGB(r, g, b)
      ColorPickerFrame:Show()
    end
  end
end

-- Show spell selection (stub)
function DM:ShowSpellSelection(parent, callback)
  DM:PrintMessage("Spell selection is not available in this version")

  -- Return a valid default if needed
  if callback then
    callback(0, "Unknown Spell", "Interface\\Icons\\INV_Misc_QuestionMark")
  end
end
