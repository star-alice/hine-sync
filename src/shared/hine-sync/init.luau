local SyncClass = require(script.classes.sync)
local Globals = require(script.constants.globals)

export type Sync<Data> = SyncClass.Self<Data>

local HineSync = {}
local Instances = {}

function HineSync.create<Data>(name: string, data: Data)
	assert(Globals.IS_SERVER, "Sync objects with data should only be created from the server.")
	local instance = SyncClass.new(data, name)

	Instances[name] = instance
	return instance
end

function HineSync.get<Data>(name: string): Sync<Data>
	local instance = Instances[name]
	if instance then
		return instance :: any
	end

	assert(not Globals.IS_SERVER, "Sync instances must be created on the server before they can be accessed.")
	return SyncClass.new(nil, name) :: any
end

return HineSync
