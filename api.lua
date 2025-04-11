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

-- Function to inject or update the DotMaster script in Plater
function DM.API:InjectPlaterScript()
  -- Simply redirect to showing the instructions
  DM:PrintMessage("Automatic script injection is no longer supported.")
  DM:PrintMessage("Please use the manual installation approach for better compatibility.")

  -- Show the manual installation instructions
  return self:ShowPlaterScriptInstructions()
end

-- Function to remove the DotMaster script from Plater to fix broken installation
function DM.API:RemovePlaterScript(promptReload)
  -- Show manual instructions instead
  DM:PrintMessage("Automatic script removal is no longer supported.")
  DM:PrintMessage("To remove the DotMaster script from Plater:")
  DM:PrintMessage("1. Type /plater")
  DM:PrintMessage("2. Go to Scripts tab")
  DM:PrintMessage("3. Find 'DotMaster Integration' in the list")
  DM:PrintMessage("4. Click the gear icon next to it")
  DM:PrintMessage("5. Select 'Delete'")
  DM:PrintMessage("6. Reload your UI with /reload")

  return true
end

-- Function to get the script content for users to manually add to Plater
function DM.API:GetPlaterScriptContent()
  local scriptCode = [[
-- DotMaster Integration

-- Initialization: This should be the code under the Initialization tab in Plater
function (scriptTable)
  --insert code here


end

-- On Show: This should be the code under the On Show tab in Plater
function (self, unitId, unitFrame, envTable, scriptTable)

end

-- On Update: This should be the code under the On Update tab in Plater
function (self, unitId, unitFrame, envTable, scriptTable)
  Plater.SetNameplateColor (unitFrame, scriptTable.config.agonyColor)
  if envTable._RemainingTime <= scriptTable.config.threshold then
    envTable.agonyFlash:Play()
  else
    envTable.agonyFlash:Stop()
  end
end

-- On Hide: This should be the code under the On Hide tab in Plater
function (self, unitId, unitFrame, envTable, scriptTable)
  Plater.SetNameplateColor (unitFrame)
  envTable.agonyFlash:Stop()
end

-- Constructor: This should be the code under the Constructor tab in Plater
function (self, unitId, unitFrame, envTable, scriptTable)
  envTable.agonyFlash = envTable.agonyFlash or Plater.CreateFlash (unitFrame.healthBar, 0.5, scriptTable.config.threshold * 2, scriptTable.config.agonyColor)
end

-- Configuration (Added in Plater):
-- Name: DotMaster Integration
-- Icon: 136139 (Agony)
-- Trigger Type: Buffs & Debuffs
-- Triggers: Agony (980), Immolate (348), Virulent Plague (34914)
-- Add Options:
--   - agonyColor (Color) default: {1, 0.1, 0.1, 1}
--   - threshold (Number) default: 3
]]

  return scriptCode
end

-- Function to display script and instructions for users to add manually to Plater
function DM.API:ShowPlaterScriptInstructions()
  -- Safety check - ensure Plater exists
  if not Plater then
    DM:PrintMessage("Error: Plater is not loaded or installed!")
    return false
  end

  -- Show instructions
  DM:PrintMessage("|cFFFFD100DotMaster Integration for Plater|r")
  DM:PrintMessage("To add the script to Plater:")
  DM:PrintMessage("1. Type /plater")
  DM:PrintMessage("2. Go to Scripts tab")
  DM:PrintMessage("3. Click '+ New'")
  DM:PrintMessage("4. Name it 'DotMaster Integration'")
  DM:PrintMessage("5. Set Trigger Type to 'Buffs & Debuffs'")
  DM:PrintMessage("6. Add these triggers: Agony (980), Immolate (348), Virulent Plague (34914)")
  DM:PrintMessage("7. IMPORTANT: Make sure to add code to the correct tabs as shown below!")

  DM:PrintMessage("|cFFFFD100For the Initialization tab:|r")
  DM:PrintMessage("function (scriptTable)")
  DM:PrintMessage("  --insert code here")
  DM:PrintMessage("end")

  DM:PrintMessage("|cFFFFD100For the On Show tab:|r")
  DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
  DM:PrintMessage("end")

  DM:PrintMessage("|cFFFFD100For the On Update tab:|r")
  DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
  DM:PrintMessage("  Plater.SetNameplateColor (unitFrame, scriptTable.config.agonyColor)")
  DM:PrintMessage("  if envTable._RemainingTime <= scriptTable.config.threshold then")
  DM:PrintMessage("    envTable.agonyFlash:Play()")
  DM:PrintMessage("  else")
  DM:PrintMessage("    envTable.agonyFlash:Stop()")
  DM:PrintMessage("  end")
  DM:PrintMessage("end")

  DM:PrintMessage("|cFFFFD100For the On Hide tab:|r")
  DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
  DM:PrintMessage("  Plater.SetNameplateColor (unitFrame)")
  DM:PrintMessage("  envTable.agonyFlash:Stop()")
  DM:PrintMessage("end")

  DM:PrintMessage("|cFFFFD100For the Constructor tab:|r")
  DM:PrintMessage("function (self, unitId, unitFrame, envTable, scriptTable)")
  DM:PrintMessage(
    "  envTable.agonyFlash = envTable.agonyFlash or Plater.CreateFlash (unitFrame.healthBar, 0.5, scriptTable.config.threshold * 2, scriptTable.config.agonyColor)")
  DM:PrintMessage("end")

  DM:PrintMessage("|cFFFFD100Options to add:|r")
  DM:PrintMessage("- agonyColor (Type: Color, Default: {1, 0.1, 0.1, 1})")
  DM:PrintMessage("- threshold (Type: Number, Default: 3)")

  return true
