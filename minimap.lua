-- DotMaster minimap.lua
-- Minimap icon implementation using LibDBIcon-1.0

local DM = DotMaster

-- Initialize function for the minimap icon
function DM:InitializeMinimapIcon()
  DM:DebugMsg("Initializing minimap icon...")

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

  -- Set up LDB data broker object
  local LDB = LibStub("LibDataBroker-1.1")

  -- Create the LibDataBroker object
  DM.minimapLDB = LDB:NewDataObject("DotMaster", {
    type = "launcher",
    text = "DotMaster",
    icon = "Interface\\AddOns\\DotMaster\\Media\\dotmaster-icon.tga",
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
        -- Toggle Find My Dots window
        DM:StartFindMyDots()
      end
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine("DotMaster")
      tooltip:AddLine("|cFFFFFFFFLeft-Click:|r Open Main Interface", 1, 1, 1)
      tooltip:AddLine("|cFFFFFFFFRight-Click:|r Find My Dots", 1, 1, 1)
    end
  })

  -- Register with LibDBIcon
  local LibDBIcon = LibStub("LibDBIcon-1.0")
  LibDBIcon:Register("DotMaster", DM.minimapLDB, DotMasterDB.minimap)

  -- Apply saved visibility state immediately
  if DotMasterDB.minimap.hide then
    LibDBIcon:Hide("DotMaster")
  else
    LibDBIcon:Show("DotMaster")
  end

  -- Additional function to toggle minimap icon
  function DM:ToggleMinimapIcon()
    -- Get latest settings
    local settings = DM.API:GetSettings()

    -- Apply the saved state
    DotMasterDB.minimap.hide = settings.minimapIcon.hide

    if DotMasterDB.minimap.hide then
      LibDBIcon:Hide("DotMaster")
    else
      LibDBIcon:Show("DotMaster")
    end

    DM:DebugMsg("Minimap icon visibility set to: " .. (DotMasterDB.minimap.hide and "hidden" or "shown"))
  end

  DM:DebugMsg("Minimap icon initialized successfully")
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

  -- Add the minimap command to the help messages
  local originalHelpHandler = function()
    DM:PrintMessage("Available commands:")
    DM:PrintMessage("  /dm on - Enable addon")
    DM:PrintMessage("  /dm off - Disable addon")
    DM:PrintMessage("  /dm status - Display debug information")
    DM:PrintMessage("  /dm console - Open Debug Console (use /dmdebug)")
    DM:PrintMessage("  /dm show - Show GUI (if loaded)")
    DM:PrintMessage("  /dm reset - Reset to default settings")
    DM:PrintMessage("  /dm save - Force save settings")
    DM:PrintMessage("  /dm reload - Reload UI")
    DM:PrintMessage("  /dm fixdb - Fix database ID format issues")
    DM:PrintMessage("  /dm dbstate - Show detailed database state and spells")
    DM:PrintMessage("  /dm minimap - Toggle minimap icon")
  end
end

-- Hook into the initialization process
local function HookInitialization()
  -- Check if bootstrap has finished
  if DM.initState and DM.initState == "player_login" then
    -- Initialize the minimap icon
    DM:InitializeMinimapIcon()

    -- Add minimap slash command
    DM:AddMinimapSlashCommand()
  else
    -- Wait for player login event
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(self, event)
      DM:InitializeMinimapIcon()
      DM:AddMinimapSlashCommand()
      self:UnregisterAllEvents()
    end)
  end
end

-- Call the initialization hook
HookInitialization()
