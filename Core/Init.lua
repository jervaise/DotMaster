--[[
    DotMaster - Initialization Module
]]

local ADDON_NAME = "DotMaster"
local DotMaster = _G[ADDON_NAME]

-- Frame for event handling
DotMaster.frame = CreateFrame("Frame")

-- Register this module with the core
function DotMaster:SetupInitialization()
  -- Initialize events
  self.frame:SetScript("OnEvent", function(_, event, ...)
    if self[event] then
      self[event](self, ...)
    end
  end)

  -- Register core events
  self.frame:RegisterEvent("PLAYER_LOGIN")
  self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  self.frame:RegisterEvent("PLAYER_LOGOUT")

  self:Debug("CORE", "Initialization setup complete")
end

-- PLAYER_LOGIN event handler
function DotMaster:PLAYER_LOGIN()
  -- Load libraries and modules after other addons have loaded
  self:LoadLibraries()

  -- Initialize spell database
  self:InitializeSpellDB()

  -- Create UI elements that need to persist
  self:CreatePersistentUI()

  self:Debug("CORE", "Player login handling complete")
end

-- PLAYER_ENTERING_WORLD event handler
function DotMaster:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
  if isInitialLogin or isReloadingUi then
    -- Apply settings on first login or UI reload
    self:ApplySettings()

    -- Show welcome message on first login if enabled
    if isInitialLogin and self.db.profile.showWelcomeMessage then
      self:Print("Welcome to DotMaster! Type /dm for options.")
    end
  end

  -- Check compatibility with other addons
  self:CheckCompatibility()

  self:Debug("CORE",
    "Player entering world. Initial login: " .. tostring(isInitialLogin) .. ", Reloading UI: " .. tostring(isReloadingUi))
end

-- PLAYER_LOGOUT event handler
function DotMaster:PLAYER_LOGOUT()
  -- Cleanup and save state before logout
  self:SaveState()

  self:Debug("CORE", "Player logout handling complete")
end

-- Load required libraries
function DotMaster:LoadLibraries()
  -- Any additional non-Ace3 libraries can be loaded here
  self:Debug("CORE", "Libraries loaded")
end

-- Apply current settings
function DotMaster:ApplySettings()
  -- Apply individual settings
  self:ApplyNameplateSettings()
  self:ApplyFilterSettings()
  self:ApplyFindMyDotsSettings()

  self:Debug("CORE", "Settings applied")
end

-- Save current state before logout
function DotMaster:SaveState()
  -- Save window positions or any other state that needs to be preserved
  if self.findMyDotsFrame and self.findMyDotsFrame:IsShown() then
    local point, relativeTo, relativePoint, xOfs, yOfs = self.findMyDotsFrame:GetPoint()
    self.db.profile.findMyDots.position = { point, relativePoint, xOfs, yOfs }
  end

  self:Debug("CORE", "State saved")
end

-- Create persistent UI elements
function DotMaster:CreatePersistentUI()
  -- Create minimap button if enabled
  if self.db.profile.minimapIcon.show then
    self:CreateMinimapButton()
  end

  self:Debug("CORE", "Persistent UI created")
end

-- Check compatibility with other addons
function DotMaster:CheckCompatibility()
  -- Check for Plater
  self.isPlaterInstalled = _G.Plater ~= nil
  if self.isPlaterInstalled then
    self:Debug("CORE", "Plater detected, enabling compatibility mode")
  end

  -- Check for other addons as needed

  self:Debug("CORE", "Compatibility check complete")
end

-- Setup the initialization when the file loads
DotMaster:SetupInitialization()
