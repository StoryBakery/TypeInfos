--!native

--[=[
	@class TypeInfos
    
	직렬화, 역직렬화, 검증에 사용하는 TypeInfo 정의를 관리합니다.
	각 TypeInfo 는 버퍼에 데이터를 안전하게 저장하는 방법을 설명합니다.
]=]

local isRobloxEnv = game ~= nil and typeof(game.GetService) == "function"

local HttpService = if isRobloxEnv then game:GetService("HttpService") else nil
local ReplicatedStorage = if isRobloxEnv then game:GetService("ReplicatedStorage") else nil
local RunService = if isRobloxEnv then game:GetService("RunService") else nil
local HAS_ROBLOX_RUNTIME = isRobloxEnv
	and HttpService ~= nil
	and ReplicatedStorage ~= nil
	and RunService ~= nil

local TableUtil = require("./roblox_packages/TableUtil")
local msgpack_luau = require("./roblox_packages/msgpack-luau")

local ReplicatedInstanceId = if HAS_ROBLOX_RUNTIME
	then require("./roblox_packages/ReplicatedInstanceId")
	else nil

local registerCommonTypes = require("@self/Register/CommonTypes")
local registerRobloxTypes = require("@self/Register/RobloxTypes")

local POS_INF = math.huge
local NEG_INF = -POS_INF

local BINARY_POS_INF_F16 = 0b0111110000000000
local BINARY_NEG_INF_F16 = 0b1111110000000000
local BINARY_NAN_F16 = 0b0111110000000001

local TypeInfos = {}
local typeInfosByName = {}

--[=[
	@class TypeInfo
	단일 데이터 타입에 대한 메타데이터로 직렬화, 역직렬화, 검증 로직을 모두 포함합니다.
]=]
local TypeInfo = {}
TypeInfo.__index = TypeInfo
TypeInfo.__type = "TypeInfo"

--[=[
	@function TypeInfo.Serialize
	전달된 버퍼에 값을 직렬화합니다.
	@param buf - 데이터를 기록할 버퍼.
	@param offset - 기록을 시작할 바이트 오프셋.
	@param value - 직렬화할 값.
]=]
export type Serialize = (buf: buffer, offset: number, value: any) -> ()

--[=[
	@function TypeInfo.Deserialize
	전달된 버퍼에서 값을 역직렬화합니다.
	@param buf - 데이터를 읽어올 버퍼.
	@param offset - 읽기를 시작할 바이트 오프셋.
	@return any - 복원된 값.
]=]
export type Deserialize = (buf: buffer, offset: number) -> any

--[=[
	@function TypeInfo.TypeCheck
	전달된 값이 이 TypeInfo 와 일치하는지 검증합니다.
	@param value - 검증할 값.
	@return boolean - 유효하면 true.
]=]
export type TypeCheck = (value: any) -> boolean

--[=[
	@prop StrictTypeCheck TypeCheck
	@within TypeInfo
	이 TypeInfo 에 대해 엄격한 타입 검사를 수행하는 함수입니다.
	기본 TypeCheck 와는 별개로, 더 엄격한 검사가 필요할 때 사용됩니다.
	
	성능 비용이 보다 크기에, TypeCheck 로만 사용하는 것을 권장합니다.
	StrictTypeCheck는 스튜디오[RunService:IsStudio]에서나, 
	런타임 도중 단 한번만 실행되는 매우 엄격한 검사가 필요한 경우에만 사용하세요.
	TypeCheck 도 성능 비용이 크기에, 과도 사용을 권장하지 않습니다.
	
	TypeCheck 는 완벽히 타입을 따르지않아도, 
	어떻게든 에러없이 Serialize/Deseiralize가 될 수 있다면 허용하는 반면 
	StrictTypeCheck 는 정확히 그 타입이어야만 허용하는 함수입니다.
	
	TypeCheck 예시: 
	uint32
	6.13 는 정확하게는 uint32 가 아님에도, Serialize 시 6 으로 에러없이 변환됨
	-150 는 정확하게는 uint32 가 아님에도, Serialize 시 4294967146 으로 에러없이 변환됨
	
	StrictTypeCheck 예시:
	uint32
	6.13 는 실수기에 허용되지 않음
	-150 는 음수기에 허용되지 않음
	
	기본적으로 TypeCheck 와 동일하게 설정됩니다.
	
	@param value - 검증할 값.
	@return boolean - 유효하면 true
	@return string? - 유효하지 않을 때의 원인, 유효하지 않을 때도 원인은 출력안될 수 있음
]=]
export type StrictTypeCheck = (value: any) -> (boolean, string?)