end

-- Function to generate a Plater script import string that users can paste directly
function DM.API:GeneratePlaterImportString()
  -- Safety check - ensure Plater exists to get version info
  if not Plater then
    DM:PrintMessage("Error: Plater is not loaded or installed!")
    return nil
  end

  -- Create the script object
  local scriptObject = {
    Name = "DotMaster Integration",
    Icon = 136139, -- Agony icon
    Desc = "Created by Nemzi-Sargeras",
    Author = "DotMaster",
    Time = time(),
    Revision = 1,
    PlaterCore = Plater.CoreVersion or 1,

    -- Script type (1 = Aura/Buff, 2 = Cast, 3 = NPC/Unit)
    ScriptType = 1,

    -- Spell IDs to trigger on
    SpellIds = {
      980,   -- Agony
      348,   -- Immolate
      34914, -- Virulent Plague
    },

    -- IMPORTANT: Script code sections below - corrected ordering based on screenshots
    -- Initialization should contain the --insert code here comment
    ["Initialization"] = [[function (scriptTable)
  --insert code here


end]],

    -- Constructor should contain the agonyFlash creation
    ["Constructor"] = [[function (self, unitId, unitFrame, envTable, scriptTable)
  envTable.agonyFlash = envTable.agonyFlash or Plater.CreateFlash (unitFrame.healthBar, 0.5, scriptTable.config.threshold * 2, scriptTable.config.agonyColor)
end]],

    -- OnShow should be empty
    ["OnShow"] = [[function (self, unitId, unitFrame, envTable, scriptTable)

end]],

    -- OnUpdate should contain color setting and flashing logic
    ["OnUpdate"] = [[function (self, unitId, unitFrame, envTable, scriptTable)
  Plater.SetNameplateColor (unitFrame, scriptTable.config.agonyColor)
  if envTable._RemainingTime <= scriptTable.config.threshold then
    envTable.agonyFlash:Play()
  else
    envTable.agonyFlash:Stop()
  end
end]],

    -- OnHide should clean up color and stop flash
    ["OnHide"] = [[function (self, unitId, unitFrame, envTable, scriptTable)
  Plater.SetNameplateColor (unitFrame)
  envTable.agonyFlash:Stop()
end]],

    -- Options and default settings
    Options = {
      {
        Type = 1, -- Color
        Name = "Agony Color",
        Key = "agonyColor",
        Value = { 1, 0.1, 0.1, 1 }, -- Red color
      },
      {
        Type = 2, -- Number
        Name = "Threshold",
        Key = "threshold",
        Value = 3,
      },
    },

    -- Default settings values
    OptionsValues = {
      agonyColor = { 1, 0.1, 0.1, 1 },
      threshold = 3,
    },
  }

  -- IMPORTANT: The tableToExport structure below defines how Plater identifies the script sections
  -- The numeric keys correspond to different script sections that must match the editor tabs order
  local tableToExport = {
    ["1"] = scriptObject.ScriptType,     -- Script Type (1=Aura)
    ["2"] = scriptObject.Name,           -- Script Name
    ["3"] = scriptObject.SpellIds,       -- Spell IDs that trigger this script
    ["4"] = scriptObject.NpcNames or {}, -- NPC names that trigger this script
    ["5"] = scriptObject.Icon,           -- Icon shown in the scripts list
    ["6"] = scriptObject.Desc,           -- Description
    ["7"] = scriptObject.Author,         -- Author
    ["8"] = scriptObject.Time,           -- Creation timestamp
    ["9"] = scriptObject.Revision,       -- Revision number
    ["10"] = scriptObject.PlaterCore,    -- Plater version this was created for

    -- The following are the actual script function sections
    -- These MUST match the order in the editor tabs:
    ["11"] = scriptObject.Initialization, -- Initialization tab
    ["12"] = scriptObject.OnShow,         -- On Show tab
    ["13"] = scriptObject.OnUpdate,       -- On Update tab
    ["14"] = scriptObject.OnHide,         -- On Hide tab
    ["15"] = scriptObject.Constructor,    -- Constructor tab

    ["options"] = scriptObject.Options,
    ["addon"] = "Plater",
    ["version"] = -1,
    ["LoadConditions"] = {
      ["talent"] = {},
      ["spec"] = {},
      ["class"] = {},
      ["race"] = {},
      ["faction"] = {},
      ["pvptalent"] = {},
      ["affix"] = {},
    },
    ["tocversion"] = select(4, GetBuildInfo()),
    ["type"] = "script",
  }

  -- Use Plater's compression functions to generate the import string
  if Plater and Plater.CompressData then
    local encodedString = Plater.CompressData(tableToExport, "print")
    if encodedString then
      return encodedString
    else
      DM:PrintMessage("Failed to encode script data.")
      return nil
    end
  else
    DM:PrintMessage("Plater compression functions not available.")
    return nil
  end
