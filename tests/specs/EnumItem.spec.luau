--[[
	EnumItem 타입 테스트입니다.
]]

local Assertions = require("../helpers/Assertions")
local Utils = require("../helpers/TypeInfosUtils")
local TypeInfos = Utils.TypeInfos
local roundTripByTypeName = Utils.roundTripByTypeName

do
	local enumItemTypeInfo = TypeInfos.GetTypeInfoByTypeName("EnumItem")
	Assertions.assertEqual(enumItemTypeInfo.Name, "EnumItem", "EnumItem TypeInfo name mismatch.")
	Assertions.assertEqual(enumItemTypeInfo.Size, 4, "EnumItem TypeInfo size mismatch.")
	Assertions.assertTrue(enumItemTypeInfo.TypeCheck(Enum.KeyCode.F), "EnumItem TypeCheck failed.")
	Assertions.assertTrue(not enumItemTypeInfo.TypeCheck(123), "EnumItem TypeCheck must reject number.")
	Assertions.assertTrue(not enumItemTypeInfo.TypeCheck("F"), "EnumItem TypeCheck must reject string.")
end

do
	local enumItems = {
		Enum.KeyCode.F,
		Enum.Material.Wood,
		Enum.FontWeight.Bold,
		Enum.NormalId.Top,
	}

	for _, enumItem in enumItems do
		local decoded = roundTripByTypeName("EnumItem", enumItem)
		Assertions.assertEqual(decoded, enumItem, `EnumItem round trip mismatch for "{tostring(enumItem)}".`)
	end
end

do
	local firstEnumItem = Enum.KeyCode.A
	local secondEnumItem = Enum.KeyCode.B

	local firstDecoded = roundTripByTypeName("EnumItem", firstEnumItem)
	local secondDecoded = roundTripByTypeName("EnumItem", secondEnumItem)

	Assertions.assertEqual(firstDecoded, firstEnumItem, "First EnumItem round trip result mismatch.")
	Assertions.assertEqual(secondDecoded, secondEnumItem, "Second EnumItem round trip result mismatch.")
	Assertions.assertTrue(firstDecoded ~= secondDecoded, "Different EnumItems must remain different after round trip.")
end

return true
