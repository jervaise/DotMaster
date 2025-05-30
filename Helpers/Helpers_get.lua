local DM = DotMaster

-- !TODO: Overload this for multi lang.
function DM:GetTextForMenu(key)
    return Localization_ENG[key] or ("Missing text for a key: " .. key)
end

function DM:ErrorMsg(key)
    return Errors[key] or ("Unable to parse error msg" .. key)
end