end

-- Function to display the import string in a standalone window
function DM.API:DisplayImportStringDialog()
  -- Safety check - ensure Plater exists
  if not Plater then
    DM:PrintMessage("Error: Plater is not loaded or installed!")
    return false
  end

  -- Generate the import string
  local importString = self:GeneratePlaterImportString()
  if not importString then
    DM:PrintMessage("Failed to generate import string. Using manual instructions instead.")
    return self:ShowPlaterScriptInstructions()
  end

  -- Create a frame if it doesn't exist
  if not DM.ImportStringFrame then
    local frame = CreateFrame("Frame", "DotMasterImportStringFrame", UIParent, "BackdropTemplate")
    DM.ImportStringFrame = frame

    -- Setup the frame
    frame:SetSize(600, 420) -- Increased size for better readability
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Register with UI special frames to enable Escape key closing
    tinsert(UISpecialFrames, "DotMasterImportStringFrame")

    -- Add a backdrop
    frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    -- Create a title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cFFCC00FFDotMaster|r: Plater Import String")

    -- Create instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -10)
    instructions:SetWidth(580)
    instructions:SetText("Copy this string and paste it into Plater's Import window")

    -- Create more detailed instructions
    local detailedInstructions = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detailedInstructions:SetPoint("TOP", instructions, "BOTTOM", 0, -8)
    detailedInstructions:SetWidth(580)
    detailedInstructions:SetJustifyH("CENTER")
    detailedInstructions:SetText(
      "1. Select All with Ctrl+A  |  2. Copy with Ctrl+C  |  3. Paste into Plater's Import dialog")

    -- Create a scrollable background for the EditBox
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(530, 220) -- Increased height
    scrollFrame:SetPoint("TOP", detailedInstructions, "BOTTOM", 0, -10)

    -- Create a background for the scroll frame
    local scrollBg = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -5, 5)
    scrollBg:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 5, -5)
    scrollBg:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 8,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    scrollBg:SetBackdropColor(0, 0, 0, 0.8)
    scrollBg:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.6)

    -- Create the actual EditBox for the scroll frame
    local scrollEditBox = CreateFrame("EditBox", nil, scrollFrame)
    scrollEditBox:SetWidth(510)
    scrollEditBox:SetFontObject("ChatFontNormal") -- More visible font
    scrollEditBox:SetMaxLetters(0)                -- No character limit
    scrollEditBox:SetCountInvisibleLetters(true)
    scrollEditBox:SetMultiLine(true)
    scrollEditBox:SetAutoFocus(false)
    scrollEditBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    scrollEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    scrollEditBox:SetScript("OnTextChanged", function(self, userInput)
      if userInput then return end
      self:SetCursorPosition(0)
    end)
    scrollEditBox:SetScript("OnMouseUp", function(self)
      self:HighlightText()
    end)

    scrollFrame:SetScrollChild(scrollEditBox)
    frame.EditBox = scrollEditBox

    -- Create a close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)

    -- Create a status label
    local statusLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetPoint("BOTTOM", frame, "BOTTOM", 0, 55)
    statusLabel:SetWidth(580)
    statusLabel:SetJustifyH("CENTER")
    statusLabel:SetText("Code ready to copy!")
    frame.StatusLabel = statusLabel

    -- Create a copy button for convenience
    local copyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyButton:SetSize(150, 22)
    copyButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 24)
    copyButton:SetText("Select All and Copy")
    copyButton:SetScript("OnClick", function()
      scrollEditBox:SetFocus()
      scrollEditBox:HighlightText()
      statusLabel:SetText("Press Ctrl+C to copy to clipboard")
    end)

    -- Create a open plater button
    local platerButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    platerButton:SetSize(180, 22)
    platerButton:SetPoint("LEFT", copyButton, "RIGHT", 10, 0)
    platerButton:SetText("Open Plater and Import")
    platerButton:SetScript("OnClick", function()
      -- Hide the dialog
      frame:Hide()
      -- Open Plater if available
      if Plater and SlashCmdList["PLATER"] then
        SlashCmdList["PLATER"]("")
        C_Timer.After(0.5, function()
          DM:PrintMessage("Ready to import: Navigate to the Scripts tab and click Import")
        end)
      else
        DM:PrintMessage("Plater is not installed or enabled!")
      end
    end)

    -- Create a manual instructions button
    local manualButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    manualButton:SetSize(180, 22)
    manualButton:SetPoint("RIGHT", copyButton, "LEFT", -10, 0)
    manualButton:SetText("Manual Instructions")
    manualButton:SetScript("OnClick", function()
      DM.API:ShowPlaterScriptInstructions()
    end)
  end

  -- Set the import string and show the frame
  DM.ImportStringFrame.EditBox:SetText(importString)
  DM.ImportStringFrame:Show()

  -- Select all text for easy copying
  C_Timer.After(0.1, function()
    if DM.ImportStringFrame and DM.ImportStringFrame.EditBox then
      DM.ImportStringFrame.StatusLabel:SetText("Select All (Ctrl+A) and Copy (Ctrl+C)")
      DM.ImportStringFrame.EditBox:SetFocus()
      DM.ImportStringFrame.EditBox:HighlightText()
    end
  end)

  return true
