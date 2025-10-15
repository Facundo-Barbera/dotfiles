return {
  "lervag/vimtex",
  lazy = false, -- lazy-loading will disable inverse search
  ft = { "tex" },
  config = function()
    -- Set PDF viewer based on OS
    vim.g.vimtex_view_method = "skim"

    -- Compiler settings - use latexmk with output directory
    vim.g.vimtex_compiler_latexmk = {
      aux_dir = "out",
      out_dir = "out",
      callback = 1,
      continuous = 1,
      executable = "latexmk",
      options = {
        "-pdf",
        "-verbose",
        "-file-line-error",
        "-synctex=1",
        "-interaction=nonstopmode",
      },
    }

    -- Auto-start compilation when opening tex files
    vim.g.vimtex_compiler_latexmk_engines = {
      _ = "-pdf",
    }

    -- Enable quickfix window for errors
    vim.g.vimtex_quickfix_mode = 1

    -- Don't auto-open quickfix on warnings, only on errors
    vim.g.vimtex_quickfix_open_on_warning = 0

    -- Enable fold and concealment (optional - you can disable if you don't like it)
    vim.g.vimtex_fold_enabled = 0
    vim.g.vimtex_imaps_enabled = 0

    -- Enable VimTeX indentation
    vim.g.vimtex_indent_enabled = 1

    -- Allow indentation for document environment (remove from ignored list)
    vim.g.vimtex_indent_ignored_envs = {}

    -- Use latexmk for cleaning
    vim.g.vimtex_compiler_clean_paths = {
      "out",
    }

    -- Auto-start compilation when opening tex files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "tex",
      callback = function()
        -- Indentation settings for LaTeX
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
        vim.opt_local.expandtab = true
        vim.opt_local.autoindent = true
        vim.opt_local.smartindent = true

        -- Start compilation automatically
        vim.cmd("VimtexCompile")
      end,
    })
  end,
}
