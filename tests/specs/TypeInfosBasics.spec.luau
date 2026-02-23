--[[
	TypeInfos 기본 조회 테스트입니다.
]]

local Assertions = require("../helpers/Assertions")
local Utils = require("../helpers/TypeInfosUtils")
local TypeInfos = Utils.TypeInfos

do
	local numberTypeInfo = TypeInfos.GetTypeInfoByTypeName("number")
	local stringTypeInfo = TypeInfos.GetTypeInfoByTypeName("string")
	local nilTypeInfo = TypeInfos.GetTypeInfoByTypeName("nil")

	Assertions.assertEqual(numberTypeInfo.Name, "number", "number TypeInfo name mismatch.")
	Assertions.assertEqual(numberTypeInfo.Size, 8, "number TypeInfo size mismatch.")
	Assertions.assertEqual(stringTypeInfo.Name, "string", "string TypeInfo name mismatch.")
	Assertions.assertEqual(stringTypeInfo.Size, "Undefined", "string TypeInfo size mismatch.")
	Assertions.assertEqual(nilTypeInfo.Name, "nil", "nil TypeInfo name mismatch.")
	Assertions.assertEqual(nilTypeInfo.Size, 0, "nil TypeInfo size mismatch.")
end

do
	local typeInfos = TypeInfos.GetTypeInfos()
	Assertions.assertTrue(#typeInfos > 0, "TypeInfos list must not be empty.")

	for i, typeInfo in typeInfos do
		Assertions.assertEqual(typeInfo.TypeId, i, "TypeInfo.TypeId must match sorted list index.")

		local byTypeId = TypeInfos.GetTypeInfoByTypeId(i)
		Assertions.assertEqual(byTypeId, typeInfo, "TypeInfo lookup by TypeId must return identical object.")
	end

	for i = 2, #typeInfos do
		local previousTypeInfo = typeInfos[i - 1]
		local currentTypeInfo = typeInfos[i]
		Assertions.assertTrue(previousTypeInfo.Name <= currentTypeInfo.Name, "TypeInfos list must be sorted by Name.")
	end
end

do
	local typeInfosByName = TypeInfos.GetTypeInfosByName()
	local numberTypeInfo = TypeInfos.GetTypeInfoByTypeName("number")
	local booleanTypeInfo = TypeInfos.GetTypeInfoByTypeName("boolean")
	local tableTypeInfo = TypeInfos.GetTypeInfoByTypeName("table")

	Assertions.assertEqual(typeInfosByName.number, numberTypeInfo, "TypeInfosByName.number mismatch.")
	Assertions.assertEqual(typeInfosByName.boolean, booleanTypeInfo, "TypeInfosByName.boolean mismatch.")
	Assertions.assertEqual(typeInfosByName.table, tableTypeInfo, "TypeInfosByName.table mismatch.")
end

do
	Assertions.assertEqual(TypeInfos.GetTypeInfoByValueType(123).Name, "number", "number lookup by value mismatch.")
	Assertions.assertEqual(TypeInfos.GetTypeInfoByValueType(true).Name, "boolean", "boolean lookup by value mismatch.")
	Assertions.assertEqual(TypeInfos.GetTypeInfoByValueType("abc").Name, "string", "string lookup by value mismatch.")
	Assertions.assertEqual(TypeInfos.GetTypeInfoByValueType(nil).Name, "nil", "nil lookup by value mismatch.")
	Assertions.assertEqual(TypeInfos.GetTypeInfoByValueType({}).Name, "table", "table lookup by value mismatch.")

	Assertions.assertEqual(
		TypeInfos.FindTypeInfoByValueType(function() end),
		nil,
		"Unsupported type lookup must return nil."
	)
end

do
	Assertions.assertErrorContains(function()
		TypeInfos.GetTypeInfoByTypeName("DoesNotExist")
	end, "Invalid Type", "Missing type name lookup must throw an error.")

	Assertions.assertErrorContains(function()
		TypeInfos.GetTypeInfoByTypeId(0)
	end, "Invalid TypeInfo Id", "TypeId 0 lookup must throw an error.")

	Assertions.assertErrorContains(function()
		TypeInfos.GetTypeInfoByTypeId(65535)
	end, "Invalid TypeInfo Id", "Out-of-range TypeId lookup must throw an error.")
end

return true
