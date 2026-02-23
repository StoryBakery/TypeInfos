--[[
	Roblox 값 타입 round-trip 테스트입니다.
]]

local Assertions = require("../helpers/Assertions")
local Utils = require("../helpers/TypeInfosUtils")
local TypeInfos = Utils.TypeInfos
local roundTripByTypeName = Utils.roundTripByTypeName

local function assertVector2Close(actual: Vector2, expected: Vector2, tolerance: number, message: string)
	Assertions.assertAlmostEqual(actual.X, expected.X, tolerance, `{message} (X mismatch).`)
	Assertions.assertAlmostEqual(actual.Y, expected.Y, tolerance, `{message} (Y mismatch).`)
end

local function assertVector3Close(actual: Vector3, expected: Vector3, tolerance: number, message: string)
	Assertions.assertAlmostEqual(actual.X, expected.X, tolerance, `{message} (X mismatch).`)
	Assertions.assertAlmostEqual(actual.Y, expected.Y, tolerance, `{message} (Y mismatch).`)
	Assertions.assertAlmostEqual(actual.Z, expected.Z, tolerance, `{message} (Z mismatch).`)
end

local function assertColor3Close(actual: Color3, expected: Color3, tolerance: number, message: string)
	Assertions.assertAlmostEqual(actual.R, expected.R, tolerance, `{message} (R mismatch).`)
	Assertions.assertAlmostEqual(actual.G, expected.G, tolerance, `{message} (G mismatch).`)
	Assertions.assertAlmostEqual(actual.B, expected.B, tolerance, `{message} (B mismatch).`)
end

local function assertCFrameClose(actual: CFrame, expected: CFrame, tolerance: number, message: string)
	local ax, ay, az, a00, a01, a02, a10, a11, a12, a20, a21, a22 = actual:GetComponents()
	local ex, ey, ez, e00, e01, e02, e10, e11, e12, e20, e21, e22 = expected:GetComponents()

	Assertions.assertAlmostEqual(ax, ex, tolerance, `{message} (X mismatch).`)
	Assertions.assertAlmostEqual(ay, ey, tolerance, `{message} (Y mismatch).`)
	Assertions.assertAlmostEqual(az, ez, tolerance, `{message} (Z mismatch).`)
	Assertions.assertAlmostEqual(a00, e00, tolerance, `{message} (R00 mismatch).`)
	Assertions.assertAlmostEqual(a01, e01, tolerance, `{message} (R01 mismatch).`)
	Assertions.assertAlmostEqual(a02, e02, tolerance, `{message} (R02 mismatch).`)
	Assertions.assertAlmostEqual(a10, e10, tolerance, `{message} (R10 mismatch).`)
	Assertions.assertAlmostEqual(a11, e11, tolerance, `{message} (R11 mismatch).`)
	Assertions.assertAlmostEqual(a12, e12, tolerance, `{message} (R12 mismatch).`)
	Assertions.assertAlmostEqual(a20, e20, tolerance, `{message} (R20 mismatch).`)
	Assertions.assertAlmostEqual(a21, e21, tolerance, `{message} (R21 mismatch).`)
	Assertions.assertAlmostEqual(a22, e22, tolerance, `{message} (R22 mismatch).`)
end

