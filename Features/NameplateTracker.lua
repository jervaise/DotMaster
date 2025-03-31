--[[
    DotMaster - Nameplate Tracker Module
    Handles the tracking and display of DoTs on nameplates
]]

local ADDON_NAME = "DotMaster"
local DotMaster = _G[ADDON_NAME]

-- Tracking data
DotMaster.nameplates = {}
DotMaster.activeDoTs = {}

-- Initialize nameplate tracking
function DotMaster:InitializeNameplateTracker()
  -- Register events for nameplate handling
  self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  self.frame:RegisterEvent("UNIT_AURA")
  self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")

  -- Hook into nameplate creation securely
  self:SecureHook(NamePlateDriverFrame, "OnNamePlateAdded", "OnNamePlateAdded")
  self:SecureHook(NamePlateDriverFrame, "OnNamePlateRemoved", "OnNamePlateRemoved")

  -- Set up update timer for tracking
  if not self.nameplateUpdateTimer then
    self.nameplateUpdateTimer = self:ScheduleRepeatingTimer("UpdateNameplates", 0.2)
  end

  self:Debug("NAMEPLATE", "Nameplate tracker initialized")
end

-- Disable nameplate tracking
function DotMaster:DisableNameplateTracker()
  -- Unregister events
  self.frame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
  self.frame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
  self.frame:UnregisterEvent("UNIT_AURA")
  self.frame:UnregisterEvent("PLAYER_TARGET_CHANGED")

  -- Unhook functions
  self:Unhook(NamePlateDriverFrame, "OnNamePlateAdded")
  self:Unhook(NamePlateDriverFrame, "OnNamePlateRemoved")

  -- Cancel timer
  if self.nameplateUpdateTimer then
    self:CancelTimer(self.nameplateUpdateTimer)
    self.nameplateUpdateTimer = nil
  end

  -- Clean up existing nameplates
  for unitID, _ in pairs(self.nameplates) do
    self:CleanupNameplate(unitID)
  end

  -- Clear tracking data
  self.nameplates = {}
  self.activeDoTs = {}

  self:Debug("NAMEPLATE", "Nameplate tracker disabled")
end

-- Apply nameplate settings
function DotMaster:ApplyNameplateSettings()
  -- Update all existing nameplates with new settings
  for unitID, _ in pairs(self.nameplates) do
    self:UpdateNameplateIndicators(unitID)
  end

  self:Debug("NAMEPLATE", "Nameplate settings applied")
end

-- Handle NAME_PLATE_UNIT_ADDED event
function DotMaster:NAME_PLATE_UNIT_ADDED(unitID)
  self:Debug("NAMEPLATE", "Nameplate added: " .. unitID)
  self:ProcessNameplate(unitID)
end

-- Handle NAME_PLATE_UNIT_REMOVED event
function DotMaster:NAME_PLATE_UNIT_REMOVED(unitID)
  self:Debug("NAMEPLATE", "Nameplate removed: " .. unitID)
  self:CleanupNameplate(unitID)
end

-- Handle UNIT_AURA event
function DotMaster:UNIT_AURA(unitID)
  -- Only process if this is a nameplate unit we're tracking
  if self.nameplates[unitID] then
    self:Debug("DOT", "Auras changed for " .. unitID)
    self:ScanUnitAuras(unitID)
  end
end

-- Handle PLAYER_TARGET_CHANGED event
function DotMaster:PLAYER_TARGET_CHANGED()
  -- Update target's nameplate if it exists
  if UnitExists("target") then
    local unitID = self:GetNameplateUnitID("target")
    if unitID and self.nameplates[unitID] then
      self:ScanUnitAuras(unitID)
    end
  end
end

-- Hook into nameplate added
function DotMaster:OnNamePlateAdded(namePlateFrame)
  -- This is intentionally empty as we handle this via NAME_PLATE_UNIT_ADDED event
  -- The hook is just to ensure compatibility with other addons
end

-- Hook into nameplate removed
function DotMaster:OnNamePlateRemoved(namePlateFrame)
  -- This is intentionally empty as we handle this via NAME_PLATE_UNIT_REMOVED event
  -- The hook is just to ensure compatibility with other addons
end

