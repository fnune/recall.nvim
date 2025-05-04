local config = require("recall.config")
local utils = require("recall.utils")
local marking = require("recall.marking")

local M = {}

local function finder()
  local marks = utils.sorted_global_marks()

  local items = {}
  for _, mark in ipairs(marks) do
    table.insert(items, {
      char = mark.char,
      text = mark.char,
      pos = { [1] = mark.info.pos[2], [2] = mark.info.pos[3] },
      file = mark.info.file,
    })
  end

  return items
end

local function unmark_selected_entry(self, item)
  vim.cmd("delmarks " .. item.char)
  marking.on_mark_update()
  self:find({
    refresh = true,
  })
end
M.pick = function()
  local unmark_normal = config.opts.snacks.mappings.unmark_selected_entry.normal
  local unmark_insert = config.opts.snacks.mappings.unmark_selected_entry.insert

  require("snacks").picker.pick({
    title = "Global Marks",
    format = "text",
    finder = finder,
    actions = {
      unmark_selected_entry = unmark_selected_entry,
    },
    win = {
      input = {
        keys = {
          [unmark_normal] = { "unmark_selected_entry", mode = { "n" }, desc = "Delete mark" },
          [unmark_insert] = { "unmark_selected_entry", mode = { "i" }, desc = "Delete mark" },
        },
      },
    },
  })
end

return M
