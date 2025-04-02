local Debugger = {}

function Debugger:Log(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[DotMaster Debugger]|r " .. message)
end

function Debugger:ShowError(errorMessage)
  self:Log("Error: " .. errorMessage)
end

-- Example usage
Debugger:Log("Debugger loaded successfully.")

-- Function to check DotMaster status
function Debugger:CheckDotMasterStatus()
  if DotMaster then
    self:Log("DotMaster is loaded.")
  else
    self:Log("DotMaster is not loaded.")
  end
end

-- Run status check on load
Debugger:CheckDotMasterStatus()

-- Register slash command
SLASH_DMDEBUGGER1 = "/dmd"

SlashCmdList["DMDEBUGGER"] = function(msg)
  if msg == "status" then
    Debugger:CheckDotMasterStatus()
  else
    Debugger:Log("Usage: /dmd status")
  end
end

-- Auto log on load
Debugger:Log("DotMaster Debugger is active.")

-- Periodic status check
local function PeriodicStatusCheck()
  Debugger:CheckDotMasterStatus()
  C_Timer.After(60, PeriodicStatusCheck) -- Check every 60 seconds
end

-- Start periodic checks after 10 seconds to allow for full loading
C_Timer.After(10, PeriodicStatusCheck)
