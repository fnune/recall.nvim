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
  local cwd = vim.fn.getcwd()

  local function create_temp_buffer()
    local _bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(_bufnr)
    set_lines(_bufnr, line_count)

    local temp_path = luv.os_tmpdir() .. "/nvim-recall-test-" .. luv.hrtime() .. ".txt"
    if jit and jit.os == "OSX" then
      -- Need to add this path prefix on macos
      temp_path = "/private" .. temp_path
    end
    table.insert(temp_paths, temp_path)

    vim.api.nvim_buf_set_name(_bufnr, temp_path)
    vim.api.nvim_buf_set_option(_bufnr, "modified", false)
    vim.cmd("w")

    return _bufnr
  end

  local function remove_temp_buffers_and_marks()
    vim.cmd("bufdo! bdelete")
    vim.cmd("delmarks A-Z")

    for _, temp_path in ipairs(temp_paths) do
      os.remove(temp_path)
    end

    temp_paths = {}
    vim.api.nvim_set_current_dir(cwd)
  end

  before_each(function()
    local telescope = require("telescope")
    telescope.setup({})
    recall.setup({})
    bufnr = create_temp_buffer()
  end)

  after_each(function()
    remove_temp_buffers_and_marks()
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

    recall.goto_next()
    assert.are.same(c_pos, vim.api.nvim_win_get_cursor(0))
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

    assert.are.equal(results[1].ordinal, "A:" .. temp_paths[1] .. ":1")
    assert.are.equal(results[1].lnum, 1)
    assert.are.equal(results[1].col, 0)

    assert.are.equal(results[2].ordinal, "B:" .. temp_paths[1] .. ":10")
    assert.are.equal(results[2].lnum, 10)
    assert.are.equal(results[2].col, 0)

    assert.are.equal(results[3].ordinal, "C:" .. temp_paths[1] .. ":20")
    assert.are.equal(results[3].lnum, 20)
    assert.are.equal(results[3].col, 0)

    -- Switch to the temp dir to test relative filenames
    vim.api.nvim_set_current_dir(vim.fs.dirname(temp_paths[1]))

    vim.cmd("Telescope recall")

    results = inspect_telescope_results()

    assert.are.equal(#results, 3)

    assert.are.equal(results[1].ordinal, "A:" .. vim.fn.fnamemodify(temp_paths[1], ":p:.") .. ":1")
    assert.are.equal(results[1].lnum, 1)
    assert.are.equal(results[1].col, 0)

    assert.are.equal(results[2].ordinal, "B:" .. vim.fn.fnamemodify(temp_paths[1], ":p:.") .. ":10")
    assert.are.equal(results[2].lnum, 10)
    assert.are.equal(results[2].col, 0)

    assert.are.equal(results[3].ordinal, "C:" .. vim.fn.fnamemodify(temp_paths[1], ":p:.") .. ":20")
    assert.are.equal(results[3].lnum, 20)
    assert.are.equal(results[3].col, 0)
  end)

  it("reuses opened windows when reuse_opened_windows is enabled", function()
    local bufnr1 = create_temp_buffer()
    local win1 = vim.api.nvim_open_win(bufnr1, true, { split = "left" })

    local bufnr2 = create_temp_buffer()
    local win2 = vim.api.nvim_open_win(bufnr2, true, { split = "right" })
    assert.are.not_equal(win1, win2)

    vim.api.nvim_set_current_win(win1)
    vim.api.nvim_set_current_buf(bufnr1)
    place_cursor(10, 1)
    recall.mark()

    vim.api.nvim_set_current_win(win2)
    vim.api.nvim_set_current_buf(bufnr2)
    place_cursor(20, 1)
    recall.mark()

    vim.api.nvim_set_current_win(win2)
    vim.api.nvim_set_current_buf(bufnr2)
    place_cursor(20, 1)
    recall.goto_next()

    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(current_win)

    assert.are.equal(current_win, win1, "Should reuse the window already displaying the target buffer")
    assert.are.equal(current_buf, bufnr1)
    assert.are.same(cursor_pos, { 10, 1 })

    recall.goto_next()

    current_win = vim.api.nvim_get_current_win()
    current_buf = vim.api.nvim_get_current_buf()
    cursor_pos = vim.api.nvim_win_get_cursor(current_win)

    assert.are.equal(current_win, win2, "Should reuse the window already displaying the target buffer")
    assert.are.equal(current_buf, bufnr2)
    assert.are.same(cursor_pos, { 20, 1 })
  end)

  it("reuses opened windows across tab pages", function()
    local bufnr1 = create_temp_buffer()
    place_cursor(10, 1)
    recall.mark()
    local tab1 = vim.api.nvim_get_current_tabpage()
    local win1 = vim.api.nvim_get_current_win()

    vim.cmd("tabnew")
    local bufnr2 = create_temp_buffer()
    place_cursor(20, 1)
    recall.mark()
    local tab2 = vim.api.nvim_get_current_tabpage()
    local win2 = vim.api.nvim_get_current_win()

    assert.are.not_equal(tab1, tab2)

    -- From tab2, navigate to the mark in tab1
    recall.goto_next()

    local current_tab = vim.api.nvim_get_current_tabpage()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(current_win)

    assert.are.equal(current_tab, tab1, "Should switch to the tab page displaying the target buffer")
    assert.are.equal(current_win, win1, "Should reuse the window in the other tab page")
    assert.are.equal(current_buf, bufnr1)
    assert.are.same(cursor_pos, { 10, 1 })

    -- Navigate back to the mark in tab2
    recall.goto_next()

    current_tab = vim.api.nvim_get_current_tabpage()
    current_win = vim.api.nvim_get_current_win()
    current_buf = vim.api.nvim_get_current_buf()
    cursor_pos = vim.api.nvim_win_get_cursor(current_win)

    assert.are.equal(current_tab, tab2, "Should switch back to the other tab page")
    assert.are.equal(current_win, win2, "Should reuse the window in the other tab page")
    assert.are.equal(current_buf, bufnr2)
    assert.are.same(cursor_pos, { 20, 1 })
  end)
end)
