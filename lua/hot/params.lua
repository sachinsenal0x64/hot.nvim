---@class Options
---@field set LANG
---@field tweaks  TWEAK

---@class LANG
---@field languages string[]

---@class TWEAK
---@field default string
---@field start string
---@field stop string
---@field test string
---@field test_done string
---@field test_fail string
---@field custom_file string

---@type Options
local opts = {
	set = {
		languages = {
			python = {
				cmd = "python3",
				desc = "Run Python file asynchronously",
				kill_desc = "Kill the running Python file",
				emoji = "🐍",
				test = "python -m unittest",
				ext = { ".py" },
				pattern = { "*.py" },
			},

			go = {
				cmd = "go run",
				desc = "Run Go file asynchronously",
				kill_desc = "Kill the running Go file",
				emoji = "🐹",
				test = "go test",
				ext = { ".go" },
				pattern = { "*.go" },
			},
		},
	},
	tweaks = {
		default = "💤",
		start = "🚀",
		stop = "💤",
		test = "🧪",
		test_done = "🧪.✅",
		test_fail = "🧪.❌",
		custom_file = "index",
	},
}

return {

	opts = opts,
}
