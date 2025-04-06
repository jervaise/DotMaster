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

-- Specialized debug function for Plater integration
function DM:PlaterDebug(message)
  if DM.DEBUG_MODE then
    DM:PrintMessage("[Plater Integration] " .. message)
  end
end

-- Version info
function DM.API:GetVersion()
  return "1.0.3"
end

-- Spell tracking functions
function DM.API:GetTrackedSpells()
  -- Return empty table to populate the Tracked Spells tab
  return {}
end

function DM.API:TrackSpell(spellID, spellName, spellIcon, color, priority)
  -- Stub for adding a spell to tracking
  DM:DebugMsg("API: TrackSpell called with ID " .. tostring(spellID))
  return true
end

function DM.API:UntrackSpell(spellID)
  -- Stub for removing a spell from tracking
  DM:DebugMsg("API: UntrackSpell called with ID " .. tostring(spellID))
  return true
end

function DM.API:UpdateSpellSettings(spellID, enabled, priority, color)
  -- Stub for updating spell settings
  DM:DebugMsg("API: UpdateSpellSettings called for " .. tostring(spellID))
  return true
end

-- Combination functions
function DM.API:GetCombinations()
  -- Return empty table to populate the Combinations tab
  return {}
end

function DM.API:CreateCombination(name, color)
  -- Stub for creating a new combination
  DM:DebugMsg("API: CreateCombination called: " .. tostring(name))
  return "combo_" .. tostring(GetTime()) -- Return a fake ID
end

function DM.API:UpdateCombination(comboID, name, enabled, color)
  -- Stub for updating a combination
  DM:DebugMsg("API: UpdateCombination called for " .. tostring(comboID))
  return true
end

function DM.API:DeleteCombination(comboID)
  -- Stub for deleting a combination
  DM:DebugMsg("API: DeleteCombination called for " .. tostring(comboID))
  return true
end

function DM.API:AddSpellToCombination(comboID, spellID, priority)
  -- Stub for adding a spell to a combination
  DM:DebugMsg("API: AddSpellToCombination called")
  return true
end

function DM.API:RemoveSpellFromCombination(comboID, spellID)
  -- Stub for removing a spell from a combination
  DM:DebugMsg("API: RemoveSpellFromCombination called")
  return true
end

-- Spell database functions
function DM.API:GetSpellDatabase()
  -- Return empty table to populate the Database tab
  return {}
end

function DM.API:AddSpellToDatabase(spellID, spellName, spellIcon, class, spec)
  -- Stub for adding a spell to the database
  DM:DebugMsg("API: AddSpellToDatabase called for " .. tostring(spellID))
  return true
end

function DM.API:RemoveSpellFromDatabase(spellID)
  -- Stub for removing a spell from the database
  DM:DebugMsg("API: RemoveSpellFromDatabase called for " .. tostring(spellID))
  return true
end

-- Settings functions
function DM.API:GetSettings()
  -- Return default settings to populate the General tab
  return {
    enabled = true,
    forceColor = false,
    borderOnly = false,
    borderThickness = 2,
    flashExpiring = false,
    flashThresholdSeconds = 3.0,
    minimapIcon = {
      hide = false
    }
  }
end

function DM.API:SaveSettings(settings)
  -- Stub for saving settings
  DM:DebugMsg("API: SaveSettings called")
  return true
end

function DM.API:EnableAddon(enabled)
  -- Stub for enabling/disabling the addon
  DM:DebugMsg("API: EnableAddon called: " .. tostring(enabled))
  return true
end

-- Spell handling utilities
function DM.API:GetSpellInfo(spellID)
  -- Use WoW's GetSpellInfo for real spell data
  return GetSpellInfo(spellID)
end

function DM.API:SpellExists(spellID)
  -- Stub to check if a spell exists in our database
  DM:DebugMsg("API: SpellExists called for " .. tostring(spellID))
  return false
end

-- Debug APIs
function DM.API:GetDebugSettings()
  return {
    categories = {
      general = true,
      database = true
    },
    consoleOutput = false
  }
