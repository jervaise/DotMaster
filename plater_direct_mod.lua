-- DotMaster plater_direct_mod.lua
-- Direct mod approach based on the sample

local DM = DotMaster

-- Function to install a direct mod into Plater
function DM:InstallPlaterDirectMod()
  local Plater = _G["Plater"]
  if not Plater then
    DM:NameplateDebug("Plater not found, cannot install direct mod")
    return
  end

  DM:NameplateDebug("Installing DotMaster direct mod into Plater")

  -- Create a mod structure identical to the sample
  local modTable = {
    Name = "DotMaster Integration",
    IconPath = [[Interface\ICONS\Spell_Shadow_ShadowWordPain]],
    Desc = "Colors nameplates based on DoTs tracked by DotMaster",
    Author = "DotMaster",
    Time = time(),
    Revision = 1,
    PlaterCore = Plater.CoreVersion or 0,
    Hooks = {
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
    },
    HooksTemp = {},
    Scripts = {
      ["Nameplate Updated"] = {
        Code = [[
function (self, unitId, unitFrame, envTable, modTable)

    self.ThrottleUpdate = 0.016

    -- Get all enabled DoTs from DotMaster
    local trackingSpells = {}
    if DotMaster and DotMaster.dmspellsdb then
        local playerClass = DotMaster.GetPlayerClass()
        for spellID, config in pairs(DotMaster.dmspellsdb) do
            if config.enabled == 1 and config.wowclass == playerClass then
                trackingSpells[spellID] = {
                    id = spellID,
                    name = config.spellname or "Unknown",
                    priority = config.priority or 999,
                    color = config.color or {1, 0, 1, 1}
                }
            end
        end
    end

    -- Check for DoTs - identical approach to sample mod
    local hasDoT = false
    local bestColor = nil
    local bestPriority = 9999

    for spellID, spellData in pairs(trackingSpells) do
        if Plater.NameplateHasAura(unitFrame, spellID) then
            if spellData.priority < bestPriority then
                hasDoT = true
                bestColor = spellData.color
                bestPriority = spellData.priority
            end
        end
    end

    -- Apply color exactly like the sample mod
    if hasDoT and bestColor then
        -- We have a DoT, apply DotMaster color
        if DotMaster.coloredPlates then
            DotMaster.coloredPlates[unitId] = true
        end
        Plater.SetNameplateColor(unitFrame, bestColor[1], bestColor[2], bestColor[3], bestColor[4] or 1)
    else
        -- No DotMaster DoT found for this unit
        if envTable.isFTCEnabled then
            -- FTC is ON, but no DoT. Plater handles threat/default color. Reset our state.
            if DotMaster.coloredPlates and DotMaster.coloredPlates[unitId] then
                Plater.RefreshNameplateColor(unitFrame)
                DotMaster.coloredPlates[unitId] = nil
            end
        else
            -- FTC is OFF and no DoT. Let Plater do its thing entirely.
            -- Do NOT call RefreshNameplateColor here.
            -- Just ensure our tracking flag is cleared if it was somehow set.
            if DotMaster.coloredPlates and DotMaster.coloredPlates[unitId] then
                 DotMaster.coloredPlates[unitId] = nil
            end
            return
        end
    end
end]],
        SpellIds = {},
        Time = time(),
        Revision = 1,
        AutoGridSize = true,
        GridSize = { Width = 1, Height = 1 },
        GridColor = { 0.1, 0.1, 0.1, 0.2 },
        Options = {},
        OptionsValues = {},
        Icon = "Interface\\ICONS\\Spell_Shadow_ShadowWordPain",
      }
    }
  }

  -- Add config
  modTable.config = {
    enabled = true
  }

  -- Install the mod directly into Plater's script_data table
  local success = false
  if Plater.db and Plater.db.profile and Plater.db.profile.script_data then
    -- Check if mod exists
    local modExists = false
    for i, mod in ipairs(Plater.db.profile.script_data) do
      if mod.Name == "DotMaster Integration" then
        modExists = true
        -- Update existing
        Plater.db.profile.script_data[i] = modTable
        DM:NameplateDebug("Updated existing DotMaster Plater mod")
        success = true
        break
      end
    end

    -- Add if new
    if not modExists then
      table.insert(Plater.db.profile.script_data, modTable)
      DM:NameplateDebug("Added new DotMaster Plater mod")
      success = true
    end

    -- Enable the mod
    if success then
      if Plater.RefreshDBUpvalues then
        Plater.RefreshDBUpvalues()
      end

      if Plater.CompileAllScripts then
        Plater.CompileAllScripts()
      end

      DM.platerDirectModInstalled = true
    end
  end

  return success
end
