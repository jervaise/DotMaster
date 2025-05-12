-- DotMaster gui_colorpicker.lua
-- Color picker functionality

local DM = DotMaster
DotMaster_ColorPicker = {}
local colorpicker = DotMaster_ColorPicker

-- Module initialization message using new debug system
if DM.Debug then
  DM.Debug:Loading("Color picker module loaded")
end

-- Helper function for color picker
function colorpicker.CreateColorSwatch(parent, r, g, b, callback)
  -- Use the proper debug function from the new system
  if DM.Debug then
    DM.Debug:UI("CreateColorSwatch ENTRY - R:%.2f G:%.2f B:%.2f", r or 0, g or 0, b or 0)
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
    if DM.Debug then
      DM.Debug:UI("Color swatch clicked")
    end

    -- Check if ColorPickerFrame exists
    if not ColorPickerFrame then
      if DM.Debug then
        DM.Debug:Error("ColorPickerFrame does not exist!")
      end
      return
    end

    if DM.Debug then
      DM.Debug:UI("Setting up ColorPickerFrame functions")
    end

    -- Store current color for cancelFunc
    local currentR, currentG, currentB = r, g, b

    -- Modern color picker setup
    local function colorPickerCallback(restore)
      local newR, newG, newB

      if restore then
        -- User canceled, restore original color
        if DM.Debug then
          DM.Debug:UI("Color canceled, reverting to original")
        end
        newR, newG, newB = currentR, currentG, currentB
      else
        -- Get selected color from color picker
        if DM.Debug then
          DM.Debug:UI("Getting new color from color picker")
        end
        -- Check available APIs for getting color
        if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
          if DM.Debug then
            DM.Debug:UI("Using Content.ColorPicker API")
          end
          newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
        elseif ColorPickerFrame.GetColorRGB then
          if DM.Debug then
            DM.Debug:UI("Using GetColorRGB API")
          end
          newR, newG, newB = ColorPickerFrame:GetColorRGB()
        else
          -- Try to get color via individual RGB functions (fallback method)
          if DM.Debug then
            DM.Debug:UI("Using fallback RGB methods")
          end
          if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
            newR = ColorPickerFrame.Content.ColorPicker:GetColorValueTexture() or currentR
            newG = ColorPickerFrame.Content.ColorPicker:GetColorSaturationTexture() or currentG
            newB = ColorPickerFrame.Content.ColorPicker:GetColorBrightnessTexture() or currentB
          else
            if DM.Debug then
              DM.Debug:UI("Couldn't get color - using defaults")
            end
            newR, newG, newB = currentR, currentG, currentB
          end
        end
      end

      -- Apply color to swatch
      if DM.Debug then
        DM.Debug:UI("Setting texture color to: %.2f, %.2f, %.2f", newR, newG, newB)
      end
      texture:SetColorTexture(newR, newG, newB)

      -- Update color reference values
      r, g, b = newR, newG, newB

      -- Call user callback if provided
      if callback then
        if DM.Debug then
          DM.Debug:UI("Running callback function with %.2f, %.2f, %.2f", newR, newG, newB)
        end
        callback(newR, newG, newB)
        if DM.Debug then
          DM.Debug:UI("Callback completed")
        end
        -- Ensure settings are saved
        if DM.SaveSettings then
          DM:SaveSettings()
        end
      end
    end

    -- Set up color picker
    if DM.Debug then
      DM.Debug:UI("Setting up color picker with color: %.2f, %.2f, %.2f", r, g, b)
    end

    -- Modern API
    if ColorPickerFrame.SetupColorPickerAndShow then
      if DM.Debug then
        DM.Debug:UI("Using SetupColorPickerAndShow API")
      end
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
      if DM.Debug then
        DM.Debug:UI("Using legacy color picker API")
      end

      -- Set frame attributes directly
      if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
        if DM.Debug then
          DM.Debug:UI("Using Content.ColorPicker.SetColorRGB")
        end
        ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
      end

      -- Set callbacks
      ColorPickerFrame.func = colorPickerCallback
      ColorPickerFrame.cancelFunc = function() colorPickerCallback(true) end
      ColorPickerFrame.opacityFunc = nil
      ColorPickerFrame.hasOpacity = false
      ColorPickerFrame.previousValues = { r = r, g = g, b = b }

      -- Show the frame
      if DM.Debug then
        DM.Debug:UI("About to show ColorPickerFrame")
      end
      ColorPickerFrame:Show()
      if DM.Debug then
        DM.Debug:UI("After Show() - IsShown: %s", tostring(ColorPickerFrame:IsShown()))
      end
    end
  end)

  swatch.GetColor = function() return r, g, b end
  swatch.SetColor = function(_, newR, newG, newB)
    r, g, b = newR, newG, newB
    texture:SetColorTexture(r, g, b, 1)
  end

  if DM.Debug then
    DM.Debug:UI("Color swatch created successfully")
  end
  return swatch
end

-- Expose the function globally - reinforce export to ensure it's accessible
_G["DotMaster_CreateColorSwatch"] = colorpicker.CreateColorSwatch
