local M = {}

M.print_table = function(t, indent)
  indent = indent or ""
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(indent .. k .. ":")
      M.print_table(v, indent .. "  ")
    else
      print(indent .. k .. ": " .. tostring(v))
    end
  end
end

M.for_each_global_mark = function(callback)
  local marks = vim.fn.getmarklist()

  for _, mark_info in ipairs(marks) do
    if mark_info.mark:match("'[A-Z]") then
      local char = mark_info.mark:sub(2)
      if callback then
        callback(char, mark_info)
      end
    end
  end
end

M.sorted_global_marks = function()
  local marks = {}
  M.for_each_global_mark(function(char, info)
    table.insert(marks, { char = char, info = info })
  end)
  table.sort(marks, function(a, b)
    return a.char < b.char
  end)
  return marks
end

M.find_buf_locations = function(bufnr)
  local results = {}

  if bufnr == -1 then
    return results
  end

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        table.insert(results, {
          tab = tab,
          win = win,
        })
      end
    end
  end

  return results
end

M.find_first_buf_location = function(bufnr)
  local locations = M.find_buf_locations(bufnr)
  if #locations == 0 then
    return nil
  end
  return locations[1]
end

M.set_cursor_for_mark_in_location = function(tab_id, window_id, mark)
  if tab_id ~= 0 then
    vim.api.nvim_set_current_tabpage(tab_id)
  end
  if window_id ~= 0 then
    vim.api.nvim_set_current_win(window_id)
  end
  vim.api.nvim_win_set_cursor(0, { mark.pos[2], mark.pos[3] })
end

M.set_cursor_for_mark_in_current_window = function(mark)
  M.set_cursor_for_mark_in_location(0, 0, mark)
end

return M