do
	local vector2 = Vector2.new(3.25, -8.5)
	local vector3 = Vector3.new(-10.5, 0.25, 8.75)
	local color3 = Color3.new(0.125, 0.5, 0.875)
	local color3uint8 = Color3.fromRGB(17, 128, 241)
	local numberRange = NumberRange.new(-5.5, 10.25)
	local uDim = UDim.new(0.25, -30)
	local uDim2 = UDim2.new(0.5, -12, 1, 44)

	local decodedVector2 = roundTripByTypeName("Vector2", vector2)
	local decodedVector3 = roundTripByTypeName("Vector3", vector3)
	local decodedColor3 = roundTripByTypeName("Color3", color3)
	local decodedColor3uint8 = roundTripByTypeName("Color3uint8", color3uint8)
	local decodedNumberRange = roundTripByTypeName("NumberRange", numberRange)
	local decodedUDim = roundTripByTypeName("UDim", uDim)
	local decodedUDim2 = roundTripByTypeName("UDim2", uDim2)

	assertVector2Close(decodedVector2, vector2, 0.0001, "Vector2 round trip mismatch.")
	assertVector3Close(decodedVector3, vector3, 0.0001, "Vector3 round trip mismatch.")
	assertColor3Close(decodedColor3, color3, 0.0001, "Color3 round trip mismatch.")
	assertColor3Close(decodedColor3uint8, color3uint8, 1 / 255, "Color3uint8 round trip mismatch.")
	Assertions.assertAlmostEqual(decodedNumberRange.Min, numberRange.Min, 0.0001, "NumberRange.Min mismatch.")
	Assertions.assertAlmostEqual(decodedNumberRange.Max, numberRange.Max, 0.0001, "NumberRange.Max mismatch.")
	Assertions.assertAlmostEqual(decodedUDim.Scale, uDim.Scale, 0.0001, "UDim.Scale mismatch.")
	Assertions.assertEqual(decodedUDim.Offset, uDim.Offset, "UDim.Offset mismatch.")
	Assertions.assertAlmostEqual(decodedUDim2.X.Scale, uDim2.X.Scale, 0.0001, "UDim2.X.Scale mismatch.")
	Assertions.assertEqual(decodedUDim2.X.Offset, uDim2.X.Offset, "UDim2.X.Offset mismatch.")
	Assertions.assertAlmostEqual(decodedUDim2.Y.Scale, uDim2.Y.Scale, 0.0001, "UDim2.Y.Scale mismatch.")
	Assertions.assertEqual(decodedUDim2.Y.Offset, uDim2.Y.Offset, "UDim2.Y.Offset mismatch.")
end

