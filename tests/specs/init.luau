--[[
	테스트 스펙 인덱스 모듈입니다.
	문자열 require 규칙에 맞춰 스펙을 고정 순서로 실행합니다.
]]

print("[TEST] Running Tests.specs.TypeInfosBasics.spec")
require("@self/TypeInfosBasics.spec")

print("[TEST] Running Tests.specs.PrimitiveRoundTrip.spec")
require("@self/PrimitiveRoundTrip.spec")

print("[TEST] Running Tests.specs.RobloxValueRoundTrip.spec")
require("@self/RobloxValueRoundTrip.spec")

print("[TEST] Running Tests.specs.EnumItem.spec")
require("@self/EnumItem.spec")

print("[TEST] Running Tests.specs.Instance.spec")
require("@self/Instance.spec")

print("[TEST] Running Tests.specs.CustomEnum.spec")
require("@self/CustomEnum.spec")

return true
