--[[
  DotMaster - ColorPicker Module

  File: gui_colorpicker.lua
  Purpose: Provides color picker functionality

  Functions:
  - CreateColorSwatch(): Creates a color swatch button with a callback

  Dependencies:
  - dm_core.lua

  Author: Jervaise
  Last Updated: 2024-07-01
]]

local DM = DotMaster
local UIColorPicker = {}
DM.UIColorPicker = UIColorPicker

-- Helper function for color picker
function UIColorPicker:CreateColorSwatch(parent, r, g, b, callback)
  -- Use proper debug function instead of print
  if DM.DEBUG_MODE then
    DM:DebugMsg("Creating color swatch with RGB: " .. r .. ", " .. g .. ", " .. b)
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
    -- Check if ColorPickerFrame exists
    if not ColorPickerFrame then
      DM:DebugMsg("ERROR: ColorPickerFrame does not exist!")
      return
    end

    -- Store current color for cancelFunc
    local currentR, currentG, currentB = r, g, b

    -- Modern color picker setup
    local function colorPickerCallback(restore)
      local newR, newG, newB

      if restore then
        -- User canceled, restore original color
        newR, newG, newB = currentR, currentG, currentB
      else
        -- Get selected color from color picker
        -- Check available APIs for getting color
        if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
          newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
        elseif ColorPickerFrame.GetColorRGB then
          newR, newG, newB = ColorPickerFrame:GetColorRGB()
        else
          -- Try to get color via individual RGB functions (fallback method)
          if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
            newR = ColorPickerFrame.Content.ColorPicker:GetColorValueTexture() or currentR
            newG = ColorPickerFrame.Content.ColorPicker:GetColorSaturationTexture() or currentG
            newB = ColorPickerFrame.Content.ColorPicker:GetColorBrightnessTexture() or currentB
          else
            newR, newG, newB = currentR, currentG, currentB
          end
        end
      end

      -- Apply color to swatch
      texture:SetColorTexture(newR, newG, newB)

      -- Update color reference values
      r, g, b = newR, newG, newB

      -- Call user callback if provided
      if callback then
        callback(newR, newG, newB)
        -- Save settings immediately
        DM:SaveSettings()
      end
    end

    -- Set up color picker
    -- Modern API
    if ColorPickerFrame.SetupColorPickerAndShow then
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
      -- Set frame attributes directly
      if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
        ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
      end

      -- Set callbacks
      ColorPickerFrame.func = colorPickerCallback
      ColorPickerFrame.cancelFunc = function() colorPickerCallback(true) end
      ColorPickerFrame.opacityFunc = nil
      ColorPickerFrame.hasOpacity = false
      ColorPickerFrame.previousValues = { r = r, g = g, b = b }

      -- Show the frame
      ColorPickerFrame:Show()
    end
  end)

  swatch.GetColor = function() return r, g, b end
  swatch.SetColor = function(_, newR, newG, newB)
    r, g, b = newR, newG, newB
    texture:SetColorTexture(r, g, b, 1)
  end

  return swatch
end

-- Function to initialize the module
function UIColorPicker:Initialize()
  DM:DebugMsg("ColorPicker module initialized")
  -- Make the CreateColorSwatch function available directly on DM
  DM.CreateColorSwatch = function(self, ...) return UIColorPicker:CreateColorSwatch(...) end
end

-- Return the module
return UIColorPicker
