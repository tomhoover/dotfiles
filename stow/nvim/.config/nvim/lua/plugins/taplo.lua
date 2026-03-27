return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      taplo = {
        root_dir = function(fname)
          if type(fname) == "number" then
            fname = vim.api.nvim_buf_get_name(fname)
          end
          if not fname or fname == "" then
            return nil
          end
          local util = require("lspconfig.util")
          local real = vim.uv.fs_realpath(fname) or fname
          return util.root_pattern(".taplo.toml", "taplo.toml", ".git")(real) or vim.fs.dirname(real)
        end,
        single_file_support = true,
      },
    },
  },
}
