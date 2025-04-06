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
  Name = "DotMaster DoT Tracker",
  Icon = [[Interface\ICONS\Ability_Rogue_RuptureTN]],
  Desc = "Tracks damage-over-time effects on nameplates. Created by DotMaster AddOn.",
  Author = "DotMaster",
  Time = time(),
  Revision = 1,
  PlaterCore = 1,

  -- Lua code sections that Plater will execute
  OnInit = [[function (scriptTable)
    -- Initialize the script
    scriptTable.config = scriptTable.config or {}

    -- Create a table to store our environment
    local envTable = {}
    scriptTable.envTable = envTable

    -- Print initialization message
    print("DotMaster DoT Tracker: Initialized!")
end]],

  OnUpdate = [[function (self, unitId, unitFrame, envTable, scriptTable)
    -- Simple validation
    if not unitId or not unitFrame then
        return
    end

    -- In a future version, this will check for active DoTs
    -- and modify the nameplate accordingly
end]],

  OnHide = [[function (self, unitId, unitFrame, envTable, scriptTable)
    -- Clean up any visual effects when the nameplate is hidden
end]],

  OnShow = [[function (self, unitId, unitFrame, envTable, scriptTable)
    -- Initialize nameplate-specific elements when shown
end]],

  -- Default script configuration options
  Options = {
    {
      Name = "Show Border",
      Type = 1,
      Value = true,
    },
    {
      Name = "Border Color",
      Type = 1,
      Value = { 1, 0, 0, 1 },
    },
  },

  -- Required Plater script metadata
  Hooks = {},
  IconTexture = [[Interface\ICONS\Ability_Rogue_RuptureTN]],
  IconTexCoords = { 0, 1, 0, 1 },
  IconSize = { 14, 14 },
  Enabled = true,
  NpcNames = {},
  SpellIds = {},
  UID = "DM" .. tostring(math.random(100000, 999999)),
  scriptId = "DMScript" .. tostring(math.random(100000, 999999)),
  version = 1,
  semver = "1.0.0",
}

-- Function to inject or update the DotMaster script in Plater
function DM.API:InjectPlaterScript()
  -- Safety check - ensure Plater exists
  if not Plater then
    DM:PlaterDebug("Error: Plater is not loaded or installed!")
    DM:PrintMessage("Error: Plater is not loaded or installed!")
    return false
  end

  DM:PlaterDebug("Preparing to inject script into Plater...")

  -- Create a copy of our template
  local scriptTable = DeepCopyTable(DM.API.PLATER_SCRIPT_TEMPLATE)

  -- Generate new unique IDs each time for new installations
  scriptTable.UID = "DM" .. tostring(math.random(100000, 999999))
  scriptTable.scriptId = "DMScript" .. tostring(math.random(100000, 999999))

  -- Apply any user-specific settings here in future versions
  DM:PlaterDebug("Applying user settings to script...")

  -- Check if our script already exists
  local existingScriptIndex = nil
  if Plater.db and Plater.db.profile and Plater.db.profile.script_data then
    for i, script in ipairs(Plater.db.profile.script_data) do
      if script and script.Name == scriptTable.Name then
        existingScriptIndex = i
        DM:PlaterDebug("Found existing script at index " .. i)
        break
      end
    end
  else
    DM:PlaterDebug("Error: Plater database structure not found!")
    DM:PrintMessage("Error: Plater database structure not found!")
    return false
  end

  -- Either update existing script or add a new one
  if existingScriptIndex then
    -- Update existing script but preserve key properties
    local existingScript = Plater.db.profile.script_data[existingScriptIndex]

    -- Keep these properties from the existing script
    scriptTable.Enabled = existingScript.Enabled or true
    scriptTable.UID = existingScript.UID
    scriptTable.scriptId = existingScript.scriptId

    -- Update version info
    scriptTable.version = (existingScript.version or 1) + 1
    scriptTable.semver = "1.0." .. tostring(scriptTable.version)
    scriptTable.Revision = (existingScript.Revision or 1) + 1

    -- Replace the script with our updated version
    Plater.db.profile.script_data[existingScriptIndex] = scriptTable
    DM:PlaterDebug("Updated existing Plater script (version " .. scriptTable.version .. ")")
    DM:PrintMessage("Updated existing Plater script (version " .. scriptTable.version .. ")")
  else
    -- Add as a new script
    table.insert(Plater.db.profile.script_data, scriptTable)
    DM:PlaterDebug("Injected new Plater script")
    DM:PrintMessage("Injected new Plater script")
  end

  -- Use a safe approach to recompile scripts
  DM:PlaterDebug("Telling Plater to recompile scripts...")

  -- Wait a moment before recompiling
  C_Timer.After(0.5, function()
    if Plater.WipeAndRecompileAllScripts then
      -- Try to safely recompile with error protection
      local success, errorMsg = pcall(function()
        Plater.WipeAndRecompileAllScripts("script")
      end)

      if not success then
        DM:PlaterDebug("Error during script recompilation: " .. tostring(errorMsg))
        -- Try alternative recompilation method
        if Plater.CompileAllScripts then
          Plater.CompileAllScripts("script")
        end
      end
    elseif Plater.CompileAllScripts then
      Plater.CompileAllScripts("script")
    else
      DM:PlaterDebug("Warning: Could not find Plater script recompilation methods")
    end

    DM:PlaterDebug("Script installation complete")
  end)

  return true
end
