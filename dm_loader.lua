--[[
  DotMaster - Loader Module

  File: dm_loader.lua
  Purpose: Final initialization sequence for all modules

  Functions:
  - OnInitialize(): Called when addon loads, performs final setup

  Dependencies:
  - All other modules

  Author: Jervaise
  Last Updated: 2024-07-01
]]

local DM = DotMaster
local Loader = {}
DM.Loader = Loader

-- Called when the addon is loaded
function Loader:Initialize()
  DM:DebugMsg("Loader module initializing...")

  -- Set up nameplate event handlers
  if DM.NPDetection then
    DM.NPDetection:Initialize()
    DM:DebugMsg("Nameplate detection initialized")
  end

  -- Initialize all modules in order of dependencies
  if DM.Debug and DM.Debug.Initialize then
    DM.Debug:Initialize()
    DM:DebugMsg("Debug module initialized")
  end

  if DM.Settings and DM.Settings.Initialize then
    DM.Settings:Initialize()
    DM:DebugMsg("Settings module initialized")
  end

  if DM.Utils and DM.Utils.Initialize then
    DM.Utils:Initialize()
    DM:DebugMsg("Utils module initialized")
  end

  if DM.SpellDB and DM.SpellDB.Initialize then
    DM.SpellDB:Initialize()
    DM:DebugMsg("SpellDB module initialized")
  end

  -- UI components
  if DM.UIMain and DM.UIMain.Initialize then
    DM.UIMain:Initialize()
    DM:DebugMsg("UI Main initialized")
  end

  if DM.UIComponents and DM.UIComponents.Initialize then
    DM.UIComponents:Initialize()
    DM:DebugMsg("UI Components initialized")
  end

  if DM.UIColorPicker and DM.UIColorPicker.Initialize then
    DM.UIColorPicker:Initialize()
    DM:DebugMsg("UI Color Picker initialized")
  end

  if DM.UIGeneralTab and DM.UIGeneralTab.Initialize then
    DM.UIGeneralTab:Initialize()
    DM:DebugMsg("UI General Tab initialized")
  end

  if DM.UISpellsTab and DM.UISpellsTab.Initialize then
    DM.UISpellsTab:Initialize()
    DM:DebugMsg("UI Spells Tab initialized")
  end

  -- Initialize minimap button if available
  if DM.MinimapButton and DM.MinimapButton.Initialize then
    DM.MinimapButton:Initialize()
    DM:DebugMsg("Minimap button initialized")
  end

  -- Features
  if DM.FindMyDots and DM.FindMyDots.Initialize then
    DM.FindMyDots:Initialize()
    DM:DebugMsg("Find My Dots initialized")
  end

  -- Final setup
  DM:DebugMsg("Loader initialization complete")
end

-- Set up any commands or event handlers that need to be connected at load time
function Loader:SetupCommands()
  -- Register slash commands
  SLASH_DOTMASTER1 = "/dotmaster"
  SLASH_DOTMASTER2 = "/dm"

  SlashCmdList["DOTMASTER"] = function(msg)
    if msg and msg:lower() == "debug" then
      DM.DEBUG_MODE = not DM.DEBUG_MODE
      DM:PrintMessage("Debug Mode " .. (DM.DEBUG_MODE and "Enabled" or "Disabled"))
      DM:SaveSettings()
    elseif msg and msg:lower() == "reset" then
      DM:ResetSettings()
      DM:PrintMessage("Settings reset to defaults")
    elseif msg and msg:lower() == "config" then
      -- Open configuration window
      if DM.UIMain and DM.UIMain.ToggleUI then
        DM.UIMain:ToggleUI()
      end
    elseif msg and msg:lower() == "minimap" then
      -- Toggle minimap button
      if DM.MinimapButton and DM.MinimapButton.ToggleMinimapButton then
        DM.minimapEnabled = not DM.minimapEnabled
        DM.MinimapButton:ToggleMinimapButton(DM.minimapEnabled)
        DM:PrintMessage("Minimap button " .. (DM.minimapEnabled and "shown" or "hidden"))
      else
        DM:PrintMessage("Minimap button functionality not available")
      end
    else
      -- Toggle addon enabled state
      DM.enabled = not DM.enabled
      DM:PrintMessage(DM.enabled and "Enabled" or "Disabled")

      if DM.enabled then
        DM:UpdateAllNameplates()
      else
        DM:ResetAllNameplates()
      end

      DM:SaveSettings()
    end
  end
end

-- Called when all addons are loaded
function Loader:OnInitialize()
  -- Load saved settings
  DM:LoadSettings()

  -- Set up commands
  self:SetupCommands()

  -- Initialize modules
  self:Initialize()

  -- Print welcome message if debug mode is on
  if DM.DEBUG_MODE then
    DM:PrintMessage("Loaded version " .. (DM.version or "Unknown"))
  end
end

-- Set up events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    Loader:OnInitialize()
  end
end)

-- Return the module
return Loader
