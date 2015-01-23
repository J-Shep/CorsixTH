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

--! Choose File Window
class "UIChooseFile" (UIFileBrowser)

---@type UIChooseFile
local UIChooseFile = _G["UIChooseFile"]

function UIChooseFile:UIChooseFile(ui, mode, title, found_callback, close_callback, trees_label, root_dir, extension_filter)
  trees_label = trees_label or _S.folders_window.savegames_label
  root_dir = root_dir or ui.app.savegame_dir
  extension_filter = extension_filter or ".sav"
  self.chosen = nil
  self.found_callback = found_callback
  self.abort_callback = close_callback

  self.treenode = FilteredFileTreeNode(root_dir, extension_filter)
  self.treenode.label = trees_label
  self:UIFileBrowser(ui, mode, title, 295, self.treenode, true)
  -- The most probable preference of sorting is by date - what you played last
  -- is the thing you want to play soon again.
  self.control:sortByDate()
end

function UIChooseFile:choiceMade(name, path)
  self.chosen_name = name
  self.chosen_path = path
  if self.found_callback then
    self.found_callback(path, name)
  end
  self:close()
end

function UIChooseFile:OnCloseWindow()
  if self.close_callback then
    self:close_callback()
  end
end
