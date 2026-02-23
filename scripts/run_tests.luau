--[=[
	로컬/CI 공용 테스트 실행 스크립트입니다.
]=]

local process = require("@lune/process")

local ROJO_COMMAND = process.env.ROJO_COMMAND or "rojo"
local RUN_IN_ROBLOX_COMMAND = process.env.RUN_IN_ROBLOX_COMMAND or "run-in-roblox"
local TEST_PROJECT_FILE = process.env.TEST_PROJECT_FILE or "test.project.json"
local TEST_PLACE_FILE = process.env.TEST_PLACE_FILE or ".test-place.rbxlx"
local TEST_ENTRY_FILE = process.env.TEST_ENTRY_FILE or "tests/RunTests.luau"

local function runCommand(commandName: string, commandArgs: { string })
	local result = process.exec(commandName, commandArgs, {
		cwd = process.cwd,
		env = process.env,
		stdio = "forward",
	})

	if not result.ok then
		process.exit(result.code)
	end
end

local function run()
	runCommand(ROJO_COMMAND, {
		"build",
		TEST_PROJECT_FILE,
		"-o",
		TEST_PLACE_FILE,
	})

	runCommand(RUN_IN_ROBLOX_COMMAND, {
		"--place",
		TEST_PLACE_FILE,
		"--script",
		TEST_ENTRY_FILE,
	})
end

run()