end

function DM.API:SaveDebugSettings(debugSettings)
  DM:DebugMsg("API: SaveDebugSettings called")
  return true
end

-- Add these functions to support color picker and spell selection

-- Show color picker (stub)
function DM:ShowColorPicker(r, g, b, callback)
  -- Use the built-in color picker directly for now
  local function colorFunc()
    local r, g, b = ColorPickerFrame:GetColorRGB()
    callback(r, g, b)
  end

  local function cancelFunc()
    local prevR, prevG, prevB = unpack(ColorPickerFrame.previousValues)
    callback(prevR, prevG, prevB)
  end

  ColorPickerFrame.func = colorFunc
  ColorPickerFrame.cancelFunc = cancelFunc
  ColorPickerFrame.previousValues = { r, g, b }
  ColorPickerFrame:SetColorRGB(r, g, b)
  ColorPickerFrame:Show()
end

-- Show spell selection (stub)
function DM:ShowSpellSelection(parent, callback)
  DM:PrintMessage("Spell selection is not available in this version")

  -- Return a valid default if needed
  if callback then
    callback(0, "Unknown Spell", "Interface\\Icons\\INV_Misc_QuestionMark")
  end
end

-- Template for the Plater script that will handle DoT tracking
DM.API.PLATER_SCRIPT_TEMPLATE = {
  Name = "DotMaster Color Handler",
  Icon = "Interface\\ICONS\\Spell_Shadow_SoulLeech_3.blp",
  Desc = "Handles nameplate coloring for DoTs managed by DotMaster",
  Author = "DotMaster",
  Time = time(),
  Revision = 1,
  PlaterCore = 1,
  Enabled = true,
  ScriptType = 1,

  -- OnInit runs once when the script is loaded
  OnInit = [[function(scriptTable)
    print("|cFF00FFDCDotMaster Plater Script Loaded|r")
  end]],

  -- OnUpdate runs many times a second
  OnUpdate = [[function(self, unitId, unitFrame, envTable, scriptTable)
    -- This is the DotMaster integration script for Plater
    -- Ensure we have required objects
    if not DotMaster then return end
    if not unitId or not unitFrame or not unitFrame.healthBar then return end

    -- Get color from DotMaster
    local color
    if DotMaster.GetColorForUnitThrottled then
      color = DotMaster.GetColorForUnitThrottled(unitId)
    elseif DotMaster.GetColorForUnit then
      color = DotMaster.GetColorForUnit(unitId)
    end

    -- Apply color if found
    if color and color.r and color.g and color.b then
      -- Store original color first time
      if not unitFrame.DotMasterOrigColor and not unitFrame.DotMasterColored then
        local r, g, b = unitFrame.healthBar:GetStatusBarColor()
        unitFrame.DotMasterOrigColor = {r=r, g=g, b=b}
      end

      -- Set the color
      unitFrame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
      unitFrame.DotMasterColored = true
    else
      -- Restore original color if it was previously colored by us
      if unitFrame.DotMasterColored and unitFrame.DotMasterOrigColor then
        unitFrame.healthBar:SetStatusBarColor(
          unitFrame.DotMasterOrigColor.r,
          unitFrame.DotMasterOrigColor.g,
          unitFrame.DotMasterOrigColor.b
        )
        unitFrame.DotMasterColored = false
      end
    end
  end]],

  -- Required empty sections
  OnHide = [[function(self, unitId, unitFrame, envTable, scriptTable)
    -- Restore original color if needed
    if unitFrame.DotMasterColored and unitFrame.DotMasterOrigColor then
      unitFrame.healthBar:SetStatusBarColor(
        unitFrame.DotMasterOrigColor.r,
        unitFrame.DotMasterOrigColor.g,
        unitFrame.DotMasterOrigColor.b
      )
      unitFrame.DotMasterColored = false
    end
  end]],

  -- Required structure elements
  SpellIds = {},
  Hooks = {},
  Options = {},
  OptionsValues = {},
  UID = "DotMaster" .. time(),
  version = 1,
  VersionCheck = 1,
  Prio = 99
}

