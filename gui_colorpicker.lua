-- DotMaster gui_colorpicker.lua
-- Enhanced Color picker functionality with favorite colors support

local DM = DotMaster
DotMaster_ColorPicker = {}
local colorpicker = DotMaster_ColorPicker

-- Default favorite colors (10 slots)
local DEFAULT_FAVORITE_COLORS = {
  { 1.0, 0.0,  0.0 }, -- Red
  { 0.0, 1.0,  0.0 }, -- Green
  { 0.0, 0.0,  1.0 }, -- Blue
  { 1.0, 1.0,  0.0 }, -- Yellow
  { 1.0, 0.0,  1.0 }, -- Magenta
  { 0.0, 1.0,  1.0 }, -- Cyan
  { 1.0, 0.5,  0.0 }, -- Orange
  { 0.5, 0.0,  1.0 }, -- Purple
  { 1.0, 0.75, 0.8 }, -- Pink
  { 0.5, 0.5,  0.5 }, -- Gray
}

-- Track the favorites panel
local favoritesPanel = nil

-- Initialize favorite colors from saved data or defaults
function colorpicker.InitializeFavoriteColors()
  if not DotMasterDB then
    DotMasterDB = {}
  end

  if not DotMasterDB.favoriteColors then
    DotMasterDB.favoriteColors = {}
    -- Copy default colors
    for i, color in ipairs(DEFAULT_FAVORITE_COLORS) do
      DotMasterDB.favoriteColors[i] = { color[1], color[2], color[3] }
    end
  end

  return DotMasterDB.favoriteColors
end

-- Auto-save favorite colors to database
function colorpicker.AutoSaveFavoriteColors()
  if DotMasterDB and DotMasterDB.favoriteColors then
    -- Data is already in DotMasterDB, just ensure it's saved
    DM:SaveSettings()
  end
end

-- Enhanced color swatch creation with favorite colors support
function colorpicker.CreateColorSwatch(parent, r, g, b, callback, options)
  options = options or {}
  local swatchSize = options.size or 24
  local showFavorites = options.showFavorites ~= false -- Default to true

  local swatch = CreateFrame("Button", nil, parent)
  swatch:SetSize(swatchSize, swatchSize)

  -- Create border for better visibility
  local border = swatch:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  border:SetColorTexture(0.1, 0.1, 0.1, 1)

  -- Create a texture for the color with slight inner border
  local texture = swatch:CreateTexture(nil, "ARTWORK")
  texture:SetPoint("TOPLEFT", 2, -2)
  texture:SetPoint("BOTTOMRIGHT", -2, 2)
  texture:SetColorTexture(r, g, b, 1)

  -- Add highlight/tooltip on hover
  swatch:SetScript("OnEnter", function(self)
    border:SetColorTexture(0.3, 0.3, 0.3, 1)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Color Values")
    GameTooltip:AddLine("R: " .. math.floor(r * 255) .. " G: " .. math.floor(g * 255) .. " B: " .. math.floor(b * 255), 1,
      1, 1)
    GameTooltip:AddLine("Click to change color", 0.7, 0.7, 0.7)
    if showFavorites then
      GameTooltip:AddLine("Enhanced picker with favorites", 0.5, 0.8, 1.0)
    end
    GameTooltip:Show()
  end)

  swatch:SetScript("OnLeave", function()
    border:SetColorTexture(0.1, 0.1, 0.1, 1)
    GameTooltip:Hide()
  end)

  -- Enhanced color picker with favorites
  swatch:SetScript("OnClick", function()
    if showFavorites then
      colorpicker.ShowEnhancedColorPicker(r, g, b, function(newR, newG, newB)
        -- Update swatch
        texture:SetColorTexture(newR, newG, newB, 1)
        r, g, b = newR, newG, newB

        -- Call user callback
        if callback then
          callback(newR, newG, newB)
        end
      end)
    else
      -- Use standard color picker
      colorpicker.ShowStandardColorPicker(r, g, b, function(newR, newG, newB)
        -- Update swatch
        texture:SetColorTexture(newR, newG, newB, 1)
        r, g, b = newR, newG, newB

        -- Call user callback
        if callback then
          callback(newR, newG, newB)
        end
      end)
    end
  end)

  -- Public methods
  swatch.GetColor = function() return r, g, b end
  swatch.SetColor = function(_, newR, newG, newB)
    r = tonumber(newR) or r
    g = tonumber(newG) or g
    b = tonumber(newB) or b
    texture:SetColorTexture(r, g, b, 1)
  end

  return swatch
