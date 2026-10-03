local tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("OneTapRemotes")
local config = require(ReplicatedStorage:WaitForChild("WeaponConfig")).Rifle
local last = 0

tool.Activated:Connect(function()
	if tool.Parent ~= player.Character or tool:GetAttribute("Reloading")
		or (tool:GetAttribute("Ammo") or config.Magazine) <= 0
		or os.clock() - last < config.FireRate then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	last = os.clock()
	remotes.FireWeapon:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and tool.Parent == player.Character and input.KeyCode == Enum.KeyCode.R then
		remotes.ReloadWeapon:FireServer()
	end
end)
