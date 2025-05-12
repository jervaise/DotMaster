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
    modTable.config = {
      spells = DotMaster.API:GetTrackedSpells(),
      combos = DotMaster.API:GetCombinations(),
      defaults = DotMaster.API:GetSettings(),
    }
  end]]

  local updateCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  local cfg = modTable.config
  if not cfg then return end -- Safety check

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

  -- Sort spells by priority (lower number = higher priority)
  table.sort(cfg.spells or {}, function(a,b) return (a.priority or 999) < (b.priority or 999) end)
  -- Sort combos by priority
  table.sort(cfg.combos or {}, function(a,b) return (a.priority or 999) < (b.priority or 999) end)

  -- Check Combinations
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
        local r, g, b, a = getColorComponents(combo.color)
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
        return
      end
    end
  end

  -- Check Individual Spells
  for _, s in ipairs(cfg.spells or {}) do
    if s and s.enabled and s.spellID then
      if Plater.NameplateHasAura(unitFrame, s.spellID) then
        local r, g, b, a = getColorComponents(s.color)
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
        return
      end
    end
  end

  -- Fallback
  Plater.RefreshNameplateColor(unitFrame)
end
]]


  -- Only proceed if the 'bokmaster' mod was found
  if foundIndex then
    local modEntry = data[foundIndex]
    modEntry.Name = modName -- Keep the name as "bokmaster"
    -- Optionally update Icon and Desc for clarity, or leave them as they are in the manual mod
    -- modEntry.Icon = "Interface\Icons\INV_Misc_QuestionMark"
    modEntry.Desc = "Managed by DotMaster Addon"     -- Update description
    modEntry.Author = "DotMaster"                    -- Update author
    modEntry.Time = time()
    modEntry.Revision = (modEntry.Revision or 0) + 1 -- Increment revision
    modEntry.PlaterCore = Plater.CoreVersion or 0
    -- Inject our hooks
    modEntry.Hooks = { ["Constructor"] = constructorCode, ["Nameplate Updated"] = updateCode }
    modEntry.HooksTemp = { ["Constructor"] = constructorCode, ["Nameplate Updated"] = updateCode }
    modEntry.LastHookEdited = "Constructor" -- Indicate which hook was last edited
    DM:PrintMessage("Updated existing 'bokmaster' Plater mod with DotMaster hooks.")

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

  -- Removed the 'else' block that created a new mod.
  -- Removed the final recompile/refresh calls from here as they are now inside the 'if foundIndex then' block.
end
