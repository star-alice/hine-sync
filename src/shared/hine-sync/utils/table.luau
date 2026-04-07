local TableUtils = {}

function TableUtils.deepCopy<T>(original: T): T
	local copy = {}

	for key, value in original do
		if type(value) == "table" then
			copy[key] = TableUtils.deepCopy(value)
		else
			copy[key] = value
		end
	end

	return copy
end

return TableUtils
