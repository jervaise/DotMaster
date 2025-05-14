-- Plater integration moved from core.lua
local DM = DotMaster
DM.PlaterIntegration = {}

-- Plater-specific globals and constants
local MEMBER_GUID = "namePlateUnitGUID"
local MEMBER_NPCID = "namePlateNpcId"
local MEMBER_REACTION = "namePlateReaction"

-- Cache to access Plater's NPC color settings
local DB_UNITCOLOR_CACHE = {}

-- Main function to install the Plater mod with current DotMaster settings
function DM.PlaterIntegration:InstallPlaterMod(forcePush)
  -- Skip if Plater is not available
  if not Plater then
    --DM:PrintMessage("Plater not detected, skipping Plater mod integration.")
    return false
  end

  -- Update the reference to Plater's NPC color cache
  DB_UNITCOLOR_CACHE = _G["Plater"] and _G["Plater"].db and _G["Plater"].db.profile and
      _G["Plater"].db.profile.npc_colors or {}

  -- Get settings needed for the Plater mod
  local settings = DM.API:GetSettings()

  -- DotMaster DB settings can be nil if this is a first-run
  if not DotMasterDB then
    DotMasterDB = {}
  end
  DotMasterDB.settings = DotMasterDB.settings or {}

  -- Get the current list of tracked spells
  local trackedSpells = DM.API:GetTrackedSpells() or {}

  -- Get the current list of spell combinations
  local combinations = DM.API:GetCombinations() or {}

  -- Decide if the mod should be enabled or disabled
  local enabledState = (DM.enabled and true) or false

  -- Directly set the enabled state in the API settings too
  settings.enabled = DM.enabled

  -- JavaScript-like template literal for easier reading
  local constructorCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  -- Store DotMaster settings as envTable variables
  envTable.DM_ENABLED = ]] .. (enabledState and "true" or "false") .. [[

  envTable.DM_FORCE_COLOR = ]] .. (settings.forceColor and "true" or "false") .. [[
  envTable.DM_FORCE_THREAT_COLOR = ]] .. (settings.forceColor and "true" or "false") .. [[
  envTable.DM_BORDER_ONLY = ]] .. (settings.borderOnly and "true" or "false") .. [[
  envTable.DM_BORDER_THICKNESS = ]] .. (settings.borderThickness or 2) .. [[
  envTable.DM_EXTEND_PLATER_COLORS = ]] .. (settings.extendPlaterColors and "true" or "false") .. [[
  envTable.DM_FLASH_EXPIRING = ]] .. (settings.flashExpiring and "true" or "false") .. [[
  envTable.DM_FLASH_THRESHOLD = ]] .. (settings.flashThresholdSeconds or 3.0) .. [[

  -- Store spell lists for DotMaster dot tracking
  envTable.DM_SPELLS = {
]]

  -- Add tracked spells to the constructor
  for i, spell in ipairs(trackedSpells) do
    -- Only include enabled spells
    if spell.enabled then
      local spellRow = "    {spellID = " .. spell.spellID

      -- Add spell name if available
      if spell.name and spell.name ~= "" then
        spellRow = spellRow .. ", name = \"" .. spell.name .. "\""
      end

      -- Add spell color if available
      if spell.color and #spell.color >= 3 then
        spellRow = spellRow .. ", color = {" .. spell.color[1] .. ", " .. spell.color[2] .. ", " .. spell.color[3]

        -- Add alpha if available
        if spell.color[4] then
          spellRow = spellRow .. ", " .. spell.color[4]
        end

        spellRow = spellRow .. "}"
      end

      spellRow = spellRow .. ", enabled = true},"
      constructorCode = constructorCode .. spellRow .. "\n"
    end
  end

  -- Add spell combinations
  if #combinations > 0 then
    constructorCode = constructorCode .. "\n  -- Spell combinations\n"
    for i, combo in ipairs(combinations) do
      if combo.enabled then
        local comboRow = "    {combo = {"

        -- Add spells in the combination
        for j, spellID in ipairs(combo.spellIDs) do
          comboRow = comboRow .. spellID
          if j < #combo.spellIDs then
            comboRow = comboRow .. ", "
          end
        end
        comboRow = comboRow .. "}"

        -- Add spell color
        if combo.color and #combo.color >= 3 then
          comboRow = comboRow .. ", color = {" .. combo.color[1] .. ", " .. combo.color[2] .. ", " .. combo.color[3]

          -- Add alpha if available
          if combo.color[4] then
            comboRow = comboRow .. ", " .. combo.color[4]
          end

          comboRow = comboRow .. "}"
        end

        comboRow = comboRow .. ", enabled = true},"
        constructorCode = constructorCode .. comboRow .. "\n"
      end
    end
  end

  -- Close the DM_SPELLS table
  constructorCode = constructorCode .. "  }\n"

  -- Add setup code to the constructor
  constructorCode = constructorCode ..
      [[
  -- Apply border thickness if set
  if envTable.DM_BORDER_ONLY and unitFrame and unitFrame.healthBar and unitFrame.healthBar.border then
    Plater.SetBorderColor(unitFrame, unpack(Plater.db.profile.border_color))

    -- Set the border thickness (improved version)
    if unitFrame.healthBar.border.SetBorderThickness then
      unitFrame.healthBar.border:SetBorderThickness(envTable.DM_BORDER_THICKNESS)
    else
      -- Fallback for older Plater versions
      if unitFrame.healthBar.border.SetThickness then
        unitFrame.healthBar.border:SetThickness(envTable.DM_BORDER_THICKNESS)
      end
    end

    -- Make sure border is shown
    unitFrame.healthBar.border:Show()
  end

  -- Flag for color flashing
  unitFrame.healthBar.dm_colFlash_IsLighterPhase = false

  -- Reset custom coloring flag
  unitFrame.healthBar.dm_has_been_custom_colored = false
end
]]

  -- The update code run by Plater on each nameplate update
  local updateCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  -- Exit early if DotMaster is disabled
  if not envTable.DM_ENABLED then
    return
  end

  -- Function to apply color based on border-only setting
  local function applyColor(r, g, b, a, isLightPhase, remainingTime)
    a = a or 1

    -- Flash effect for expiring dots
    if envTable.DM_FLASH_EXPIRING and remainingTime and remainingTime < envTable.DM_FLASH_THRESHOLD then
      -- Create a flashing effect for dots about to expire
      if isLightPhase then
        -- Use a lighter color
        r = min(r * 1.5, 1.0)
        g = min(g * 1.5, 1.0)
        b = min(b * 1.5, 1.0)
      end

      -- Store phase for next update
      self.dm_colFlash_IsLighterPhase = not isLightPhase
    end

    -- Mark this healthbar as custom colored by DotMaster
    self.dm_has_been_custom_colored = true

    if envTable.DM_BORDER_ONLY then
      -- Border-only mode: Set only the border color
      if unitFrame.healthBar.border then
        -- Set border color
        unitFrame.healthBar.border:SetVertexColor(r, g, b, a)

        -- Set custom border color flag (so Plater knows this is custom)
        unitFrame.customBorderColor = {r, g, b, a}

        -- Reset nameplate color to default (since we're only changing border)
        Plater.RefreshNameplateColor(unitFrame)

        -- Ensure border is visible - sometimes needed due to Plater updates
        unitFrame.healthBar.border:Show()
      end
    else
      -- Normal mode: Set the entire nameplate color
      Plater.SetNameplateColor(unitFrame, r, g, b, a)
    end
  end

  -- Get the tracked spells list
  local spells = envTable.DM_SPELLS

  -- First check for combinations (priority over single spells)
  for i, combo in ipairs(spells) do
    if combo.enabled and combo.combo then
      -- Check if all spells in the combo are active
      local allSpellsActive = true
      for j, spellID in ipairs(combo.combo) do
        if not Plater.NameplateHasAura(unitFrame, spellID, true) then
          allSpellsActive = false
          break
        end
      end

      -- If all spells are active, apply the combo color
      if allSpellsActive then
        applyColor(combo.color[1], combo.color[2], combo.color[3], combo.color[4] or 1, self.dm_colFlash_IsLighterPhase, 999)
        return
      end
    end
  end

  -- Then check for individual spells
  for i, spell in ipairs(spells) do
    if spell.enabled and spell.spellID and Plater.NameplateHasAura(unitFrame, spell.spellID, true) then
      local spellIDToQuery = spell.spellID
      local sName, _, _, _, sDuration, sExpirationTime = Plater.GetAura(unitFrame.namePlateUnitToken, spellIDToQuery, true)
      local remainingTime = 999 -- Default high if no specific expiration
      if sExpirationTime and sExpirationTime > 0 then remainingTime = math.max(0, sExpirationTime - GetTime()) end
      applyColor(spell.color[1], spell.color[2], spell.color[3], spell.color[4] or 1, false, remainingTime)
      return
    end
  end

  if self.dm_has_been_custom_colored then
      Plater.RefreshNameplateColor(unitFrame)
      if envTable.DM_FLASH_EXPIRING then self.dm_colFlash_IsLighterPhase = false end
  end
  self.dm_has_been_custom_colored = false

  -- Simple implementation of Extend Plater Colors to Borders
  if envTable.DM_EXTEND_PLATER_COLORS and unitFrame.healthBar.border then
    -- Check if this NPC has a custom color set in Plater
    local npcId = unitFrame[MEMBER_NPCID] or -1
    -- Only apply if this NPC has a custom color in Plater's NPC Colors & Names tab
    if DB_UNITCOLOR_CACHE[npcId] then
      -- Get the current color of the nameplate
      local r, g, b, a = unitFrame.healthBar:GetStatusBarColor()
      if r and g and b then
        -- Apply the nameplate color to the border
        unitFrame.healthBar.border:SetVertexColor(r, g, b, a or 1)
        unitFrame.customBorderColor = {r, g, b, a or 1}
        unitFrame.healthBar.border:Show()
      end
    end
  end

  if envTable.DM_BORDER_ONLY then
    if unitFrame.healthBar.border then unitFrame.customBorderColor = nil; Plater.RefreshNameplateColor(unitFrame) end
  else
    Plater.RefreshNameplateColor(unitFrame)
    if unitFrame.healthBar.border then unitFrame.customBorderColor = nil end
  end

  -- Any leftover DM_Text should be hidden and we should consider removing it entirely
  if unitFrame.DM_Text then
    unitFrame.DM_Text:Hide()
    -- Optionally, completely remove the text element
    -- unitFrame.DM_Text:SetParent(nil)
    -- unitFrame.DM_Text = nil
  end
end
]]

  -- Add nameplate added hook to run CheckAggro when a nameplate is added
  local nameplatAddedCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  if not (_G['DotMaster'] and _G['DotMaster'].enabled) then --print('DotMaster Integration: DotMaster not found or disabled, skipping nameplate added.');
    return
  end
  -- When a nameplate is first added, check threat if enabled
  if envTable.DM_FORCE_THREAT_COLOR and unitFrame and unitId then
    -- Function to apply color based on border-only setting
    local function applyColor(r, g, b, a, isThreatColor)
      a = a or 1

      -- Force threat color should always color the entire nameplate, regardless of border-only setting
      if isThreatColor then
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
        return
      end

      if envTable.DM_BORDER_ONLY then
        -- Border-only mode: Set only the border color
        if unitFrame.healthBar.border then
          -- Set border color
          unitFrame.healthBar.border:SetVertexColor(r, g, b, a)

          -- Set custom border color flag
          unitFrame.customBorderColor = {r, g, b, a}

          -- Reset nameplate color to default (since we're only changing border)
          Plater.RefreshNameplateColor(unitFrame)

          -- Ensure border is visible - sometimes needed due to Plater updates
          unitFrame.healthBar.border:Show()
        end
      else
        -- Normal mode: Set the entire nameplate color
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
      end
    end

    -- Get threat info directly
    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unitId)
    local isTank = Plater.PlayerIsTank

    -- For tanks, high threat = good, for DPS/healer, high threat = bad
    if isTank then
      -- For tanks: color if NOT tanking and in combat
      if unitFrame.InCombat and not isTanking then
        -- Apply the no-aggro color for tanks
        local color = Plater.db.profile.tank.colors.noaggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        -- Remove text display for tank warning in nameplate added hook
      end
    else
      -- For DPS/Healers: color if tanking and in combat
      if unitFrame.InCombat and isTanking then
        -- Apply the aggro color for DPS
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        -- Remove text display for DPS warning in nameplate added hook
      end
    end
  end
