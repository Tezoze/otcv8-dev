-- @docclass
g_tooltip = {}

-- private variables
local toolTipLabel
local toolTipLabel2
local currentHoveredWidget

-- private functions
local function moveToolTip(first)
  if not first and (not toolTipLabel or not toolTipLabel:isVisible() or toolTipLabel:getOpacity() < 0.1) then
    return
  end

  local pos = g_window.getMousePosition()
  local windowSize = g_window.getSize()
  local labelSize = toolTipLabel:getSize()

  pos.x = pos.x + 1
  pos.y = pos.y + 1

  -- flip horizontally if too close to right edge
  if windowSize.width - (pos.x + labelSize.width) < 10 then
    pos.x = pos.x - labelSize.width - 10
  else
    pos.x = pos.x + 10
  end

  -- calculate total height (first + second label + 2px gap)
  local totalHeight = labelSize.height + 2
  if toolTipLabel2 and toolTipLabel2:isVisible() then
    totalHeight = totalHeight + toolTipLabel2:getSize().height
  end

  -- flip vertically if too close to bottom
  if windowSize.height - (pos.y + totalHeight) < 10 then
    pos.y = pos.y - totalHeight - 10
  else
    pos.y = pos.y + 10
  end

  toolTipLabel:setPosition(pos)

  if toolTipLabel2 and toolTipLabel2:isVisible() then
    toolTipLabel2:setPosition({ x = pos.x, y = pos.y + labelSize.height + 2 })
  end
end

local function onWidgetHoverChange(widget, hovered)
  if hovered then
    if widget.tooltip and not g_mouse.isPressed() then
      g_tooltip.display(widget.tooltip)
      currentHoveredWidget = widget
    end
  elseif widget == currentHoveredWidget then
    g_tooltip.hide()
    currentHoveredWidget = nil
  end
end

local function onWidgetStyleApply(widget, styleName, styleNode)
  if styleNode.tooltip then
    widget.tooltip = styleNode.tooltip
  end
end

-- public functions
function g_tooltip.init()
  connect(UIWidget, {
    onStyleApply  = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  addEvent(function()
    toolTipLabel = g_ui.createWidget('UILabel', rootWidget)
    toolTipLabel:setId('toolTip')
    toolTipLabel:setBackgroundColor('#111111cc')
    toolTipLabel:setTextAlign(AlignCenter)
    toolTipLabel:hide()

    toolTipLabel2 = g_ui.createWidget('UILabel', rootWidget)
    toolTipLabel2:setId('toolTip')
    toolTipLabel2:setBackgroundColor('#111111cc')
    toolTipLabel2:setTextAlign(AlignCenter)
    toolTipLabel2:hide()
  end)
end

function g_tooltip.terminate()
  disconnect(UIWidget, {
    onStyleApply  = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  if toolTipLabel then
    toolTipLabel:destroy()
    toolTipLabel = nil
  end
  if toolTipLabel2 then
    toolTipLabel2:destroy()
    toolTipLabel2 = nil
  end

  currentHoveredWidget = nil
end

function g_tooltip.display(text)
  if not text or text:len() == 0 or not toolTipLabel then return end

  -- split first line / rest
  local firstLine = text:match("^(.-)\n") or text
  local rest      = text:match("\n(.*)") or ""

  -- rarity detection anywhere in the whole tooltip text
  local lower = text:lower()
  local color = "#ffffff"

  if lower:find("mythic") then
    color = "#ff6600"        -- change if you prefer another mythic color
  elseif lower:find("legendary") then
    color = "#ff8000"
  elseif lower:find("epic") then
    color = "#a335ee"
  elseif lower:find("rare") then
    color = "#0070dd"
  end

  -- first label (item name / first line)
  toolTipLabel:setText(firstLine)
  toolTipLabel:setColor(color)
  toolTipLabel:resizeToText()
  toolTipLabel:resize(toolTipLabel:getWidth() + 4, toolTipLabel:getHeight() + 4)

  -- second label (description, bonuses, etc.)
  if rest:len() > 0 then
    toolTipLabel2:setText(rest)
    toolTipLabel2:setColor("#ffffff")
    toolTipLabel2:resizeToText()
    toolTipLabel2:resize(toolTipLabel2:getWidth() + 4, toolTipLabel2:getHeight() + 4)
    toolTipLabel2:show()
    toolTipLabel2:raise()
    g_effects.fadeIn(toolTipLabel2, 100)
  else
    toolTipLabel2:hide()
  end

  -- make both labels same width
  local maxW = math.max(toolTipLabel:getWidth(), toolTipLabel2:getWidth())
  toolTipLabel:resize(maxW, toolTipLabel:getHeight())
  if rest:len() > 0 then
    toolTipLabel2:resize(maxW, toolTipLabel2:getHeight())
  end

  toolTipLabel:show()
  toolTipLabel:raise()
  g_effects.fadeIn(toolTipLabel, 100)

  moveToolTip(true)
  connect(rootWidget, { onMouseMove = moveToolTip })
end

function g_tooltip.hide()
  g_effects.fadeOut(toolTipLabel, 100)
  if toolTipLabel2 and toolTipLabel2:isVisible() then
    g_effects.fadeOut(toolTipLabel2, 100)
  end
  disconnect(rootWidget, { onMouseMove = moveToolTip })
end

-- UIWidget extensions
function UIWidget:setTooltip(text)   self.tooltip = text end
function UIWidget:removeTooltip()    self.tooltip = nil end
function UIWidget:getTooltip()       return self.tooltip end

-- init & terminate
g_tooltip.init()
connect(g_app, { onTerminate = g_tooltip.terminate })
