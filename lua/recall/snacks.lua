local utils = require("recall.utils")

local M = {}

local function finder()
  local marks = utils.sorted_global_marks()

  local items = {}
  for _, mark in ipairs(marks) do
    table.insert(items, {
      text = mark.char,
      pos = { [1] = mark.info.pos[2], [2] = mark.info.pos[3] },
      file = mark.info.file,
    })
  end

  return items
end

M.pick = function()
  require("snacks").picker.pick({
    title = "Global Marks",
    format = "text",
    finder = finder,
  })
end

return M
