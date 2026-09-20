local tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local fireRemote = ReplicatedStorage:WaitForChild("OneTapRemotes"):WaitForChild("FireWeapon")
local ammo = 30
local reloading = false
local last = 0

local function fire()
	if reloading or ammo <= 0 or os.clock() - last < 0.12 then return end
	last = os.clock()
	ammo -= 1
	tool:SetAttribute("Ammo", ammo)
	local camera = workspace.CurrentCamera
	fireRemote:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
end

tool.Activated:Connect(fire)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or tool.Parent ~= player.Character then return end
	if input.KeyCode == Enum.KeyCode.R and not reloading and ammo < 30 then
		reloading = true
		tool:SetAttribute("Reloading", true)
		task.wait(1.8)
		ammo = 30
		tool:SetAttribute("Ammo", ammo)
		tool:SetAttribute("Reloading", false)
		reloading = false
	end
end)

tool:SetAttribute("Ammo", ammo)
