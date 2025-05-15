-- DotMaster gui_colorpicker.lua
-- Color picker functionality

local DM = DotMaster
DotMaster_ColorPicker = {}
local colorpicker = DotMaster_ColorPicker

-- Module initialization message
DM:DebugMsg("|cFFCC00FFDotMaster Debug:|r Color picker module loaded")

-- Add debug method for color picker if it doesn't exist
if not DM.ColorPickerDebug then
  DM.ColorPickerDebug = function(self, message)
    -- Fall back to standard PrintMessage if available
    if self.PrintMessage then
      self:PrintMessage("ColorPicker: " .. message)
    else
      print("|cFFCC00FFDotMaster ColorPicker:|r " .. message)
    end
  end
end

-- Helper function for color picker
function colorpicker.CreateColorSwatch(parent, r, g, b, callback)
  -- Use the proper debug function
  DM:ColorPickerDebug("CreateColorSwatch ENTRY - R:" .. tostring(r) .. " G:" .. tostring(g) .. " B:" .. tostring(b))

  if DM.DEBUG_CATEGORIES.colorpicker then
    DM:ColorPickerDebug("Creating swatch RGB - R:" .. tostring(r) .. " G:" .. tostring(g) .. " B:" .. tostring(b))
  end

  local swatch = CreateFrame("Button", nil, parent)
  swatch:SetSize(24, 24)

  -- Create border for better visibility
  local border = swatch:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  border:SetColorTexture(0.1, 0.1, 0.1, 1)

  -- Create a texture for the color with slight inner border
  local texture = swatch:CreateTexture(nil, "ARTWORK")
  texture:SetPoint("TOPLEFT", 2, -2)
  texture:SetPoint("BOTTOMRIGHT", -2, 2)
  texture:SetColorTexture(r, g, b, 1)

  -- Add highlight/tooltip on hover instead of debug message
  swatch:SetScript("OnEnter", function(self)
    -- Add highlight effect
    border:SetColorTexture(0.3, 0.3, 0.3, 1)

    -- Show tooltip with color values
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Color Values")
    GameTooltip:AddLine("R: " .. math.floor(r * 255) .. " G: " .. math.floor(g * 255) .. " B: " .. math.floor(b * 255), 1,
      1, 1)
    GameTooltip:AddLine("Click to change color", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  swatch:SetScript("OnLeave", function()
    border:SetColorTexture(0.1, 0.1, 0.1, 1)
    GameTooltip:Hide()
  end)

  -- Use standard WoW color picker with updated API
  swatch:SetScript("OnClick", function()
    DM:ColorPickerDebug("Color swatch clicked")

    -- Check if ColorPickerFrame exists
    if not ColorPickerFrame then
      DM:ColorPickerDebug("ERROR: ColorPickerFrame does not exist!")
      return
    end

    DM:ColorPickerDebug("Setting up ColorPickerFrame functions")

    -- Store current color for cancelFunc
    local currentR, currentG, currentB = r, g, b

    -- Modern color picker setup
    local function colorPickerCallback(restore)
      local newR, newG, newB

      if restore then
        -- User canceled, restore original color
        DM:ColorPickerDebug("Color canceled, reverting to original")
        newR, newG, newB = currentR, currentG, currentB
      else
        -- Get selected color from color picker
        DM:ColorPickerDebug("Getting new color from color picker")
        -- Check available APIs for getting color
        if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
          DM:ColorPickerDebug("Using Content.ColorPicker API")
          newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
        elseif ColorPickerFrame.GetColorRGB then
          DM:ColorPickerDebug("Using GetColorRGB API")
          newR, newG, newB = ColorPickerFrame:GetColorRGB()
        else
          -- Try to get color via individual RGB functions (fallback method)
          DM:ColorPickerDebug("Using fallback RGB methods")
          if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
            newR = ColorPickerFrame.Content.ColorPicker:GetColorValueTexture() or currentR
            newG = ColorPickerFrame.Content.ColorPicker:GetColorSaturationTexture() or currentG
            newB = ColorPickerFrame.Content.ColorPicker:GetColorBrightnessTexture() or currentB
          else
            DM:ColorPickerDebug("Couldn't get color - using defaults")
            newR, newG, newB = currentR, currentG, currentB
          end
        end
      end

      -- Safety checks to ensure all values are numbers
      newR = tonumber(newR) or currentR
      newG = tonumber(newG) or currentG
      newB = tonumber(newB) or currentB

      -- Apply color to swatch
      DM:ColorPickerDebug("Setting texture color to: " ..
        tostring(newR) .. ", " .. tostring(newG) .. ", " .. tostring(newB))
      texture:SetColorTexture(newR, newG, newB, 1)

      -- Update color reference values
      r, g, b = newR, newG, newB

      -- Call user callback if provided
      if callback then
        DM:ColorPickerDebug("Running callback function with " ..
          tostring(newR) .. ", " .. tostring(newG) .. ", " .. tostring(newB))
        callback(newR, newG, newB)
        DM:ColorPickerDebug("Callback completed, saving settings")
        -- Renklerin kaydedildiğinden emin olmak için SaveSettings'i doğrudan çağır
        DM:SaveSettings()
      end
    end

    -- Set up color picker
    DM:ColorPickerDebug("Setting up color picker with color: " ..
      tostring(r) .. ", " .. tostring(g) .. ", " .. tostring(b))

    -- Modern API
    if ColorPickerFrame.SetupColorPickerAndShow then
      DM:ColorPickerDebug("Using SetupColorPickerAndShow API")
      local info = {}
      info.swatchFunc = colorPickerCallback
      info.cancelFunc = function() colorPickerCallback(true) end
      info.r = r
      info.g = g
      info.b = b
      info.opacity = 1
      info.hasOpacity = false

      -- Show the color picker
      ColorPickerFrame:SetupColorPickerAndShow(info)
    else
      -- Legacy API fallback
      DM:ColorPickerDebug("Using legacy color picker API")

      -- Set frame attributes directly
      if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
        DM:ColorPickerDebug("Using Content.ColorPicker.SetColorRGB")
        ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
      end

      -- Set callbacks
      ColorPickerFrame.func = colorPickerCallback
      ColorPickerFrame.cancelFunc = function() colorPickerCallback(true) end
      ColorPickerFrame.opacityFunc = nil
      ColorPickerFrame.hasOpacity = false
      ColorPickerFrame.previousValues = { r = r, g = g, b = b }

      -- Show the frame
      DM:ColorPickerDebug("About to show ColorPickerFrame")
      ColorPickerFrame:Show()
      DM:ColorPickerDebug("After Show() - IsShown: " .. tostring(ColorPickerFrame:IsShown()))
    end
  end)

  swatch.GetColor = function() return r, g, b end
  swatch.SetColor = function(_, newR, newG, newB)
    -- Safety checks to ensure all values are numbers
    r = tonumber(newR) or r
    g = tonumber(newG) or g
    b = tonumber(newB) or b
    texture:SetColorTexture(r, g, b, 1)
  end

  DM:ColorPickerDebug("Color swatch created successfully")
  return swatch
end

-- Expose the function globally - reinforce export to ensure it's accessible
_G["DotMaster_CreateColorSwatch"] = colorpicker.CreateColorSwatch
