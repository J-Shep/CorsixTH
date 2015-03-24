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
class "UIReportProblem" (UIResizable)

---@type UIReportProblem
local UIReportProblem = _G["UIReportProblem"]

local _, _, send, save = dofile("send_report")

local col_bg = {
  red = 154,
  green = 146,
  blue = 198,
}

function UIReportProblem:updateSavedContactInfo()
  if self.save_contact_tbutt.toggled then
    TheApp.config.contact_info = self.contact_details_tbox:getText()
  else
    TheApp.config.contact_info = nil
  end
  TheApp:saveConfig()
end

function UIReportProblem:attachFile(browser_title, attachments, list_tbox, attached_name, tree_name, root_dir, extension_filter)
  self:addWindow(UIChooseFile(self.ui,
                              "menu",
                              browser_title,
                              function(chosen_files_path, name)
                                table.insert(attachments, {path = chosen_files_path, attach_name = attached_name or chosen_files_path:match("[^" .. package.config:sub(1, 1) .. "]+$")})
                                if list_tbox:getText() == "" then
                                  list_tbox:setText(name)
                                else
                                  list_tbox:setText(list_tbox:getText() .. " " .. name)
                                end
                              end,
                              nil,
                              tree_name,
                              root_dir,
                              extension_filter))
end

function UIReportProblem:UIReportProblem(ui)
  self.attached_screenshots = {}
  self.attached_saves = {}

  self:UIResizable(ui, 400, 480, col_bg)

  self.esc_closes = true
  self.on_top = true
  self:setDefaultPosition(0.5, 0.25)

  local h1_font = TheApp.gfx:loadFont("QData", "Font04V")
  local h2_font = TheApp.gfx:loadFont("QData", "Font02V")
  local black_font = TheApp.gfx:loadFont("QData", "Font00V")

  local lm = self:setMainLayout(LineLayout, true, 5)
  self:addLabel(_S.report_problem.title, nil, nil, nil, 10, false, h1_font, "center")

  self:addLabel(_S.report_problem.explain, nil, nil, nil, 8, false, h2_font)
  self.explain_tbox = self:addTextBox(nil, nil, 400, 35, true)
  self:addLabel(_S.report_problem.how_to_reproduce, nil, nil, nil, 8, false, h2_font)
  self.reproduce_tbox = self:addTextBox(nil, nil, 400, 76, true)
  self:addLabel(_S.report_problem.screenshots, nil, nil, nil, 8, false, h2_font)
  self.attached_screenshots_tbox = self:addTextBox(nil, nil, 400, 15, true)

  lm = self:addLayoutPanel("main", "attached_screenshots_buttons", self.width, 15, LineLayout, false, 2)
  self.attach_screenshot_butt = self:addButton(_S.report_problem.attach, "", nil, nil, 198, 15, function()
                                                                                                  self:attachFile(_S.report_problem.attach_screenshot,
                                                                                                                  self.attached_screenshots,
                                                                                                                  self.attached_screenshots_tbox,
                                                                                                                  nil,
                                                                                                                  _S.folders_window.screenshots_label,
                                                                                                                  ui.app.screenshot_dir,
                                                                                                                  ".bmp")
                                                                                                end)
  self.detach_screenshots_butt = self:addButton(_S.report_problem.detach_all, "", nil, nil, 199, 15, function()
                                                                                                       self.attached_screenshots = {}
                                                                                                       self.attached_screenshots_tbox:setText("")
                                                                                                     end)
  self.layout = "main"
  self:addLabel(_S.report_problem.saves, nil, nil, nil, 8, false, h2_font)
  self.attached_saves_tbox = self:addTextBox(nil, nil, 400, 15, true)
  self.save_has_problem_tbutt = self:addToggleButton(_S.report_problem.toggle_has_problem, 220, _S.shared.yes, _S.shared.no, "", nil, nil, 60, 15)
  lm = self:addLayoutPanel("main", "attach_saved_game_buttons", self.width, 25, LineLayout, false, 2)
  self.attach_save_butt = self:addButton(_S.report_problem.attach, "", nil, nil, 200, 15, function()
                                                                                            self:attachFile(_S.report_problem.attach_save,
                                                                                                            self.attached_saves,
                                                                                                            self.attached_saves_tbox,
                                                                                                            "problem.sav",
                                                                                                            _S.folders_window.savegames_label)
                                                                                          end)
  self.detach_saved_games_butt = self:addButton(_S.report_problem.detach, "", nil, nil, 195, 15, function()
                                                                                                   self.attached_saves = {}
                                                                                                   self.attached_saves_tbox:setText("")
                                                                                                 end)
  self.layout = "main"
  self:addLabel(_S.report_problem.prefer_manual_report, nil, nil, nil, 8, false, h2_font)
  self:addLabel(_S.report_problem.please_open_github_issue, nil, nil, 400, 30, true)
  self:addLabel("github.com/CorsixTH/CorsixTH/issues", nil, nil, nil, 8, false, black_font, "center")
  self:addLabel(_S.report_problem.if_not_going_to_manually_report, nil, nil, nil, 8, false, h2_font)
  self:addLabel(_S.report_problem.please_provide_contact_details, nil, nil, nil, 32, true)
  self.contact_details_tbox = self:addTextBox(nil, nil, 400, 15)
  self.save_contact_tbutt = self:addToggleButton(_S.ui_report_error.save_contact_info, 220, _S.shared.yes, _S.shared.no, "", nil, nil, 60, 15)

  if TheApp.config.contact_info then
    self.save_contact_tbutt:toggle()
    self.contact_details_tbox:setText(TheApp.config.contact_info)
  end

  lm = self:addLayoutPanel("main", "report_buttons", self.width, 30, LineLayout, false, 2)
  lm:addSpace(self.width - (lm.spacing * 3) - 360 - 2)
  self:addButton(_S.ui_report_error.discard, "", nil, nil, 120, 30, function()
                                                                      self:close()
                                                                      self:updateSavedContactInfo()
                                                                    end)
  self:addButton(_S.ui_report_error.save, "", nil, nil, 120, 30, self.saveProblemReport)
  self:addButton(_S.ui_report_error.send, "", nil, nil, 120, 30, self.sendProblemReport)
