-- DotMaster minimap.lua
-- Minimap icon implementation using LibDBIcon-1.0

local DM = DotMaster

-- Initialize function for the minimap icon
function DM:InitializeMinimapIcon()
  -- First check if required WoW API functions exist
  if not CreateFrame then
    DM:PrintMessage("Error: CreateFrame API not available. Minimap functionality disabled.")
    return
  end

  -- Basic check if we're ready to initialize
  if not DM or type(DM) ~= "table" then
    print("DotMaster error: Addon not properly initialized")
    return
  end

  -- Ensure this function doesn't run more than once
  if DM.minimapInitialized then
    return
  end
  DM.minimapInitialized = true

  -- Create or access saved variables for the minimap icon
  if not DotMasterDB then
    DotMasterDB = {}
  end

  if not DotMasterDB.minimap then
    DotMasterDB.minimap = {
      hide = false,     -- Default to showing the icon
      minimapPos = 220, -- Default angle around minimap (220 degrees)
      radius = 80,      -- Default distance from minimap center
    }
  end

  -- Get settings from API
  local settings = DM.API:GetSettings()
  if not settings.minimapIcon then
    settings.minimapIcon = {
      hide = false,
      minimapPos = 220,
      radius = 80
    }
    -- Use AutoSave instead of direct SaveSettings
    DM:AutoSave()
  end

  -- Use API settings to override DotMasterDB for minimap state
  DotMasterDB.minimap.hide = settings.minimapIcon.hide

  -- Check for required libraries
  if not LibStub then
    DM:PrintMessage("Error: LibStub not found. Minimap functionality disabled.")
    return
  end

  -- Try to create required library objects
  local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
  if not LDB then
    DM:PrintMessage("Error: LibDataBroker-1.1 not found. Minimap functionality disabled.")
    return
  end

  local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
  if not LibDBIcon then
    DM:PrintMessage("Error: LibDBIcon-1.0 not found. Minimap functionality disabled.")
    return
  end
  DM.LDBIcon = LibDBIcon

  -- Use a simpler icon setup
  local iconPath = "Interface\\AddOns\\DotMaster\\Media\\dotmaster-icon.tga"

  -- Simple LDB object creation
  DM.minimapLDB = LDB:NewDataObject("DotMaster", {
    type = "launcher",
    text = "DotMaster",
    icon = iconPath,
    OnClick = function(_, button)
      -- Use the new ToggleGUI function for consistent behavior
      DM:ToggleGUI()
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine("DotMaster")
      tooltip:AddLine("|cFFFFFFFFClick:|r Open DotMaster Interface", 1, 1, 1)
    end
  })

  -- Safety check to ensure the object was created
  if not DM.minimapLDB then
    DM:PrintMessage("Error: Failed to create minimap button data")
    return
  end

  -- Simple registration
  if not DotMasterDB.minimap then
    DotMasterDB.minimap = {
      hide = false,
      minimapPos = 220,
      radius = 80
    }
  end

  LibDBIcon:Register("DotMaster", DM.minimapLDB, DotMasterDB.minimap)

  -- Apply saved visibility state immediately
  if DotMasterDB.minimap.hide then
    LibDBIcon:Hide("DotMaster")
  else
    LibDBIcon:Show("DotMaster")
  end
end

-- Additional function to toggle minimap icon
function DM:ToggleMinimapIcon()
  -- Basic check for LibDBIcon
  local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
  if not LibDBIcon then
    DM:PrintMessage("Error: LibDBIcon-1.0 not available for toggle")
    return
  end

  -- Determine desired visibility from saved variables (fallback to API settings)
  local hide
  if DotMasterDB and DotMasterDB.minimap and type(DotMasterDB.minimap.hide) == "boolean" then
    hide = DotMasterDB.minimap.hide
  elseif DM.API and DM.API.settings and DM.API.settings.minimapIcon then
    hide = DM.API.settings.minimapIcon.hide and true or false
  else
    hide = false
  end

  -- Apply to minimap icon
  if hide then
    LibDBIcon:Hide("DotMaster")
  else
    LibDBIcon:Show("DotMaster")
  end
end

-- Add minimap slash command
function DM:AddMinimapSlashCommand()
  -- Slash command is handled in settings.lua via DM:InitializeMainSlashCommands()
end

-- Hook into the initialization process
local function HookInitialization()
  -- Initialization is handled in bootstrap.lua; no delayed hooks here.
end

-- Call the initialization hook
-- (No-op; bootstrap handles initialization)
