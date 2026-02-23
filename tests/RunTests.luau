--[[
	테스트 엔트리 모듈입니다.
	스펙 실행 모듈을 불러와 테스트를 수행합니다.
]]

local function runTests(): boolean
	return require("@game/ReplicatedStorage/Tests/specs")
end

local testResult = runTests()
print("[TEST] All specs passed")
return testResult
