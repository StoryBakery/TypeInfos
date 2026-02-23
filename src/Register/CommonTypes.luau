--!native

--[[
	Common TypeInfo 등록 모듈입니다.
	Luau 기본 타입과 공용 확장 타입의 직렬화 규칙을 등록합니다.
]]

local function registerCommonTypes(context)
	local createTypeInfo = context.createTypeInfo
	local typeInfosByName = context.typeInfosByName
	local TypeInfos = context.TypeInfos
	local TableUtil = context.TableUtil
	local POS_INF = context.POS_INF
	local NEG_INF = context.NEG_INF
	local BINARY_POS_INF_F16 = context.BINARY_POS_INF_F16
	local BINARY_NEG_INF_F16 = context.BINARY_NEG_INF_F16
	local BINARY_NAN_F16 = context.BINARY_NAN_F16

	local function assertUInt16(value: any, label: string)
		if typeof(value) ~= "number" or value % 1 ~= 0 or value < 0 or value > 65535 then
			error(`{label} must be an integer between 0 and 65535.`)
		end
	end

	typeInfosByName["boolean"] = createTypeInfo("boolean", {
		Default = false,
		IsLuauType = true,
		Size = 1,
		Serialize = function(b, offset, value)
			buffer.writeu8(b, offset, if value then 1 else 0)
		end,
		Deserialize = function(b, offset)
			return buffer.readu8(b, offset) == 1
		end,
	})

	typeInfosByName["string"] = createTypeInfo("string", {
		Default = "",
		IsLuauType = true,
		Size = "Undefined",
		GetSize = function(value: string)
			return #value + 2
		end,
		Serialize = function(b, offset, value)
			local length = string.len(value)
			if length > 65535 then
				error("string length must be <= 65535.")
			end

			buffer.writeu16(b, offset, length)
			buffer.writestring(b, offset + 2, value)
		end,
		Deserialize = function(b, offset)
			local len = buffer.readu16(b, offset)
			return buffer.readstring(b, offset + 2, len)
		end,
	})

	typeInfosByName["number"] = createTypeInfo("number", {
		Default = 0,
		IsLuauType = true,
		Size = 8,
		Serialize = function(b, offset, value)
			buffer.writef64(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readf64(b, offset)
		end,
	})

	typeInfosByName["FloatList"] = createTypeInfo("FloatList", {
		Default = {},
		Size = "Undefined",
		GetSize = function(value: { number })
			return 2 + #value * 8
		end,
		Serialize = function(b, offset, value: { number })
			local length = #value
			if length > 65535 then
				error("FloatList length must be <= 65535.")
			end

			buffer.writeu16(b, offset, length)
			for i = 1, length do
				buffer.writef64(b, offset + 2 + (i - 1) * 8, value[i])
			end
		end,
		Deserialize = function(b, offset)
			local length = buffer.readu16(b, offset)
			local result = table.create(length)
			for i = 1, length do
				result[i] = buffer.readf64(b, offset + 2 + (i - 1) * 8)
			end
			return result
		end,
		TypeCheck = "table",
		StrictTypeCheck = function(value)
			if typeof(value) ~= "table" then
				return false, `Not a table, but received "{value}", "{typeof(value)}"`
			end

			if not TableUtil.isArray(value) then
				return false, "Not an array"
			end

			for index, v in value do
				if typeof(v) ~= "number" then
					return false, `Element "{v}" at index "{index}" is not a number`
				end
			end

			return true
		end,
		TypeAnnotation = "{number}",
	})

	typeInfosByName["float16"] = createTypeInfo("float16", {
		Default = 0,
		Size = 2,
		Serialize = function(b, offset, value)
			if value == 0 then
				buffer.writeu16(b, offset, 0)
			elseif value == POS_INF then
				buffer.writeu16(b, offset, BINARY_POS_INF_F16)
			elseif value == NEG_INF then
				buffer.writeu16(b, offset, BINARY_NEG_INF_F16)
			elseif value ~= value then
				buffer.writeu16(b, offset, BINARY_NAN_F16)
			else
				local mantissa, exponent = math.frexp(math.abs(value))
				mantissa = math.round((mantissa - 0.5) * 2 ^ 11)
				exponent = math.clamp(exponent, -15, 16) + 15
				buffer.writeu16(b, offset, (value >= 0 and 0 or 2 ^ 15) + exponent * 2 ^ 10 + mantissa)
			end
		end,
		Deserialize = function(b, offset)
			local value = buffer.readu16(b, offset)

			if value == 0 then
				return 0
			elseif value == BINARY_POS_INF_F16 then
				return POS_INF
			elseif value == BINARY_NEG_INF_F16 then
				return NEG_INF
			elseif value == BINARY_NAN_F16 then
				return 0 / 0
			end

			local sign = bit32.band(value, 2 ^ 15) == 0 and 1 or -1
			local exponent = bit32.extract(value, 10, 5) - 15
			local mantissa = value % 2 ^ 10
			return sign * (mantissa / 2 ^ 10 * 0.5 + 0.5) * math.pow(2, exponent)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["float32"] = createTypeInfo("float32", {
		Default = 0,
		Size = 4,
		Serialize = function(b, offset, value)
			buffer.writef32(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readf32(b, offset)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["int8"] = createTypeInfo("int8", {
		Default = 0,
		Size = 1,
		Serialize = function(b, offset, value)
			buffer.writei8(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readi8(b, offset)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["int16"] = createTypeInfo("int16", {
		Default = 0,
		Size = 2,
		Serialize = function(b, offset, value)
			buffer.writei16(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readi16(b, offset)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["int32"] = createTypeInfo("int32", {
		Default = 0,
		Size = 4,
		Serialize = function(b, offset, value)
			buffer.writei32(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readi32(b, offset)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["uint8"] = createTypeInfo("uint8", {
		Default = 0,
		Size = 1,
		Serialize = function(b, offset, value)
			buffer.writeu8(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readu8(b, offset)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["uint16"] = createTypeInfo("uint16", {
		Default = 0,
		Size = 2,
		Serialize = function(b, offset, value)
			buffer.writeu16(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readu16(b, offset)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["uint32"] = createTypeInfo("uint32", {
		Default = 0,
		Size = 4,
		Serialize = function(b, offset, value)
			buffer.writeu32(b, offset, value)
		end,
		Deserialize = function(b, offset)
			return buffer.readu32(b, offset)
		end,
		TypeCheck = "number",
		TypeAnnotation = "number",
	})

	typeInfosByName["nil"] = createTypeInfo("nil", {
		Default = nil,
		IsLuauType = true,
		Size = 0,
		Serialize = function(b, offset, value) end,
		Deserialize = function(b, offset)
			return nil
		end,
	})

	do
		local function calculateTableElementSize(key: any, value: any): number
			local keyInfo = TypeInfos.GetTypeInfoByValueType(key)
			local valueInfo = TypeInfos.GetTypeInfoByValueType(value)
			return 2 + keyInfo.GetSize(key) + 2 + valueInfo.GetSize(value)
		end

		typeInfosByName["table"] = createTypeInfo("table", {
			Default = {},
			IsLuauType = true,
			Size = "Undefined",
			GetSize = function(value)
				local totalSize = 4
				for k, v in value do
					totalSize += calculateTableElementSize(k, v)
				end
				return totalSize
			end,
			Serialize = function(b, offset, value: { any })
				local count = 0
				for _ in value do
					count += 1
				end

				buffer.writeu32(b, offset, count)
				local currentOffset = offset + 4

				for key, itemValue in value do
					local keyInfo = TypeInfos.GetTypeInfoByValueType(key)
					local valueInfo = TypeInfos.GetTypeInfoByValueType(itemValue)

					buffer.writeu16(b, currentOffset, keyInfo.TypeId)
					currentOffset += 2

					keyInfo.Serialize(b, currentOffset, key)
					currentOffset += keyInfo.GetSize(key)

					buffer.writeu16(b, currentOffset, valueInfo.TypeId)
					currentOffset += 2

					valueInfo.Serialize(b, currentOffset, itemValue)
					currentOffset += valueInfo.GetSize(itemValue)
				end
			end,
			Deserialize = function(b, offset)
				local count = buffer.readu32(b, offset)
				local currentOffset = offset + 4
				local newTable = {}

				for _ = 1, count do
					local keyTypeId = buffer.readu16(b, currentOffset)
					local keyInfo = TypeInfos.GetTypeInfoByTypeId(keyTypeId)
					currentOffset += 2

					local key = keyInfo.Deserialize(b, currentOffset)
					local keySize = keyInfo.GetSize(key)
					currentOffset += keySize

					local valueTypeId = buffer.readu16(b, currentOffset)
					local valueInfo = TypeInfos.GetTypeInfoByTypeId(valueTypeId)
					currentOffset += 2

					local value = valueInfo.Deserialize(b, currentOffset)
					local valueSize = valueInfo.GetSize(value)
					currentOffset += valueSize

					newTable[key] = value
				end
				return newTable
			end,
		})
	end

	do
		local function resolveCustomEnumId(value)
			if typeof(value) ~= "table" then
				error(`CustomEnum must be a table, got "{typeof(value)}".`)
			end

			local id
			local getEnumId = value.GetEnumId
			if typeof(getEnumId) == "function" then
				id = getEnumId(value)
			else
				id = value.Id
			end

			if typeof(id) ~= "number" then
				error("CustomEnum.Id must be a number.")
			end

			assertUInt16(id, "CustomEnum.Id")
			return id
		end

		local function resolveCustomEnumItemIds(value)
			if typeof(value) ~= "table" then
				error(`CustomEnumItem must be a table, got "{typeof(value)}".`)
			end

			local enumId
			local itemId

			local getEnumId = value.GetEnumId
			if typeof(getEnumId) == "function" then
				enumId = getEnumId(value)
			else
				enumId = value.EnumId
			end

			local getItemId = value.GetItemId
			if typeof(getItemId) == "function" then
				itemId = getItemId(value)
			else
				itemId = value.ItemId
			end

			if typeof(enumId) ~= "number" then
				error("CustomEnumItem.EnumId must be a number.")
			end
			if typeof(itemId) ~= "number" then
				error("CustomEnumItem.ItemId must be a number.")
			end

			assertUInt16(enumId, "CustomEnumItem.EnumId")
			assertUInt16(itemId, "CustomEnumItem.ItemId")

			return enumId, itemId
		end

		typeInfosByName["CustomEnum"] = createTypeInfo("CustomEnum", {
			Default = { Id = 0 },
			IsEnum = true,
			Size = 2,
			Serialize = function(b, offset, value)
				buffer.writeu16(b, offset, resolveCustomEnumId(value))
			end,
			Deserialize = function(b, offset)
				return { Id = buffer.readu16(b, offset) }
			end,
			TypeCheck = function(value)
				if typeof(value) ~= "table" then
					return false
				end
				if typeof(value.GetEnumId) == "function" then
					return true
				end
				return typeof(value.Id) == "number"
			end,
			TypeAnnotation = "CustomEnum",
		})

		typeInfosByName["CustomEnumItem"] = createTypeInfo("CustomEnumItem", {
			Default = { EnumId = 0, ItemId = 0 },
			IsEnum = true,
			Size = 4,
			Serialize = function(b, offset, value)
				local enumId, itemId = resolveCustomEnumItemIds(value)
				buffer.writeu16(b, offset, enumId)
				buffer.writeu16(b, offset + 2, itemId)
			end,
			Deserialize = function(b, offset)
				return {
					EnumId = buffer.readu16(b, offset),
					ItemId = buffer.readu16(b, offset + 2),
				}
			end,
			TypeCheck = function(value)
				if typeof(value) ~= "table" then
					return false
				end

				local hasEnumId = typeof(value.GetEnumId) == "function" or typeof(value.EnumId) == "number"
				local hasItemId = typeof(value.GetItemId) == "function" or typeof(value.ItemId) == "number"
				return hasEnumId and hasItemId
			end,
			TypeAnnotation = "CustomEnumItem",
		})
	end
end

return registerCommonTypes