-- Process a new nameplate
function DotMaster:ProcessNameplate(unitID)
  -- Skip if not enabled
  if not self.db.profile.nameplate.enabled then
    return
  end

  -- Skip if we're only tracking enemies and this is friendly
  if self.db.profile.filter.trackOnlyMyDoTs and not UnitIsEnemy("player", unitID) then
    return
  end

  -- Get nameplate frame
  local namePlateFrame = C_NamePlate.GetNamePlateForUnit(unitID)
  if not namePlateFrame then
    self:Debug("NAMEPLATE", "No nameplate frame found for " .. unitID)
    return
  end

  -- Create storage for this nameplate if it doesn't exist
  if not self.nameplates[unitID] then
    self.nameplates[unitID] = {
      indicators = {},
      dots = {},
      guid = UnitGUID(unitID)
    }
  end

  -- Create indicators for the nameplate
  self:CreateNameplateIndicators(namePlateFrame, unitID)

  -- Scan for auras on this unit
  self:ScanUnitAuras(unitID)
end

-- Clean up a nameplate when it's removed
function DotMaster:CleanupNameplate(unitID)
  -- If we have data for this nameplate, clean it up
  if self.nameplates[unitID] then
    -- Hide and release indicator frames
    for spellID, indicator in pairs(self.nameplates[unitID].indicators) do
      indicator:Hide()
      indicator:SetParent(nil)
    end

    -- Remove from active DoTs
    for spellID, _ in pairs(self.nameplates[unitID].dots) do
      if self.activeDoTs[spellID] and self.activeDoTs[spellID][unitID] then
        self.activeDoTs[spellID][unitID] = nil
      end
    end

    -- Clear data
    self.nameplates[unitID] = nil
  end
end

-- Create visual indicators for a nameplate
function DotMaster:CreateNameplateIndicators(namePlateFrame, unitID)
  -- Get the frame to attach to (healthbar is most reliable)
  local parent = namePlateFrame.UnitFrame and namePlateFrame.UnitFrame.healthBar or namePlateFrame

  -- Get indicator size
  local size = 10 * self.db.profile.nameplate.size

  -- Get enabled spells
  local enabledSpells = self:GetEnabledSpells()

  -- Create indicator for each spell
  for _, spell in ipairs(enabledSpells) do
    -- Create frame if it doesn't exist
    if not self.nameplates[unitID].indicators[spell.spellID] then
      local indicator = CreateFrame("Frame", nil, parent)
      indicator:SetSize(size, size)

      -- Position based on settings
      self:PositionIndicator(indicator, parent, spell.spellID)

      -- Create texture for the indicator
      local texture = indicator:CreateTexture(nil, "OVERLAY")
      texture:SetAllPoints()

      -- Set default color
      texture:SetColorTexture(spell.color.r, spell.color.g, spell.color.b, 0.7)

      -- Create spell icon if enabled
      if self.db.profile.nameplate.showIcon then
        local iconSize = size * 0.8
        local icon = indicator:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("CENTER")

        -- Get spell icon
        local spellInfo = self:GetSpellInfo(spell.spellID)
        icon:SetTexture(spellInfo.iconID)

        -- Make icon slightly transparent
        icon:SetAlpha(0.8)

        indicator.icon = icon
      end

      -- Create timer text if enabled
      if self.db.profile.nameplate.showTimer then
        local text = indicator:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetTextColor(1, 1, 1)
        text:SetText("")

        indicator.text = text
      end

      -- Store references
      indicator.texture = texture
      indicator.spellID = spell.spellID

      -- Hide by default
      indicator:Hide()

      -- Store in nameplates data
      self.nameplates[unitID].indicators[spell.spellID] = indicator
    end
  end
end

-- Position indicator based on settings
function DotMaster:PositionIndicator(indicator, parent, spellID)
  local position = self.db.profile.nameplate.position
  local size = indicator:GetWidth()

  -- Get offset based on how many DoTs are already in this position
  local count = 0
  local offset = 0

  if self.nameplates[unitID] then
    for id, _ in pairs(self.nameplates[unitID].indicators) do
      if id ~= spellID then
        count = count + 1
      end
    end
    offset = count * (size + 2)     -- 2px spacing
  end

  -- Set position based on setting
  if position == "TOP" then
    indicator:SetPoint("BOTTOM", parent, "TOP", offset - (count * size / 2), 0)
  elseif position == "BOTTOM" then
    indicator:SetPoint("TOP", parent, "BOTTOM", offset - (count * size / 2), 0)
  elseif position == "LEFT" then
    indicator:SetPoint("RIGHT", parent, "LEFT", 0, offset - (count * size / 2))
  elseif position == "RIGHT" then
    indicator:SetPoint("LEFT", parent, "RIGHT", 0, offset - (count * size / 2))
  elseif position == "TOPLEFT" then
    indicator:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", offset, 0)
  elseif position == "TOPRIGHT" then
    indicator:SetPoint("BOTTOMLEFT", parent, "TOPRIGHT", -offset, 0)
  elseif position == "BOTTOMLEFT" then
    indicator:SetPoint("TOPRIGHT", parent, "BOTTOMLEFT", offset, 0)
  elseif position == "BOTTOMRIGHT" then
    indicator:SetPoint("TOPLEFT", parent, "BOTTOMRIGHT", -offset, 0)
  else
    -- Default to center
    indicator:SetPoint("CENTER", parent, "CENTER", offset - (count * size / 2), 0)
  end
