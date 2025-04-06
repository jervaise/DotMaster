-- DotMaster by Jervaise
-- Main initialization file (init.lua)

local DM = DotMaster

-- Setup basic variables needed for GUI
DM.GUI = DM.GUI or {}

-- Create Components namespace if it doesn't exist
if not DotMaster_Components then
  DotMaster_Components = {}
end

-- Log initialization completion
DM:DebugMsg("DotMaster GUI framework initialized.")
