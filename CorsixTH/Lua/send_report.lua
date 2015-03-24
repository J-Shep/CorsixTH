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

-- This script can't report pre-app errors.
local destination = "<errors@jmail.com>"
local config_path = (TheApp.command_line["config-file"] or ""):match("^(.-)[^".. package.config:sub(1, 1) .."]*$")

local function makeCrashScreenshots(tick_entity)
  local unattached_screenshots = {}

  --1. Player's view screenshot: if the error report dialog
  -- was used before this script was called then it made this screenshot:
  local pcall_worked = nil
  local error = nil
  local screenshot = TheApp.screenshot_dir .. "Players_View.bmp"
  if is_file_unreadable(screenshot) then
    pcall_worked, screenshot, error = pcall(TheApp.ui.makeScreenshot, TheApp.ui, "Players_View")
  end
  if not pcall_worked and not error then
    table.insert(unattached_screenshots, {path = screenshot, attach_name = screenshot:match("[^" .. package.config:sub(1, 1) .. "]+$")})
  end

  --2. Tick entity screenshot:
  if TheApp.world then
    if tick_entity and tick_entity.tile_x and tick_entity.tile_y then
      -- Setup the hospital view for the tick entity screenshot:
      local tile_x_before, tile_y_before = TheApp.ui:centerViewAtTile(tick_entity.tile_x,
                                                                      tick_entity.tile_y)
      for _, window in ipairs(TheApp.ui.windows) do
        window.visible = false
      end

      -- Redraw the hospital & then take this screenshot:
      local worked, error = pcall(TheApp.drawFrame, TheApp)
      if worked then
        pcall_worked, screenshot, error = pcall(TheApp.ui.makeScreenshot, TheApp.ui, "Tick_Entity")
        if pcall_worked and not error then
          table.insert(unattached_screenshots, {path = screenshot, attach_name = screenshot:match("[^" .. package.config:sub(1, 1) .. "]+$")})
        end
      else
        TheApp:announceError(error, false)
      end

      -- Restore the hospital view to the state it was in before this screenshot:
      TheApp.ui:setScreenOffset(tile_x_before, tile_y_before)
      for _, window in ipairs(TheApp.ui.windows) do
        window.visible = true
      end

      -- Delay to prevent screen flicker (for epilepsy players):
      wait(1)
      pcall_worked, error = pcall(TheApp.drawFrame, TheApp)
      if not pcall_worked then
        TheApp:announceError(error, false)
      end
    elseif tick_entity then
      TheApp:announceError("Error: TE tile_x: " .. (tick_entity.tile_x or "nil") .. "," ..
                                     "tile_y: " .. (tick_entity.tile_x or "nil"), false)
    end
  end
  return unattached_screenshots
end

local function findSavedGames(this_coroutine)
  local unattached_saves = {}
  local save_info_table = nil
  if TheApp.save_info_file then
    save_info_table = LoadTableFromFile(TheApp.save_info_file)
  end
  -- Manual search:
  if not TheApp.world.id or not save_info_table then
    TheApp:showWindow(UIConfirmDialog,
                      _S.report_error.manually_locate_save,
                      function()
                        file_chooser = TheApp:showWindow(UIChooseFile,
                                                         "menu",
                                                         _S.report_error.manually_find_latest_save_file_browser,
                                                         function(chosen_files_path)
                                                           table.insert(unattached_saves, {path = chosen_files_path})
                                                           coroutine.resume(this_coroutine)
                                                         end)
                      end,
                      function() coroutine.resume(this_coroutine) end)
    coroutine.yield()
  -- Auto search:
  elseif TheApp.world.id and save_info_table then
    for path, info in pairs(save_info_table) do
      if info and info.world_id == TheApp.world.id then
        table.insert(unattached_saves, {path = path})
      elseif not info then
        TheApp:announceError("NIL info for saved game in save_info.table:" .. path, false)
      end
    end
  end
  return unattached_saves
end

local function renameSavedGames(unattached_saves, tick_entity)
  if not TheApp.save_info_file then
    return
  end

  local new_name = nil
  local most_recent = {index = -1, date = -1}
  local mod_date = nil
  local error = nil
  local save_info_table = LoadTableFromFile(TheApp.save_info_file)

  -- First find out which saved game is the latest:
  for i, attachment in ipairs(unattached_saves) do
    mod_date, error = lfs.attributes(attachment.path, "modification")
    if not error then
      if mod_date > most_recent.date  then
        most_recent.index = i
        most_recent.date = mod_date or -1
      end
    else
      TheApp:announceError("lfs.attributes(saved_game, modification):" .. error, false)
    end
  end

  -- Assign new names:
  for i, attachment in ipairs(unattached_saves) do
    mod_date, error = lfs.attributes(attachment.path, "modification")
    if not error then
      -- Decide name:
      if i == most_recent.index then
        new_name = "before"
      else
        new_name = mod_date

        if tick_entity and save_info_table then
          if save_info_table[attachment.path].unused_entity_id > tick_entity.id then
            new_name = new_name .. "(TE)"
          end
        end
      end

      attachment.attach_name = new_name .. ".sav"
    else
      TheApp:announceError("lfs.attributes(path, modification):" .. error, false)
    end
  end
