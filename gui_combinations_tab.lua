-- DotMaster gui_combinations_tab.lua
-- Combinations Tab for combining multiple DoTs on nameplates

local DM = DotMaster

function DM:CreateCombinationsTab(parent)
  -- Create a container frame for all content in this tab
  local container = CreateFrame("Frame", nil, parent)
  container:SetAllPoints(parent)

  -- Create the info area at the top of the tab
  local infoArea = DotMaster_Components.CreateTabInfoArea(
    container,
    "DoT Combinations",
    "Create combinations of DoTs to apply unique visual effects when multiple spells are active on the same target."
  )

  -- The rest of the tab will be implemented later
  -- This placeholder ensures we have the basic structure ready

  return container
end

-- Register with the components system
DotMaster_Components.CreateCombinationsTab = function(parent)
  return DM:CreateCombinationsTab(parent)
end
