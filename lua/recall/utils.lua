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

M.find_first_buf_location = function(bufnr)
  if bufnr == -1 then
    return nil
  end

  local current_tab = vim.api.nvim_get_current_tabpage()
  local first = nil

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        if tab == current_tab then
          return { tab = tab, win = win }
        end
        if first == nil then
          first = { tab = tab, win = win }
        end
      end
    end
  end

  return first
end

M.set_cursor_for_mark = function(buf_location, mark)
  if buf_location then
    if buf_location.tab then
      vim.api.nvim_set_current_tabpage(buf_location.tab)
    end
    if buf_location.win then
      vim.api.nvim_set_current_win(buf_location.win)
    end
  end
  vim.api.nvim_win_set_cursor(0, { mark.pos[2], mark.pos[3] })
end

return M
