local Players = game:GetService("Players")

local Globals = require(script.Parent.Parent.constants.globals)
local State = require(script.Parent.state)

local Sync = {}
Sync.__index = Sync

export type Props<Data> = {
	loaded: boolean,
	_remote: RemoteEvent,
	_state: State.Self<Data>,
	_readyBindable: BindableEvent?,
}

export type Self<Data> = Props<Data> & {
	get: (self: Self<Data>) -> Data?,
	onUpdate: (self: Self<Data>, callback: (newState: Data, oldState: Data) -> ()) -> { disconnect: () -> () },
	update: (self: Self<Data>, update: (oldState: Data) -> ()) -> keyof<Data>,
	destroy: (self: Self<Data>) -> (),
}

function Sync.new<Data>(data: Data?, name: string): Self<Data>
	local self = setmetatable({} :: Props<Data>, Sync)

	self._remote = Globals.IS_CLIENT and script:WaitForChild(name, 60) or Instance.new("RemoteEvent", script)

	if not self._remote then
		error(`You need to create then hine sync class on the server first, missing: {name}`)
	end

	self._remote.Name = name
	self._remote.Parent = script

	self._state = State.new(data :: Data)

	if Globals.IS_CLIENT then
		self._readyBindable = Instance.new("BindableEvent")
		self._remote.OnClientEvent:Connect(function(diff)
			local actualValue = self._state:applyDiff(diff)

			if not self.loaded then
				self.loaded = true
				self._readyBindable:Fire(actualValue)
				self._readyBindable:Destroy()
				self._readyBindable = nil
			end
		end)
	else
		self._remote.OnServerEvent:Connect(function(player: Player)
			self:_sendData(player)
		end)

		Players.PlayerAdded:Connect(function(player: Player)
			self:_sendData(player)
		end)
	end

	return self
end

function Sync.get<Data>(self: Self<Data>): Data?
	if not self.loaded and self._readyBindable then
		self._remote:FireServer()
		self._readyBindable.Event:Wait()
	end

	return self._state:get()
end

function Sync.onUpdate<Data>(self: Self<Data>, callback: (newState: Data, oldState: Data) -> ())
	if not self.loaded and self._readyBindable then
		self._readyBindable.Event:Wait()
	end

	return self._state:onUpdate(callback)
end

function Sync.update<Data>(self: Self<Data>, update: (oldState: Data) -> ()): keyof<Data>
	assert(Globals.IS_SERVER, "Updates should only be performed from the server.")

	local diff = self._state:update(update)
	if not diff then
		return
	end

	self._remote:FireAllClients(diff)
end

function Sync.destroy(self: Self<any>)
	if Globals.IS_SERVER then
		self._remote:FireAllClients(nil)
	end

	self._state = nil
	self._remote = nil

	setmetatable(self, nil)
	table.clear(self)
end

-- - - Private functions
function Sync._sendData<Data>(self: Self<Data>, player: Player)
	self._remote:FireClient(player, self._state:get())
end

return Sync
