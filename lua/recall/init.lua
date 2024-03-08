local config = require("recall.config")
local marking = require("recall.marking")
local navigation = require("recall.navigation")

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.goto_next()
  navigation.goto_mark("next")
end

function M.goto_prev()
  navigation.goto_mark("prev")
end

function M.mark()
  marking.set_global_mark()
end

function M.unmark()
  marking.unset_global_mark()
end

function M.toggle()
  marking.toggle_global_mark()
end

function M.clear()
  marking.clear_all_global_marks()
end

vim.api.nvim_create_user_command("RecallMark", M.mark, {})
vim.api.nvim_create_user_command("RecallUnmark", M.unmark, {})
vim.api.nvim_create_user_command("RecallToggle", M.toggle, {})
vim.api.nvim_create_user_command("RecallNext", M.goto_next, {})
vim.api.nvim_create_user_command("RecallPrevious", M.goto_prev, {})
vim.api.nvim_create_user_command("RecallClear", M.clear, {})

return M
