-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- LaTeX template command with menu and preview
vim.api.nvim_create_user_command("TexTemplate", function()
  local templates = { "base", "article", "beamer", "homework", "blank" }
  local template_dir = vim.fn.stdpath("config") .. "/templates/tex/"

  -- Helper function to insert template
  local function insert_template(template_name)
    local template_path = template_dir .. template_name .. ".tex"
    if vim.fn.filereadable(template_path) == 1 then
      local lines = vim.fn.readfile(template_path)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.notify("Inserted template: " .. template_name, vim.log.levels.INFO)
    else
      vim.notify("Template not found: " .. template_name, vim.log.levels.ERROR)
    end
  end

  -- Try Telescope first (most reliable, well-documented)
  local telescope_ok = pcall(require, "telescope.builtin")
  if telescope_ok then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
      .new({}, {
        prompt_title = "LaTeX Templates",
        finder = finders.new_table({
          results = templates,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
          title = "Template Preview",
          define_preview = function(self, entry)
            local template_path = template_dir .. entry.value .. ".tex"
            if vim.fn.filereadable(template_path) == 1 then
              local lines = vim.fn.readfile(template_path)
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
              vim.bo[self.state.bufnr].filetype = "tex"
            end
          end,
        }),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection then
              insert_template(selection.value)
            end
          end)
          return true
        end,
      })
      :find()
    return
  end

  -- Try fzf-lua (LazyVim 14 default)
  local fzf_ok, fzf_lua = pcall(require, "fzf-lua")
  if fzf_ok then
    fzf_lua.fzf_exec(templates, {
      prompt = "LaTeX Templates> ",
      fzf_opts = {
        ["--preview"] = string.format("cat %s/{}.tex", vim.fn.shellescape(template_dir)),
        ["--preview-window"] = "right:50%",
      },
      actions = {
        ["default"] = function(selected)
          if selected and #selected > 0 then
            insert_template(selected[1])
          end
        end,
      },
    })
    return
  end

  -- No picker available - show helpful error
  vim.notify(
    "No picker available! Please enable one via :LazyExtras\n" .. "Options: Telescope or fzf-lua",
    vim.log.levels.ERROR
  )
end, {
  nargs = 0,
})