end

-- Function to display script import string or instructions for users to add to Plater
function DM.API:ShowPlaterImportString()
  -- Just call our new dialog function
  return self:DisplayImportStringDialog()
end

-- This is a reference import string for validating our own
DM.ReferenceImportString =
"9svBVnnmq4)oRiAuDEzTfX(WyiK6quq4k(uLxCtUKyrItKD6GYh8VDo7K0MnvMgIjKRspBF3Z9CV4JryBy06MwrTuJIRD73CObyR9z0pX)jB9YLm67bDcEEbyIBluGUOUm1eNvRmXkOIlKczUjoDVIBrcvQ2eVdYfOywjxxGx7HWjKwpq)GINy1JTJr)gVCp6Slz018kaVZQUj(hfGfgrfmYdm6Qe0k6kzlOY4jW2Rtt)SuV9lLC8KTIkEoO32fo3j3xTdum6hHdm6rwZATr2XGKm43RZRLhmX8MMsbGXwsDzTAGEUeJ9NV7BG7BO9BBp(CR530zZFdj7Dtx(frdXRTo5EqPT5N1eYmYSzi8PPwm7GGrDKH2AJaQorjAqZc6zP)IisqKJQ(lJc9JC8nmK4pFUfE)JX6gSm8DlCOkKGljbyHoerbvAoMwGQFjMs5QCqX1mkwHUrbO)XKZo06hFpjKrZ2lt6AaUqdLzV2eVxkAxL2lG19kaLb59B47kTIDS3TBI5wtC)6wqMIB7xi4rpe8ZA10PcPguT2Ixk23uakymMNtc9dJUeJ)im4xG)ppmmyryyegUKGxUiQRY5rHwB7wJDNRBbX9ioJuFappxFL7nXBWgJMlMmk1Gm0)LJHNXLM4R(dNBjEFi11u0F(PGXRa4LTfVJRqpoZl6H(1dFIKjY9gnm5vMy)ZR0P3wt6lyeY)3kZZGxdWjYgLYU7RdJU24MK92RE6CGD6ko37u)5t0oG8(WfJRFLA45z5qJ0jDsF0dU)LfwDM1nzK97p"

