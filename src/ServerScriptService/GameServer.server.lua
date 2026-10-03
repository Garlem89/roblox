local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weapons = require(ReplicatedStorage:WaitForChild("WeaponConfig"))
local Match = require(script.Parent.MatchService)

local remotes = Instance.new("Folder")
remotes.Name = "OneTapRemotes"
local fire = Instance.new("RemoteEvent")
fire.Name = "FireWeapon"
fire.Parent = remotes
local reload = Instance.new("RemoteEvent")
reload.Name = "ReloadWeapon"
reload.Parent = remotes
remotes.Parent = ReplicatedStorage

local lastShot, magazines = {}, {}
local function equipped(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local tool = character and character:FindFirstChild("Rifle")
	if not humanoid or humanoid.Health <= 0 or not tool or not tool:IsA("Tool") then return end
	return tool, character
end

local function magazine(tool)
	local data = magazines[tool]
	if not data then
		data = {ammo = Weapons.Rifle.Magazine, reloading = false}
		magazines[tool] = data
		tool:SetAttribute("Ammo", data.ammo)
		tool:SetAttribute("Reloading", false)
		tool.Destroying:Connect(function() magazines[tool] = nil end)
	end
	return data
end

local function finiteVector(v)
	if typeof(v) ~= "Vector3" then return false end
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < math.huge and math.abs(v.Y) < math.huge
		and math.abs(v.Z) < math.huge
end

reload.OnServerEvent:Connect(function(player)
	local tool = equipped(player)
	if not tool then return end
	local data = magazine(tool)
	if data.reloading or data.ammo == Weapons.Rifle.Magazine then return end
	data.reloading = true
	tool:SetAttribute("Reloading", true)
	task.delay(Weapons.Rifle.ReloadTime, function()
		if magazines[tool] ~= data then return end
		data.ammo = Weapons.Rifle.Magazine
		data.reloading = false
		tool:SetAttribute("Ammo", data.ammo)
		tool:SetAttribute("Reloading", false)
	end)
end)

fire.OnServerEvent:Connect(function(player, origin, direction)
	if not Match.IsActive() or not finiteVector(origin) or not finiteVector(direction) then return end
	if direction.Magnitude < 0.001 or direction.Magnitude > 10000 then return end
	local tool, character = equipped(player)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	if not tool or not root or not head or (root.Position - origin).Magnitude > 12 then return end
	local now = os.clock()
	if lastShot[player] and now - lastShot[player] < Weapons.Rifle.FireRate then return end
	local data = magazine(tool)
	if data.reloading or data.ammo <= 0 then return end
	lastShot[player] = now
	data.ammo = data.ammo - 1
	tool:SetAttribute("Ammo", data.ammo)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	-- Reject camera origins placed through walls; damage ray starts at the server head.
	if workspace:Raycast(head.Position, origin - head.Position, params) then return end
	local result = workspace:Raycast(head.Position, direction.Unit * Weapons.Rifle.Range, params)
	if not result then return end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	while model and not model:FindFirstChildOfClass("Humanoid") do
		model = model:FindFirstAncestorOfClass("Model")
	end
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local victim = model and Players:GetPlayerFromCharacter(model)
	if not victim or not humanoid or humanoid.Health <= 0
		or model:FindFirstChildOfClass("ForceField") or not Match.CanDamage(player, victim) then return end
	humanoid:SetAttribute("OneTapKilled", true)
	humanoid.Health = 0
	Match.RecordKill(player, victim)
end)

Players.PlayerRemoving:Connect(function(player) lastShot[player] = nil end)

local function addPlayer(player)
	local function characterAdded(character)
		local function added(child)
			if child:IsA("Tool") and child.Name == "Rifle" then magazine(child) end
		end
		character.ChildAdded:Connect(added)
		for _, child in ipairs(character:GetChildren()) do added(child) end
	end
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then characterAdded(player.Character) end
end
Players.PlayerAdded:Connect(addPlayer)
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
Match.Start()
