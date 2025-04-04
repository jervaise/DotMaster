-- DotMaster core.lua
-- Core functionality

local DM = DotMaster

-- Initialize nameplate handling
function DM:InitializeNameplates()
  -- Initialize nameplate tables properly
  DM.activePlates = DM.activePlates or {}
  DM.coloredPlates = DM.coloredPlates or {}
  DM.originalColors = DM.originalColors or {}

  -- Register nameplate related events
  DM:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  DM:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  DM:RegisterEvent("UNIT_AURA")

  -- Hook our OnEvent handler to handle nameplate events
  local existingOnEvent = DM:GetScript("OnEvent")
  DM:SetScript("OnEvent", function(self, event, arg1, ...)
    -- Call the existing event handler for all events first
    if existingOnEvent then
      existingOnEvent(self, event, arg1, ...)
    end

    -- Handle nameplate events after other handlers
    if event == "NAME_PLATE_UNIT_ADDED" and self.NameplateAdded then
      self:NameplateAdded(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" and self.NameplateRemoved then
      self:NameplateRemoved(arg1)
    elseif event == "UNIT_AURA" and self.UnitAuraChanged then
      self:UnitAuraChanged(arg1)
    end
  end)
end
