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
DM.GUI = {}
DM.recordingDots = false
DM.detectedDots = {}
DM.defaults = {
  enabled = true,
  version = "0.6.7",
  lastSortOrder = 1, -- Added for sorting functionality
}

-- Debug mode enabled by default
DM.DEBUG_CATEGORIES = {
  general = true,
  -- Add any other categories you want to enable/disable
}

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

  -- TEMPORARILY DISABLED NAMEPLATE FEATURES
  -- Core nameplate events commented out for development
  -- self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  -- self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  -- self:RegisterEvent("UNIT_AURA")

  -- Only register non-nameplate events
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("PLAYER_LOGOUT")
  if self.DebugMsg then self:DebugMsg("Core events registered (nameplate features temporarily disabled)") end

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

  -- TEMPORARILY DISABLED NAMEPLATE FEATURES
  -- Plater hook disabled for development
  -- local platerOK, platerErr = pcall(function()
  --   if _G["Plater"] then
  --     local Plater = _G["Plater"]
  --     if self.DebugMsg then self:DebugMsg("Plater detected, adding hooks") end
  --     hooksecurefunc(Plater, "UpdatePlateFrame", function(plateFrame)
  --       C_Timer.After(0.1, function()
  --         if not DM.enabled then return end
  --         local unitToken = plateFrame.namePlateUnitToken
  --         if unitToken and DM.activePlates[unitToken] then
  --           DM:UpdateNameplate(unitToken)
  --         end
  --       end)
  --     end)
  --   else
  --     if self.DebugMsg then self:DebugMsg("Plater not detected.") end
  --   end
  -- end)
  -- if not platerOK then
  --   if self.DebugMsg then self:DebugMsg("ERROR hooking Plater: " .. tostring(platerErr)) end
  -- end

  -- Final message
  self:PrintMessage(
    "loaded with nameplate features temporarily disabled. Type /dm for options or /dmdebug for debug console.")
  if self.DebugMsg then self:DebugMsg("Main Initialization finished.") end
end

-- Event handler
function DM:OnEvent(event, ...)
  if event == "NAME_PLATE_UNIT_ADDED" then
    -- TEMPORARILY DISABLED
    -- self:NameplateAdded(...)
    self:DebugMsg("Nameplate feature disabled: NAME_PLATE_UNIT_ADDED event ignored")
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    -- TEMPORARILY DISABLED
    -- self:NameplateRemoved(...)
    self:DebugMsg("Nameplate feature disabled: NAME_PLATE_UNIT_REMOVED event ignored")
  elseif event == "UNIT_AURA" then
    -- TEMPORARILY DISABLED
    -- self:UnitAuraChanged(...)
    self:DebugMsg("Nameplate feature disabled: UNIT_AURA event ignored")
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

-- Modify PrintMessage to respect DEBUG_CATEGORIES.general
function DM:PrintMessage(message, ...)
  if not DM.DEBUG_CATEGORIES.general then return end
  local prefix = "|cFFCC00FFDotMaster:|r "
  if select('#', ...) > 0 then
    DM:DebugMsg(prefix .. message, ...)
  else
    DM:DebugMsg(prefix .. message)
  end
end

-- We'll call Initialize() at the end of core.lua after all modules are loaded
