local M = {}

local buffers_access_times = {}

local function startsWith(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

local function get_listed_buffers()
	local buffers = vim.tbl_filter(function(b)
		return vim.fn.buflisted(b) == 1
	end, vim.api.nvim_list_bufs())
	return buffers
end

local buffers_blacklist = { "oil:" }
local function is_buffer_blacklisted(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)

	for _, prefix in ipairs(buffers_blacklist) do
		if startsWith(bufname, prefix) then
			return true
		end
	end

	return false
end

local function can_track_buffer(bufnr)
	return vim.api.nvim_buf_is_valid(bufnr)
		and vim.fn.bufexists(bufnr) == 1
		and vim.fn.buflisted(bufnr) == 1
		and vim.api.nvim_buf_get_option(bufnr, "buftype") == ""
		and not is_buffer_blacklisted(bufnr)
end

local function cleanup_buffer_access_times()
	for buf, _ in pairs(buffers_access_times) do
		if not can_track_buffer(buf) then
			buffers_access_times[buf] = nil
		end
	end
end

-- Update buffer access times
local function update_buffer_track_time(bufnr)
	if not can_track_buffer(bufnr) then
		return
	end

	buffers_access_times[bufnr] = os.time()
end

local function can_close_buffer(bufnr)
	return can_track_buffer(bufnr)
		-- We do not close buffers that are currently visible (in a split for ex)
		and vim.fn.bufwinnr(bufnr) == -1
		and not vim.api.nvim_buf_get_option(bufnr, "modified")
end

-- Function to close the least recently used buffer
local function delete_least_recently_used_buffer()
	cleanup_buffer_access_times()

	local oldest_buffer = nil
	local oldest_time = os.time()

	for bufnr, time in pairs(buffers_access_times) do
		-- Check if the buffer exists and is valid
		if can_close_buffer(bufnr) then
			if time < oldest_time then
				oldest_time = time
				oldest_buffer = bufnr
			end
		end
	end

	if oldest_buffer then
		-- Close the oldest buffer
		vim.api.nvim_buf_delete(oldest_buffer, { force = true })
	else
		-- print("No buffer found to close.")
	end
end

------------------------------------------------------

local function handle_buf_add(callback_options, options)
	local bufnr = callback_options.buf

	if not can_track_buffer(bufnr) then
		return
	end

	local buffers = get_listed_buffers()

	if #buffers > options.max_buffers then
		delete_least_recently_used_buffer()
	end
end

local function handle_buf_enter(options)
	update_buffer_track_time(options.buf)
end

------------------------------------------------------

M.setup = function(user_options)
	----------------------------
	local options = {}
	local default_options = {
		max_buffers = 5,
	}
	if user_options then
		for k, v in pairs(user_options) do
			options[k] = v or default_options[k]
		end
	end
	----------------------------

	-- Track new buffers
	-- BufAdd is the same as BufCreate
	-- BufAdd happens before BufEnter
	vim.api.nvim_create_autocmd("BufAdd", {
		pattern = "*",
		callback = function(opts)
			handle_buf_add(opts, options)
		end,
	})

	-- Track buffer access times
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		pattern = "*",
		callback = handle_buf_enter,
	})

	vim.api.nvim_create_user_command("DeleteLeastRecentlyUsedBuffer", delete_least_recently_used_buffer, {})
end

return M
