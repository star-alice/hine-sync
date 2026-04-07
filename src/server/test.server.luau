local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HineSync = require(ReplicatedStorage.Shared["hine-sync"])

local testSync: HineSync.Sync<number> = HineSync.create("Test", 5)
local testSync2: HineSync.Sync<{ message: string, message2: string }> =
	HineSync.create("Test2", { message = "Hello, world!", message2 = "Hello, Luau!" })
print(testSync:get())
print(testSync2:get().message)

task.wait(5)

testSync:update(function(state)
	return state + 1
end)

testSync2:update(function(state)
	state.message2 = "test"
	return state
end)

print(testSync:get())
print(testSync2:get().message2)