end

local function getOS()
  local os = "Unknown"
  for _, command in pairs{windows="ver", unix="uname"} do
    local program = io.popen("ver", 'r')
    if program then
      os = program:read('*a'):gsub("\n", "")
      program:close()
      break
    end
  end
  return os
end

local function makeProblemReport(explanation, reproduce_steps, unattached_screenshots, unattached_saves)
  local report = "**** [REPORTED PROBLEM] ****\n" ..
                 "Version: " .. TheApp:getVersion() .. "\n" ..
                 "OS: " .. getOS() .. "\n\n" ..

                 "[Error Explanation]:\n" ..
                 explanation .. "\n\n" ..
                 "[Steps To Reproduce?]:\n" ..
                 reproduce_steps .. "\n\n"

  return report, unattached_screenshots, unattached_saves
end

local function makeCrashReport(this_coroutine, error_message, last_dispatch_type, reproduce_steps)
  last_dispatch_type = last_dispatch_type or TheApp.last_dispatch_type
  reproduce_steps = reproduce_steps or ""

  local unattached_screenshots = {}
  local unattached_saves = {}
  local save_attachment_names = {}
  local error = nil

  local tick_entity = nil
  if TheApp.world then
    tick_entity = TheApp.world.current_tick_entity
  end

  if TheApp.ui then
    unattached_screenshots = makeCrashScreenshots(tick_entity)
  end
  if TheApp.world then
    unattached_saves = findSavedGames(this_coroutine, tick_entity)
    renameSavedGames(unattached_saves, tick_entity)
  end

  -- ----------------------
  -- Make report's message
  -- ----------------------
  local report = "Version: " .. TheApp:getVersion() .. "\n" ..
                 "OS: " .. getOS() .. "\n"

  if not TheApp.world then
    report = "**** [LUA CRASH] Pre-Game: ****\n" .. report
  else
    report = "**** [LUA CRASH] In Game: ****\n" ..
             report ..
             "World previously recovered from error?: " .. (tostring(TheApp.world.recovered_from_error) or "nil") .. "\n" ..
             "World date: " .. (tostring(TheApp.world.day) or "nil") .. "/" .. (tostring(TheApp.world.month) or "nil") .. "/" .. (tostring(TheApp.world.year) or "nil") .. ":" .. (tostring(TheApp.world.hour) or "nil") ..  " (D/M/Y:H)\n" ..
             "Map: " .. (tostring(TheApp.map.level_name) or "nil") .. "\n" ..
             "Tick entity: " .. (tick_entity and tick_entity.id or "None") .. "\n"
  end

  report = report .. "\n[The Error]:\n"
  if last_dispatch_type then
    report = report .. "Occurred in " .. last_dispatch_type .. " handler:\n"
  end
  report = report ..
           error_message .. "\n\n" ..
           "[Steps To Reproduce?]:\n" ..
           (reproduce_steps or " ") .. "\n"
  
  print("\n" .. report .. "\n")
  return report, unattached_screenshots, unattached_saves
end

local function makeEmail(error_type, victims_contact_details, message, unattached_screenshots, unattached_saves)
  local mime = require("mime")
  local ltn12 = require("ltn12")
  local sender = victims_contact_details or "unknown"

  -- Make email's message:
  local email = {
    headers = {
      to = "Error Reports " .. destination,
      subject = error_type .. " " .. TheApp:getVersion() .. ": ".. "<" .. sender .. "> <" .. os.date("%c") .. ">"
    },
    body = {
      preamble = "This email can only be read with an email client which supports attachments.",
      [1] = {body = message, mime.eol(0, message)}
    }
  }

  -- Add attachments:
  local body_index = 2
  local function addAttachments(attachments, type, description)
    local pathsep = package.config:sub(1, 1)
    for _, attachment in ipairs(attachments) do
      local file, error = io.open(attachment.path, "rb")
      if not error then
        email.body[body_index] =
          {
            headers = {
              ["content-type"] = type .. '; name=' .. attachment.path,
              ["content-disposition"] = 'attachment; filename=' .. attachment.attach_name,
              ["content-description"] = description,
              ["content-transfer-encoding"] = "BASE64"
            },
            body = ltn12.source.chain(ltn12.source.file(file),
                                      ltn12.filter.chain(mime.encode("base64"),
                                      mime.wrap()))
          }
        body_index = body_index + 1
      else
        TheApp:announceError("addAttachments():" .. error, false)
      end
    end
  end

  addAttachments(unattached_screenshots, "image/bmp", "Screenshot")
  addAttachments(unattached_saves, "text/plain", "Saved game")
  addAttachments({path = config_path .. "config.txt", attached_name = "config.txt"},
                 "text/plain",
                 "Game Config")
  if #TheApp.log_messages > 0 then
    pcall(TheApp.dumpLog, TheApp)
    addAttachments({path = config_path .. "log.txt", attached_name = "log.txt"},
                   "text/plain",
                   "Log")
  end
  if TheApp.world then
    pcall(TheApp.world.dumpGameLog, TheApp.world)
    addAttachments({path = config_path .. "gamelog.txt", attached_name = "gamelog.txt"},
                   "text/plain",
                   "Game Log")
  end

  return email