end

function UIReportProblem:attachSavesFromBeforeProblem()
  local attached_saves_path = self.attached_saves[1].path
  local save_info_table = LoadTableFromFile(TheApp.save_info_file)
  local problems_world_id = save_info_table[attached_saves_path].world_id

  local find_nearest_problem = self.save_has_problem_tbutt.toggled
  local nearest_problem = {date = -1}

  -- Get the chosen saved game's date:
  local attached_saves_date, error = lfs.attributes(attached_saves_path, "modification")
  if error then
    TheApp:announceError(error)
    return
  end

  -- Search for saved games from before the chosen saved game for its world:
  for path, info in pairs(save_info_table) do
    if info.world_id == problems_world_id then
      local saves_date, error = lfs.attributes(path, "modification")
      if error then
        TheApp:announceError(error)
        return
      end
      if saves_date < attached_saves_date then
        table.insert(self.attached_saves, {path = path, attach_name = saves_date .. ".sav"})
        if find_nearest_problem and saves_date > nearest_problem.date then
          nearest_problem.date = saves_date
          nearest_problem.path = path
          nearest_problem.index = #self.attached_saves
        end
      end
    end
  end

  -- Name the saved game nearest the problem "before.sav":
  if find_nearest_problem then
    self.attached_saves[nearest_problem.index].attach_name = "before.sav"
  else
    self.attached_saves[1].attach_name = "before.sav"
  end
end

function UIReportProblem:saveProblemReport()
  self:close()
  self:updateSavedContactInfo()
  self:attachSavesFromBeforeProblem()
  save(self.explain_tbox:getText(),
       self.reproduce_tbox:getText(),
       self.attached_screenshots,
       self.attached_saves)
end

function UIReportProblem:sendProblemReport()
  self:close()
  self:updateSavedContactInfo()
  self:attachSavesFromBeforeProblem()
  send(self.contact_details_tbox:getText(),
       self.explain_tbox:getText(),
       self.reproduce_tbox:getText(),
       self.attached_screenshots,
       self.attached_saves)
end