export type TypeInfo = setmetatable<{
	--[=[
		@prop TypeInfo.Name string
		TypeInfo 의 이름입니다. 예: "float32", "Color3", "Instance".
	]=]
	Name: string,

	--[=[
		@prop TypeInfo.TypeId number
		이 TypeInfo 에 부여된 내부 숫자 식별자입니다.
	]=]
	TypeId: number,

	--[=[
		@prop TypeInfo.RobloxTypeId number?
		Roblox 엔진 타입에 대응하는 경우 사용하는 엔진 타입 식별자입니다.
	]=]
	RobloxTypeId: number?,

	--[=[
		@prop TypeInfo.EnumTypeId number?
		Enum 에 대응하는 경우 사용하는 Enum 식별자입니다.
	]=]
	EnumTypeId: number?,

	--[=[
		@prop TypeInfo.Default any
		값이 주어지지 않았을 때 사용할 기본값입니다.
	]=]
	Default: any,

	--[=[
		@prop TypeInfo.TypeAnnotation string
		Luau 타입 표기 문자열입니다. 예: "number", "Color3".
	]=]
	TypeAnnotation: string,

	--[=[
		@prop TypeInfo.Size number | "Undefined"
		고정 크기 타입이라면 여기에서 바이트 길이를 저장하고, 가변 크기 타입이라면 "Undefined" 로 두고 GetSize 를 사용합니다.
	]=]
	Size: number | "Undefined",
	GetSize: (value: any) -> number,

	Serialize: Serialize,
	Deserialize: Deserialize,
	TypeCheck: TypeCheck,
	StrictTypeCheck: StrictTypeCheck,

	--[=[
		@prop TypeInfo.IsLuauType boolean
		이 타입이 Luau 에서 제공하는 기본 타입인지 여부를 나타냅니다.
	]=]
	IsLuauType: boolean,

	--[=[
		@prop TypeInfo.IsRobloxType boolean
		이 타입이 Roblox 엔진에서 제공하는 기본 타입인지 여부를 나타냅니다.
	]=]
	IsRobloxType: boolean,

	--[=[
		@prop TypeInfo.IsEnum boolean
		이 타입이 Enum 을 표현하는지 여부를 나타냅니다.
	]=]
	IsEnum: boolean,

	--[=[
		@prop TypeInfo.IsAttributeCompatible boolean
		Instance 의 Attribute 에 값을 그대로 넣어도 가능한 타입인지 여부입니다.
	]=]
	IsAttributeCompatible: boolean,
}, typeof(TypeInfo)>

export type CustomEnumItem = {
	EnumId: number,
	ItemId: number,
	Name: string,
	Value: any,
	GetEnumId: (self: CustomEnumItem) -> number,
	GetItemId: (self: CustomEnumItem) -> number,
}

export type CustomEnum = {
	Id: number,
	Name: string,
	Items: { CustomEnumItem },
	GetEnumId: (self: CustomEnum) -> number,
	GetEnumItems: (self: CustomEnum) -> { CustomEnumItem },
}

local any = {} :: any
local ATTRIBUTE_COMPATIBLE_TYPEOFS = table.freeze({
	boolean = true,
	number = true,
	string = true,
	Vector2 = true,
	Vector3 = true,
	Vector2int16 = true,
	Vector3int16 = true,
	UDim = true,
	UDim2 = true,
	Rect = true,
	CFrame = true,
	Color3 = true,
	ColorSequence = true,
	BrickColor = true,
	NumberRange = true,
	NumberSequence = true,
	PhysicalProperties = true,
})
local DATA_TYPE_PARAMS_TYPE = {
	Default = any :: any?,
	TypeAnnotation = any :: string?,

	Size = any :: number | "Undefined",
	GetSize = any :: ((value: any) -> number)?,

	Serialize = any :: Serialize,
	Deserialize = any :: Deserialize,
	TypeCheck = any :: TypeCheck | string?,
	StrictTypeCheck = any :: TypeCheck?,

	IsLuauType = any :: boolean?,
	IsRobloxType = any :: boolean?,
	IsEnum = any :: boolean?,
	IsAttributeCompatible = any :: boolean?,
}
type TypeInfoParams = typeof(DATA_TYPE_PARAMS_TYPE)

