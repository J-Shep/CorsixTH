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
class "ErrorOccurred" (UIResizable)

---@type ErrorOccurred
local ErrorOccurred = _G["ErrorOccurred"]

local send, save = dofile("send_report")

local col_bg = {
  red = 154,
  green = 146,
  blue = 198,
}

function ErrorOccurred:updateSavedContactInfo()
  if self.save_contact_tbutt.toggled then
    TheApp.config.contact_info = self.contact_details_tbox:getText()
  else
    TheApp.config.contact_info = nil
  end
  TheApp:saveConfig()
end

function ErrorOccurred:ErrorOccurred(ui, error, error_dispatch_type, is_lua_error, after_callback)
  pcall(ui.makeScreenshot, ui, "Players_View")

  self.is_lua_error = is_lua_error
  self.error = error
  self.dispatch_type = error_dispatch_type

  self:UIResizable(ui, 400, 472, col_bg)

  self.esc_closes = true
  self.on_top = true
  self:setDefaultPosition(0.5, 0.25)

  local h1_font = TheApp.gfx:loadFont("QData", "Font04V")
  local h2_font = TheApp.gfx:loadFont("QData", "Font02V")
  local black_font = TheApp.gfx:loadFont("QData", "Font00V")

  local lm = self:setMainLayout(LineLayout, true, 5)
  self:addLabel(_S.ui_report_error.an_error_has_occured, nil, nil, nil, 10, false, h1_font, "center")
  self:addLabel(_S.ui_report_error.apology, nil, nil, nil, 24, true)
  lm:addSpace(10)
  self:addLabel(_S.ui_report_error.how_to_reproduce, nil, nil, nil, 8, false, h2_font)
  self.reproduce_tbox = self:addTextBox(nil, nil, 400, 185, true)
  lm:addSpace(10)
  self:addLabel(_S.ui_report_error.prefer_manual_report, nil, nil, nil, 8, false, h2_font)
  self:addLabel(_S.ui_report_error.please_open_github_issue, nil, nil, 400, 30, true)
  self:addLabel("github.com/CorsixTH/CorsixTH/issues", nil, nil, nil, 8, false, black_font, "center")
  lm:addSpace(10)
  self:addLabel(_S.ui_report_error.if_not_going_to_manually_report, nil, nil, nil, 8, false, h2_font)
  self:addLabel(_S.ui_report_error.please_provide_contact_details, nil, nil, nil, 32, true)
  self.contact_details_tbox = self:addTextBox(nil, nil, 400, 12)
  self.save_contact_tbutt = self:addToggleButton(_S.ui_report_error.save_contact_info, 220, _S.shared.yes, _S.shared.no, "", nil, nil, 60, 15)

  if TheApp.config.contact_info then
    self.save_contact_tbutt:toggle()
    self.contact_details_tbox:setText(TheApp.config.contact_info)
  end

  lm = self:addLayoutPanel("main", "buttons_panel", self.width, 30, LineLayout, false, 2)
  lm:addSpace(self.width - (lm.spacing * 3) - 360 - 2)
  self:addButton(_S.ui_report_error.discard, "", nil, nil, 120, 30, function()
                                                                      self:close()
                                                                      self:updateSavedContactInfo()
                                                                      os.remove(TheApp.screenshot_dir .. "Players_View.bmp")
                                                                      if after_callback then
                                                                        after_callback()
                                                                      end
                                                                    end)
  self:addButton(_S.ui_report_error.save, "", nil, nil, 120, 30, function() self:reportActionButtonUsed(save, after_callback) end)
  self:addButton(_S.ui_report_error.send, "", nil, nil, 120, 30, function() self:reportActionButtonUsed(send, after_callback) end)
end

function ErrorOccurred:reportActionButtonUsed(reportFunction, after_callback)
  self:close()
  self:updateSavedContactInfo()
  reportFunction(self.error,
                 self.dispatch_type,
                 self.reproduce_tbox:getText(),
                 self.contact_details_tbox:getText(),
                 self.is_lua_error)
  if after_callback then
    after_callback()
  end
end
