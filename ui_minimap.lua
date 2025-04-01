--[[
  DotMaster - UI Minimap Module

  File: ui_minimap.lua
  Purpose: Implements minimap button functionality

  Functions:
  - Initialize(): Sets up minimap button
  - ToggleMinimapButton(): Shows or hides the minimap button
  - OnClick(): Handles clicking on the minimap button

  Dependencies:
  - LibDataBroker-1.1
  - LibDBIcon-1.0

  Author: Jervaise
  Last Updated: 2024-07-01
]]

local DM = DotMaster             -- reference to main addon
local MinimapButton = {}         -- local table for module functions
DM.MinimapButton = MinimapButton -- expose to addon namespace

-- Local constants
-- Try our custom icon first, fall back to a default WoW icon if not available
local ADDON_ICON = "Interface\\AddOns\\DotMaster\\Media\\dotmaster-icon"
local DEFAULT_ICON = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" -- A default DOT icon as fallback
local MINIMAP_BUTTON_NAME = "DotMasterMinimapButton"

-- Initialize the minimap button
function MinimapButton:Initialize()
  self:DebugMsg("Initializing minimap button")

  -- Check if required libraries exist
  if not LibStub then
    self:DebugMsg("LibStub not found - minimap button disabled")
    return
  end

  -- Create the LDB object
  local LDB = LibStub("LibDataBroker-1.1", true)
  if not LDB then
    self:DebugMsg("LibDataBroker-1.1 not found - minimap button disabled")
    return
  end

  local LibDBIcon = LibStub("LibDBIcon-1.0", true)
  if not LibDBIcon then
    self:DebugMsg("LibDBIcon-1.0 not found - minimap button disabled")
    return
  end

  -- Test if custom icon exists, use default if not
  local iconTexture = ADDON_ICON
  local textureFile = ADDON_ICON:gsub("Interface\\", "")
  if not C_Texture or not C_Texture.GetFileIDFromPath or not C_Texture.GetFileIDFromPath(textureFile) then
    iconTexture = DEFAULT_ICON
    self:DebugMsg("Custom icon not found, using default icon")
  end

  -- Create a LibDataBroker object for our addon
  self.ldbObject = LDB:NewDataObject(MINIMAP_BUTTON_NAME, {
    type = "launcher",
    text = "DotMaster",
    icon = iconTexture,
    OnClick = function(_, button)
      MinimapButton:OnClick(button)
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine("DotMaster")
      tooltip:AddLine("Click to open/close configuration", 1, 1, 1)
      tooltip:AddLine("Right-click for quick options", 1, 1, 1)
    end,
  })

  -- Initialize the minimap button using LibDBIcon
  if LibDBIcon then
    -- Initialize the DB for saving button position
    DM.minimapDB = DM.minimapDB or {}
    DM.minimapDB.hide = DM.minimapDB.hide or not DM.minimapEnabled

    -- Register the button with LibDBIcon
    LibDBIcon:Register(MINIMAP_BUTTON_NAME, self.ldbObject, DM.minimapDB)

    -- Show or hide based on the current setting
    self:ToggleMinimapButton(DM.minimapEnabled)

    -- Log success
    self:DebugMsg("Minimap button initialized successfully")
  end
end

-- Handle clicks on the minimap button
function MinimapButton:OnClick(button)
  if button == "LeftButton" then
    -- Left click opens the main configuration window
    if DM.UIMain and DM.UIMain.ToggleUI then
      DM.UIMain:ToggleUI()
    elseif DM.GUI and DM.GUI.ToggleUI then
      DM.GUI:ToggleUI()
    elseif DM.ShowConfig then
      DM:ShowConfig()
    else
      self:DebugMsg("No UI toggle method found")
    end
  elseif button == "RightButton" then
    -- Right click could show a quick menu with common options
    -- For now, just toggle the addon
    DM.enabled = not DM.enabled
    DM:PrintMessage(DM.enabled and "Enabled" or "Disabled")

    -- Safe handling of nameplate functions
    if DM.enabled then
      if DM.UpdateAllNameplates then
        DM:UpdateAllNameplates()
      elseif DM.Nameplate and DM.Nameplate.UpdateAll then
        DM.Nameplate:UpdateAll()
      end
    else
      if DM.ResetAllNameplates then
        DM:ResetAllNameplates()
      elseif DM.Nameplate and DM.Nameplate.ResetAll then
        DM.Nameplate:ResetAll()
      end
    end

    DM:SaveSettings()
  end
end

-- Show or hide the minimap button
function MinimapButton:ToggleMinimapButton(show)
  local LibDBIcon = LibStub("LibDBIcon-1.0", true)
  if not LibDBIcon then return end

  if show then
    LibDBIcon:Show(MINIMAP_BUTTON_NAME)
    DM.minimapDB.hide = false
  else
    LibDBIcon:Hide(MINIMAP_BUTTON_NAME)
    DM.minimapDB.hide = true
  end

  DM.minimapEnabled = show
  DM:SaveSettings()
end

-- Debug message function with module name
function MinimapButton:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[MinimapButton] " .. message)
  end
end

-- Return the module
return MinimapButton