--[[
	새로운 **TypeInfo**를 정의해 **TypeInfos** 테이블에 등록하는 내부 함수입니다. 

	이 함수를 통해 `Serialize`, `Deserialize`, `Size`, `TypeCheck` 등 필요한 정보를 모두 설정하면,  
	해당 `TypeInfo` 객체가 `TypeInfos[name]` 에 보관되고, 이후 직렬화/역직렬화 시 사용됩니다.

	외부에서 사용할 수 없습니다.
]]
local function setTypeAnnotation(self: TypeInfo, paramTypeAnnotation: string?, default: any?)
	if paramTypeAnnotation == nil then
		self.TypeAnnotation = typeof(default)
	elseif typeof(paramTypeAnnotation) == "table" then
		self.TypeAnnotation = `"{table.concat(paramTypeAnnotation, `"|"`)}"`
	else
		self.TypeAnnotation = paramTypeAnnotation
	end
end

local function assertUInt16(value: any, label: string)
	if typeof(value) ~= "number" or value % 1 ~= 0 or value < 0 or value > 65535 then
		error(`{label} must be an integer between 0 and 65535.`)
	end
end

local function resolveCustomEnumItemDefinition(
	baseItem: string | { Name: string, Value: any },
	index: number
): (string, any)
	if typeof(baseItem) == "string" then
		return baseItem, nil
	end
	if typeof(baseItem) ~= "table" then
		error(`Enum item at index "{index}" must be string or table.`)
	end

	local itemName = baseItem.Name
	if typeof(itemName) ~= "string" then
		error(`Enum item Name at index "{index}" must be a string.`)
	end

	return itemName, baseItem.Value
end

local function createCustomEnumItem(
	enumId: number,
	itemId: number,
	itemName: string,
	itemValue: any
): CustomEnumItem
	assertUInt16(enumId, "EnumId")
	assertUInt16(itemId, "ItemId")

	return {
		EnumId = enumId,
		ItemId = itemId,
		Name = itemName,
		Value = itemValue,
		GetEnumId = function(self)
			return self.EnumId
		end,
		GetItemId = function(self)
			return self.ItemId
		end,
	}
end

