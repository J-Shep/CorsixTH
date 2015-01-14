--[[ Copyright (c) 2015 Joseph Sheppard

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

--! This LayoutManager can arrange components in either a vertical or horizontal line.
class "LineLayout" (LayoutManager)

---@type LineLayout
local LineLayout = _G["LineLayout"]

--!param area (Window/Table) The Window object/table provided must have these
-- fields for the area the LayoutManager will be for: x, y, width & height.
--!param vertical (boolean) Arrange components vertically instead of horizontally?
--!param spacing (integer) The spacing between added components. Specified in pixels.
function LineLayout:LineLayout(x, y, width, height, vertical, spacing)
  self:LayoutManager(x, y, width, height)
  self.vertical = vertical
  self.spacing = spacing
end

--! Overrides LayoutManager:getAddCoardinates(): This function is
-- responsible for determining where components will be located.
function LineLayout:getAddCoardinates(width, height)
  if #self.components == 0 then
    return self.top_left_x, self.top_left_y
  else
    local previous_component = self.components[#self.components]
    if self.vertical then
      return previous_component.x, 
             previous_component.y + previous_component.height + self.spacing
    else
      return previous_component.x + previous_component.width + self.spacing, 
             previous_component.y
    end
  end
end

--! Adds an invisible space component to the layout's window/panel.
--!param size (integer) Height if components are being arranged vertically
-- otherwise width.
function LineLayout:addSpace(size)
  local width = self.vertical and 0 or size
  local height = self.vertical and size or 0
  self:add(width, height)
end

