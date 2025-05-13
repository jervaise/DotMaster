-- Plater integration moved from core.lua
local DM = DotMaster

-- Add function to install DotMaster mod into Plater
function DM:InstallPlaterMod()
  local Plater = _G["Plater"]
  if not (Plater and Plater.db and Plater.db.profile) then
    DM:PrintMessage("Plater not found or incompatible")
    return
  end

  -- Ensure hook_data table exists
  if not Plater.db.profile.hook_data then
    -- If hook_data doesn't exist, Plater isn't fully ready or has an issue.
    DM:PrintMessage("Error: Plater hook data not found. Cannot update 'bokmaster' mod.")
    return
  end

  -- Get current class/spec settings from DotMaster
  local trackedSpells = DM.API:GetTrackedSpells() or {}
  local combinations = DM.API:GetCombinations() or {}
  local settings = DM.API:GetSettings() or {}

  -- Format tracked spells for direct embedding
  local spellsLuaCode = "{\n"
  for i, spell in ipairs(trackedSpells) do
    local colorStr = "{"
    if type(spell.color) == "table" then
      if spell.color.r then
        colorStr = string.format("{%s, %s, %s, %s}",
          spell.color.r or 1,
          spell.color.g or 0,
          spell.color.b or 1,
          spell.color.a or 1)
      elseif #spell.color >= 3 then
        colorStr = string.format("{%s, %s, %s, %s}",
          spell.color[1] or 1,
          spell.color[2] or 0,
          spell.color[3] or 1,
          spell.color[4] or 1)
      end
    else
      colorStr = "{1, 0, 1, 1}" -- Default purple
    end

    spellsLuaCode = spellsLuaCode .. string.format(
      "    {spellID = %s, name = %q, color = %s, enabled = true, priority = %s},\n",
      spell.spellID or 0,
      spell.name or ("Spell " .. (spell.spellID or 0)),
      colorStr,
      spell.priority or 50
    )
  end
  spellsLuaCode = spellsLuaCode .. "}"

  -- Format combinations for direct embedding
  local combosLuaCode = "{\n"
  for i, combo in ipairs(combinations) do
    local spellListStr = "{"
    for j, spellID in ipairs(combo.spellList or {}) do
      spellListStr = spellListStr .. spellID
      if j < #combo.spellList then
        spellListStr = spellListStr .. ", "
      end
    end
    spellListStr = spellListStr .. "}"

    local colorStr = "{"
    if type(combo.color) == "table" then
      if combo.color.r then
        colorStr = string.format("{%s, %s, %s, %s}",
          combo.color.r or 1,
          combo.color.g or 0,
          combo.color.b or 1,
          combo.color[4] or 1)
      elseif #combo.color >= 3 then
        colorStr = string.format("{%s, %s, %s, %s}",
          combo.color[1] or 1,
          combo.color[2] or 0,
          combo.color[3] or 1,
          combo.color[4] or 1)
      end
    else
      colorStr = "{1, 0, 1, 1}" -- Default purple
    end

    combosLuaCode = combosLuaCode .. string.format(
      "    {name = %q, spells = %s, color = %s, enabled = true, priority = %s},\n",
      combo.name or "Combo " .. i,
      spellListStr,
      colorStr,
      combo.priority or 10
    )
  end
  combosLuaCode = combosLuaCode .. "}"

  -- Define constructor code with embedded config
  local constructorCode = string.format([[
function(self, unitId, unitFrame, envTable, modTable)
  -- PRIORITY ORDER:
  -- 1. Force Threat Color (if enabled - overrides all other coloring)
  -- 2. DoT Combinations (if no threat coloring is active)
  -- 3. Individual DoT Spells (if no combinations match)

  -- Directly embed DotMaster configuration
  envTable.DM_SPELLS = %s
  envTable.DM_COMBOS = %s
  envTable.DM_FORCE_THREAT_COLOR = %s
  envTable.DM_BORDER_ONLY = %s

  -- Make sure thickness is a valid number with proper conversion
  local borderThickness = tonumber(%s)

  -- Use a clearly identifiable debug message
  print("|cFFFF9900DotMaster-BorderDebug: APPLYING border thickness " .. tostring(borderThickness) .. "|r")

  if not borderThickness or borderThickness < 1 or borderThickness > 10 then
    borderThickness = 2 -- Default to 2px if invalid
    print("|cFFFF9900DotMaster-BorderDebug: WARNING - Invalid thickness, using default 2px|r")
  end

  envTable.DM_BORDER_THICKNESS = borderThickness

  envTable.DM_FLASH_EXPIRING = %s
  envTable.DM_FLASH_THRESHOLD = %s

  -- Store last build time for debugging
  envTable.lastBuildTime = %s

  -- If border-only mode is enabled, set Plater's global border thickness
  if envTable.DM_BORDER_ONLY and Plater.db and Plater.db.profile then
    -- Save previous border thickness for restoration later if needed
    envTable.previousBorderThickness = Plater.db.profile.border_thickness or 1

    -- Set Plater's global border thickness
    Plater.db.profile.border_thickness = envTable.DM_BORDER_THICKNESS

    -- Update all nameplates to use the new border thickness
    if Plater.UpdateAllPlatesBorderThickness then
      Plater.UpdateAllPlatesBorderThickness()
    end

    print("|cFFFF9900DotMaster-BorderDebug: SET PLATER border thickness to " .. envTable.DM_BORDER_THICKNESS .. "|r")
  end

  -- Debug info at initialization
  print("DotMaster: Plater mod initialized - Force Threat Color: " .. (envTable.DM_FORCE_THREAT_COLOR and "ENABLED" or "DISABLED"))
  print("DotMaster: Border Only Mode: " .. (envTable.DM_BORDER_ONLY and "ENABLED" or "DISABLED") .. " (Thickness: " .. envTable.DM_BORDER_THICKNESS .. ")")
  print("DotMaster: Loaded " .. #envTable.DM_SPELLS .. " spells and " .. #envTable.DM_COMBOS .. " combos")
end]],
    spellsLuaCode, combosLuaCode,
    settings.forceColor and "true" or "false",
    settings.borderOnly and "true" or "false",
    settings.borderThickness,
    settings.flashExpiring and "true" or "false",
    settings.flashThresholdSeconds or 3.0,
    GetTime())

  local updateCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  -- IMPORTANT: This function runs for every nameplate, every frame
  -- So we need to keep it efficient and avoid excessive debug messages

  -- Quick early exit check - if no nameplate or health bar, nothing to color
  if not unitFrame or not unitFrame.healthBar then
    return
  end

  local unitName = unitFrame.namePlateUnitName or unitId or "Unknown"

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

  -- First, check for threat coloring (has priority if enabled)
  if envTable.DM_FORCE_THREAT_COLOR then
    -- Get threat info directly
    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unitId)
    local isTank = Plater.PlayerIsTank

    -- For tanks, high threat = good, for DPS/healer, high threat = bad
    local threatIsActive = false

    if isTank then
      -- For tanks: color if NOT tanking and in combat
      if unitFrame.InCombat and not isTanking then
        -- Apply the no-aggro color for tanks
        local color = Plater.db.profile.tank.colors.noaggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ NOT TANKING")
        unitFrame.DM_Text:Show()
        return -- Exit early, don't process DoTs
      end
    else
      -- For DPS/Healers: color if tanking and in combat
      if unitFrame.InCombat and isTanking then
        -- Apply the aggro color for DPS
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ AGGRO")
        unitFrame.DM_Text:Show()
        return -- Exit early, don't process DoTs
      end
    end
  end

  -- Debug text on the nameplate
  unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
  unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)

  -- Use the directly embedded configuration
  local spells = envTable.DM_SPELLS or {}
  local combos = envTable.DM_COMBOS or {}

  -- Check for combinations first (higher priority)
  for i, combo in ipairs(combos) do
    if combo.enabled then
      local allSpellsPresent = true
      for _, spellID in ipairs(combo.spells) do
        if not Plater.NameplateHasAura(unitFrame, spellID) then
          allSpellsPresent = false
          break
        end
      end

      if allSpellsPresent then
        -- Apply combination color
        applyColor(combo.color[1], combo.color[2], combo.color[3], combo.color[4] or 1, false) -- false = not threat color
        unitFrame.DM_Text:SetText("◆ " .. combo.name)
        unitFrame.DM_Text:Show()
        return
      end
    end
  end

  -- Check for individual spells
  for i, spell in ipairs(spells) do
    if spell.enabled and spell.spellID and Plater.NameplateHasAura(unitFrame, spell.spellID) then
      -- Apply spell color
      applyColor(spell.color[1], spell.color[2], spell.color[3], spell.color[4] or 1, false) -- false = not threat color
      unitFrame.DM_Text:SetText(spell.name)
      unitFrame.DM_Text:Show()
      return
    end
  end

  -- No spells or combos detected, reset nameplate
  if envTable.DM_BORDER_ONLY then
    -- Reset the border color and clear any customBorderColor flag
    if unitFrame.healthBar.border then
      unitFrame.customBorderColor = nil
      unitFrame.healthBar.border:SetVertexColor(1, 1, 1, 1)
    end
  else
    -- Reset the entire nameplate
    Plater.RefreshNameplateColor(unitFrame)
  end

  unitFrame.DM_Text:Hide()
