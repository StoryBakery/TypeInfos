--[[
	Instance 타입 테스트입니다.
]]

local Assertions = require("../helpers/Assertions")
local Utils = require("../helpers/TypeInfosUtils")
local TypeInfos = Utils.TypeInfos
local roundTripByTypeName = Utils.roundTripByTypeName

do
	local instanceTypeInfo = TypeInfos.GetTypeInfoByTypeName("Instance")
	Assertions.assertEqual(instanceTypeInfo.Name, "Instance", "Instance TypeInfo name mismatch.")
	Assertions.assertEqual(instanceTypeInfo.Size, 4, "Instance TypeInfo size mismatch.")
	Assertions.assertTrue(instanceTypeInfo.TypeCheck(nil), "Instance TypeCheck must allow nil.")
	Assertions.assertTrue(
		instanceTypeInfo.TypeCheck(workspace),
		"Instance TypeCheck must allow Instance."
	)
	Assertions.assertTrue(
		not instanceTypeInfo.TypeCheck({}),
		"Instance TypeCheck must reject table."
	)
	Assertions.assertEqual(
		roundTripByTypeName("Instance", nil),
		nil,
		"nil Instance round trip result mismatch."
	)
end

do
	local tempFolder = Instance.new("Folder")
	tempFolder.Name = "TypeInfos_InstanceSpec_Folder"
	tempFolder.Parent = workspace

	Assertions.assertErrorContains(function()
		roundTripByTypeName("Instance", tempFolder)
	end, "Failed To Find Id", "Untracked Instance round trip must throw an error.")

	tempFolder:Destroy()
end

return true
