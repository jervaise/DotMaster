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

  local data = Plater.db.profile.hook_data
  local modName = "bokmaster" -- Target the manually added mod
  local foundIndex
  for i, mod in ipairs(data) do
    if mod.Name == modName then
      foundIndex = i
      break
    end
  end

  -- Define hook code strings
  local constructorCode = [[function(self, unitId, unitFrame, envTable, modTable)
    -- Ensure we only run this once per update to avoid any issues
    self.ThrottleUpdate = 0.016

    -- Get all tracking data from DotMaster
    modTable.config = {
      spells = DotMaster.API:GetTrackedSpells(),
      combos = DotMaster.API:GetCombinations(),
      defaults = DotMaster.API:GetSettings(),
    }

    -- Debug print to confirm constructor is running
    -- print("DotMaster bokmaster constructor executed")
  end]]

  local updateCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  -- Early exit if configuration is missing
  local cfg = modTable.config
  if not cfg then return end

  -- Set throttle to ensure smooth updates
  self.ThrottleUpdate = 0.016

  -- Helper to safely get color components
  local function getColorComponents(colorTable)
    if not colorTable then return 1, 1, 1, 1 end -- Default to white if nil
    -- Check for keys first, then indices
    local r = colorTable.r
    local g = colorTable.g
    local b = colorTable.b
    local a = colorTable.a
    if r == nil and type(colorTable) == 'table' and #colorTable >= 3 then
      r = colorTable[1]
      g = colorTable[2]
      b = colorTable[3]
      a = colorTable[4]
    end
    -- Ensure valid numbers, default to 1 if not
    r = (type(r) == 'number' and r) or 1
    g = (type(g) == 'number' and g) or 1
    b = (type(b) == 'number' and b) or 1
    a = (type(a) == 'number' and a) or 1
    return r, g, b, a
  end

  -- Track if we applied a color
  local appliedColor = false

  -- Sort spells by priority (lower number = higher priority)
  table.sort(cfg.spells or {}, function(a,b) return (a.priority or 999) < (b.priority or 999) end)
  -- Sort combos by priority
  table.sort(cfg.combos or {}, function(a,b) return (a.priority or 999) < (b.priority or 999) end)

  -- Check Combinations first (they have higher priority)
  for _, combo in ipairs(cfg.combos or {}) do
    if combo and combo.spellList and combo.enabled then
      local allSpellsPresent = true
      for _, sid in ipairs(combo.spellList) do
        if not Plater.NameplateHasAura(unitFrame, sid) then
          allSpellsPresent = false
          break
        end
      end
      if allSpellsPresent then
        -- We found a matching combo, apply the color
        local r, g, b, a = getColorComponents(combo.color)
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
        -- print("DotMaster: Applied combo color", r, g, b)
        appliedColor = true
        break -- Exit after applying highest priority combo
      end
    end
  end

  -- If we didn't apply a combo color, check individual spells
  if not appliedColor then
    for _, s in ipairs(cfg.spells or {}) do
      if s and s.enabled and s.spellID then
        if Plater.NameplateHasAura(unitFrame, s.spellID) then
          local r, g, b, a = getColorComponents(s.color)
          Plater.SetNameplateColor(unitFrame, r, g, b, a)
          -- print("DotMaster: Applied spell color", r, g, b, "for spell", s.spellID)
          appliedColor = true
          break -- Exit after applying highest priority spell
        end
      end
    end
  end

  -- If we didn't apply any color, restore default
  if not appliedColor then
    Plater.RefreshNameplateColor(unitFrame)
  end
end
]]


  -- Only proceed if the 'bokmaster' mod was found
  if foundIndex then
    local modEntry = data[foundIndex]
    modEntry.Name = modName -- Keep the name as "bokmaster"
    -- Update icon to match DoT functionality
    modEntry.Icon = "Interface\\ICONS\\Spell_Shadow_ShadowWordPain"
    modEntry.Desc = "Colors nameplates based on DoTs tracked by DotMaster"
    modEntry.Author = "DotMaster"
    modEntry.Time = time()
    modEntry.Revision = (modEntry.Revision or 0) + 1 -- Increment revision
    modEntry.PlaterCore = Plater.CoreVersion or 0

    -- Ensure the proper hooks are enabled
    modEntry.Hooks = {
      ["Constructor"] = true,
      ["Nameplate Updated"] = true,
      ["Nameplate Created"] = false,
      ["Nameplate Added"] = false,
      ["Nameplate Removed"] = false,
      ["Cast Start"] = false,
      ["Cast Update"] = false,
      ["Cast Stop"] = false,
      ["Target Changed"] = false,
      ["Load Screen"] = false,
      ["Player Power Update"] = false,
      ["Player Talent Update"] = false,
      ["Health Update"] = false,
      ["Zone Changed"] = false,
      ["Name Updated"] = false,
    }

    -- Inject our hook code
    modEntry.HooksTemp = {
      ["Constructor"] = constructorCode,
      ["Nameplate Updated"] = updateCode
    }

    modEntry.LastHookEdited = "Nameplate Updated" -- Indicate which hook was last edited

    -- Make sure mod is enabled
    modEntry.Enabled = true

    DM:PrintMessage("Updated bokmaster Plater mod with DotMaster hooks.")

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
