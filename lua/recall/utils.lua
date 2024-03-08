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

M.iterate_global_marks = function(callback)
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

M.get_sorted_global_marks = function()
  local marks = {}
  M.iterate_global_marks(function(char, info)
    table.insert(marks, { char = char, info = info })
  end)
  table.sort(marks, function(a, b)
    return a.char < b.char
  end)
  return marks
end

return M
