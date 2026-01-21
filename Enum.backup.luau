local Enum = {}

local CustomEnum = {}
CustomEnum.__index = CustomEnum
CustomEnum.__type = "CustomEnum"

function CustomEnum:GetEnumId()
	return self.Id
end

function CustomEnum:GetEnumItems()
	return self.Items
end

local CustomEnumItem = {}
CustomEnumItem.__index = CustomEnumItem
CustomEnumItem.__type = "CustomEnumItem"

function CustomEnumItem:GetEnumId()
	return self.EnumId
end

function CustomEnumItem:GetItemId()
	return self.ItemId
end

local enumsById = {}
local enumItemsById = {}
local enumList = {}
local nextEnumId = 0

local function assertU16(value, label)
	if typeof(value) ~= "number" or value % 1 ~= 0 or value < 0 or value > 65535 then
		error(`{label} must be an integer between 0 and 65535.`)
	end
end

local function registerEnum(enum)
	if enumsById[enum.Id] ~= nil then
		error(`EnumId "{enum.Id}" already exists.`)
	end

	enumsById[enum.Id] = enum
	enumItemsById[enum.Id] = {}
	table.insert(enumList, enum)
	Enum[enum.Name] = enum
end

function Enum.Define(name, itemNames, enumId)
	if typeof(name) ~= "string" then
		error("Enum name must be a string.")
	end
	if typeof(itemNames) ~= "table" then
		error("ItemNames must be a table.")
	end

	if enumId == nil then
		enumId = nextEnumId + 1
	end
	assertU16(enumId, "EnumId")
	nextEnumId = math.max(nextEnumId, enumId)

	local enum = setmetatable({
		Id = enumId,
		Name = name,
		Items = {},
	}, CustomEnum)

	registerEnum(enum)

	for i, itemName in itemNames do
		if typeof(itemName) ~= "string" then
			error(`ItemName must be a string, got {typeof(itemName)}.`)
		end

		local itemId = i - 1
		assertU16(itemId, "ItemId")

		local item = setmetatable({
			EnumId = enumId,
			ItemId = itemId,
			Name = itemName,
			EnumType = enum,
		}, CustomEnumItem)

		enum[itemName] = item
		enum.Items[i] = item
		enumItemsById[enumId][itemId] = item
	end

	return enum
end

function Enum.GetEnums()
	return enumList
end

function Enum.GetEnumById(enumId)
	return enumsById[enumId]
end

function Enum.GetEnumItemById(enumId, itemId)
	local items = enumItemsById[enumId]
	if items == nil then
		return nil
	end
	return items[itemId]
end

Enum.CustomEnum = CustomEnum
Enum.CustomEnumItem = CustomEnumItem

local easingStyles = {
	"Linear",
	"Quad",
	"Cubic",
	"Quart",
	"Quint",
	"Sine",
	"Expo",
	"Circ",
	"Elastic",
	"Back",
	"Bounce",
}

Enum.Define("EasingStyle", easingStyles)
Enum.Define("InterpolationMode", {
	"Linear",
	"Quad",
	"Cubic",
	"Quart",
	"Quint",
	"Sine",
	"Expo",
	"Circ",
	"Elastic",
	"Back",
	"Bounce",
	"Constant",
	"Bezier",
})

Enum.Define("EasingDirection", {
	"In",
	"Out",
	"InOut",
})

Enum.Define("RotationOrder", {
	"XYZ",
	"XZY",
	"YZX",
	"YXZ",
	"ZXY",
	"ZYX",
})

Enum.Define("MaterialId", {
	"Plastic",
	"Wood",
	"Slate",
	"Concrete",
	"CorrodedMetal",
	"DiamondPlate",
	"Foil",
	"Grass",
	"Ice",
	"Marble",
	"Granite",
	"Brick",
	"Pebble",
	"Sand",
	"Fabric",
	"SmoothPlastic",
	"Metal",
	"WoodPlanks",
	"Cobblestone",
	"Air",
	"Water",
	"Rock",
	"Glacier",
	"Snow",
	"Sandstone",
	"Mud",
	"Basalt",
	"Ground",
	"CrackedLava",
	"Neon",
	"Glass",
	"Asphalt",
	"LeafyGrass",
	"Salt",
	"Limestone",
	"Pavement",
	"ForceField",
	"Cardboard",
	"Carpet",
	"CeramicTiles",
	"ClayRoofTiles",
	"RoofShingles",
	"Leather",
	"Plaster",
	"Rubber",
})

Enum.Define("PartType", {
	"Ball",
	"Block",
	"Cylinder",
	"Wedge",
	"CornerWedge",
})

Enum.Define("NormalId", {
	"Top",
	"Bottom",
	"Back",
	"Front",
	"Right",
	"Left",
})

Enum.Define("ActuatorType", {
	"None",
	"Motor",
	"Servo",
})

Enum.Define("TextureMode", {
	"Stretch",
	"Wrap",
	"Static",
})

Enum.Define("ParticleOrientation", {
	"FacingCamera",
	"FacingCameraWorldUp",
	"VelocityParallel",
	"VelocityPerpendicular",
})

Enum.Define("ParticleEmitterShape", {
	"Box",
	"Sphere",
	"Cylinder",
	"Disc",
})

Enum.Define("ParticleEmitterShapeStyle", {
	"Volume",
	"Surface",
})

Enum.Define("ParticleEmitterShapeInOut", {
	"Outward",
	"Inward",
	"InAndOut",
})

Enum.Define("ParticleFlipbookLayout", {
	"None",
	"Grid2x2",
	"Grid4x4",
	"Grid8x8",
})

Enum.Define("ParticleFlipbookMode", {
	"Loop",
	"OneShot",
	"PingPong",
	"Random",
})

Enum.Define("AutomaticSize", {
	"None",
	"X",
	"Y",
	"XY",
})

Enum.Define("LineJoinMode", {
	"Round",
	"Bevel",
	"Miter",
})

Enum.Define("Face2D", {
	"Left",
	"Right",
	"Top",
	"Bottom",
})

return Enum
