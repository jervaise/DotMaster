-- DotMaster core.lua
-- Final initialization and startup

local DM = DotMaster

-- First ensure debug system is initialized
if DM.Debug and DM.Debug.Init then
  -- Use pcall to catch any errors during initialization
  local success, errorMsg = pcall(DM.Debug.Init, DM.Debug)
  if not success then
    print("|cFFCC00FFDotMaster:|r Error initializing debug system: " .. tostring(errorMsg))
  end
end

-- Now that all modules are loaded, we can safely initialize the addon
DM:Initialize()

-- Debug note to indicate everything has loaded correctly
if DM.DebugMsg then
  DM:DebugMsg("Core initialization complete - all modules loaded")
else
  print("|cFFCC00FFDotMaster:|r Core initialization complete")
end

-- Create debug window if DEBUG_MODE is enabled
if DM.DEBUG_MODE and DM.Debug and DM.Debug.CreateDebugWindow then
  C_Timer.After(1, function()
    -- Use pcall to catch any errors when creating the debug window
    local success, errorMsg = pcall(DM.Debug.CreateDebugWindow, DM.Debug)
    if not success then
      print("|cFFCC00FFDotMaster:|r Error creating debug window: " .. tostring(errorMsg))
    end
  end)
end