end

-- Create favorites panel that attaches to ColorPickerFrame
function colorpicker.CreateFavoritesPanel(callback)
  if not ColorPickerFrame then
    return
  end

  -- Clean up existing panel if it exists
  if favoritesPanel then
    favoritesPanel:Hide()
    favoritesPanel:SetParent(nil)
    favoritesPanel = nil
  end

  -- Initialize favorite colors
  local favoriteColors = colorpicker.InitializeFavoriteColors()

  -- Create favorites panel as a simple frame (no template) to match ColorPickerFrame aesthetic
  favoritesPanel = CreateFrame("Frame", "DotMasterFavoritesPanel", ColorPickerFrame)

  -- Get ColorPickerFrame dimensions and position
  local pickerWidth = ColorPickerFrame:GetWidth()
  local panelHeight = 100 -- Reduced height for cleaner look

  favoritesPanel:SetSize(pickerWidth, panelHeight)
  favoritesPanel:SetFrameLevel(ColorPickerFrame:GetFrameLevel() + 1)

  -- Position below ColorPickerFrame instead of above
  favoritesPanel:SetPoint("TOP", ColorPickerFrame, "BOTTOM", 0, 0)

  -- Create dark transparent background to match ColorPickerFrame
  local bg = favoritesPanel:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.8) -- Dark transparent background like ColorPickerFrame

  -- Enable mouse
  favoritesPanel:EnableMouse(true)

  -- Favorite colors title - styled to match the gold "Color Picker" title
  local favoritesLabel = favoritesPanel:CreateFontString(nil, "OVERLAY", DM:GetExpresswayFont("GameFontNormal"))
  favoritesLabel:SetPoint("TOP", favoritesPanel, "TOP", 0, -12)
  favoritesLabel:SetText("Favorite Colors")
  favoritesLabel:SetTextColor(1, 0.82, 0, 1) -- Gold color to match WoW UI

  -- Make the favorites panel draggable by clicking on the title
  favoritesPanel:SetMovable(true)
  favoritesPanel:EnableMouse(true)

  -- Create an invisible button over the title area for dragging
  local titleButton = CreateFrame("Button", nil, favoritesPanel)
  titleButton:SetPoint("TOPLEFT", favoritesLabel, "TOPLEFT", -50, 5)
  titleButton:SetPoint("BOTTOMRIGHT", favoritesLabel, "BOTTOMRIGHT", 50, -5)
  titleButton:EnableMouse(true)
  titleButton:RegisterForDrag("LeftButton")

  -- Handle dragging - move both panels together
  titleButton:SetScript("OnDragStart", function()
    -- Start moving the ColorPickerFrame (which will move the favorites panel with it since it's a child)
    if ColorPickerFrame:IsMovable() then
      ColorPickerFrame:StartMoving()
    else
      -- If ColorPickerFrame isn't movable, make it movable temporarily
      ColorPickerFrame:SetMovable(true)
      ColorPickerFrame:StartMoving()
    end
  end)

  titleButton:SetScript("OnDragStop", function()
    ColorPickerFrame:StopMovingOrSizing()
  end)

  -- Visual feedback on hover
  titleButton:SetScript("OnEnter", function()
    favoritesLabel:SetTextColor(1, 1, 0.5, 1) -- Lighter gold on hover
    SetCursor("Interface\\CURSOR\\UI-Cursor-Move")
  end)

  titleButton:SetScript("OnLeave", function()
    favoritesLabel:SetTextColor(1, 0.82, 0, 1) -- Back to normal gold
    SetCursor(nil)
  end)

  -- Create favorite color swatches
  local favoriteSwatches = {}
  local swatchSize = 20 -- Slightly smaller for cleaner look
  local swatchSpacing = 24
  local swatchesPerRow = 5
  local totalWidth = (swatchesPerRow * swatchSpacing) - (swatchSpacing - swatchSize)
  local startX = -(totalWidth / 2) + (swatchSize / 2)

  for i = 1, 10 do
    local row = math.floor((i - 1) / swatchesPerRow)
    local col = (i - 1) % swatchesPerRow

    local favoriteFrame = CreateFrame("Button", nil, favoritesPanel)
    favoriteFrame:SetSize(swatchSize, swatchSize)
    favoriteFrame:SetPoint("TOP", favoritesLabel, "BOTTOM",
      startX + (col * swatchSpacing), -8 - (row * 28))

    -- Simple dark border like ColorPickerFrame elements
    local favoriteBorder = favoriteFrame:CreateTexture(nil, "BACKGROUND")
    favoriteBorder:SetAllPoints()
    favoriteBorder:SetColorTexture(0.2, 0.2, 0.2, 1) -- Subtle dark border

    -- Color texture with small inset
    local favoriteTexture = favoriteFrame:CreateTexture(nil, "ARTWORK")
    favoriteTexture:SetPoint("TOPLEFT", 1, -1)
    favoriteTexture:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Set color from saved favorites
    local color = favoriteColors[i]
    if color then
      favoriteTexture:SetColorTexture(color[1], color[2], color[3], 1)
    else
      favoriteTexture:SetColorTexture(0.3, 0.3, 0.3, 1) -- Darker default color
    end

    -- Subtle hover effects
    favoriteFrame:SetScript("OnEnter", function()
      favoriteBorder:SetColorTexture(0.4, 0.4, 0.4, 1) -- Lighter border on hover
      GameTooltip:SetOwner(favoriteFrame, "ANCHOR_RIGHT")
      GameTooltip:SetText("Favorite Color " .. i)
      if color then
        GameTooltip:AddLine("RGB: " .. math.floor(color[1] * 255) .. ", " ..
          math.floor(color[2] * 255) .. ", " .. math.floor(color[3] * 255), 1, 1, 1)
      end
      GameTooltip:AddLine("Left-click: Use color", 0.7, 0.7, 0.7)
      GameTooltip:AddLine("Right-click: Save current color", 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)

    favoriteFrame:SetScript("OnLeave", function()
      favoriteBorder:SetColorTexture(0.2, 0.2, 0.2, 1) -- Back to normal border
      GameTooltip:Hide()
    end)

    -- Click handlers
    favoriteFrame:SetScript("OnClick", function(self, button)
      if button == "LeftButton" then
        -- Use this favorite color
        if color then
          -- Set color in ColorPickerFrame
          if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
            ColorPickerFrame.Content.ColorPicker:SetColorRGB(color[1], color[2], color[3])
          elseif ColorPickerFrame.SetColorRGB then
            ColorPickerFrame:SetColorRGB(color[1], color[2], color[3])
          end

          -- Call the callback immediately
          if callback then
            callback(color[1], color[2], color[3])
          end
        end
      elseif button == "RightButton" then
        -- Get current color from ColorPickerFrame
        local currentR, currentG, currentB
        if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
          currentR, currentG, currentB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
        elseif ColorPickerFrame.GetColorRGB then
          currentR, currentG, currentB = ColorPickerFrame:GetColorRGB()
        else
          currentR, currentG, currentB = 1, 1, 1 -- Default to white
        end

        -- Save current color to this slot
        favoriteColors[i] = { currentR, currentG, currentB }
        favoriteTexture:SetColorTexture(currentR, currentG, currentB, 1)
        color = favoriteColors[i] -- Update local reference

        -- Auto-save to database
        colorpicker.AutoSaveFavoriteColors()
      end
    end)

    favoriteFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    favoriteSwatches[i] = favoriteFrame
  end

  favoritesPanel:Show()
end

-- Show enhanced color picker with favorites
function colorpicker.ShowEnhancedColorPicker(r, g, b, callback)
  -- Store the callback for later use
  colorpicker.currentCallback = callback

  -- Position the ColorPickerFrame BEFORE showing it to prevent weird loading
  ColorPickerFrame:ClearAllPoints()

  -- Check for combination dialog first (highest priority)
  local combinationDialog = _G["DotMasterCombinationDialog"]
  if combinationDialog and combinationDialog:IsShown() then
    -- Position to the right of the combination dialog
    ColorPickerFrame:SetPoint("TOPLEFT", combinationDialog, "TOPRIGHT", 10, 0)
    -- Check for any other DotMaster dialogs that might be open
  elseif DM and DM.GUI and DM.GUI.combinationDialog and DM.GUI.combinationDialog:IsShown() then
    -- Alternative reference to combination dialog
    ColorPickerFrame:SetPoint("TOPLEFT", DM.GUI.combinationDialog, "TOPRIGHT", 10, 0)
    -- Check if main DotMaster GUI exists and is shown
  elseif DM and DM.GUI and DM.GUI.frame and DM.GUI.frame:IsShown() then
    -- Position to the right top of the main GUI, aligned with favorites panel
    ColorPickerFrame:SetPoint("TOPLEFT", DM.GUI.frame, "TOPRIGHT", 10, 0)
  else
    -- Fallback to screen center if main GUI not available
    ColorPickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end

  -- Set up the color picker
  local info = {
    r = r,
    g = g,
    b = b,
    swatchFunc = function()
      local newR, newG, newB = ColorPickerFrame:GetColorRGB()
      if colorpicker.currentCallback then
        colorpicker.currentCallback(newR, newG, newB)
      end
    end,
    cancelFunc = function()
      -- Restore original color if canceled
      if colorpicker.currentCallback then
        colorpicker.currentCallback(r, g, b)
      end
    end
  }

  -- Show the color picker
  if ColorPickerFrame.SetupColorPickerAndShow then
    ColorPickerFrame:SetupColorPickerAndShow(info)
  else
    -- Legacy method
    ColorPickerFrame.func = info.swatchFunc
    ColorPickerFrame.cancelFunc = info.cancelFunc
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Show()
  end

  -- Create or update favorites panel after the ColorPickerFrame is shown
  colorpicker.CreateFavoritesPanel(callback)
end

-- Standard color picker (fallback/compatibility)
function colorpicker.ShowStandardColorPicker(r, g, b, callback)
  if not ColorPickerFrame then
    return
  end

  local currentR, currentG, currentB = r, g, b

  local function colorPickerCallback(restore)
    local newR, newG, newB

    if restore then
      newR, newG, newB = currentR, currentG, currentB
    else
      -- Get selected color from color picker
      if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
        newR, newG, newB = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
      elseif ColorPickerFrame.GetColorRGB then
        newR, newG, newB = ColorPickerFrame:GetColorRGB()
      else
        newR, newG, newB = currentR, currentG, currentB
      end
    end

    -- Safety checks
    newR = tonumber(newR) or currentR
    newG = tonumber(newG) or currentG
    newB = tonumber(newB) or currentB

    if callback then
      callback(newR, newG, newB)
    end
  end

  -- Modern API
  if ColorPickerFrame.SetupColorPickerAndShow then
    local info = {
      swatchFunc = colorPickerCallback,
      cancelFunc = function() colorPickerCallback(true) end,
      r = r,
      g = g,
      b = b,
      opacity = 1,
      hasOpacity = false
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
  else
    -- Legacy API
    ColorPickerFrame.func = colorPickerCallback
    ColorPickerFrame.cancelFunc = function() colorPickerCallback(true) end
    ColorPickerFrame.opacityFunc = nil
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = { r = r, g = g, b = b }

    if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.SetColorRGB then
      ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
    end
    ColorPickerFrame:Show()
  end
end

-- Utility function to convert hex to RGB
function colorpicker.HexToRGB(hex)
  hex = hex:gsub("#", "")
  if hex:len() == 6 then
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
  end
  return 1, 1, 1 -- Default to white if invalid
end

-- Utility function to convert RGB to hex
function colorpicker.RGBToHex(r, g, b)
  return string.format("#%02x%02x%02x",
    math.floor(r * 255),
    math.floor(g * 255),
    math.floor(b * 255))
end

-- Expose functions globally
_G["DotMaster_CreateColorSwatch"] = colorpicker.CreateColorSwatch
_G["DotMaster_ShowEnhancedColorPicker"] = colorpicker.ShowEnhancedColorPicker
_G["DotMaster_ShowStandardColorPicker"] = colorpicker.ShowStandardColorPicker
