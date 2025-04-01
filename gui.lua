-- DotMaster gui.lua
-- Ana GUI işlevselliği ve temel yapılar

local DM = DotMaster
DM.GUI = {}

-- Function to refresh the spell list
function DM.GUI:RefreshSpellList()
  if not DM.GUI.spellFrames then
    DM:DebugMsg("spellFrames not found in RefreshSpellList")
    return
  end

  for _, frame in ipairs(DM.GUI.spellFrames) do
    frame:Hide()
  end

  DM.GUI.spellFrames = {}
  local yOffset = 40 -- Start after header with more space
  local index = 0

  -- Add all spells
  for spellID, _ in pairs(DM.spellConfig) do
    index = index + 1
    DM:CreateSpellConfigRow(spellID, index, yOffset)
    yOffset = yOffset + 36 -- More space between rows
  end

  if DM.GUI.scrollChild and DM.GUI.scrollFrame then
    DM.GUI.scrollChild:SetHeight(math.max(yOffset + 10, DM.GUI.scrollFrame:GetHeight()))
  else
    DM:DebugMsg("scrollChild or scrollFrame not found in RefreshSpellList")
  end
end

-- Helper function to check if a spell ID already exists
function DM:SpellExists(spellID)
  -- Convert to number for comparison if needed
  local numericID = tonumber(spellID)
  if not numericID then return false end

  -- Check each spell config
  for existingID, _ in pairs(DM.spellConfig) do
    -- Direct ID match
    if tonumber(existingID) == numericID then
      return true
    end

    -- Check for IDs in comma-separated list
    if type(existingID) == "string" and existingID:find(",") then
      for id in string.gmatch(existingID, "%d+") do
        if tonumber(id) == numericID then
          return true
        end
      end
    end
  end

  return false
end

-- Removed duplicate CreateGUI function - Using the implementation from gui_common.lua instead