do
	local numberSequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0, 0),
		NumberSequenceKeypoint.new(0.3, 0.75, 0.1),
		NumberSequenceKeypoint.new(1, 1, 0),
	})
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 128, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})

	local decodedNumberSequence = roundTripByTypeName("NumberSequence", numberSequence)
	local decodedColorSequence = roundTripByTypeName("ColorSequence", colorSequence)

	Assertions.assertEqual(#decodedNumberSequence.Keypoints, #numberSequence.Keypoints, "NumberSequence keypoint count mismatch.")
	for i, keypoint in numberSequence.Keypoints do
		local decodedKeypoint = decodedNumberSequence.Keypoints[i]
		Assertions.assertAlmostEqual(decodedKeypoint.Time, keypoint.Time, 0.0001, "NumberSequence.Time mismatch.")
		Assertions.assertAlmostEqual(decodedKeypoint.Value, keypoint.Value, 0.0001, "NumberSequence.Value mismatch.")
		Assertions.assertAlmostEqual(
			decodedKeypoint.Envelope,
			keypoint.Envelope,
			0.0001,
			"NumberSequence.Envelope mismatch."
		)
	end

	Assertions.assertEqual(#decodedColorSequence.Keypoints, #colorSequence.Keypoints, "ColorSequence keypoint count mismatch.")
	for i, keypoint in colorSequence.Keypoints do
		local decodedKeypoint = decodedColorSequence.Keypoints[i]
		Assertions.assertAlmostEqual(decodedKeypoint.Time, keypoint.Time, 0.0001, "ColorSequence.Time mismatch.")
		assertColor3Close(decodedKeypoint.Value, keypoint.Value, 1 / 255, "ColorSequence.Value mismatch.")
	end
end

do
	local alignedRotation = CFrame.Angles(math.rad(90), 0, 0)
	local alignedCFrame = CFrame.new(0, 0, 0) * alignedRotation
	local movedAlignedCFrame = CFrame.new(5, 10, 15) * alignedRotation
	local unalignedCFrame = CFrame.new(-7, 3.25, 99.5) * CFrame.Angles(math.rad(33), math.rad(-12), math.rad(48))
	local cFrameTypeInfo = TypeInfos.GetTypeInfoByTypeName("CFrame")

	Assertions.assertEqual(cFrameTypeInfo.GetSize(alignedCFrame), 14, "Aligned CFrame size mismatch.")
	Assertions.assertEqual(cFrameTypeInfo.GetSize(movedAlignedCFrame), 14, "Moved aligned CFrame size mismatch.")
	Assertions.assertEqual(cFrameTypeInfo.GetSize(unalignedCFrame), 19, "Unaligned CFrame size mismatch.")

	local alignedDecoded = roundTripByTypeName("CFrame", alignedCFrame)
	local movedAlignedDecoded = roundTripByTypeName("CFrame", movedAlignedCFrame)
	local unalignedDecoded = roundTripByTypeName("CFrame", unalignedCFrame)

	assertCFrameClose(alignedDecoded, alignedCFrame, 0.0001, "Aligned CFrame round trip mismatch.")
	assertCFrameClose(movedAlignedDecoded, movedAlignedCFrame, 0.0001, "Moved aligned CFrame round trip mismatch.")
	assertCFrameClose(unalignedDecoded, unalignedCFrame, 0.01, "Unaligned CFrame round trip mismatch.")
end

do
	local numberSequenceTypeInfo = TypeInfos.GetTypeInfoByTypeName("NumberSequence")
	local overflowNumberSequence = { Keypoints = table.create(256, true) }
	local numberSequenceBuffer = buffer.create(1)

	Assertions.assertErrorContains(function()
		numberSequenceTypeInfo.Serialize(numberSequenceBuffer, 0, overflowNumberSequence)
	end, "NumberSequence keypoint count must be <= 255", "NumberSequence keypoint overflow must throw an error.")

	local colorSequenceTypeInfo = TypeInfos.GetTypeInfoByTypeName("ColorSequence")
	local overflowColorSequence = { Keypoints = table.create(256, true) }
	local colorSequenceBuffer = buffer.create(1)

	Assertions.assertErrorContains(function()
		colorSequenceTypeInfo.Serialize(colorSequenceBuffer, 0, overflowColorSequence)
	end, "ColorSequence keypoint count must be <= 255", "ColorSequence keypoint overflow must throw an error.")
end

do
	local cFrameList = {
		CFrame.new(0, 0, 0),
		CFrame.new(10, 5, -2) * CFrame.Angles(math.rad(15), math.rad(30), math.rad(45)),
		CFrame.new(-1.5, 9, 99.125) * CFrame.Angles(math.rad(-10), math.rad(-25), math.rad(5)),
	}

	local decodedList = roundTripByTypeName("CFrameList", cFrameList)
	Assertions.assertEqual(#decodedList, #cFrameList, "CFrameList length mismatch.")
	for i, value in cFrameList do
		assertCFrameClose(decodedList[i], value, 0.01, "CFrameList element round trip mismatch.")
	end
end

do
	local overflowCFrameList = table.create(65536, CFrame.identity)
	Assertions.assertErrorContains(function()
		roundTripByTypeName("CFrameList", overflowCFrameList)
	end, "CFrameList length must be <= 65535", "CFrameList length overflow must throw an error.")
end

do
	local fontValue = Font.fromEnum(Enum.Font.GothamBold)
	local decodedFont = roundTripByTypeName("Font", fontValue)

	Assertions.assertEqual(decodedFont.Family, fontValue.Family, "Font.Family round trip mismatch.")
	Assertions.assertEqual(decodedFont.Weight, fontValue.Weight, "Font.Weight round trip mismatch.")
	Assertions.assertEqual(decodedFont.Style, fontValue.Style, "Font.Style round trip mismatch.")

	local overflowFontFamily = string.rep("A", 65536)
	local overflowFont = Font.new(overflowFontFamily, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	Assertions.assertErrorContains(function()
		roundTripByTypeName("Font", overflowFont)
	end, "Font family length must be <= 65535", "Font family length overflow must throw an error.")
end

return true
