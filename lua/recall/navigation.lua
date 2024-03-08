local utils = require("recall.utils")

local M = {}

M.latest_mark_from_jumplist = function(marks)
  local jumplist = vim.fn.getjumplist()
  for i = #jumplist[1], 1, -1 do
    local jump = jumplist[1][i]
    for _, mark in ipairs(marks) do
      if mark.info.pos[1] == jump.bufnr and mark.info.pos[2] == jump.lnum then
        return mark
      end
    end
  end
  return nil
end

M.current_pos_if_mark = function(marks, current_pos, current_bufnr)
  for _, mark in ipairs(marks) do
    local bufnr, lnum, col = unpack(mark.info.pos)
    if bufnr == current_bufnr and lnum == current_pos[1] and col == current_pos[2] then
      return mark
    end
  end
  return nil
end

M.find_mark = function(direction)
  local marks = utils.get_sorted_global_marks()
  if #marks == 0 then
    return nil
  end

  local current_pos = vim.api.nvim_win_get_cursor(0)
  local current_bufnr = vim.api.nvim_get_current_buf()

  local latest_mark = M.current_pos_if_mark(marks, current_pos, current_bufnr) or M.latest_mark_from_jumplist(marks)

  if not latest_mark then
    latest_mark = direction == "next" and marks[1] or marks[#marks]
  end

  local index = 1
  for i, mark in ipairs(marks) do
    if mark.char == latest_mark.char then
      index = i
      break
    end
  end

  local target_index
  if direction == "next" then
    target_index = (index % #marks) + 1
  elseif direction == "prev" then
    target_index = ((index - 2 + #marks) % #marks) + 1
  end

  return marks[target_index].info
end

M.goto_mark = function(direction)
  local mark = M.find_mark(direction)
  if mark then
    vim.cmd("edit " .. mark.file)
    vim.api.nvim_win_set_cursor(0, { mark.pos[2], mark.pos[3] })
  else
    print("No global marks set")
  end
end

return M