-- Function to inject or update the DotMaster script in Plater
function DM.API:InjectPlaterScript()
  -- Safety check - ensure Plater exists
  if not Plater then
    DM:PrintMessage("Error: Plater is not loaded or installed.")
    return false
  end

  -- Ensure Plater database is ready
  if not Plater.db or not Plater.db.profile or not Plater.db.profile.script_data then
    DM:PrintMessage("Error: Plater is not fully initialized. Try again later.")
    return false
  end

  DM:PrintMessage("Adding DotMaster script to Plater...")

  -- Create a script object that won't interfere with Plater's systems
  local script = {
    Name = DM.API.PLATER_SCRIPT_TEMPLATE.Name,
    Icon = DM.API.PLATER_SCRIPT_TEMPLATE.Icon,
    Desc = DM.API.PLATER_SCRIPT_TEMPLATE.Desc,
    Author = DM.API.PLATER_SCRIPT_TEMPLATE.Author,
    Time = time(),
    Revision = DM.API.PLATER_SCRIPT_TEMPLATE.Revision,
    PlaterCore = DM.API.PLATER_SCRIPT_TEMPLATE.PlaterCore,
    Enabled = true,
    ScriptType = DM.API.PLATER_SCRIPT_TEMPLATE.ScriptType,
    OnInit = DM.API.PLATER_SCRIPT_TEMPLATE.OnInit,
    OnUpdate = DM.API.PLATER_SCRIPT_TEMPLATE.OnUpdate,
    OnHide = DM.API.PLATER_SCRIPT_TEMPLATE.OnHide,
    SpellIds = {},
    Hooks = {},
    Options = {},
    OptionsValues = {},
    UID = "DotMaster" .. time(),
    version = 1,
    VersionCheck = 1,
    Prio = 99
  }

  -- Check if script already exists
  local exists = false
  for i, existingScript in ipairs(Plater.db.profile.script_data) do
    if existingScript and existingScript.Name == script.Name then
      -- Preserve enabled state
      script.Enabled = existingScript.Enabled
      -- Keep the original UID to avoid issues
      script.UID = existingScript.UID

      -- Increment version
      script.version = (existingScript.version or 1) + 1
      script.Revision = (existingScript.Revision or 1) + 1

      -- Replace the existing script
      Plater.db.profile.script_data[i] = script
      exists = true
      DM:PrintMessage("Updated existing DotMaster script.")
      break
    end
  end

  -- Add as new script if not found
  if not exists then
    table.insert(Plater.db.profile.script_data, script)
    DM:PrintMessage("Added new DotMaster script to Plater.")
  end

  -- Important: Tell the user they need to reload
  DM:PrintMessage("|cFFFFFF00IMPORTANT:|r You MUST type /reload to complete the installation.")

  return true
end

-- Function to remove the DotMaster script from Plater to fix broken installation
function DM.API:RemovePlaterScript()
  -- Safety check - ensure Plater exists
  if not Plater then
    DM:PrintMessage("Error: Plater is not loaded or installed!")
    return false
  end

  -- Ensure Plater.db is populated
  if not Plater.db or not Plater.db.profile or not Plater.db.profile.script_data then
    DM:PrintMessage("Error: Plater database structure not found!")
    return false
  end

  DM:PrintMessage("Removing DotMaster script from Plater...")

  -- Look for our script by name
  local found = false
  for i = #Plater.db.profile.script_data, 1, -1 do
    local script = Plater.db.profile.script_data[i]
    if script and script.Name and (script.Name == "DotMaster Color Handler" or script.Name:find("DotMaster")) then
      -- Remove the script from the table
      table.remove(Plater.db.profile.script_data, i)
      found = true
      DM:PrintMessage("Removed DotMaster script from Plater")
    end
  end

  if not found then
    DM:PrintMessage("No DotMaster scripts found in Plater")
  else
    DM:PrintMessage("Important: Please type /reload to complete the cleanup")
  end

  return true
end
