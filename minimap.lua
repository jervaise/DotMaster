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
    DM.API:SaveSettings(settings)
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

  -- Use a simpler icon setup
  local iconPath = "Interface\\AddOns\\DotMaster\\Media\\dotmaster-icon.tga"

  -- Simple LDB object creation
  DM.minimapLDB = LDB:NewDataObject("DotMaster", {
    type = "launcher",
    text = "DotMaster",
    icon = iconPath,
    OnClick = function(_, button)
      if button == "LeftButton" then
        -- Toggle main interface
        if DM.GUI and DM.GUI.frame then
          if DM.GUI.frame:IsShown() then
            DM.GUI.frame:Hide()
          else
            DM.GUI.frame:Show()
          end
        end
      elseif button == "RightButton" then
        DM:PrintMessage("Right-click functionality is currently disabled")
      end
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine("DotMaster")
      tooltip:AddLine("|cFFFFFFFFLeft-Click:|r Open Main Interface", 1, 1, 1)
      tooltip:AddLine("|cFFFFFFFFRight-Click:|r Currently disabled", 1, 1, 1)
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

  -- Get latest settings
  local settings = DM.API:GetSettings()

  -- Update saved state
  if not DotMasterDB then DotMasterDB = {} end
  if not DotMasterDB.minimap then
    DotMasterDB.minimap = { hide = false }
  end

  if not settings.minimapIcon then settings.minimapIcon = {} end

  -- Set the hide value
  DotMasterDB.minimap.hide = settings.minimapIcon.hide

  -- Apply to minimap icon
  if DotMasterDB.minimap.hide then
    LibDBIcon:Hide("DotMaster")
  else
    LibDBIcon:Show("DotMaster")
  end
end

-- Add minimap slash command
function DM:AddMinimapSlashCommand()
  -- Original slash command handler is in settings.lua, so we'll just add to it
  local originalSlashHandler = SlashCmdList["DOTMASTER"]

  SlashCmdList["DOTMASTER"] = function(msg)
    local command, arg = strsplit(" ", msg, 2)
    command = strtrim(command:lower())

    if command == "minimap" then
      -- Get settings
      local settings = DM.API:GetSettings()

      -- Toggle minimap visibility
      if not settings.minimapIcon then settings.minimapIcon = {} end
      settings.minimapIcon.hide = not settings.minimapIcon.hide

      -- Save settings
      DM.API:SaveSettings(settings)

      -- Apply change
      DM:ToggleMinimapIcon()

      DM:PrintMessage(settings.minimapIcon.hide and "Minimap icon hidden" or "Minimap icon shown")
      return
    end

    -- Call the original handler for other commands
    originalSlashHandler(msg)
  end
end

-- Hook into the initialization process
local function HookInitialization()
  -- Check if bootstrap has finished
  if DM.initState and DM.initState == "player_login" then
    -- Use a larger delay to ensure all APIs are loaded
    C_Timer.After(2.0, function()
      -- Initialize the minimap icon
      DM:InitializeMinimapIcon()
      -- Add minimap slash command
      DM:AddMinimapSlashCommand()
    end)
  else
    -- Wait for player login event
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(self, event)
      -- Use a larger delay to ensure all APIs are loaded
      C_Timer.After(2.0, function()
        DM:InitializeMinimapIcon()
        DM:AddMinimapSlashCommand()
      end)
      self:UnregisterAllEvents()
    end)
  end
end

-- Call the initialization hook
HookInitialization()
