local opts = require("hot.params").opts

local function check()
	print(vim.inspect(opts.set.languages))
end

return {

	check = check,
}
