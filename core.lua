-- DotMaster core.lua
-- Core structures and minimal initialization

local DM = DotMaster

-- Skip duplicate initialization if bootstrap has already handled it
if DM.initState and DM.initState ~= "bootstrap" then
  return
end

-- Initialize necessary structures
DM.settings = DM.settings or {}
DM.enabled = true

-- Set up basic defaults
DM.defaults = DM.defaults or {
  enabled = true,
  version = "1.0.3",
  flashExpiring = false,
  flashThresholdSeconds = 3.0
}

-- First, we'll setup our slash commands and the help system
local function HelpCommand(msg)
  print("|cff00cc00DotMaster|r: Available commands:");
  print("   |cff00ff00/dm help|r - Shows this help");
  print("   |cff00ff00/dm show|r - Shows configuration window");
  print("   |cff00ff00/dm toggle|r - Shows/hides configuration window");
end

-- Process slash commands
function DM:SlashCommand(msg)
  msg = string.lower(msg);
  if (msg == "" or msg == "help") then
    HelpCommand(msg);
  elseif (msg == "show") then
    DM.GUI:Show();
  elseif (msg == "toggle") then
    DM.GUI:Toggle();
  elseif (msg == "on") then
    DM.enabled = true
    DM:PrintMessage("DotMaster enabled")
  elseif (msg == "off") then
    DM.enabled = false
    DM:PrintMessage("DotMaster disabled")
  else
    DM:PrintMessage("Unknown command: " .. msg)
    HelpCommand(msg);
  end
end

-- Helper function to count table entries
function DM:TableCount(t)
  if type(t) ~= "table" then
    return 0
  end

  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- Basic message printing function
function DM:PrintMessage(message)
  print("|cFFCC00FFDotMaster:|r " .. message)
end

-- Function to update a specific nameplate
function DM:UpdateNameplate(nameplate)
  if not nameplate or not DM.enabled then return end

  if DM.Debug then
    DM.Debug:LogThrottled("nameplate_update", 2, DM.Debug.CATEGORY.UI, "Updating nameplate: %s",
      nameplate:GetName() or "unnamed")
  end

  -- Get settings
  local settings = DM.API:GetSettings()

  -- Code for the nameplate updating will be inserted here
  -- This is a stub for the GUI isolation phase
end

-- Function to update all nameplates
function DM:UpdateAllNameplates()
  if not DM.enabled then return end

  if DM.Debug then
    DM.Debug:Performance("UpdateAllNameplates", function()
      -- Get all nameplates
      for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        DM:UpdateNameplate(nameplate)
      end
    end)
  else
    -- Get all nameplates
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
      DM:UpdateNameplate(nameplate)
    end
  end
end

-- Function to enable nameplate hook
function DM:EnableNameplateHook()
  if DM.nameplateHooked then return end

  if DM.Debug then
    DM.Debug:Loading("Enabling nameplate hooks")
  end

  -- Set enabled state
  DM.enabled = true

  -- Register nameplate events
  DM:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  DM:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

  -- Update hook flag
  DM.nameplateHooked = true

  -- Update existing nameplates
  DM:UpdateAllNameplates()
end

-- Function to disable nameplate hook
function DM:DisableNameplateHook()
  if not DM.nameplateHooked then return end

  if DM.Debug then
    DM.Debug:Loading("Disabling nameplate hooks")
  end

  -- Set enabled state
  DM.enabled = false

  -- Unregister nameplate events
  DM:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
  DM:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")

  -- Update hook flag
  DM.nameplateHooked = false

  -- Reset existing nameplates
  for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
    -- Reset color changes on nameplate
    -- This is a stub for the GUI isolation phase
  end
end

-- Update a specific nameplate for a specific unit
function DM:UpdateNameplateForUnit(unit)
  if not unit or not DM.enabled then return end

  if DM.Debug then
    DM.Debug:LogThrottled("unit_update_" .. unit, 1, DM.Debug.CATEGORY.UI, "Updating nameplate for unit: %s", unit)
  end

  -- Get nameplate for unit
  local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
  if nameplate then
    DM:UpdateNameplate(nameplate)
  end
end

-- Create GUI function
function DM:CreateGUI()
  -- Early exit if we've already created the GUI
  if DM.GUI and DM.GUI.frame then
    return DM.GUI.frame
  end

  if DM.Debug then
    DM.Debug:Loading("Creating GUI")
  end

  -- Create GUI namespace if needed
  DM.GUI = DM.GUI or {}

  -- Create main GUI frame
  local frame = CreateFrame("Frame", "DotMasterGUI", UIParent, "BackdropTemplate")
  frame:SetSize(450, 550)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetClampedToScreen(true)
  frame:SetFrameStrata("DIALOG")

  -- Set backdrop
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })

  -- Create title text
  local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titleText:SetPoint("TOP", frame, "TOP", 0, -15)
  titleText:SetText("DotMaster")

  -- Create close button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

  -- Create tabs
  if DotMaster_Components and DotMaster_Components.CreateTabSystem then
    local tabSystem = DotMaster_Components.CreateTabSystem(frame, 430, 480)
    tabSystem:SetPoint("TOP", titleText, "BOTTOM", 0, -5)

    -- Add General tab
    local generalTab = tabSystem:AddTab("General", function(parent)
      if DM.CreateGeneralTab then
        return DM:CreateGeneralTab(parent)
      end
      return parent
    end)

    -- Add Tracked Spells tab
    local trackedSpellsTab = tabSystem:AddTab("Tracked Spells", function(parent)
      if DM.CreateTrackedSpellsTab then
        return DM:CreateTrackedSpellsTab(parent)
      end
      return parent
    end)

    -- Add Combinations tab
    local combinationsTab = tabSystem:AddTab("Combinations", function(parent)
      if DM.CreateCombinationsTab then
        return DM:CreateCombinationsTab(parent)
      end
      return parent
    end)

    -- Initialize the tab system
    tabSystem:Initialize()
    tabSystem:SelectTab(1)

    -- Store reference to tab system
    DM.GUI.tabSystem = tabSystem
  end

  -- Store reference to main frame
  DM.GUI.frame = frame

  -- Hide by default
  frame:Hide()

  if DM.Debug then
    DM.Debug:Loading("GUI created successfully")
  end

  return frame
end

-- Main event handler
DM:SetScript("OnEvent", function(self, event, ...)
  if event == "NAME_PLATE_UNIT_ADDED" then
    local unit = ...
    if DM.Debug then
      DM.Debug:LogThrottled("nameplate_added", 0.5, DM.Debug.CATEGORY.UI, "Nameplate added: %s", unit)
    end

    C_Timer.After(0.1, function()
      DM:UpdateNameplateForUnit(unit)
    end)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    local unit = ...
    if DM.Debug then
      DM.Debug:LogThrottled("nameplate_removed", 0.5, DM.Debug.CATEGORY.UI, "Nameplate removed: %s", unit)
    end

    -- Any cleanup needed when a nameplate is removed
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Combat started
    if DM.Debug then
      DM.Debug:Combat("Entered combat")
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Combat ended
    if DM.Debug then
      DM.Debug:Combat("Exited combat")
    end
  end
end)
