return {
	dependencies = {
		"3rd/image.nvim",
	},
	"sahaj-b/brainrot.nvim",
	event = "VeryLazy",
	opts = {
		-- defaults:

		disable_phonk = false, -- skip phonk/overlay on "no errors"
		phonk_time = 4.5, -- seconds the phonk/image overlay stays
		min_error_duration = 10.5, -- minimum seconds errors must exist before phonk triggers (0 = instant)
		block_input = false, -- block input during phonk/overlay
		dim_level = 0, -- phonk overlay darkness 0..100

		sound_enabled = true, -- enable sounds
		image_enabled = true, -- enable images (needs image.nvim)

		boom_volume = 100, -- volume for vine boom sound (0..100)
		phonk_volume = 100, -- volume for phonk sound (0..100)

		boom_sound = nil, -- custom boom sound path (e.g., "~/sounds/boom.ogg")
		phonk_dir = nil, -- custom phonk folder path (e.g., "~/sounds/phonks")
		image_dir = nil, -- custom image folder path (e.g., "~/memes/images")

		lsp_wide = false, -- track errors workspace-wide(get ALL lsp errors)
	},

	config = function()
		require("brainrot").setup()
		require("image").setup({
			backend = "kitty", -- or "ueberzug" or "sixel"
			processor = "magick_cli", -- or "magick_rock"
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					only_render_image_at_cursor_mode = "popup", -- or "inline"
					floating_windows = false, -- if true, images will be rendered in floating markdown windows
					filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
				},
				asciidoc = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					only_render_image_at_cursor_mode = "popup",
					floating_windows = false,
					filetypes = { "asciidoc", "adoc" },
				},
				neorg = {
					enabled = true,
					filetypes = { "norg" },
				},
				rst = {
					enabled = true,
				},
				typst = {
					enabled = true,
					filetypes = { "typst" },
				},
				html = {
					enabled = false,
				},
				css = {
					enabled = false,
				},
			},
			max_width = nil,
			max_height = nil,
			max_width_window_percentage = nil,
			max_height_window_percentage = 50,
			scale_factor = 1.0,
			kitty_direct_chunk_size = 4096, -- chunk size for direct Kitty graphics protocol transmission
			window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
			window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
			editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
			tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
			hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
		})
	end,
}