end

local function saveReport(report, screenshots, saves)
  if TheApp.unreported_errors_dir then
    -- Create report's directory:
    local pathsep = package.config:sub(1, 1)
    local dir = TheApp.unreported_errors_dir .. os.date("%c"):gsub("/", "_"):gsub(":", "-")
    local _, error = lfs.mkdir(dir)
    if not error then
      dir = dir .. pathsep

      -- Make report.txt:
      local report_txt, error = io.open(dir .. "report.txt", "w")
      if not error then
        report_txt:write(report)
        report_txt:close()
      else
        TheApp:announceError(S_.errors.error .. " failed to make " .. (dir .. "report.txt") .. ":" .. error)
        return nil
      end

      -- Move screenshots:
      for _, attachment in ipairs(screenshots) do
        local _, error = os.rename(attachment.path, dir .. attachment.attach_name)
        if error then
          TheApp:announceError(S_.errors.error .. " failed to move screenshot to report's directory:" .. error)
          os.remove(attachment.path)
        end
      end

      -- Copy saved games to the report's directory:
      for _, attachment in ipairs(saves) do
        copy_file(attachment.path, dir .. attachment.attach_name)
      end

      -- Copy game config file and logs to the report's directory:
      copy_file(config_path .. "config.txt", dir .. "error_config.txt")
      if #TheApp.log_messages > 0 and pcall(TheApp.dumpLog, TheApp) then
        copy_file(config_path .. "log.txt", dir .. "log.txt")
      end
      if TheApp.world and pcall(TheApp.dumpLog, TheApp) then
        copy_file(config_path .. "gamelog.txt", dir .. "gamelog.txt")
      end
    else
      TheApp:announceError(_S.errors.error .. " failed to save report because its directory couldn't be created:" .. error)
      return nil
    end
    return dir
  end
end

local function send(email, report, screenshots, saves)
  local smtp = require("socket.smtp")
  local _, error_message = smtp.send{
    from = "",
    rcpt = destination,
    source = smtp.message(email)
  }

  if error_message then
    local saved = saveReport(report, screenshots, saves)
    if saved then
      TheApp:announceError(S_.report_error.not_sent_but_saved)
    end
  else
    for _, screenshot in ipairs(screenshots) do
      os.remove(screenshot.path)
    end
  end

  return error_message
end

local function saveProblemReport(...)
  local report, screenshots, saves = makeProblemReport(...)
  saveReport(report, screenshots, saves)
end

local function sendProblemReport(victims_contact_details, ...)
  local report, screenshots, saves = makeProblemReport(...)
  local email = makeEmail("[REPORTED PROBLEM]",
                          victims_contact_details,
                          report,
                          screenshots,
                          saves,
                          nil)
  return send(email, report, screenshots, saves, {})
end

local function saveCrashReport(this_coroutine, ...)
  local report, screenshots, saves = makeCrashReport(this_coroutine, ...)
  saveReport(report, screenshots, saves)
end

local function sendCrashReport(this_coroutine, error_message, last_dispatch_type, reproduce_steps, victims_contact_details)
  local report, screenshots, saves = makeCrashReport(this_coroutine,
                                                     error_message,
                                                     last_dispatch_type,
                                                     reproduce_steps)
  local email = makeEmail("[LUA CRASH]",
                          victims_contact_details,
                          report,
                          screenshots,
                          saves)
  return send(email, report, screenshots, saves)
end

local function startSendCrashReport(...)
  local the_coroutine = coroutine.create(sendCrashReport)
  coroutine.resume(the_coroutine, the_coroutine, ...)
end

local function startSaveCrashReport(...)
  local the_coroutine = coroutine.create(saveCrashReport)
  coroutine.resume(the_coroutine, the_coroutine, ...)
end

return startSendCrashReport, startSaveCrashReport, sendProblemReport, saveProblemReport
