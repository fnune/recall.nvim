local config = require("recall.config")
local utils = require("recall.utils")

local M = {}

M.refresh_signs = function()
  vim.fn.sign_unplace("*", { group = "RecallMark" })

  utils.for_each_global_mark(function(char, info)
    local bufnr = info.pos[1]
    local lnum = info.pos[2]
    if bufnr and bufnr > 0 and lnum then
      vim.fn.sign_place(0, "", "RecallMark", bufnr, { lnum = lnum, priority = 10, id = string.byte(char) })
    end
  end)
end

M.on_mark_update = function()
  M.refresh_signs()

  if config.opts.wshada then
    vim.cmd("wshada!")
  end
end

M.is_mark_set = function(mark)
  local marks = vim.api.nvim_exec("marks", true)
  return string.find(marks, "%s" .. mark .. " ")
end

M.next_available_mark = function()
  for ascii = 65, 90 do -- ASCII values for A-Z
    local mark = string.char(ascii)
    if not M.is_mark_set(mark) then
      return mark
    end
  end
  return nil
end

M.remove_mark_if_exists = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local mark_removed = false

  utils.for_each_global_mark(function(char, info)
    if info.pos[1] == bufnr and info.pos[2] == row then
      vim.cmd("delmarks " .. char)
      mark_removed = true
    end
  end)

  return mark_removed
end

function M.set_global_mark()
  local mark = M.next_available_mark()
  if mark then
    vim.cmd("mark " .. mark)
    M.on_mark_update()
  end
end

function M.unset_global_mark()
  if M.remove_mark_if_exists() then
    M.on_mark_update()
  end
end

function M.toggle_global_mark()
  if M.remove_mark_if_exists() then
    M.on_mark_update()
  else
    M.set_global_mark()
  end
end

function M.clear_all_global_marks()
  vim.cmd("delmarks A-Z")
  M.on_mark_update()
end

return M
