--[[
  DotMaster - Find My Dots Core Module

  File: fmd_core.lua
  Purpose: Automatic dot detection and tracking system

  Functions:
    StartFindMyDots(): Starts the dot recording mode
    StopFindMyDots(): Stops the dot recording mode
    RecordDots(): Records dots cast by the player
    ShowRecordingIndicator(): Shows the recording UI
    HideRecordingIndicator(): Hides the recording UI
    ShowDetectedDotNotification(): Shows notification when a dot is detected
    ShowDotsConfirmationDialog(): Shows confirmation dialog for detected dots

  Dependencies:
    DotMaster core

  Author: Jervaise
  Last Updated: 2024-06-19
]]

local DM = DotMaster

-- Create module table
local FindMyDots = {}
DM.FindMyDots = FindMyDots

-- Dot recording system state
local recordingDots = false
local detectedDots = {}
local shownNotifications = {}
local totalDotsFound = 0

-- UI Elements
local recordingFrame = nil
local recordingText = nil
local recordingTime = nil
local dotsFoundText = nil
local finishButton = nil
local cancelButton = nil
local recordingTicker = nil
local recordingTimer = nil
local recordingTimeLeft = 30
local dotAlertContainer = nil
local dotsConfirmFrame = nil
local dotCheckboxes = {}
local dotsScrollChild = nil

-- Start dot recording mode
function FindMyDots:StartFindMyDots()
  -- If already active, exit
  if recordingDots then return end

  -- Reset shown notifications
  shownNotifications = {}
  totalDotsFound = 0

  recordingDots = true
  detectedDots = {}

  -- Show visual feedback
  self:ShowRecordingIndicator()

  -- Set time limit (30 seconds)
  recordingTimer = C_Timer.NewTimer(30, function()
    self:StopFindMyDots(true) -- true = indicates automatic stopping
  end)

  -- User information message
  DM:PrintMessage("Dot recording mode active! Cast your spells on targets (30 seconds).")

  -- Create special event handler and register it
  DM:RegisterEvent("UNIT_AURA")

  -- Update event handler
  DM:HookScript("OnEvent", function(self, event, ...)
    if event == "UNIT_AURA" and recordingDots then
      FindMyDots:RecordDots(...)
    end
  end)
end

-- Stop dot recording mode
function FindMyDots:StopFindMyDots(automatic, finished)
  if not recordingDots then return end

  recordingDots = false

  -- No need to keep checking UNIT_AURA
  -- (We don't unregister the event as it's used by main functions)

  if recordingTimer then
    recordingTimer:Cancel()
    recordingTimer = nil
  end

  -- Remove visual indicator
  self:HideRecordingIndicator()

  -- Show results
  local count = 0
  if detectedDots then
    count = DM:TableCount(detectedDots)
  end

  if count > 0 then
    if finished then
      DM:PrintMessage(string.format("%d dots detected! Recording completed.", count))
    else
      DM:PrintMessage(string.format("%d dots detected! Do you want to add them?", count))
    end
    self:ShowDotsConfirmationDialog(detectedDots)
  else
    if automatic then
      DM:PrintMessage("Time expired! No dots detected.")
    elseif finished then
      DM:PrintMessage("Recording completed. No dots detected.")
    else
      DM:PrintMessage("Dot recording mode canceled. No dots detected.")
    end
  end
end

-- Record dots
function FindMyDots:RecordDots(unitToken)
  if not recordingDots then return end
  if not unitToken or not unitToken:match("^nameplate") then return end

  -- Use AuraUtil.ForEachAura instead of C_UnitAuras API
  AuraUtil.ForEachAura(unitToken, "HARMFUL", nil,
    function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId)
      -- Only record player's own debuffs and if not already detected
      if source == "player" and not detectedDots[spellId] then
        -- Record detailed info
        detectedDots[spellId] = {
          name = name,
          id = spellId,
          timestamp = GetTime()
        }

        -- Update spell database with class and spec info
        local className, specName = self:GetPlayerClassAndSpec()

        -- Save to spell database
        DM:AddSpellToDatabase(spellId, name, className, specName)

        -- Also add to spell config automatically if not exists
        if not DM:SpellExists(spellId) then
          DM.spellConfig[tostring(spellId)] = {
            enabled = true,
            color = { 1, 0, 0 }, -- Default red color
            name = name,
            priority = DM:GetNextPriority(),
            saved = true
          }

          -- Refresh GUI if open
          if DM.GUI and DM.GUI.RefreshSpellList then
            DM.GUI:RefreshSpellList()
          end

          -- Save settings immediately
          DM:SaveSettings()
        end

        -- Update dot counter
        totalDotsFound = totalDotsFound + 1
        if dotsFoundText then
          dotsFoundText:SetText(totalDotsFound .. " DOT BULUNDU")
        end

        -- Inform user
        DM:PrintMessage(string.format("Dot detected: %s (ID: %d)", name, spellId))

        -- Show visual feedback
        self:ShowDetectedDotNotification(name, spellId)
      end

      return false -- Continue iterating
    end)
end

-- Get player class and specialization
function FindMyDots:GetPlayerClassAndSpec()
  -- Get class info
  local className = select(2, UnitClass("player")) or "UNKNOWN"

  -- Default spec name
  local specName = "General"

  -- Get active spec index
  local specIndex = GetSpecialization()

  -- If spec index exists, get spec info
  if specIndex then
    local _, name = GetSpecializationInfo(specIndex)

    -- Use name if available
    if name and name ~= "" then
      specName = name
    end
  end

  return className, specName
end

-- Toggle Find My Dots window
function FindMyDots:ToggleFindMyDotsWindow()
  if recordingDots then
    self:StopFindMyDots()
  else
    if DM:TableCount(DM.spellConfig) > 0 then
      -- Already have spells, offer direct start
      self:StartFindMyDots()
    else
      -- No spells yet, show help prompt
      DM:ShowFindMyDotsPrompt()
    end
  end
end

-- Initialize the module
function FindMyDots:Initialize()
  DM:DebugMsg("Find My Dots module initialized")
end

-- Return the module
return FindMyDots
