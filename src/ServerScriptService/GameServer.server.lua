local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("OneTapRemotes") or Instance.new("Folder")
remotes.Name = "OneTapRemotes"
remotes.Parent = ReplicatedStorage

local fire = remotes:FindFirstChild("FireWeapon") or Instance.new("RemoteEvent")
fire.Name = "FireWeapon"
fire.Parent = remotes

local lastShot = {}

fire.OnServerEvent:Connect(function(player, origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - origin).Magnitude > 12 then return end

	local now = os.clock()
	if lastShot[player] and now - lastShot[player] < 0.1 then return end
	lastShot[player] = now

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local result = workspace:Raycast(origin, direction.Unit * 1000, params)
	if not result then return end

	local model = result.Instance:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastShot[player] = nil
end)