end
]]

  local data = Plater.db.profile.hook_data
  local modName = "DotMaster Integration" -- Target the manually added mod
  local foundIndex
  for i, mod in ipairs(data) do
    if mod.Name == modName then
      foundIndex = i
      break
    end
  end

  -- Only proceed if the 'DotMaster Integration' mod was found
  if foundIndex then
    local modEntry = data[foundIndex]
    modEntry.Name = modName                          -- Keep the name as "DotMaster Integration"
    modEntry.Desc = "Managed by DotMaster Addon"     -- Update description
    modEntry.Author = "Jervaise"                     -- Update author
    modEntry.Time = time()
    modEntry.Revision = (modEntry.Revision or 0) + 1 -- Increment revision
    modEntry.PlaterCore = Plater.CoreVersion or 0

    -- CRITICAL: Explicitly set the Enabled state of the mod based on DotMaster settings
    modEntry.Enabled = enabledState
    -- print("DotMaster: Setting DotMaster Integration mod Enabled state to: " .. (enabledState and "ENABLED" or "DISABLED"))

    -- Inject our hooks
    modEntry.Hooks = {
      ["Constructor"] = constructorCode,
      ["Nameplate Updated"] = updateCode,
      ["Nameplate Added"] = nameplatAddedCode
    }
    modEntry.HooksTemp = {
      ["Constructor"] = constructorCode,
      ["Nameplate Updated"] = updateCode,
      ["Nameplate Added"] = nameplatAddedCode
    }
    modEntry.LastHookEdited = "Constructor" -- Indicate which hook was last edited

    local forceColorStatus = settings.forceColor and "enabled" or "disabled"
    -- DM:PrintMessage("Updated 'DotMaster Integration' with " ..
    --   #trackedSpells .. " spells and " .. #combinations .. " combos. Force Threat Color is " .. forceColorStatus ..
    --   ". Mod enabled: " .. (enabledState and "yes" or "no") .. ".")
    -- DM:PrintMessage("|cFFFFFF00Consider using /reload to fully apply these changes.|r")

    -- Recompile hook scripts and refresh plates (needed after changing hooks)
    if Plater.WipeAndRecompileAllScripts then
      Plater.WipeAndRecompileAllScripts("hook")
    end

    -- Force a more aggressive refresh of all Plater plates
    C_Timer.After(0.1, function()
      if Plater.FullRefreshAllPlates then
        -- print("DotMaster: Forcing full Plater refresh...")
        Plater.FullRefreshAllPlates()
      end
    end)

    -- Double check that the mod settings were properly applied after a slight delay
    C_Timer.After(0.5, function()
      if Plater.db and Plater.db.profile and Plater.db.profile.hook_data and Plater.db.profile.hook_data[foundIndex] then
        local currentState = Plater.db.profile.hook_data[foundIndex].Enabled
        -- print("DotMaster: Verifying DotMaster Integration mod state - Expected: " ..
        --  (enabledState and "ENABLED" or "DISABLED") ..
        --  ", Actual: " .. (currentState and "ENABLED" or "DISABLED"))

        -- If there's a mismatch, try to force it again
        if currentState ~= enabledState then
          -- print("DotMaster: State mismatch detected, forcing correction...")
          Plater.db.profile.hook_data[foundIndex].Enabled = enabledState
          Plater.WipeAndRecompileAllScripts("hook")
          Plater.FullRefreshAllPlates()
        end
      end
    end)

    -- Update the mod in the Plater hook DB
  else
    -- If the 'DotMaster Integration' mod was NOT found, print an error and do nothing else
    DM:PrintMessage(
      "|cFFFF0000Error: Plater mod 'DotMaster Integration' not found. Please add it manually via Plater options and ensure the name is exactly 'DotMaster Integration'.|r")
  end
end