local function createCustomEnum(
	enumId: number,
	enumItems: { string | { Name: string, Value: any } }
): CustomEnum
	assertUInt16(enumId, "EnumId")

	local items = table.create(#enumItems)
	local enumValue = {
		Id = enumId,
		Name = tostring(enumId),
		Items = items,
		GetEnumId = function(self)
			return self.Id
		end,
		GetEnumItems = function(self)
			return self.Items
		end,
	}

	for i, baseItem in enumItems do
		local itemName, itemValue = resolveCustomEnumItemDefinition(baseItem, i)
		local item = createCustomEnumItem(enumId, i - 1, itemName, itemValue)

		items[i] = item
		if enumValue[itemName] ~= nil then
			error(`Enum item name "{itemName}" is reserved or duplicated.`)
		end
		enumValue[itemName] = item
	end

	return enumValue
end

local function createTypeInfo(name: string, params: TypeInfoParams): TypeInfo
	assert(typeInfosByName[name] == nil, `TypeInfo "{name}" has already been declared.`)

	for key in params do
		if DATA_TYPE_PARAMS_TYPE[key] == nil then
			error(`"{key}" is invalid TypeInfoParams Key.`)
		end
	end

	local self = setmetatable({}, TypeInfo)

	self.Name = name

	if params.Default == nil and not (name == "Instance" or name == "nil") then
		error(`TypeInfo "{name}"'s Default is nil.`)
	end
	self.Default = params.Default

	self.Serialize = params.Serialize or error(`Missing Serialize Function for TypeInfo "{name}"`)
	self.Deserialize = params.Deserialize
		or error(`Missing Deserialize Function for TypeInfo "{name}"`)

	local size = params.Size
	if typeof(size) == "number" then
		self.Size = size

		if params.GetSize then
			error(`Cannot set GetSize for TypeInfo "{name}". It already has a defined size.`)
		end

		self.GetSize = function()
			return self.Size
		end
	elseif size == "Undefined" then
		self.Size = size

		self.GetSize = params.GetSize or error(`Missing GetSize Function for TypeInfo "{name}"`)
	else
		error(`TypeInfo "{name}" Size must be a number or 'Undefined'.`)
	end

	if params.TypeCheck == nil then
		self.TypeCheck = function(value)
			return typeof(value) == name
		end
	elseif typeof(params.TypeCheck) == "string" then
		local dataName = params.TypeCheck
		self.TypeCheck = function(value)
			return typeof(value) == dataName
		end
	else
		self.TypeCheck = params.TypeCheck
	end

	self.StrictTypeCheck = params.StrictTypeCheck or self.TypeCheck

	setTypeAnnotation(self, params.TypeAnnotation, params.Default)

	self.IsEnum = params.IsEnum or false
	self.IsLuauType = params.IsLuauType or false
	self.IsRobloxType = params.IsLuauType or params.IsRobloxType or false
	local isAttributeCompatible = params.IsAttributeCompatible
	if isAttributeCompatible == nil then
		local defaultValue = params.Default
		isAttributeCompatible = ATTRIBUTE_COMPATIBLE_TYPEOFS[typeof(defaultValue)] == true
	end
	self.IsAttributeCompatible = isAttributeCompatible

	typeInfosByName[name] = self
	TypeInfos[name] = self

	return self
end

registerCommonTypes({
	createTypeInfo = createTypeInfo,
	typeInfosByName = typeInfosByName,
	TypeInfos = TypeInfos,
	TableUtil = TableUtil,
	POS_INF = POS_INF,
	NEG_INF = NEG_INF,
	BINARY_POS_INF_F16 = BINARY_POS_INF_F16,
	BINARY_NEG_INF_F16 = BINARY_NEG_INF_F16,
	BINARY_NAN_F16 = BINARY_NAN_F16,
})

if HAS_ROBLOX_RUNTIME then
	registerRobloxTypes({
		createTypeInfo = createTypeInfo,
		typeInfosByName = typeInfosByName,
		ReplicatedInstanceId = ReplicatedInstanceId,
	})
end

type TypeInfosByName = typeof(typeInfosByName)

export type TypeName = keyof<typeof(typeInfosByName)>

do
	local typeInfosById = {}
	for typeInfo, info in typeInfosByName do
		table.insert(typeInfosById, info)
	end
	table.sort(typeInfosById, function(a, b)
		return a.Name < b.Name
	end)
	for i, info in typeInfosById do
		info.TypeId = i
	end

	function TypeInfos.GetTypeInfos(): { TypeInfo }
		return typeInfosById
	end

	function TypeInfos.GetTypeInfoByTypeId(id: number): TypeInfo
		return typeInfosById[id] or error(`Invalid TypeInfo Id "{id}".`)
	end
end

function TypeInfos.GetTypeInfosByName(): TypeInfosByName
	return typeInfosByName
end

function TypeInfos.GetTypeInfoByTypeName(name: string): TypeInfo
	return typeInfosByName[name] or error(`Invalid Type "{name}", which is not a supported type.`)
end

function TypeInfos.FindTypeInfoByValueType(value: any): TypeInfo?
	return typeInfosByName[typeof(value)]
end

function TypeInfos.GetTypeInfoByValueType(value: any): TypeInfo
	return TypeInfos.FindTypeInfoByValueType(value)
		or error(`Invalid Value "{value}", Type "{typeof(value)}" which is not a supported type.`)
end

--[=[
	@param enumId - 
	@return - 
]=]
function TypeInfos.CreateCustomEnum(
	enumId: number,
	enumItems: { string | { Name: string, Value: any } }
): CustomEnum
	return createCustomEnum(enumId, enumItems)
end

return table.freeze(TypeInfos)
