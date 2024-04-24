local opts = require("hot.params").opts

local job_id = nil
local output_buf = nil
local output_win = nil

local function output_to_buffer(data, is_error)
	if not data or #data == 0 then
		return
	end

	local lines = {}
	if is_error then
		lines = { table.concat(data, " ") }
	else
		lines = data
	end

	-- Attempt to set lines in buffer
	local success, err = pcall(function()
		vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, lines)
	end)

	-- Check if there was an error
	if not success then
		print("")
	end
end -- Ensure the functions are accessible by making them global

-- Function to close the output buffer
local function close_output_buffer()
	if output_win and vim.api.nvim_win_is_valid(output_win) then
		vim.api.nvim_win_close(output_win, true)
		output_win = nil
	end
	if output_buf and vim.api.nvim_buf_is_valid(output_buf) then
		vim.api.nvim_buf_delete(output_buf, { force = true })
		output_buf = nil
	end
	vim.notify("🤏 Buffer Closed", vim.log.levels.INFO)
end

-- Function to open the output buffer in a floating window
local function open_output_buffer()
	-- Check if the buffer is still valid or if it needs to be created
	if not output_buf or not vim.api.nvim_buf_is_valid(output_buf) then
		-- Create a new buffer that is not listed and not loaded into memory when deleted
		output_buf = vim.api.nvim_create_buf(false, true)
		-- Calculate window dimensions as a percentage of the total screen size
		local win_height = math.floor(vim.api.nvim_get_option("lines") * 0.3) -- 30% of available height
		local win_width = math.floor(vim.api.nvim_get_option("columns") * 0.8) -- 80% of available width

		-- Calculate and set window position and create the window
		output_win = vim.api.nvim_open_win(output_buf, true, {
			relative = "editor",
			width = win_width,
			height = win_height,
			row = vim.api.nvim_get_option("lines") - win_height - 1,
			col = 10,
			style = "minimal",
			border = "rounded",
		})
		-- Set specific window options
		vim.api.nvim_win_set_option(output_win, "wrap", false)
		vim.api.nvim_buf_set_option(output_buf, "bufhidden", "wipe")
	end
end

-- Define the function to handle the F5 key press for stopping a running job
local function stop()
	local lan

	if type(opts.set.languages) == "table" then
		for lang, lang_config in pairs(opts.set.languages) do
			if type(lang_config) == "table" then
				lan = lang_config -- Assign lang_config to lan
			else
				print("Error: Missing field for language", lang)
			end
		end
	else
		print("Error: opts.set.languages is not a table")
	end

	if not job_id then
		vim.notify(lan.emoji .. " No script is running.", vim.log.levels.INFO)
		return
	end

	-- Stop the job if it's running
	vim.fn.jobstop(job_id)
	vim.notify(lan.emoji .. " Stopping script...", vim.log.levels.INFO)
	close_output_buffer()

	Reloader = opts.tweaks.stop
	job_id = nil

	-- Close the output window if it's still valid and open
	if output_win and vim.api.nvim_win_is_valid(output_win) then
		vim.api.nvim_win_close(output_win, true)
	end
end

-- Recursive function to search for the main file in the directory and its subdirectories
local function find_main_file(directory, extensions)
	for _, file in ipairs(vim.fn.readdir(directory)) do
		local path = directory .. "/" .. file
		if vim.fn.isdirectory(path) == 1 then
			-- If it's a directory, recursively search inside it
			local main_file = find_main_file(path, extensions)
			if main_file then
				return main_file
			end
		else
			-- Check if the file name matches any of the extensions
			for _, ext in ipairs(extensions) do
				if file == "main" .. ext then
					return path
				elseif file == opts.tweaks.custom_file .. ext then
					return path
				end
			end
		end
	end
end

local function restart()
	if job_id then
		vim.fn.jobstop(job_id)
		job_id = nil
	end

	local filetype = vim.bo.filetype -- Get the current buffer's filetype
	local lan = nil -- Initialize lan to nil

	if type(opts.set.languages) == "table" then
		-- Check if there is a language configuration for the current filetype
		if opts.set.languages[filetype] then
			lan = opts.set.languages[filetype] -- Assign the language configuration to lan
		else
			vim.notify("Main file not found in project directory or its subdirectories", vim.log.levels.ERROR)

			return
		end
	else
		print("Error: opts.set.languages is not a table")
		return
	end

	-- Check if lan is still accessible here
	if lan then
		-- Get the root directory of the project
		local root_dir = vim.fn.getcwd()
		-- Find the main file in the root directory and its subdirectories
		local main_file = find_main_file(root_dir, lan.ext)

		if not main_file then
			vim.notify("Main file not found in project directory or its subdirectories", vim.log.levels.ERROR)
			return
		end

		vim.cmd("write")
		local file = vim.fn.shellescape(main_file) -- Get the current file path

		-- Set up the job to execute the script
		Reloader = opts.tweaks.start
		open_output_buffer()

		vim.defer_fn(function()
			job_id = vim.fn.jobstart(lan.cmd .. " " .. file, {
				on_stdout = function(_, data)
					output_to_buffer(data, false)
				end,
				on_stderr = function(_, data)
					output_to_buffer(data, true)
				end,
				on_exit = function(_, code)
					job_id = nil
					-- Handle job exit if needed
				end,
			})
		end, 500)
	end
