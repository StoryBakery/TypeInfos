--[[
	TypeInfos 테스트 공용 유틸입니다.
]]

local TypeInfos = require("@game/ReplicatedStorage/TypeInfos")

local Utils = {}

function Utils.roundTripByTypeName(typeName: string, value: any): any
	local typeInfo = TypeInfos.GetTypeInfoByTypeName(typeName)
	local size = typeInfo.GetSize(value)
	local b = buffer.create(size)
	typeInfo.Serialize(b, 0, value)
	return typeInfo.Deserialize(b, 0)
end

Utils.TypeInfos = TypeInfos

return Utils