end

-- Update all nameplate indicators
function DotMaster:UpdateNameplateIndicators(unitID)
  -- Skip if not tracking this nameplate
  if not self.nameplates[unitID] then
    return
  end

  -- Get nameplate frame
  local namePlateFrame = C_NamePlate.GetNamePlateForUnit(unitID)
  if not namePlateFrame then
    return
  end

  -- Get parent frame
  local parent = namePlateFrame.UnitFrame and namePlateFrame.UnitFrame.healthBar or namePlateFrame

  -- Update each indicator
  for spellID, indicator in pairs(self.nameplates[unitID].indicators) do
    -- Update position
    self:PositionIndicator(indicator, parent, spellID)

    -- Update size
    local size = 10 * self.db.profile.nameplate.size
    indicator:SetSize(size, size)

    -- Update icon if it exists
    if indicator.icon and self.db.profile.nameplate.showIcon then
      local iconSize = size * 0.8
      indicator.icon:SetSize(iconSize, iconSize)
      indicator.icon:Show()
    elseif indicator.icon then
      indicator.icon:Hide()
    end

    -- Show/hide timer text
    if indicator.text then
      indicator.text:SetShown(self.db.profile.nameplate.showTimer)
    end

    -- Update visibility based on active DoTs
    self:UpdateIndicatorVisibility(indicator, unitID, spellID)
  end
end

-- Update the visibility and appearance of an indicator based on active DoTs
function DotMaster:UpdateIndicatorVisibility(indicator, unitID, spellID)
  -- Check if this DoT is active
  local dotActive = self.nameplates[unitID].dots[spellID]

  if dotActive then
    -- Show indicator
    indicator:Show()

    -- Update timer text if enabled
    if indicator.text and self.db.profile.nameplate.showTimer then
      local timeLeft = dotActive.expirationTime - GetTime()
      if timeLeft > 0 then
        -- Format time differently based on duration left
        local formattedTime
        if timeLeft < 5 then
          formattedTime = string.format("%.1f", timeLeft)
          indicator.text:SetTextColor(1, 0, 0)           -- Red for almost expired
        elseif timeLeft < 10 then
          formattedTime = string.format("%.1f", timeLeft)
          indicator.text:SetTextColor(1, 1, 0)           -- Yellow for medium duration
        else
          formattedTime = string.format("%d", math.floor(timeLeft))
          indicator.text:SetTextColor(0, 1, 0)           -- Green for long duration
        end

        indicator.text:SetText(formattedTime)
      else
        -- DoT expired
        indicator.text:SetText("")
        indicator:Hide()
        self.nameplates[unitID].dots[spellID] = nil
      end
    end
  else
    -- Hide indicator if no active DoT
    indicator:Hide()
  end
end

-- Scan unit for auras
function DotMaster:ScanUnitAuras(unitID)
  -- Skip if unit doesn't exist
  if not UnitExists(unitID) then
    return
  end

  -- Clear current DoTs for this unit
  if self.nameplates[unitID] then
    self.nameplates[unitID].dots = {}
  else
    return     -- Not tracking this nameplate
  end

  -- Get player's DoTs on this unit
  local debuffs = self:GetPlayerDebuffsOnUnit(unitID)

  -- Update tracked DoTs
  for _, debuff in ipairs(debuffs) do
    -- Check if this is a tracked DoT
    if self:IsTrackedDoT(debuff.spellID) then
      -- Store DoT information
      self.nameplates[unitID].dots[debuff.spellID] = {
        name = debuff.name,
        icon = debuff.icon,
        count = debuff.count,
        duration = debuff.duration,
        expirationTime = debuff.expirationTime,
        spellID = debuff.spellID
      }

      -- Also store in active DoTs for global tracking
      if not self.activeDoTs[debuff.spellID] then
        self.activeDoTs[debuff.spellID] = {}
      end

      self.activeDoTs[debuff.spellID][unitID] = {
        name = debuff.name,
        icon = debuff.icon,
        count = debuff.count,
        duration = debuff.duration,
        expirationTime = debuff.expirationTime,
        targetName = UnitName(unitID),
        targetGUID = UnitGUID(unitID)
      }
    end
  end

  -- Update indicators
  self:UpdateNameplateIndicators(unitID)
