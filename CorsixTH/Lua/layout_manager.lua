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

--! This abstract class is the parent of all layout managers. 
-- It can't be used as a layout manager.
class "LayoutManager"

---@type LayoutManager
local LayoutManager = _G["LayoutManager"]

--!param top_left_x (integer) The x coordinate for a layout manager's components area's top left corner.
--!param top_left_y (integer) The y coordinate for a layout manager's components area's top left corner.
--!param width (integer) The width of the layout manager's components area.
--!param height (integer) The height of the layout manager's components area.
function LayoutManager:LayoutManager(x, y, width, height)
  self.name = nil
  self.top_left_x = x
  self.top_left_y = y
  self.width = width
  self.height = height

  self.components = {}
end

--! This function is responsible for determining where components will be located.
-- All LayoutManagers must override this function to return appropriate component positions 
-- for the layout they implement.
function LayoutManager:getAddCoardinates(width, height)
  return 0, 0
end

--! This function should be called by all the Window class's component adding methods.
-- because this is the function which gives a LayoutManager control over the layout of
-- a window's/layout panel's components by returning what the location of each component 
-- should be.
--!param width (integer) The width of the component being added to the Window.
--!param height (integer) The height of the component being added to the Window.
--!return x (integer) The x coardinate for where the component should be located.
--!return y (integer) The y coardinate for where the component should be located.
function LayoutManager:add(width, height)
  local x, y = self:getAddCoardinates(width, height)
  table.insert(self.components, {x = x, y = y, width = width, height = height})
  return x, y
end

--! This function must be called when all the components are removed
-- from a layout manager's panel and its sub panels.
function LayoutManager:removeAll()
  self.components = {}
  self.layout_panels = {}
end