end

-- Define a function to find the main_test file
local function find_test_file(directory, extensions)
	for _, file in ipairs(vim.fn.readdir(directory)) do
		local path = directory .. "/" .. file
		if vim.fn.isdirectory(path) == 1 then
			-- If it's a directory, recursively search inside it
			local test_file = find_test_file(path, extensions)
			if test_file then
				return test_file
			end
		else
			-- Check if the file name matches any of the extensions
			for _, ext in ipairs(extensions) do
				if file:match("_test" .. ext .. "$") then
					return path
				elseif file:match("test_" .. ext .. "$") then
					return path
				end
			end
		end
	end
	return nil
end

local function test_restart()
	if job_id then
		vim.fn.jobstop(job_id)
		job_id = nil
	end

	local filetype = vim.bo.filetype -- Get the current buffer's filetype
	local lan = nil -- Initialize lan to nil

	if type(opts.set.languages) == "table" then
		-- Check if there is a language configuration for the current filetype
		if opts.set.languages[filetype] then
			lan = opts.set.languages[filetype] -- Assign the language configuration to lan
		else
			vim.notify("Test file not found in project directory or its subdirectories", vim.log.levels.ERROR)

			return
		end
	else
		print("Error: opts.set.languages is not a table")
		return
	end

	if lan then
		-- Get the root directory of the project
		local root_dir = vim.fn.getcwd()

		-- Find the test file in the root directory and its subdirectories
		local test_file = find_test_file(root_dir, lan.ext)

		if not test_file then
			vim.notify("Test file not found in project directory or its subdirectories", vim.log.levels.ERROR)
			return
		end

		vim.cmd("write")
		local file = vim.fn.shellescape(test_file) -- Get the current file path

		-- vim.notify(lang.emoji .. ' Starting script...', vim.log.levels.INFO)
		Reloader = opts.tweaks.test
		open_output_buffer()

		vim.defer_fn(function()
			job_id = vim.fn.jobstart(lan.test .. "", {
				on_stdout = function(_, data)
					output_to_buffer(data, false)
				end,
				on_stderr = function(_, data)
					output_to_buffer(data, true)
				end,
				on_exit = function(_, code)
					job_id = nil
					if code > 0 then
						vim.notify(lan.emoji .. " Script exited with code " .. code, vim.log.levels.WARN)
						Reloader = opts.tweaks.test_fail
					else
						vim.notify(lan.emoji .. " Script executed successfully", vim.log.levels.INFO)
						Reloader = opts.tweaks.test_done
					end
				end,
			})
		end, 500)
	end
end

-- Function to silently restart the script

local function silent()
	if job_id then
		vim.fn.jobstop(job_id)
		job_id = nil
	end

	local filetype = vim.bo.filetype -- Get the current buffer's filetype
	local lan = nil -- Initialize lan to nil

	if type(opts.set.languages) == "table" then
		-- Check if there is a language configuration for the current filetype
		if opts.set.languages[filetype] then
			lan = opts.set.languages[filetype] -- Assign the language configuration to lan
		else
			vim.notify("Main file not found in project directory or its subdirectories", vim.log.levels.ERROR)

			return
		end
	else
		print("Error: opts.set.languages is not a table")
		return
	end

	-- Check if lan is still accessible here
	if lan then
		vim.defer_fn(function()
			-- Get the root directory of the project
			local root_dir = vim.fn.getcwd()
			-- Find the main file in the root directory and its subdirectories
			local main_file = find_main_file(root_dir, lan.ext)
			vim.notify(lan.ext)
			if not main_file then
				vim.notify("Main file not found in project directory or its subdirectories", vim.log.levels.ERROR)
				return
			end

			vim.cmd("write")
			local file = vim.fn.shellescape(main_file) -- Get the current file path

			-- vim.notify(lang.emoji .. ' Silently starting script...', vim.log.levels.INFO)
			Reloader = opts.tweaks.start
			job_id = vim.fn.jobstart(lan.cmd .. " " .. file, {
				on_stdout = function(_, data) end, -- No output handling
				on_stderr = function(_, data) end, -- No output handling
				on_exit = function(_, code)
					job_id = nil
					-- Uncomment the following lines to display exit status notifications
					-- if code > 0 then
					--   vim.notify(lang.emoji .. ' Silent script exited with code ' .. code, vim.log.levels.WARN)
					-- else
					-- vim.notify(lang.emoji .. ' Silent script executed successfully', vim.log.levels.INFO)
					-- end
				end,
			})
		end, 500) -- Defer the function call by 500ms to allow for any pending operations
	end
end

return {
	restart = restart,
	open_output_buffer = open_output_buffer,
	close_output_buffer = close_output_buffer,
	test_restart = test_restart,
	stop = stop,
	silent = silent,
}
