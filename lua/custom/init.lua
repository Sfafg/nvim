local M = {}
require("custom.remap")
require("custom.set")
require("custom.sticky_notes")
require("custom.project_manager").setup()
require("custom.file_jumper").setup()

function M.setup()
	require("custom.colorscheme_picker").load_colorscheme()
	require("custom.colorscheme_picker").load_opacity()
end
return M