-- Function to validate our generated import string against the reference
function DM.API:ValidateImportString(testMode)
  -- First create our own string
  local ourString = self:GeneratePlaterImportString()
  if not ourString then
    DM:PrintMessage("Error: Failed to generate our import string")
    return false
  end

  -- Get the reference string
  local refString = DM.ReferenceImportString

  -- Safety check - ensure needed libraries exist
  if not LibStub or not LibStub:GetLibrary("LibDeflate") or not LibStub:GetLibrary("AceSerializer-3.0") then
    DM:PrintMessage("Error: Required libraries not available for validation!")
    return false
  end

  local LibDeflate = LibStub:GetLibrary("LibDeflate")
  local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

  -- Create helper function to decode a string
  local function decodeString(str)
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return nil end

    decoded = LibDeflate:DecompressDeflate(decoded)
    if not decoded then return nil end

    local success, data = LibAceSerializer:Deserialize(decoded)
    if not success then return nil end

    return data
  end

  -- Decode both strings
  local refData = decodeString(refString)
  local ourData = decodeString(ourString)

  if not refData then
    DM:PrintMessage("Error: Could not decode reference string")
    return false
  end

  if not ourData then
    DM:PrintMessage("Error: Could not decode our string")
    return false
  end

  -- Compare key elements
  local function compareData(ref, our, prefix)
    prefix = prefix or ""
    local differences = {}

    -- Check what's in the reference but missing or different in ours
    for key, value in pairs(ref) do
      if type(value) == "table" then
        if type(our[key]) ~= "table" then
          table.insert(differences, prefix .. key .. ": Missing table in our data")
        else
          local subDiffs = compareData(value, our[key], prefix .. key .. ".")
          for _, diff in ipairs(subDiffs) do
            table.insert(differences, diff)
          end
        end
      else
        if our[key] == nil then
          table.insert(differences, prefix .. key .. ": Missing in our data")
        elseif type(our[key]) ~= type(value) then
          table.insert(differences,
            prefix .. key .. ": Type mismatch - ref: " .. type(value) .. ", our: " .. type(our[key]))
        elseif tostring(our[key]) ~= tostring(value) and key ~= "Time" and key ~= "8" then
          -- Ignore time difference
          table.insert(differences,
            prefix .. key .. ": Value mismatch - ref: " .. tostring(value) .. ", our: " .. tostring(our[key]))
        end
      end
    end

    -- Check what's in ours but not in reference
    for key, value in pairs(our) do
      if ref[key] == nil then
        table.insert(differences, prefix .. key .. ": Extra in our data")
      end
    end

    return differences
  end

  local differences = compareData(refData, ourData)

  if testMode then
    -- Just print the differences and return
    if #differences > 0 then
      DM:PrintMessage("Import string validation found " .. #differences .. " differences:")
      for i, diff in ipairs(differences) do
        if i <= 10 then
          DM:PrintMessage(diff)
        else
          DM:PrintMessage("...and " .. (#differences - 10) .. " more differences")
          break
        end
      end
    else
      DM:PrintMessage("Import string validation passed! Strings are compatible.")
    end
    return true
  else
    -- Set flags to fix any issues automatically
    if #differences > 0 then
      DM:DebugMsg("Import validation found " .. #differences .. " issues to fix")

      -- Ensure we're properly formatting our export
      return false
    else
      DM:DebugMsg("Import validation successful!")
      return true
    end
  end
end
