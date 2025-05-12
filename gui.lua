-- DotMaster gui.lua
-- Basic GUI functionality and initialization

local DM = DotMaster
-- Initialize GUI namespace
DM.GUI = DM.GUI or {}

-- Print debug message to verify loading
print("|cFFFF00FFDEBUG:|r gui.lua loaded, GUI namespace initialized")

-- Helper function to check if a spell ID already exists
function DM:SpellExists(spellID)
  -- Convert to number for comparison if needed
  local numericID = tonumber(spellID)
  if not numericID then return false end

  -- Check dmspellsdb first with the string ID
  if self.dmspellsdb and self.dmspellsdb[tostring(numericID)] then
    return true
  end

  -- Also check with numeric ID for compatibility
  if self.dmspellsdb then
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

-- Add a simple placeholder CreateGUI in the GUI namespace
-- that will be replaced by the implementation in gui_common.lua
DM.GUI.CreateGUI = function()
  print("|cFFFF00FFDEBUG:|r Placeholder CreateGUI called, this should be replaced by gui_common.lua")
  return nil
end
