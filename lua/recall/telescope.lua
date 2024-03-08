local config = require("recall.config")
local utils = require("recall.utils")
local marking = require("recall.marking")

local M = {}

M.extension = function(opts)
  local telescope_action_state = require("telescope.actions.state")
  local telescope_conf = require("telescope.config").values
  local telescope_entry_display = require("telescope.pickers.entry_display")
  local telescope_finders = require("telescope.finders")
  local telescope_pickers = require("telescope.pickers")

  local entry_layout = telescope_entry_display.create({
    separator = " ",
    items = { { width = 1 }, { remaining = true } },
  })

  local function display_entry(entry)
    return entry_layout({
      { config.opts.sign, config.opts.sign_highlight },
      entry.value.info.file,
    })
  end

  local function create_finder()
    local marks = utils.sorted_global_marks()
    return telescope_finders.new_table({
      results = marks,
      entry_maker = function(entry)
        return {
          value = entry,
          display = display_entry,
          ordinal = entry.char,
          lnum = entry.info.pos[2],
          col = entry.info.pos[3] - 1,
          filename = entry.info.file,
        }
      end,
    })
  end

  local function unmark_selected_entry(picker_bufnr)
    local selection = telescope_action_state.get_selected_entry()
    local picker = telescope_action_state.get_current_picker(picker_bufnr)

    if selection then
      vim.cmd("delmarks " .. selection.value.char)
      marking.on_mark_update()
      picker:refresh(create_finder(), { reset_prompt = true })
    end
  end

  telescope_pickers
    .new(opts, {
      prompt_title = "Recall",
      results_title = "Global Marks",
      finder = create_finder(),
      previewer = telescope_conf.grep_previewer({}),
      sorter = telescope_conf.generic_sorter({}),
      attach_mappings = function(picker_bufnr, picker_map)
        local unmark_normal = config.opts.telescope.mappings.unmark_selected_entry.normal
        if unmark_normal ~= nil then
          picker_map({ "n" }, unmark_normal, function()
            unmark_selected_entry(picker_bufnr)
          end)
        end

        local unmark_insert = config.opts.telescope.mappings.unmark_selected_entry.insert
        if unmark_insert ~= nil then
          picker_map({ "i" }, unmark_insert, function()
            unmark_selected_entry(picker_bufnr)
          end)
        end

        return true
      end,
    })
    :find()
end

M.register = function()
  local telescope = require("telescope")
  return telescope.register_extension({ exports = { recall = M.extension } })
end

M.autoload = function()
  local has_telescope, telescope = pcall(require, "telescope")
  if has_telescope then
    telescope.load_extension("recall")
  end
end

return M
