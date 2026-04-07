local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HineSync = require(ReplicatedStorage.Shared["hine-sync"])

local testSync: HineSync.Sync<number> = HineSync.get("Test")
local testSync2: HineSync.Sync<{ message: string, message2: string }> = HineSync.get("Test2")

testSync:onUpdate(function(newState, oldState)
	print("State updated from", oldState, "to", newState)
	print(testSync:get())
end)

testSync2:onUpdate(function(newState, oldState)
	print("State updated from", oldState.message2, "to", newState.message2)
	print(testSync2:get())
end)

print(testSync:get())
print(testSync2:get().message)