end

-- Get player-applied debuffs on a unit
function DotMaster:GetPlayerDebuffsOnUnit(unitID)
  local debuffs = {}
  local playerGUID = UnitGUID("player")

  -- i starts at 1 and counts up until we can't find any more debuffs
  local i = 1
  while true do
    -- Use "PLAYER" filter to only get debuffs applied by the player
    local name, icon, count, debuffType, duration, expirationTime, caster, _, _, spellID = UnitDebuff(unitID, i, "PLAYER")

    if not name then break end     -- No more debuffs

    -- Double-check caster GUID to ensure it's the player
    if caster and UnitGUID(caster) == playerGUID then
      table.insert(debuffs, {
        name = name,
        icon = icon,
        count = count,
        debuffType = debuffType,
        duration = duration,
        expirationTime = expirationTime,
        spellID = spellID
      })
    end

    i = i + 1
  end

  return debuffs
end

-- Update all nameplates
function DotMaster:UpdateNameplates()
  -- Skip if not enabled
  if not self.db.profile.nameplate.enabled then
    return
  end

  -- Throttle updates in combat for performance
  if InCombatLockdown() then
    if self.lastNameplateUpdate and (GetTime() - self.lastNameplateUpdate) < self.PERFORMANCE.COMBAT_SCAN_THROTTLE then
      return
    end
  else
    if self.lastNameplateUpdate and (GetTime() - self.lastNameplateUpdate) < self.PERFORMANCE.NORMAL_SCAN_THROTTLE then
      return
    end
  end

  self.lastNameplateUpdate = GetTime()

  -- Update all nameplates
  local nameplates = C_NamePlate.GetNamePlates()
  for _, nameplate in ipairs(nameplates) do
    local unitID = nameplate.namePlateUnitToken
    if unitID and UnitExists(unitID) then
      -- Check if we need to process this nameplate
      if not self.nameplates[unitID] then
        self:ProcessNameplate(unitID)
      else
        -- Update existing nameplate
        self:ScanUnitAuras(unitID)
      end
    end
  end

  -- Clean up any expired DoTs
  self:CleanupExpiredDoTs()
end

-- Cleanup expired DoTs
function DotMaster:CleanupExpiredDoTs()
  local currentTime = GetTime()

  -- Check each spell
  for spellID, units in pairs(self.activeDoTs) do
    for unitID, dot in pairs(units) do
      if dot.expirationTime < currentTime then
        -- Remove expired DoT
        self.activeDoTs[spellID][unitID] = nil

        -- Also remove from nameplate if it exists
        if self.nameplates[unitID] and self.nameplates[unitID].dots[spellID] then
          self.nameplates[unitID].dots[spellID] = nil

          -- Update indicator
          if self.nameplates[unitID].indicators[spellID] then
            self.nameplates[unitID].indicators[spellID]:Hide()
          end
        end
      end
    end
  end
end

-- Get nameplate unitID from unit (like "target")
function DotMaster:GetNameplateUnitID(unit)
  if not UnitExists(unit) then return nil end

  local targetGUID = UnitGUID(unit)

  -- Check all nameplates
  local nameplates = C_NamePlate.GetNamePlates()
  for _, nameplate in ipairs(nameplates) do
    local unitID = nameplate.namePlateUnitToken
    if unitID and UnitGUID(unitID) == targetGUID then
      return unitID
    end
  end

  return nil
end

-- Apply filter settings
function DotMaster:ApplyFilterSettings()
  -- Clear all tracking data
  for unitID, _ in pairs(self.nameplates) do
    self:CleanupNameplate(unitID)
  end

  -- Reset data
  self.nameplates = {}
  self.activeDoTs = {}

  -- Force a scan of all nameplates
  self:UpdateNameplates()
end

-- Get all active DoTs across all units
function DotMaster:GetAllActiveDoTs()
  local activeDoTs = {}

  for spellID, units in pairs(self.activeDoTs) do
    for unitID, dot in pairs(units) do
      -- Skip if expired
      if dot.expirationTime > GetTime() then
        table.insert(activeDoTs, {
          targetName = dot.targetName,
          targetGUID = dot.targetGUID,
          name = dot.name,
          icon = dot.icon,
          count = dot.count,
          duration = dot.duration,
          expirationTime = dot.expirationTime,
          timeLeft = dot.expirationTime - GetTime(),
          spellID = spellID
        })
      end
    end
  end

  return activeDoTs
end
