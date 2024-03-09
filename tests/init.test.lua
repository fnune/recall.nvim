local luv = require("luv")

local run_id = luv.hrtime()
local lazypath_base = luv.os_tmpdir() .. "/nvim-recall-test-lazy-" .. run_id .. "-"
local lazypaths = {
  path = lazypath_base .. "lazypath",
  plugins = lazypath_base .. "plugins",
  lock = lazypath_base .. "lazy-lock.json",
  state = lazypath_base .. "state.json",
  readme = lazypath_base .. "readme",
}

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for _, path in pairs(lazypaths) do
      os.execute('rm -rf "' .. path .. '"')
    end
  end,
})

if not vim.loop.fs_stat(lazypaths.path) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypaths.path,
  })
end
vim.opt.rtp:prepend(lazypaths.path)

require("lazy").setup({
  "nvim-lua/plenary.nvim",
  "nvim-telescope/telescope.nvim",
}, {
  root = lazypaths.plugins,
  lockfile = lazypaths.lock,
  readme = { root = lazypaths.readme },
  state = lazypaths.state,
})
