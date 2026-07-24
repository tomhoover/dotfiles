-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Change comment color to gray
vim.api.nvim_set_hl(0, "Comment", { fg = "#6a737d", italic = true })

-- Change standard line numbers to dark gray
-- vim.api.nvim_set_hl(0, "LineNr", { fg = "#4a505a" })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#6a737d" })

-- Change relative line numbers above/below cursor
-- vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#4a505a" })
vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#6a737d" })
-- vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#4a505a" })
vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#6a737d" })

-- Change the current line number (cursor line) to blue
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#569cd6", bold = true })
