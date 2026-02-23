--[[
	기본 Luau 타입과 공용 확장 타입 round-trip 테스트입니다.
]]

local Assertions = require("../helpers/Assertions")
local Utils = require("../helpers/TypeInfosUtils")
local TypeInfos = Utils.TypeInfos
local roundTripByTypeName = Utils.roundTripByTypeName

local function assertRoundTripEquals(typeName: string, values: { any })
	for _, value in values do
		local decoded = roundTripByTypeName(typeName, value)
		Assertions.assertEqual(decoded, value, `{typeName} round trip mismatch.`)
	end
end

do
	assertRoundTripEquals("boolean", { false, true })
	assertRoundTripEquals("string", { "", "A", "Hello, TypeInfos" })
	assertRoundTripEquals("number", { -123.5, 0, 999_999.25 })

	local overflowString = string.rep("A", 65536)
	Assertions.assertErrorContains(function()
		roundTripByTypeName("string", overflowString)
	end, "string length must be <= 65535", "string length overflow must throw an error.")
end

do
	local nilTypeInfo = TypeInfos.GetTypeInfoByTypeName("nil")
	Assertions.assertTrue(nilTypeInfo.TypeCheck(nil), "nil TypeCheck must allow nil.")
	Assertions.assertEqual(roundTripByTypeName("nil", nil), nil, "nil round trip mismatch.")
end

do
	local float16Values = { -2.5, 0, 1.5, math.huge, -math.huge }
	for _, value in float16Values do
		local decoded = roundTripByTypeName("float16", value)
		if math.abs(value) == math.huge then
			Assertions.assertEqual(decoded, value, "float16 infinity round trip mismatch.")
		else
			Assertions.assertAlmostEqual(decoded, value, 0.01, "float16 round trip mismatch.")
		end
	end

	local float16Nan = roundTripByTypeName("float16", 0 / 0)
	Assertions.assertTrue(float16Nan ~= float16Nan, "float16 NaN round trip mismatch.")
end

do
	local float32Values = { -123.25, 0, 456.5 }
	for _, value in float32Values do
		local decoded = roundTripByTypeName("float32", value)
		Assertions.assertAlmostEqual(decoded, value, 0.0001, "float32 round trip mismatch.")
	end
end

do
	assertRoundTripEquals("int8", { -128, -1, 0, 127 })
	assertRoundTripEquals("int16", { -32768, -1, 0, 32767 })
	assertRoundTripEquals("int32", { -2_147_483_648, -1, 0, 2_147_483_647 })

	assertRoundTripEquals("uint8", { 0, 1, 255 })
	assertRoundTripEquals("uint16", { 0, 1, 65535 })
	assertRoundTripEquals("uint32", { 0, 1, 4_294_967_295 })
end

do
	local floatListTypeInfo = TypeInfos.GetTypeInfoByTypeName("FloatList")
	local floatList = { -10.5, 0, 123.75 }
	local decodedFloatList = roundTripByTypeName("FloatList", floatList)

	Assertions.assertEqual(#decodedFloatList, #floatList, "FloatList length mismatch.")
	for i, value in floatList do
		Assertions.assertAlmostEqual(decodedFloatList[i], value, 0.0001, "FloatList element mismatch.")
	end

	local strictOk = select(1, floatListTypeInfo.StrictTypeCheck(floatList))
	Assertions.assertTrue(strictOk, "FloatList StrictTypeCheck must allow numeric array.")

	local strictDictionaryOk = select(1, floatListTypeInfo.StrictTypeCheck({ X = 1 }))
	Assertions.assertTrue(not strictDictionaryOk, "FloatList StrictTypeCheck must reject dictionary.")

	local strictElementOk = select(1, floatListTypeInfo.StrictTypeCheck({ 1, "A" }))
	Assertions.assertTrue(not strictElementOk, "FloatList StrictTypeCheck must reject non-number element.")

	local overflowFloatList = table.create(65536, 1.25)
	Assertions.assertErrorContains(function()
		roundTripByTypeName("FloatList", overflowFloatList)
	end, "FloatList length must be <= 65535", "FloatList length overflow must throw an error.")
end

do
	local tableValue = {
		[1] = "One",
		[true] = false,
		Index = 7,
		Nested = {
			Flag = true,
			Name = "Nested",
		},
	}

	local decodedTable = roundTripByTypeName("table", tableValue)
	Assertions.assertEqual(decodedTable[1], "One", "table numeric key round trip mismatch.")
	Assertions.assertEqual(decodedTable[true], false, "table boolean key round trip mismatch.")
	Assertions.assertEqual(decodedTable.Index, 7, "table string key round trip mismatch.")
	Assertions.assertEqual(decodedTable.Nested.Flag, true, "table nested boolean round trip mismatch.")
	Assertions.assertEqual(decodedTable.Nested.Name, "Nested", "table nested string round trip mismatch.")
end

return true
