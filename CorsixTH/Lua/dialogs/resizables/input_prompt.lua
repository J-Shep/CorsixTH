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

--! Class for error report window.
class "UIInputPrompt" (UIResizable)

---@type UIInputPrompt
local UIInputPrompt = _G["UIInputPrompt"]

function UIInputPrompt:UIInputPrompt(ui, message, ok_callback, gmatch_string)
  self.ok_callback = ok_callback
  self.gmatch_string = gmatch_string
  self:UIResizable(ui, 400, 62, {red = 154, green = 146, blue = 198})

  self.esc_closes = true
  self.on_top = true
  self:setDefaultPosition(0.5, 0.25)

  local lm = self:setMainLayout(LineLayout, true, 5)
  self:addLabel(message, nil, nil, nil, 8)
  self.text_box = self:addTextBox(nil, nil, 400, 12, true)
  lm = self:addLayoutPanel("main", "buttons_panel", self.width, 50, LineLayout, false, 10)
  self:addButton("Cancel", "", nil, nil, 120, 30, function() self:close() end)
  self:addButton("OK", "", nil, nil, 120, 30, self.okButton)
end

function UIInputPrompt:okButton()
  self:close()
  if not self.gmatch_string then
    self.ok_callback(self.text_box:getText())
  else
    self.ok_callback(self.text_box:getText():gmatch(self.gmatch_string))
  end
end
