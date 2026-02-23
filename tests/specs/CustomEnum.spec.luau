--[[
	CustomEnum 생성 테스트입니다.
]]

local Assertions = require("../helpers/Assertions")
local Utils = require("../helpers/TypeInfosUtils")
local TypeInfos = Utils.TypeInfos
local roundTripByTypeName = Utils.roundTripByTypeName

do
	local customEnumInfo = TypeInfos.GetTypeInfoByTypeName("CustomEnum")
	local customEnumItemInfo = TypeInfos.GetTypeInfoByTypeName("CustomEnumItem")

	local enumId = 2_401
	local enumItems = {
		"Idle",
		"Run",
		{ Name = "Jump", Value = 999 },
	}

	local enumA = TypeInfos.CreateCustomEnum(enumId, enumItems)
	local enumB = TypeInfos.CreateCustomEnum(enumId, enumItems)

	Assertions.assertEqual(enumA.Id, enumB.Id, "Enums with same EnumId must keep the same Id value.")
	Assertions.assertEqual(enumA.Name, tostring(enumId), "CustomEnum name must follow EnumId.")
	Assertions.assertEqual(enumA.Idle.ItemId, 0, "First enum item ItemId mismatch.")
	Assertions.assertEqual(enumA.Run.ItemId, 1, "Second enum item ItemId mismatch.")
	Assertions.assertEqual(enumA.Jump.ItemId, 2, "Third enum item ItemId mismatch.")
	Assertions.assertEqual(enumA.Jump.Value, 999, "Enum item Value mismatch.")
	Assertions.assertEqual(enumA:GetEnumId(), enumId, "GetEnumId must return EnumId.")
	Assertions.assertEqual(enumA:GetEnumItems()[3], enumA.Jump, "GetEnumItems result mismatch.")

	Assertions.assertTrue(customEnumInfo.TypeCheck(enumA), "CustomEnum TypeCheck rejected created enum.")
	Assertions.assertTrue(customEnumItemInfo.TypeCheck(enumA.Jump), "CustomEnumItem TypeCheck rejected created item.")

	local decodedEnum = roundTripByTypeName("CustomEnum", enumA)
	Assertions.assertEqual(decodedEnum.Id, enumA.Id, "CustomEnum round trip Id mismatch.")

	local decodedItem = roundTripByTypeName("CustomEnumItem", enumA.Jump)
	Assertions.assertEqual(decodedItem.EnumId, enumA.Id, "CustomEnumItem EnumId round trip mismatch.")
	Assertions.assertEqual(decodedItem.ItemId, enumA.Jump.ItemId, "CustomEnumItem ItemId round trip mismatch.")
end

do
	local enumMin = TypeInfos.CreateCustomEnum(0, { "None" })
	local enumMax = TypeInfos.CreateCustomEnum(65535, {
		{ Name = "Enabled", Value = true },
		{ Name = "Disabled", Value = false },
	})

	Assertions.assertEqual(enumMin.Id, 0, "CustomEnum minimum EnumId mismatch.")
	Assertions.assertEqual(enumMax.Id, 65535, "CustomEnum maximum EnumId mismatch.")
	Assertions.assertEqual(enumMax.Enabled.Value, true, "CustomEnum object item Value(true) mismatch.")
	Assertions.assertEqual(enumMax.Disabled.Value, false, "CustomEnum object item Value(false) mismatch.")
end

do
	Assertions.assertErrorContains(function()
		TypeInfos.CreateCustomEnum(2_402, { "A", "A" })
	end, "reserved or duplicated", "Duplicate enum item names must throw an error.")

	Assertions.assertErrorContains(function()
		TypeInfos.CreateCustomEnum(-1, { "A" })
	end, "EnumId must be an integer between 0 and 65535", "Negative EnumId must throw an error.")

	Assertions.assertErrorContains(function()
		TypeInfos.CreateCustomEnum(65536, { "A" })
	end, "EnumId must be an integer between 0 and 65535", "Too large EnumId must throw an error.")

	Assertions.assertErrorContains(function()
		TypeInfos.CreateCustomEnum(2_403, { 123 :: any })
	end, "must be string or table", "Non-string enum item must throw an error.")

	Assertions.assertErrorContains(function()
		TypeInfos.CreateCustomEnum(2_404, { { Name = 123 :: any, Value = "X" } })
	end, "must be a string", "Enum item Name must be a string.")

	Assertions.assertErrorContains(function()
		roundTripByTypeName("CustomEnum", { Id = 65536 })
	end, "CustomEnum.Id must be an integer between 0 and 65535", "CustomEnum serialize overflow must throw an error.")

	Assertions.assertErrorContains(function()
		roundTripByTypeName("CustomEnum", { Id = 1.25 })
	end, "CustomEnum.Id must be an integer between 0 and 65535", "CustomEnum serialize non-integer must throw an error.")

	Assertions.assertErrorContains(function()
		roundTripByTypeName("CustomEnumItem", { EnumId = 65536, ItemId = 0 })
	end, "CustomEnumItem.EnumId must be an integer between 0 and 65535", "CustomEnumItem EnumId overflow must throw an error.")

	Assertions.assertErrorContains(function()
		roundTripByTypeName("CustomEnumItem", { EnumId = 0, ItemId = 1.5 })
	end, "CustomEnumItem.ItemId must be an integer between 0 and 65535", "CustomEnumItem ItemId non-integer must throw an error.")
end

return true
