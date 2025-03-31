-- Toggle the Find My Dots window
function DotMaster:ToggleFindMyDots()
  -- Initialize if needed
  if not self.findMyDotsFrame then
    self:InitializeFindMyDots()
  end

  -- Toggle visibility
  if self.findMyDotsFrame:IsShown() then
    self.findMyDotsFrame:Hide()
    self.db.profile.findMyDots.enabled = false
    self:Debug("DOT", "Find My Dots window hidden")
  else
    self.findMyDotsFrame:Show()
    self.db.profile.findMyDots.enabled = true
    self:Debug("DOT", "Find My Dots window shown")
  end

  -- Ensure timer is running when visible
  if self.findMyDotsFrame:IsShown() and not self.findMyDotsTimer then
    self.findMyDotsTimer = self:ScheduleRepeatingTimer("UpdateFindMyDotsDisplay", 0.1)
  end

  return self.findMyDotsFrame:IsShown()
end
