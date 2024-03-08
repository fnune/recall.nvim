# Changelog

All notable changes to Recall will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0](<(https://github.com/fnune/recall.nvim/releases/tag/1.0.0)>) - 2024-03-08

### Added

Initial release of Recall.

- Basic global mark management with `:Recall{Toggle,Mark,Unmark}` and
  `:RecallClear`
- Basic global mark navigation with `:Recall{Next,Previous}`
- Sign column with a customizable character
- Support for Neovim 0.10.x and also 0.9.x and lower
- Telescope integration beyond the built-in `:Telescope marks` that allows mark
  deletion and displaying only global marks
- Improved stability by adding CI and testing using [plenary][plenary-tests]

[plenary-tests]: https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md
