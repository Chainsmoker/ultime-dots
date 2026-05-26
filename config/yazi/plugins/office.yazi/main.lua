--- @since 25.2.7

local M = {}

local emit = ya.emit or ya.mgr_emit or ya.manager_emit

function M:peek(job)
	local start, cache = os.clock(), ya.file_cache(job)
	if not cache then
		return
	end

	local ok, err = self:preload(job)
	if not ok or err then
		return ya.preview_widget(job, err)
	end

	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))
	local _, show_err = ya.image_show(cache, job.area)
	ya.preview_widget(job, show_err)
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		local step = ya.clamp(-1, job.units, 1)
		emit("peek", { math.max(0, cx.active.preview.skip + step), only_if = job.file.url })
	end
end

function M:doc2pdf(job)
	local base = "/tmp/yazi-" .. ya.uid() .. "/"
	local tmp = base .. ya.hash("office.yazi") .. "/"

	-- LibreOffice is single-instance: every `--convert-to` that uses the same user
	-- profile tries to hand its job to one shared process over a named pipe. When Yazi
	-- preloads several office files at once (a folder with multiple docs), those calls
	-- race over that pipe, the losers get `EPIPE`/`short write: 0` and exit non-success
	-- -> "Failed to preconvert". Giving each file its own `-env:UserInstallation` makes
	-- every conversion a fully independent instance, so concurrent previews never clash.
	local profile_path = base .. "office-profile-" .. ya.hash(tostring(job.file.url))
	local profile_uri = "file://" .. profile_path

	--[[	For Future Reference: Regarding `libreoffice` as preconverter
	  1. It prints errors to stdout (always, doesn't matter if it succeeded or it failed)
	  2. Always writes the converted files to the filesystem, so no "Mario|Bros|Piping|Magic" for the data stream (https://ask.libreoffice.org/t/using-convert-to-output-to-stdout/38753)
	  3. The `pdf:draw_pdf_Export` filter needs literal double quotes when defining its options (https://help.libreoffice.org/latest/en-US/text/shared/guide/pdf_params.html?&DbPAR=SHARED&System=UNIX#generaltext/shared/guide/pdf_params.xhp)
	  3.1 Regarding double quotes and Lua strings, see https://www.lua.org/manual/5.1/manual.html#2.1 --]]
	-- NOTE: `-env:` options MUST precede the regular `--` switches.
	local args = {
		"-env:UserInstallation=" .. profile_uri,
		"--headless",
		"--norestore",
		"--convert-to",
		'pdf:draw_pdf_Export:{"PageRange":{"type":"string","value":"' .. job.skip + 1 .. '"}}',
		"--outdir",
		tmp,
		tostring(job.file.url),
	}

	-- One conversion attempt. Tries `libreoffice` from PATH first, then the Nix profile
	-- (this machine ships LibreOffice via `~/.nix-profile/bin`, which isn't always on the
	-- PATH Yazi inherits). Returns the command Output (or nil) plus any spawn error.
	local function run_lo()
		local out, e = Command("libreoffice")
			:arg(args)
			:stdin(Command.NULL)
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()
		if not out then
			local nix_path = os.getenv("HOME") .. "/.nix-profile/bin/libreoffice"
			out, e = Command(nix_path)
				:arg(args)
				:stdin(Command.NULL)
				:stdout(Command.PIPED)
				:stderr(Command.PIPED)
				:output()
		end
		return out, e
	end

	local libreoffice, err = run_lo()

	-- Cold-starting a brand-new isolated profile can transiently fail (EBUSY on
	-- `user/extensions/buildid`, EPIPE) while LibreOffice bootstraps it; and a profile
	-- left half-written by an aborted preview stays broken on every later run. Wipe the
	-- profile and try once more — the retry recreates it from scratch with no contention.
	if not libreoffice or not libreoffice.status.success then
		Command("rm"):arg({ "-rf", profile_path }):stdout(Command.NULL):stderr(Command.NULL):output()
		libreoffice, err = run_lo()
	end

	if not libreoffice then
		return nil, Err("Failed to start `libreoffice`: %s. Is LibreOffice installed?", err or "unknown error")
	end

	if not libreoffice.status.success then
		local output = libreoffice.stdout .. libreoffice.stderr
		local version = (output:match("LibreOffice .+") or ""):gsub("%\n.*", "")
		local error = (output:match("Error:? .+") or ""):gsub("%\n.*", "")
		if version ~= "" or error ~= "" then
			ya.err((version or "LibreOffice") .. " " .. (error or "Unknown error"))
		end
		return nil, Err("Failed to preconvert `%s` to a temporary PDF", job.file.name)
	end

	local pdf = tmp .. job.file.name:gsub("%.[^%.]+$", ".pdf")
	local read_permission = io.open(pdf, "r")
	if not read_permission then
		return nil, Err("Failed to read `%s`: make sure file exists and have read access", pdf)
	end
	read_permission:close()

	return pdf
end

function M:preload(job)
	local cache = ya.file_cache(job)
	if not cache or fs.cha(cache) then
		return true
	end

	local tmp_pdf, err = self:doc2pdf(job)
	if not tmp_pdf then
		return true, Err("    " .. "%s", err)
	end

	local output, err = Command("pdftoppm")
		:arg({
			"-singlefile",
			"-jpeg",
			"-jpegopt",
			"quality=" .. rt.preview.image_quality,
			"-f",
			1,
			tostring(tmp_pdf),
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output then
		local nix_pdftoppm = os.getenv("HOME") .. "/.nix-profile/bin/pdftoppm"
		output, err = Command(nix_pdftoppm)
			:arg({
				"-singlefile",
				"-jpeg",
				"-jpegopt",
				"quality=" .. rt.preview.image_quality,
				"-f",
				1,
				tostring(tmp_pdf),
			})
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()
	end

	local rm_tmp_pdf, rm_err = fs.remove("file", Url(tmp_pdf))
	if not rm_tmp_pdf then
		return true, Err("Failed to remove %s, error: %s", tmp_pdf, rm_err)
	end

	if not output then
		return true, Err("Failed to start `pdftoppm`, error: %s", err)
	elseif not output.status.success then
		local pages = tonumber(output.stderr:match("the last page %((%d+)%)")) or 0
		if job.skip > 0 and pages > 0 then
			emit("peek", { math.max(0, pages - 1), only_if = job.file.url, upper_bound = true })
		end
		return true, Err("Failed to convert %s to image, stderr: %s", tmp_pdf, output.stderr)
	end

	return fs.write(cache, output.stdout)
end

return M
