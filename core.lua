-- DotMaster core.lua
-- Final initialization and startup

local DM = DotMaster

-- Now that all modules are loaded, we can safely initialize the addon
DM:Initialize()

-- Debug note to indicate everything has loaded correctly
DM:DebugMsg("Core initialization complete - all modules loaded")
