local TableUtils = require(script.Parent.Parent.utils.table)

local State = {}
State.__index = State

export type Props<T> = {
	_value: T,
	_onUpdateCallbacks: { (newState: T, oldState: T) -> () },
}

export type Self<T> = Props<T> & {
	get: (self: Self<T>) -> T,
	set: (self: Self<T>, newValue: T) -> keyof<T>,
	update: (self: Self<T>, updater: (oldState: T) -> T?) -> keyof<T>,
	applyDiff: (self: Self<T>, diff: keyof<T>) -> T,
	onUpdate: (self: Self<T>, callback: (newState: T, oldState: T) -> ()) -> { disconnect: () -> () },
}

function State.new<T>(value: T): Self<T>
	return setmetatable({ _value = value, _onUpdateCallbacks = {} }, State)
end

-- Public
function State.get<T>(self: Self<T>): T
	return self._value
end

function State.set<T>(self: Self<T>, newValue: T): keyof<T>
	return self:update(function()
		return newValue
	end)
end

function State.update<T>(self: Self<T>, updater: (oldState: T) -> T?): keyof<T>
	local isTable = typeof(self._value) == "table"
	local oldValue = isTable and TableUtils.deepCopy(self._value) or self._value
	local draft = isTable and TableUtils.deepCopy(self._value) or self._value
	local result = updater(draft)
	local newValue = result ~= nil and result or draft

	if self._value ~= nil and typeof(newValue) ~= typeof(self._value) then
		error(`State type mismatch: expected '{typeof(self._value)}', got '{typeof(newValue)}'`)
	end

	local diff = self:_computeDiff(oldValue, newValue)

	if isTable then
		self:_mergeDeep(self._value, diff)
	else
		self._value = newValue
	end

	self:_notifyListeners(oldValue)
	return diff
end

function State.applyDiff<T>(self: Self<T>, diff: keyof<T>): T
	local oldValue = typeof(self._value) == "table" and TableUtils.deepCopy(self._value) or self._value

	if typeof(self._value) == "table" then
		self:_mergeDeep(self._value, diff)
	else
		self._value = diff
	end

	self:_notifyListeners(oldValue)
	return self._value
end

function State.onUpdate<T>(self: Self<T>, callback: (newState: T, oldState: T) -> ()): { disconnect: () -> () }
	table.insert(self._onUpdateCallbacks, callback)

	return {
		disconnect = function()
			local index = table.find(self._onUpdateCallbacks, callback)
			if index then
				table.remove(self._onUpdateCallbacks, index)
			end
		end,
	}
end

-- Private
function State._computeDiff<T>(self: Self<T>, oldValue: T, newValue: T): keyof<T>
	if typeof(newValue) ~= "table" then
		return newValue
	end

	local diff = {}

	for key, value in newValue do
		local old = oldValue[key]
		if type(value) == "table" and type(old) == "table" then
			local nested = self:_computeDiff(old, value)
			if next(nested) then
				diff[key] = nested
			end
		elseif old ~= value then
			diff[key] = value
		end
	end

	return diff
end

function State._notifyListeners<T>(self: Self<T>, oldValue: T)
	for _, callback in self._onUpdateCallbacks do
		callback(self._value, oldValue)
	end
end

function State._mergeDeep<T>(self: Self<T>, target: T, source: keyof<T>)
	for key, value in source do
		if type(value) == "table" and type(target[key]) == "table" then
			self:_mergeDeep(target[key], value)
		else
			target[key] = value
		end
	end
end

return State