end
]]

  -- Add nameplate added hook to run CheckAggro when a nameplate is added
  local nameplatAddedCode = [[
function(self, unitId, unitFrame, envTable, modTable)
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

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ NOT TANKING")
        unitFrame.DM_Text:Show()
      end
    else
      -- For DPS/Healers: color if tanking and in combat
      if unitFrame.InCombat and isTanking then
        -- Apply the aggro color for DPS
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ AGGRO")
        unitFrame.DM_Text:Show()
      end
    end
  end
end
]]

  local data = Plater.db.profile.hook_data
  local modName = "bokmaster" -- Target the manually added mod
  local foundIndex
  for i, mod in ipairs(data) do
    if mod.Name == modName then
      foundIndex = i
      break
    end
  end

  -- Only proceed if the 'bokmaster' mod was found
  if foundIndex then
    local modEntry = data[foundIndex]
    modEntry.Name = modName                          -- Keep the name as "bokmaster"
    modEntry.Desc = "Managed by DotMaster Addon"     -- Update description
    modEntry.Author = "DotMaster"                    -- Update author
    modEntry.Time = time()
    modEntry.Revision = (modEntry.Revision or 0) + 1 -- Increment revision
    modEntry.PlaterCore = Plater.CoreVersion or 0
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
    DM:PrintMessage("Updated 'bokmaster' with " ..
      #trackedSpells .. " spells and " .. #combinations .. " combos. Force Threat Color is " .. forceColorStatus .. ".")
    DM:PrintMessage("|cFFFFFF00Consider using /reload to fully apply these changes.|r")

    -- Recompile hook scripts and refresh plates (needed after changing hooks)
    if Plater.WipeAndRecompileAllScripts then
      Plater.WipeAndRecompileAllScripts("hook")
    end
    if Plater.FullRefreshAllPlates then
      Plater.FullRefreshAllPlates()
    end
  else
    -- If the 'bokmaster' mod was NOT found, print an error and do nothing else
    DM:PrintMessage(
      "|cFFFF0000Error: Plater mod 'bokmaster' not found. Please add it manually via Plater options and ensure the name is exactly 'bokmaster'.|r")
  end
end
