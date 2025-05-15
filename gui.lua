-- DotMaster gui.lua
-- Ana GUI işlevselliği ve temel yapılar

local DM = DotMaster
DM.GUI = {}

-- Helper function to check if a spell ID already exists
function DM:SpellExists(spellID)
  -- Convert to number for comparison
  local numericID = tonumber(spellID)
  if not numericID then return false end

  -- Get current class and spec
  local currentClass, currentSpecID
  if DM.ClassSpec and DM.ClassSpec.GetCurrentClassAndSpec then
    currentClass, currentSpecID = DM.ClassSpec:GetCurrentClassAndSpec()
  else
    return false
  end

  -- Check if the spell exists in the current class/spec profile
  if currentClass and currentSpecID and
      DotMasterDB and DotMasterDB.classProfiles and
      DotMasterDB.classProfiles[currentClass] and
      DotMasterDB.classProfiles[currentClass][currentSpecID] and
      DotMasterDB.classProfiles[currentClass][currentSpecID].spells then
    -- Look through the spells array for this ID
    for _, spell in ipairs(DotMasterDB.classProfiles[currentClass][currentSpecID].spells) do
      if spell.spellID == numericID then
        return true
      end
    end
  end

  -- Fallback to legacy global database check (for migration)
  if self.dmspellsdb then
    -- Check with string ID
    if self.dmspellsdb[tostring(numericID)] then
      return true
    end

    -- Check with numeric ID
    for existingIDStr, _ in pairs(self.dmspellsdb) do
      -- Direct ID match
      if tonumber(existingIDStr) == numericID then
        return true
      end

      -- Check for IDs in comma-separated list
      if type(existingIDStr) == "string" and existingIDStr:find(",") then
        for id in string.gmatch(existingIDStr, "%d+") do
          if tonumber(id) == numericID then
            return true
          end
        end
      end
    end
  end

  return false
end

-- Removed duplicate CreateGUI function - Using the implementation from gui_common.lua instead
