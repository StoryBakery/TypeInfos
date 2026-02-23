--[[
	테스트 공용 단언 함수입니다.
]]

local Assertions = {}

function Assertions.assertEqual(actual: any, expected: any, message: string)
	if actual ~= expected then
		error(`{message} (actual: {tostring(actual)}, expected: {tostring(expected)})`)
	end
end

function Assertions.assertAlmostEqual(actual: number, expected: number, tolerance: number, message: string)
	if math.abs(actual - expected) > tolerance then
		error(
			`{message} (actual: {tostring(actual)}, expected: {tostring(expected)}, tolerance: {tostring(tolerance)})`
		)
	end
end

function Assertions.assertTrue(condition: boolean, message: string)
	if not condition then
		error(message)
	end
end

function Assertions.assertErrorContains(fn: () -> (), pattern: string, message: string)
	local ok, err = pcall(fn)
	if ok then
		error(message)
	end

	local errMessage = tostring(err)
	if string.find(errMessage, pattern, 1, true) == nil then
		error(`Error message must contain "{pattern}". (actual: {errMessage})`)
	end
end

return Assertions
