--!native

--[[
	Roblox TypeInfo 등록 모듈입니다.
	엔진 제공 타입과 Enum 직렬화 규칙을 등록합니다.
]]

local function registerRobloxTypes(context)
	local createTypeInfo = context.createTypeInfo
	local typeInfosByName = context.typeInfosByName
	local ReplicatedInstanceId = context.ReplicatedInstanceId

	typeInfosByName["Vector3"] = createTypeInfo("Vector3", {
		Default = Vector3.zero,
		IsRobloxType = true,
		Size = 12,
		Serialize = function(b, offset, value)
			buffer.writef32(b, offset, value.X)
			buffer.writef32(b, offset + 4, value.Y)
			buffer.writef32(b, offset + 8, value.Z)
		end,
		Deserialize = function(b, offset)
			local x = buffer.readf32(b, offset)
			local y = buffer.readf32(b, offset + 4)
			local z = buffer.readf32(b, offset + 8)
			return Vector3.new(x, y, z)
		end,
	})

	typeInfosByName["Color3"] = createTypeInfo("Color3", {
		Default = Color3.fromRGB(255, 255, 255),
		IsRobloxType = true,
		Size = 12,
		Serialize = function(b, offset, value)
			buffer.writef32(b, offset, value.R)
			buffer.writef32(b, offset + 4, value.G)
			buffer.writef32(b, offset + 8, value.B)
		end,
		Deserialize = function(b, offset)
			local r = buffer.readf32(b, offset)
			local g = buffer.readf32(b, offset + 4)
			local b_ = buffer.readf32(b, offset + 8)
			return Color3.new(r, g, b_)
		end,
	})

	typeInfosByName["Color3uint8"] = createTypeInfo("Color3uint8", {
		Default = Color3.fromRGB(255, 255, 255),
		Size = 3,
		Serialize = function(b, offset, value: Color3)
			buffer.writeu8(b, offset, math.floor(value.R * 255 + 0.5))
			buffer.writeu8(b, offset + 1, math.floor(value.G * 255 + 0.5))
			buffer.writeu8(b, offset + 2, math.floor(value.B * 255 + 0.5))
		end,
		Deserialize = function(b, offset)
			return Color3.fromRGB(buffer.readu8(b, offset), buffer.readu8(b, offset + 1), buffer.readu8(b, offset + 2))
		end,
		TypeCheck = "Color3",
		TypeAnnotation = "Color3",
	})

	typeInfosByName["NumberSequence"] = createTypeInfo("NumberSequence", {
		Default = NumberSequence.new(0),
		IsRobloxType = true,
		Size = "Undefined",
		GetSize = function(value: NumberSequence)
			local count = #value.Keypoints
			return 1 + count * 12
		end,
		Serialize = function(b, offset, value)
			local keypoints = value.Keypoints
			local count = #keypoints
			if count > 255 then
				error("NumberSequence keypoint count must be <= 255.")
			end

			buffer.writeu8(b, offset, count)
			offset += 1
			for i = 1, count do
				local kp = keypoints[i]
				buffer.writef32(b, offset, kp.Time)
				buffer.writef32(b, offset + 4, kp.Value)
				buffer.writef32(b, offset + 8, kp.Envelope)
				offset = offset + 12
			end
		end,
		Deserialize = function(b, offset)
			local count = buffer.readu8(b, offset)
			offset += 1

			local keypoints = {}
			for i = 1, count do
				local time = buffer.readf32(b, offset)
				local value = buffer.readf32(b, offset + 4)
				local envelope = buffer.readf32(b, offset + 8)
				keypoints[i] = NumberSequenceKeypoint.new(time, value, envelope)
				offset = offset + 12
			end
			return NumberSequence.new(keypoints)
		end,
	})

	typeInfosByName["ColorSequence"] = createTypeInfo("ColorSequence", {
		Default = ColorSequence.new(Color3.new(1, 1, 1)),
		IsRobloxType = true,
		Size = "Undefined",
		GetSize = function(value: ColorSequence)
			local count = #value.Keypoints
			return 1 + count * 7
		end,
		Serialize = function(b, offset, value)
			local keypoints = value.Keypoints
			local count = #keypoints
			if count > 255 then
				error("ColorSequence keypoint count must be <= 255.")
			end

			buffer.writeu8(b, offset, count)
			offset += 1

			for _, kp in keypoints do
				buffer.writef32(b, offset, kp.Time)
				local r = math.floor(kp.Value.R * 255 + 0.5)
				local g = math.floor(kp.Value.G * 255 + 0.5)
				local b_ = math.floor(kp.Value.B * 255 + 0.5)
				buffer.writeu8(b, offset + 4, r)
				buffer.writeu8(b, offset + 5, g)
				buffer.writeu8(b, offset + 6, b_)
				offset = offset + 7
			end
		end,
		Deserialize = function(b, offset)
			local count = buffer.readu8(b, offset)
			offset = offset + 1

			local keypoints = {}
			for i = 1, count do
				local time = buffer.readf32(b, offset)
				local r = buffer.readu8(b, offset + 4)
				local g = buffer.readu8(b, offset + 5)
				local b_ = buffer.readu8(b, offset + 6)
				keypoints[i] = ColorSequenceKeypoint.new(time, Color3.fromRGB(r, g, b_))
				offset = offset + 7
			end
			return ColorSequence.new(keypoints)
		end,
	})

	typeInfosByName["NumberRange"] = createTypeInfo("NumberRange", {
		Default = NumberRange.new(0),
		IsRobloxType = true,
		Size = 8,
		Serialize = function(b, offset, value)
			buffer.writef32(b, offset, value.Min)
			buffer.writef32(b, offset + 4, value.Max)
		end,
		Deserialize = function(b, offset)
			local min = buffer.readf32(b, offset)
			local max = buffer.readf32(b, offset + 4)
			return NumberRange.new(min, max)
		end,
	})

	typeInfosByName["Vector2"] = createTypeInfo("Vector2", {
		Default = Vector2.zero,
		IsRobloxType = true,
		Size = 8,
		Serialize = function(b, offset, value)
			buffer.writef32(b, offset, value.X)
			buffer.writef32(b, offset + 4, value.Y)
		end,
		Deserialize = function(b, offset)
			local x = buffer.readf32(b, offset)
			local y = buffer.readf32(b, offset + 4)
			return Vector2.new(x, y)
		end,
	})

	typeInfosByName["UDim"] = createTypeInfo("UDim", {
		Default = UDim.new(),
		IsRobloxType = true,
		Size = 8,
		Serialize = function(b, offset, value)
			buffer.writef32(b, offset, value.Scale)
			buffer.writei32(b, offset + 4, value.Offset)
		end,
		Deserialize = function(b, offset)
			local scale = buffer.readf32(b, offset)
			local offset_ = buffer.readi32(b, offset + 4)
			return UDim.new(scale, offset_)
		end,
	})

	typeInfosByName["UDim2"] = createTypeInfo("UDim2", {
		Default = UDim2.new(),
		IsRobloxType = true,
		Size = 16,
		Serialize = function(b, offset, value)
			buffer.writef32(b, offset, value.X.Scale)
			buffer.writei32(b, offset + 4, value.X.Offset)
			buffer.writef32(b, offset + 8, value.Y.Scale)
			buffer.writei32(b, offset + 12, value.Y.Offset)
		end,
		Deserialize = function(b, offset)
			local xScale = buffer.readf32(b, offset)
			local xOffset = buffer.readi32(b, offset + 4)
			local yScale = buffer.readf32(b, offset + 8)
			local yOffset = buffer.readi32(b, offset + 12)
			return UDim2.new(xScale, xOffset, yScale, yOffset)
		end,
	})

	do
		local I16_PRECISION = 32767

		local function quaternionVector3FromCFrame(cf: CFrame)
			local axis, angle = cf:ToAxisAngle()
			local half = math.sin(angle / 2)
			return axis * half
		end

		local alignedCFrames = {
			CFrame.Angles(0, 0, 0),
			CFrame.Angles(math.rad(90), 0, 0),
			CFrame.Angles(0, math.rad(180), math.rad(180)),
			CFrame.Angles(math.rad(-90), 0, 0),
			CFrame.Angles(0, math.rad(180), math.rad(90)),
			CFrame.Angles(0, math.rad(90), math.rad(90)),
			CFrame.Angles(0, 0, math.rad(90)),
			CFrame.Angles(0, math.rad(-90), math.rad(90)),
			CFrame.Angles(math.rad(-90), math.rad(-90), 0),
			CFrame.Angles(0, math.rad(-90), 0),
			CFrame.Angles(math.rad(90), math.rad(-90), 0),
			CFrame.Angles(0, math.rad(90), math.rad(180)),
			CFrame.Angles(0, math.rad(-90), math.rad(180)),
			CFrame.Angles(0, math.rad(180), math.rad(0)),
			CFrame.Angles(math.rad(-90), math.rad(-180), math.rad(0)),
			CFrame.Angles(0, math.rad(0), math.rad(180)),
			CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
			CFrame.Angles(0, math.rad(0), math.rad(-90)),
			CFrame.Angles(0, math.rad(-90), math.rad(-90)),
			CFrame.Angles(0, math.rad(-180), math.rad(-90)),
			CFrame.Angles(0, math.rad(90), math.rad(-90)),
			CFrame.Angles(math.rad(90), math.rad(90), 0),
			CFrame.Angles(0, math.rad(90), 0),
			CFrame.Angles(math.rad(-90), math.rad(90), 0),
		}

		local ALIGNED_COMPONENT_TOLERANCE = 0.00001

		local function normalizeAlignedComponent(value: number): number?
			if math.abs(value) <= ALIGNED_COMPONENT_TOLERANCE then
				return 0
			end
			if math.abs(value - 1) <= ALIGNED_COMPONENT_TOLERANCE then
				return 1
			end
			if math.abs(value + 1) <= ALIGNED_COMPONENT_TOLERANCE then
				return -1
			end
			return nil
		end

		local function getAlignedRotationKey(value: CFrame): string?
			local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
			local n00 = normalizeAlignedComponent(r00)
			local n01 = normalizeAlignedComponent(r01)
			local n02 = normalizeAlignedComponent(r02)
			local n10 = normalizeAlignedComponent(r10)
			local n11 = normalizeAlignedComponent(r11)
			local n12 = normalizeAlignedComponent(r12)
			local n20 = normalizeAlignedComponent(r20)
			local n21 = normalizeAlignedComponent(r21)
			local n22 = normalizeAlignedComponent(r22)
			if n00 == nil or n01 == nil or n02 == nil then
				return nil
			end
			if n10 == nil or n11 == nil or n12 == nil then
				return nil
			end
			if n20 == nil or n21 == nil or n22 == nil then
				return nil
			end

			return `{n00},{n01},{n02},{n10},{n11},{n12},{n20},{n21},{n22}`
		end

		local alignedCFrameIdsByRotationKey = {}
		for i, alignedCFrame in alignedCFrames do
			local key = getAlignedRotationKey(alignedCFrame)
			if key ~= nil then
				alignedCFrameIdsByRotationKey[key] = i - 1
			end
		end

		local function getAlignedCFrameId(value: CFrame): number?
			local key = getAlignedRotationKey(value)
			if key == nil then
				return nil
			end
			return alignedCFrameIdsByRotationKey[key]
		end

		local function serializeCFrame(b: buffer, offset: number, value: CFrame)
			buffer.writef32(b, offset, value.X)
			buffer.writef32(b, offset + 4, value.Y)
			buffer.writef32(b, offset + 8, value.Z)

			local qVector = quaternionVector3FromCFrame(value)
			local qx = math.floor(qVector.X * I16_PRECISION + 0.5)
			local qy = math.floor(qVector.Y * I16_PRECISION + 0.5)
			local qz = math.floor(qVector.Z * I16_PRECISION + 0.5)

			buffer.writei16(b, offset + 12, qx)
			buffer.writei16(b, offset + 14, qy)
			buffer.writei16(b, offset + 16, qz)
		end

		local function deserializeCFrame(b: buffer, offset: number): CFrame
			local x = buffer.readf32(b, offset)
			local y = buffer.readf32(b, offset + 4)
			local z = buffer.readf32(b, offset + 8)

			local qx = buffer.readi16(b, offset + 12) / I16_PRECISION
			local qy = buffer.readi16(b, offset + 14) / I16_PRECISION
			local qz = buffer.readi16(b, offset + 16) / I16_PRECISION

			local qw = math.sqrt(1 - (qx ^ 2 + qy ^ 2 + qz ^ 2))
			return CFrame.new(x, y, z, qx, qy, qz, qw)
		end

		typeInfosByName["CFrame"] = createTypeInfo("CFrame", {
			Default = CFrame.identity,
			IsRobloxType = true,
			Size = "Undefined",
			GetSize = function(value)
				return if getAlignedCFrameId(value) ~= nil then 14 else 19
			end,
			Serialize = function(b, offset, value)
				local alignedCFrameId = getAlignedCFrameId(value)
				if alignedCFrameId ~= nil then
					buffer.writeu8(b, offset, 1)
					buffer.writeu8(b, offset + 1, alignedCFrameId)
					buffer.writef32(b, offset + 2, value.X)
					buffer.writef32(b, offset + 6, value.Y)
					buffer.writef32(b, offset + 10, value.Z)
					return
				end

				buffer.writeu8(b, offset, 0)
				serializeCFrame(b, offset + 1, value)
			end,
			Deserialize = function(b, offset)
				local isAligned = buffer.readu8(b, offset) == 1
				if isAligned then
					local alignedCFrameId = buffer.readu8(b, offset + 1)
					local alignedCFrame = alignedCFrames[alignedCFrameId + 1]
					local x = buffer.readf32(b, offset + 2)
					local y = buffer.readf32(b, offset + 6)
					local z = buffer.readf32(b, offset + 10)
					return CFrame.new(x, y, z) * alignedCFrame
				end

				return deserializeCFrame(b, offset + 1)
			end,
		})

		typeInfosByName["CFrameList"] = createTypeInfo("CFrameList", {
			Default = {},
			TypeAnnotation = "{CFrame}",
			Size = "Undefined",
			GetSize = function(value: { CFrame })
				return 2 + #value * 18
			end,
			Serialize = function(b, offset, value: { CFrame })
				local length = #value
				if length > 65535 then
					error("CFrameList length must be <= 65535.")
				end

				buffer.writeu16(b, offset, length)
				for i = 1, length do
					serializeCFrame(b, offset + 2 + 18 * (i - 1), value[i])
				end
			end,
			Deserialize = function(b, offset)
				local length = buffer.readu16(b, offset)
				local t = {}
				for i = 1, length do
					t[i] = deserializeCFrame(b, offset + 2 + 18 * (i - 1))
				end
				return t
			end,
		})
	end

	local fontWeights = Enum.FontWeight:GetEnumItems()
	local fontWeightIdsByWeight = {}
	for i, fontWeight in fontWeights do
		fontWeightIdsByWeight[fontWeight] = i
	end

	local fontStyles = Enum.FontStyle:GetEnumItems()
	local fontStyleIdsByStyle = {}
	for i, fontStyle in fontStyles do
		fontStyleIdsByStyle[fontStyle] = i
	end

	typeInfosByName["Font"] = createTypeInfo("Font", {
		Default = Enum.Font.Arial,
		IsRobloxType = true,
		Size = "Undefined",
		GetSize = function(value: Font)
			return 4 + #value.Family
		end,
		Serialize = function(b, offset, value: Font)
			local familyLength = #value.Family
			if familyLength > 65535 then
				error("Font family length must be <= 65535.")
			end

			buffer.writeu16(b, offset, familyLength)
			buffer.writestring(b, offset + 2, value.Family)

			offset += 2 + familyLength
			buffer.writeu8(b, offset, fontWeightIdsByWeight[value.Weight] - 1)
			buffer.writeu8(b, offset + 1, fontStyleIdsByStyle[value.Style] - 1)
		end,
		Deserialize = function(b, offset)
			local len = buffer.readu16(b, offset)
			local family = buffer.readstring(b, offset + 2, len)

			offset += 2 + len
			local weightVal = buffer.readu8(b, offset)
			local styleVal = buffer.readu8(b, offset + 1)

			local fontWeight = fontWeights[weightVal + 1]
			local fontStyle = fontStyles[styleVal + 1]

			return Font.new(family, fontWeight, fontStyle)
		end,
	})

	typeInfosByName["Instance"] = createTypeInfo("Instance", {
		Default = nil,
		IsRobloxType = true,
		Size = 4,
		Serialize = function(b, offset, value: Instance?)
			if value then
				buffer.writeu32(b, offset, ReplicatedInstanceId.FindOrAssignId(value))
			else
				buffer.writeu32(b, offset, 0)
			end
		end,
		Deserialize = function(b, offset)
			local id = buffer.readu32(b, offset)
			if id == 0 then
				return nil
			end
			return ReplicatedInstanceId.FindInstanceFromId(id)
		end,
		TypeCheck = function(value)
			return typeof(value) == "Instance" or value == nil
		end,
	})

	do
		local robloxEnumIdsByEnum = {}
		local robloxEnumsById = {}
		local robloxEnumItemIdsByEnum = {}
		local robloxEnumItemsByEnumAndId = {}

		for enumIndex, enum in Enum:GetEnums() do
			robloxEnumIdsByEnum[enum] = enumIndex
			robloxEnumsById[enumIndex] = enum

			robloxEnumItemsByEnumAndId[enum] = {}
			for enumItemIndex, enumItem in enum:GetEnumItems() do
				robloxEnumItemIdsByEnum[enumItem] = enumItemIndex
				robloxEnumItemsByEnumAndId[enum][enumItemIndex] = enumItem
			end
		end

		typeInfosByName["EnumItem"] = createTypeInfo("EnumItem", {
			Default = Enum.KeyCode.X,
			IsEnum = true,
			IsRobloxType = true,
			Size = 4,
			Serialize = function(b, offset, value: EnumItem)
				buffer.writeu16(b, offset, robloxEnumIdsByEnum[value.EnumType])
				buffer.writeu16(b, offset + 2, robloxEnumItemIdsByEnum[value])
			end,
			Deserialize = function(b, offset)
				local enum = robloxEnumsById[buffer.readu16(b, offset)]
				return robloxEnumItemsByEnumAndId[enum][buffer.readu16(b, offset + 2)]
			end,
		})
	end
end

return registerRobloxTypes
