-- DotMaster by Jervaise
-- Main initialization file (init.lua)

-- Create addon frame and namespace
DotMaster = CreateFrame("Frame")
local DM = DotMaster

-- Constants
DM.VIRULENT_PLAGUE_ID = 191587
DM.DEFAULT_PURPLE_COLOR = { 0.6, 0.2, 1.0 }
DM.MAX_CUSTOM_SPELLS = 20

-- Setup basic variables
DM.activePlates = {}
DM.coloredPlates = {}
DM.originalColors = {}
DM.enabled = true
DM.spellConfig = {}
DM.GUI = {}
-- Setup basic variables
DM.activePlates = {}
DM.coloredPlates = {}
DM.originalColors = {}
DM.enabled = true
DM.spellConfig = {}
DM.GUI = {}
DM.recordingDots = false
DM.detectedDots = {}
DM.defaults = {
  enabled = true,
  version = "0.5.2",
  lastSortOrder = 1, -- Added for sorting functionality
  spellConfig = {
    -- Default spells disabled, users will add their own
    -- [DM.VIRULENT_PLAGUE_ID] = { enabled = true, color = DM.DEFAULT_PURPLE_COLOR, name = "Virulent Plague" }
  }
}

-- Debug mode enabled by default
DM.DEBUG_MODE = true

-- Simple print function that doesn't require DebugMsg
function DM:SimplePrint(message)
  DM:DebugMsg("|cFFCC00FFDotMaster:|r " .. message)
end

-- Main initialization function
function DM:Initialize()
  -- Use SimplePrint as a fallback if DebugMsg is not available yet
  if self.DebugMsg then
    self:DebugMsg("Starting Main Initialization")
  else
    self:SimplePrint("Starting Main Initialization")
  end

  -- Register core events (these are generally safe)
  self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  self:RegisterEvent("UNIT_AURA")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_LOGOUT")
  if self.DebugMsg then self:DebugMsg("Core events registered") end

  -- Initialize potentially fragile components using pcall

  -- Create the main GUI
  local guiOK, guiErr = pcall(function()
    if self.CreateGUI then
      self:CreateGUI()
      if self.DebugMsg then self:DebugMsg("Main GUI creation attempted.") end
    else
      if self.DebugMsg then self:DebugMsg("CreateGUI function not found.") end
    end
  end)
  if not guiOK then
    if self.DebugMsg then self:DebugMsg("ERROR creating main GUI: " .. tostring(guiErr)) end
  end

  -- Initialize main slash commands
  local slashOK, slashErr = pcall(function()
    self:InitializeMainSlashCommands()
  end)
  if not slashOK then
    if self.DebugMsg then self:DebugMsg("ERROR initializing main slash commands: " .. tostring(slashErr)) end
  end

  -- Hook Plater if available
  local platerOK, platerErr = pcall(function()
    if _G["Plater"] then
      local Plater = _G["Plater"]
      if self.DebugMsg then self:DebugMsg("Plater detected, adding hooks") end
      hooksecurefunc(Plater, "UpdatePlateFrame", function(plateFrame)
        C_Timer.After(0.1, function()
          if not DM.enabled then return end
          local unitToken = plateFrame.namePlateUnitToken
          if unitToken and DM.activePlates[unitToken] then
            DM:UpdateNameplate(unitToken)
          end
        end)
      end)
    else
      if self.DebugMsg then self:DebugMsg("Plater not detected.") end
    end
  end)
  if not platerOK then
    if self.DebugMsg then self:DebugMsg("ERROR hooking Plater: " .. tostring(platerErr)) end
  end

  -- Final message
  self:PrintMessage("loaded. Type /dm for options or /dmdebug for debug console.")
  if self.DebugMsg then self:DebugMsg("Main Initialization finished.") end
end

-- Event handler
function DM:OnEvent(event, ...)
  if event == "NAME_PLATE_UNIT_ADDED" then
    self:NameplateAdded(...)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    self:NameplateRemoved(...)
  elseif event == "UNIT_AURA" then
    self:UnitAuraChanged(...)
  elseif event == "PLAYER_ENTERING_WORLD" then
    wipe(self.activePlates)
    wipe(self.coloredPlates)
    wipe(self.originalColors)
  elseif event == "PLAYER_LOGOUT" then
    self:SaveSettings()
  end
end

-- Set up event handling
DM:SetScript("OnEvent", function(self, ...) self:OnEvent(...) end)

-- Modify PrintMessage to respect DEBUG_MODE
function DM:PrintMessage(message, ...)
  if not self.DEBUG_MODE then return end
  local prefix = "|cFFCC00FFDotMaster:|r "
  if select('#', ...) > 0 then
    DM:DebugMsg(prefix .. message, ...)
  else
    DM:DebugMsg(prefix .. message)
  end
end

-- We'll call Initialize() at the end of core.lua after all modules are loaded
