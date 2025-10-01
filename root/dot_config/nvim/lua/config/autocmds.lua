-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- LaTeX template command
vim.api.nvim_create_user_command("TexTemplate", function(opts)
  local template_name = opts.args
  if template_name == "" then
    print("Available templates: base, article, beamer, homework, blank")
    return
  end

  local template_path = vim.fn.stdpath("config") .. "/templates/tex/" .. template_name .. ".tex"

  -- Check if template exists
  if vim.fn.filereadable(template_path) == 0 then
    print("Template '" .. template_name .. "' not found. Available: base, article, beamer, homework, blank")
    return
  end

  -- Read template and insert into current buffer
  local lines = vim.fn.readfile(template_path)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  print("Inserted template: " .. template_name)
end, {
  nargs = 1,
  complete = function()
    return { "base", "article", "beamer", "homework", "blank" }
  end,
})
