--[[
  DotMaster - Nameplate Core Module

  File: np_core.lua
  Purpose: Core nameplate handling functionality

  Functions:
  - HandleNameplateAdded(): Processes new nameplates
  - HandleNameplateRemoved(): Cleans up removed nameplates
  - UpdateNameplate(): Updates dots on a nameplate
  - UpdateAllNameplates(): Updates all active nameplates
  - ResetNameplate(): Removes dots from a nameplate
  - ResetAllNameplates(): Removes dots from all nameplates

  Dependencies:
  - DotMaster core

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Create Nameplate Core module
local NameplateCore = {}
DM.NameplateCore = NameplateCore

-- Tracking active nameplates and their dots
local activePlates = {}
local nameplateFrames = {}

-- Position options
local POSITION_OFFSETS = {
  ABOVE = { x = 0, y = 15 },
  BELOW = { x = 0, y = -15 },
  LEFT = { x = -30, y = 0 },
  RIGHT = { x = 30, y = 0 }
}

-- Process a newly added nameplate
function NameplateCore:HandleNameplateAdded(nameplateID)
  -- Skip if disabled
  if not DM.enabled then return end

  local nameplate = C_NamePlate.GetNamePlateForUnit(nameplateID)
  if not nameplate then return end

  -- Store the nameplate in our tracking table
  activePlates[nameplateID] = nameplate

  -- Create dot container if it doesn't exist
  if not nameplate.dotContainer then
    nameplate.dotContainer = CreateFrame("Frame", nil, nameplate)
    nameplate.dotContainer:SetSize(100, 20)
    nameplate.dotContainer:SetPoint("CENTER", nameplate, "CENTER")
    nameplate.dots = {}
  end

  -- Update the nameplate
  self:UpdateNameplate(nameplateID)
end

-- Clean up a removed nameplate
function NameplateCore:HandleNameplateRemoved(nameplateID)
  -- Remove from tracking
  activePlates[nameplateID] = nil

  -- Remove any stored frames
  if nameplateFrames[nameplateID] then
    nameplateFrames[nameplateID] = nil
  end
end

-- Update dots on a specific nameplate
function NameplateCore:UpdateNameplate(nameplateID)
  -- Skip if disabled
  if not DM.enabled then return end

  local nameplate = activePlates[nameplateID]
  if not nameplate then return end

  -- Get unit auras
  local unitAuras = {}

  -- Use AuraUtil.ForEachAura instead of C_UnitAuras API
  AuraUtil.ForEachAura(nameplateID, "HARMFUL", nil,
    function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId)
      -- Only track harmful debuffs and from the player
      if source == "player" then
        unitAuras[tostring(spellId)] = {
          name = name,
          spellId = spellId,
          duration = duration,
          expirationTime = expirationTime
        }
      end
      return false -- Continue iterating
    end)

  -- Track active debuffs for positioning
  local activeDebuffs = {}

  -- Create the dot container if it doesn't exist
  if not nameplate.dotContainer then
    nameplate.dotContainer = CreateFrame("Frame", nil, nameplate)
    nameplate.dotContainer:SetSize(100, 20)
    nameplate.dotContainer:SetPoint("CENTER", nameplate, "CENTER")
    nameplate.dots = {}
  end

  -- Process all configured spells
  for spellID, config in pairs(DM.spellConfig) do
    -- Only process enabled spells
    if config.enabled then
      local aura = unitAuras[spellID]

      -- Check if the dot exists in the container
      local dot = nameplate.dots[spellID]

      if aura then
        -- Debuff is active, create or update dot
        if not dot then
          -- Create new dot
          dot = nameplate.dotContainer:CreateTexture(nil, "OVERLAY")
          dot:SetSize(DM.dotSize, DM.dotSize)
          dot:SetTexture("Interface\\AddOns\\DotMaster\\Textures\\dot")
          dot:SetColorTexture(config.color[1], config.color[2], config.color[3], DM.dotAlpha)

          -- Store the dot in the nameplate
          nameplate.dots[spellID] = dot
        else
          -- Update existing dot
          dot:SetSize(DM.dotSize, DM.dotSize)
          dot:SetColorTexture(config.color[1], config.color[2], config.color[3], DM.dotAlpha)
        end

        -- Show the dot
        dot:Show()

        -- Add to active debuffs for positioning
        table.insert(activeDebuffs, {
          dot = dot,
          priority = config.priority or 999
        })
      elseif dot then
        -- Debuff is not active, hide the dot
        dot:Hide()
      end
    end
  end

  -- Position the dots based on configuration
  if #activeDebuffs > 0 then
    -- Sort by priority
    table.sort(activeDebuffs, function(a, b) return a.priority < b.priority end)

    local dotPosition = DM.dotPosition or "ABOVE"
    local dotPadding = DM.dotPadding or 2

    for i, debuff in ipairs(activeDebuffs) do
      if dotPosition == "ABOVE" or dotPosition == "BELOW" then
        -- Horizontal layout
        local basePos = POSITION_OFFSETS[dotPosition]
        local xOffset = ((i - 1) - (#activeDebuffs - 1) / 2) * (DM.dotSize + dotPadding)
        debuff.dot:SetPoint("CENTER", nameplate, "CENTER", basePos.x + xOffset, basePos.y)
      else
        -- Vertical layout (LEFT or RIGHT)
        local basePos = POSITION_OFFSETS[dotPosition]
        local yOffset = ((i - 1) - (#activeDebuffs - 1) / 2) * (DM.dotSize + dotPadding)
        debuff.dot:SetPoint("CENTER", nameplate, "CENTER", basePos.x, basePos.y + yOffset)
      end
    end
  end
end

-- Update all active nameplates
function NameplateCore:UpdateAllNameplates()
  -- Skip if disabled
  if not DM.enabled then return end

  for nameplateID in pairs(activePlates) do
    self:UpdateNameplate(nameplateID)
  end
end

-- Reset a specific nameplate (remove all dots)
function NameplateCore:ResetNameplate(nameplateID)
  local nameplate = activePlates[nameplateID]
  if not nameplate or not nameplate.dots then return end

  for spellID, dot in pairs(nameplate.dots) do
    dot:Hide()
  end
end

-- Reset all nameplates
function NameplateCore:ResetAllNameplates()
  for nameplateID in pairs(activePlates) do
    self:ResetNameplate(nameplateID)
  end
end

-- Test dots on current target
function NameplateCore:TestDotsOnTarget()
  if not UnitExists("target") or not UnitCanAttack("player", "target") then
    DM:PrintMessage("You need to target an enemy to test dots")
    return
  end

  local targetID = UnitGUID("target")
  if not targetID then return end

  local nameplateID = "nameplate" .. UnitNameplateID("target")
  if not nameplateID then
    DM:PrintMessage("Target doesn't have a nameplate")
    return
  end

  -- Get the nameplate
  local nameplate = C_NamePlate.GetNamePlateForUnit(nameplateID)
  if not nameplate then
    DM:PrintMessage("Couldn't find target's nameplate")
    return
  end

  -- Store the nameplate
  activePlates[nameplateID] = nameplate

  -- Create dot container if needed
  if not nameplate.dotContainer then
    nameplate.dotContainer = CreateFrame("Frame", nil, nameplate)
    nameplate.dotContainer:SetSize(100, 20)
    nameplate.dotContainer:SetPoint("CENTER", nameplate, "CENTER")
    nameplate.dots = {}
  end

  -- Create temporary test dots for all configured spells
  local testDots = {}
  for spellID, config in pairs(DM.spellConfig) do
    if config.enabled then
      -- Create or update dot
      local dot = nameplate.dots[spellID] or nameplate.dotContainer:CreateTexture(nil, "OVERLAY")
      dot:SetSize(DM.dotSize, DM.dotSize)
      dot:SetTexture("Interface\\AddOns\\DotMaster\\Textures\\dot")
      dot:SetColorTexture(config.color[1], config.color[2], config.color[3], DM.dotAlpha)

      -- Store the dot
      nameplate.dots[spellID] = dot

      -- Add to test dots for positioning
      table.insert(testDots, {
        dot = dot,
        priority = config.priority or 999
      })
    end
  end

  -- Position test dots
  if #testDots > 0 then
    -- Sort by priority
    table.sort(testDots, function(a, b) return a.priority < b.priority end)

    local dotPosition = DM.dotPosition or "ABOVE"
    local dotPadding = DM.dotPadding or 2

    for i, debuff in ipairs(testDots) do
      if dotPosition == "ABOVE" or dotPosition == "BELOW" then
        -- Horizontal layout
        local basePos = POSITION_OFFSETS[dotPosition]
        local xOffset = ((i - 1) - (#testDots - 1) / 2) * (DM.dotSize + dotPadding)
        debuff.dot:SetPoint("CENTER", nameplate, "CENTER", basePos.x + xOffset, basePos.y)
      else
        -- Vertical layout (LEFT or RIGHT)
        local basePos = POSITION_OFFSETS[dotPosition]
        local yOffset = ((i - 1) - (#testDots - 1) / 2) * (DM.dotSize + dotPadding)
        debuff.dot:SetPoint("CENTER", nameplate, "CENTER", basePos.x, basePos.y + yOffset)
      end

      -- Show the dot
      debuff.dot:Show()
    end
  end

  DM:PrintMessage("Test dots shown on target (" .. #testDots .. " dots)")

  -- Hide test dots after 5 seconds
  C_Timer.After(5, function()
    for _, dotInfo in ipairs(testDots) do
      dotInfo.dot:Hide()
    end
    DM:PrintMessage("Test dots hidden")
  end)
end

-- Process nameplate event (NAME_PLATE_UNIT_ADDED)
function NameplateCore:OnNameplateAdded(nameplateID)
  self:HandleNameplateAdded(nameplateID)
end

-- Process nameplate event (NAME_PLATE_UNIT_REMOVED)
function NameplateCore:OnNameplateRemoved(nameplateID)
  self:HandleNameplateRemoved(nameplateID)
end

-- Register nameplate events
function NameplateCore:RegisterEvents()
  DM:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  DM:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

  DM:HookScript("OnEvent", function(self, event, unitID)
    if event == "NAME_PLATE_UNIT_ADDED" then
      NameplateCore:OnNameplateAdded(unitID)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
      NameplateCore:OnNameplateRemoved(unitID)
    end
  end)
end

-- Debug message function with module name
function NameplateCore:DebugMsg(message)
  if DM.DebugMsg then
    DM:DebugMsg("[NameplateCore] " .. message)
  end
end

-- Connect to DM namespace for backward compatibility
function NameplateCore:ConnectToDMNamespace()
  DM.UpdateNameplate = function(self, nameplateID)
    NameplateCore:UpdateNameplate(nameplateID)
  end

  DM.UpdateAllNameplates = function(self)
    NameplateCore:UpdateAllNameplates()
  end

  DM.ResetNameplate = function(self, nameplateID)
    NameplateCore:ResetNameplate(nameplateID)
  end

  DM.ResetAllNameplates = function(self)
    NameplateCore:ResetAllNameplates()
  end

  DM.TestDotsOnTarget = function(self)
    NameplateCore:TestDotsOnTarget()
  end
end

-- Initialize the module
function NameplateCore:Initialize()
  self:ConnectToDMNamespace()
  self:RegisterEvents()
  NameplateCore:DebugMsg("Nameplate core module initialized")
end

-- Return the module
return NameplateCore
