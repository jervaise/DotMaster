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
  print("   |cff00ff00/dm on|r - Enable DotMaster");
  print("   |cff00ff00/dm off|r - Disable DotMaster");
  print("   |cff00ff00/dm debug|r - Toggle debug console");
  print("   |cff00ff00/dm minimap|r - Toggle minimap icon");
  print("   |cff00ff00/dm status|r - Show debug status information");
end

-- Process slash commands
function DM:SlashCommand(msg)
  msg = string.lower(msg);

  -- Log slash command in debug console
  if DM.Debug then
    DM.Debug:General("Slash command received: %s", msg)
  end

  if (msg == "" or msg == "help") then
    HelpCommand(msg);
  elseif (msg == "show") then
    -- Create GUI if it doesn't exist
    if not DM.GUI or not DM.GUI.frame then
      if DM.Debug then
        DM.Debug:UI("Creating GUI from slash command")
      end
      DM:CreateGUI()
    end

    -- Show GUI
    if DM.GUI and DM.GUI.frame then
      DM.GUI.frame:Show()
      if DM.Debug then
        DM.Debug:UI("GUI shown via slash command")
      end
    else
      DM:PrintMessage("Could not display GUI. Please try again.")
      if DM.Debug then
        DM.Debug:Error("Failed to show GUI - frame not created")
      end
    end
  elseif (msg == "toggle") then
    -- Create GUI if it doesn't exist
    if not DM.GUI or not DM.GUI.frame then
      DM:CreateGUI()
    end

    -- Toggle GUI visibility
    if DM.GUI and DM.GUI.frame then
      if DM.GUI.frame:IsShown() then
        DM.GUI.frame:Hide()
        if DM.Debug then
          DM.Debug:UI("GUI hidden via slash command")
        end
      else
        DM.GUI.frame:Show()
        if DM.Debug then
          DM.Debug:UI("GUI shown via slash command")
        end
      end
    else
      DM:PrintMessage("Could not toggle GUI. Please try again.")
      if DM.Debug then
        DM.Debug:Error("Failed to toggle GUI - frame not created")
      end
    end
  elseif (msg == "debug") then
    -- Toggle debug console
    if DM.debugFrame then
      DM.debugFrame:Toggle()
      if DM.Debug then
        DM.Debug:General("Debug console toggled via slash command")
      end
    else
      DM:PrintMessage("Debug console not available")
      if DM.Debug then
        DM.Debug:Error("Debug console not available")
      end
    end
  elseif (msg == "status") then
    -- Check GUI status
    DM:CheckGUIStatus()
  elseif (msg == "on") then
    DM.enabled = true
    DM:PrintMessage("DotMaster enabled")
    if DM.Debug then
      DM.Debug:General("DotMaster enabled via slash command")
    end
  elseif (msg == "off") then
    DM.enabled = false
    DM:PrintMessage("DotMaster disabled")
    if DM.Debug then
      DM.Debug:General("DotMaster disabled via slash command")
    end
  else
    DM:PrintMessage("Unknown command: " .. msg)
    HelpCommand(msg);
  end
end

-- Add convenience function for GUI toggle
function DM:ToggleGUI()
  -- Create GUI if it doesn't exist
  if not DM.GUI or not DM.GUI.frame then
    DM:CreateGUI()
  end

  -- Toggle GUI visibility
  if DM.GUI and DM.GUI.frame then
    if DM.GUI.frame:IsShown() then
      DM.GUI.frame:Hide()
    else
      DM.GUI.frame:Show()
    end
  end
end

-- Add debug function to check GUI status
function DM:CheckGUIStatus()
  print("|cFFFF00FFDEBUG:|r Checking GUI status:")

  -- Check if GUI namespace exists
  if not DM.GUI then
    print("- DM.GUI namespace does not exist")
    return
  end

  print("- DM.GUI namespace exists")

  -- Check if frame exists
  if not DM.GUI.frame then
    print("- DM.GUI.frame does not exist")
    return
  end

  print("- DM.GUI.frame exists: " .. tostring(DM.GUI.frame:GetName() or "unnamed"))
  print("- GUI is " .. (DM.GUI.frame:IsShown() and "VISIBLE" or "HIDDEN"))

  -- Check components
  if DM.GUI.tabSystem then
    print("- TabSystem exists")
  else
    print("- TabSystem does not exist")
  end

  -- Check DotMaster_Components
  if DotMaster_Components then
    print("- DotMaster_Components exists")
    if DotMaster_Components.CreateTabSystem then
      print("- CreateTabSystem exists")
    else
      print("- CreateTabSystem does not exist")
    end
  else
    print("- DotMaster_Components does not exist")
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

-- Core CreateGUI function - acts as a wrapper for the main implementation in gui_common.lua
function DM:CreateGUI()
  -- Print a clear debug message to help diagnose issues
  print("|cFFFF00FFDEBUG:|r DM:CreateGUI in core.lua called (wrapper)")

  -- Check if we already have a GUI frame
  if DM.GUI and DM.GUI.frame then
    return DM.GUI.frame
  end

  if DM.Debug then
    DM.Debug:Loading("Creating GUI (core wrapper)")
  end

  -- Ensure we have a GUI namespace
  DM.GUI = DM.GUI or {}

  -- Call the implementation from gui_common.lua if it exists
  if DotMaster_Components and DotMaster_Components.CreateTabSystem then
    if DM.Debug then
      DM.Debug:Loading("Using DotMaster_Components.CreateTabSystem")
    end

    -- Call the implementation in gui_common.lua directly by our own method
    local frame = DM.GUI.CreateGUI and DM.GUI.CreateGUI()
    if frame then
      return frame
    else
      if DM.Debug then
        DM.Debug:Error("GUI.CreateGUI returned nil")
      end
    end
  else
    -- Fallback to very basic frame if we can't find the other implementation
    if DM.Debug then
      DM.Debug:Error("DotMaster_Components not found, using fallback GUI")
    end

    -- Create a basic frame as fallback
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

    -- Create message about incomplete setup
    local errorMsg = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    errorMsg:SetPoint("CENTER", frame, "CENTER", 0, 0)
    errorMsg:SetWidth(400)
    errorMsg:SetText("GUI components could not be loaded properly.\nPlease check the addon installation.")
    errorMsg:SetJustifyH("CENTER")
    errorMsg:SetTextColor(1, 0.2, 0.2, 1)

    -- Store reference to main frame
    DM.GUI.frame = frame

    -- Hide by default
    frame:Hide()

    return frame
  end
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
