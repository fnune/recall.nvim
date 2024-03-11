local luv = require("luv")
local recall = require("recall")

local function set_lines(buffer, count)
  local lines = {}
  for i = 1, count do
    table.insert(lines, i .. "Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
  end
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
end

local function place_cursor(line, column)
  vim.api.nvim_win_set_cursor(0, { line, column })
end

local function count_signs(buffer)
  local signs = vim.fn.sign_getplaced(buffer, { group = "RecallSigns" })[1].signs
  return #signs
end

local function find_telescope_bufnr()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    if buftype == "prompt" then
      return bufnr
    end
  end
end
local function inspect_telescope_picker()
  vim.wait(1000, function()
    return find_telescope_bufnr() ~= nil
  end)
  local telescope_action_state = require("telescope.actions.state")
  local telescope_bufnr = find_telescope_bufnr()
  return telescope_action_state.get_current_picker(telescope_bufnr)
end

local function inspect_telescope_results()
  local finder = inspect_telescope_picker().finder
  if finder ~= nil then
    return finder.results
  end
  return {}
end

describe("Recall", function()
  local bufnr
  local line_count = 100
  local temp_paths = {}

  before_each(function()
    local telescope = require("telescope")
    telescope.setup({})
    recall.setup({})

    bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(bufnr)
    set_lines(bufnr, line_count)

    local temp_path = luv.os_tmpdir() .. "/nvim-recall-test-" .. luv.hrtime() .. ".txt"
    table.insert(temp_paths, temp_path)

    vim.api.nvim_buf_set_name(bufnr, temp_path)
    vim.api.nvim_buf_set_option(bufnr, "modified", false)
    vim.cmd("w")
  end)

  after_each(function()
    vim.cmd("bufdo! bdelete")
    vim.cmd("delmarks A-Z")

    for _, temp_path in ipairs(temp_paths) do
      os.remove(temp_path)
    end

    temp_paths = {}
  end)

  it("can toggle marks and show/hide signs", function()
    recall.toggle()
    assert.are.equal(count_signs(bufnr), 1)

    place_cursor(10, 0)
    recall.toggle()
    assert.are.equal(count_signs(bufnr), 2)

    recall.toggle()
    assert.are.equal(count_signs(bufnr), 1)

    place_cursor(1, 0)
    recall.toggle()
    assert.are.equal(count_signs(bufnr), 0)
  end)

  it("can toggle marks regardless of the column", function()
    place_cursor(1, 0)
    recall.toggle()
    assert.are.equal(count_signs(bufnr), 1)

    place_cursor(1, 5)
    recall.toggle()
    assert.are.equal(count_signs(bufnr), 0)
  end)

  it("does not set a mark on an unsaved buffer", function()
    assert.are.equal(count_signs(bufnr), 0)

    bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(bufnr)

    recall.toggle()
    assert.are.equal(count_signs(bufnr), 0)
  end)

  it("can navigate to next and previous marks", function()
    local a_pos = { 1, 1 }
    place_cursor(unpack(a_pos))
    recall.toggle()

    local b_pos = { 10, 1 }
    place_cursor(unpack(b_pos))
    recall.toggle()

    local c_pos = { 20, 1 }
    place_cursor(unpack(c_pos))
    recall.toggle()

    recall.goto_prev()
    assert.are.same(b_pos, vim.api.nvim_win_get_cursor(0))

    recall.goto_prev()
    assert.are.same(a_pos, vim.api.nvim_win_get_cursor(0))

    recall.goto_next()
    assert.are.same(b_pos, vim.api.nvim_win_get_cursor(0))

    recall.goto_next()
    assert.are.same(c_pos, vim.api.nvim_win_get_cursor(0))

    recall.goto_prev()
    assert.are.same(b_pos, vim.api.nvim_win_get_cursor(0))
  end)

  it("can clear all marks", function()
    recall.toggle()
    place_cursor(10, 0)
    recall.toggle()
    place_cursor(20, 0)
    recall.toggle()

    recall.clear()
    assert.are.equal(count_signs(bufnr), 0)
  end)

  it("can list marks using Telescope", function()
    recall.toggle()
    place_cursor(10, 0)
    recall.toggle()
    place_cursor(20, 0)
    recall.toggle()

    vim.cmd("Telescope recall")

    local results = inspect_telescope_results()

    assert.are.equal(#results, 3)

    assert.are.equal(results[1].ordinal, "A")
    assert.are.equal(results[1].lnum, 1)
    assert.are.equal(results[1].col, 0)

    assert.are.equal(results[2].ordinal, "B")
    assert.are.equal(results[2].lnum, 10)
    assert.are.equal(results[2].col, 0)

    assert.are.equal(results[3].ordinal, "C")
    assert.are.equal(results[3].lnum, 20)
    assert.are.equal(results[3].col, 0)
  end)
end)
