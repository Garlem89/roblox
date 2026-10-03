local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("MatchConfig"))
local Rules = require(script.Parent.MatchRules)

local Match = {}
local state = Instance.new("Folder")
state.Name = "OneTapMatch"
local mode, phase = Config.Rotation[1], "Waiting"
local scores, teamScores = {}, {Red = 0, Blue = 0}
local teams, spawns, connected = {}, {}, {}
local started = false
local roundId = 0

local function publish()
	state:SetAttribute("Mode", mode)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("RedScore", teamScores.Red)
	state:SetAttribute("BlueScore", teamScores.Blue)
	state:SetAttribute("ScoreLimit", Config.ScoreLimits[mode])
	local best = 0
	for _, score in pairs(scores) do best = math.max(best, score) end
	state:SetAttribute("LeadingScore", best)
end

local function assign(player)
	if mode == "FFA" then
		player.Team = nil
		player.Neutral = true
		player.RespawnLocation = spawns.FFA[math.random(#spawns.FFA)]
		return
	end
	local counts = {Red = 0, Blue = 0}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Team then
			local name = other.Team.Name
			if counts[name] then counts[name] = counts[name] + 1 end
		end
	end
	local name = counts.Red <= counts.Blue and "Red" or "Blue"
	player.Team = teams[name]
	player.Neutral = false
	player.RespawnLocation = spawns[name][math.random(#spawns[name])]
end

local function addPlayer(player)
	if connected[player] then return end
	connected[player] = true
	scores[player.UserId] = scores[player.UserId] or 0
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({"Kills", "Deaths"}) do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
	stats.Kills.Value = scores[player.UserId]
	assign(player)
	local function characterAdded(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid or player.Character ~= character then return end
		local characterRound = roundId
		character:SetAttribute("OneTapRound", characterRound)
		humanoid.Died:Connect(function()
			if (phase == "Active" or humanoid:GetAttribute("OneTapKilled"))
				and characterRound == roundId and stats.Parent then
				stats.Deaths.Value = stats.Deaths.Value + 1
			end
		end)
	end
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then task.spawn(characterAdded, player.Character) end
end

local function finish()
	if phase ~= "Active" then return end
	phase = "Results"
	state:SetAttribute("Winner", Rules.winner(mode, teamScores, scores))
	state:SetAttribute("EndsAt", workspace:GetServerTimeNow() + Config.ResultsDuration)
	publish()
end

function Match.CanDamage(attacker, victim)
	if not attacker.Character or not victim.Character
		or attacker.Character:GetAttribute("OneTapRound") ~= roundId
		or victim.Character:GetAttribute("OneTapRound") ~= roundId then return false end
	return Rules.canDamage(mode, phase == "Active", attacker.UserId, victim.UserId,
		attacker.Team and attacker.Team.Name, victim.Team and victim.Team.Name)
end

function Match.IsActive()
	return phase == "Active"
end

-- Called only immediately after a server-validated lethal hit, without yielding.
function Match.RecordKill(attacker, victim)
	if not Match.CanDamage(attacker, victim) then return end
	scores[attacker.UserId] = (scores[attacker.UserId] or 0) + 1
	attacker.leaderstats.Kills.Value = scores[attacker.UserId]
	local score = scores[attacker.UserId]
	if mode == "TDM" then
		local name = attacker.Team.Name
		teamScores[name] = teamScores[name] + 1
		score = teamScores[name]
	end
	publish()
	if score >= Config.ScoreLimits[mode] then finish() end
end

function Match.Start()
	if started then return end
	started = true
	-- Dedicated server-owned spawns keep city generation independent of script order.
	local folder = Instance.new("Folder")
	folder.Name = "OneTapSpawns"
	folder.Parent = workspace
	for name, color in pairs({Red = "Bright red", Blue = "Bright blue"}) do
		local team = Instance.new("Team")
		team.Name = name
		team.TeamColor = BrickColor.new(color)
		team.AutoAssignable = false
		team.Parent = Teams
		teams[name] = team
	end
	for name, positions in pairs({
		Red = {Vector3.new(-300, 1, -20), Vector3.new(-300, 1, 20)},
		Blue = {Vector3.new(300, 1, -20), Vector3.new(300, 1, 20)},
		FFA = {Vector3.new(-80, 1, 0), Vector3.new(80, 1, 0),
			Vector3.new(0, 1, -200), Vector3.new(0, 1, 200)},
	}) do
		spawns[name] = {}
		for i, position in ipairs(positions) do
			local spawn = Instance.new("SpawnLocation")
			spawn.Name = name .. i
			spawn.Size = Vector3.new(8, 1, 8)
			spawn.Position = position
			spawn.Anchored = true
			spawn.Neutral = name == "FFA"
			if teams[name] then spawn.TeamColor = teams[name].TeamColor end
			spawn.AllowTeamChangeOnTouch = false
			spawn.Duration = Config.SpawnProtection
			spawn.Parent = folder
			table.insert(spawns[name], spawn)
		end
	end
	state:SetAttribute("Winner", "")
	state:SetAttribute("EndsAt", 0)
	publish()
	state.Parent = ReplicatedStorage
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player)
		connected[player] = nil
		-- Keep departed players' round scores for the FFA result.
	end)
	for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
	task.spawn(function()
		local rotation = 1
		while true do
			phase = "Waiting"
			state:SetAttribute("EndsAt", 0)
			publish()
			repeat task.wait(1) until #Players:GetPlayers() >= Config.MinPlayers
			mode = Config.Rotation[rotation]
			phase = "Intermission"
			state:SetAttribute("Winner", "")
			state:SetAttribute("EndsAt", workspace:GetServerTimeNow() + Config.Intermission)
			publish()
			repeat task.wait(0.2) until workspace:GetServerTimeNow() >= state:GetAttribute("EndsAt")
				or #Players:GetPlayers() < Config.MinPlayers
			if #Players:GetPlayers() >= Config.MinPlayers then
				roundId = roundId + 1
				scores, teamScores = {}, {Red = 0, Blue = 0}
				-- Clear old teams before balancing the full roster.
				for _, player in ipairs(Players:GetPlayers()) do player.Team = nil end
				for _, player in ipairs(Players:GetPlayers()) do
					scores[player.UserId] = 0
					player.leaderstats.Kills.Value = 0
					player.leaderstats.Deaths.Value = 0
					assign(player)
				end
				phase = "Preparing"
				publish()
				local pending = 0
				for _, player in ipairs(Players:GetPlayers()) do
					pending = pending + 1
					task.spawn(function()
						if player.Parent == Players then
							local ok, err = pcall(function() player:LoadCharacterAsync() end)
							if not ok then warn(err) end
						end
						pending = pending - 1
					end)
				end
				repeat task.wait(0.1) until pending == 0
				phase = "Active"
				state:SetAttribute("EndsAt", workspace:GetServerTimeNow() + Config.RoundDuration)
				publish()
				repeat task.wait(0.2) until phase ~= "Active"
					or workspace:GetServerTimeNow() >= state:GetAttribute("EndsAt")
					or #Players:GetPlayers() < Config.MinPlayers
				finish()
				repeat task.wait(0.2) until workspace:GetServerTimeNow() >= state:GetAttribute("EndsAt")
				rotation = rotation % #Config.Rotation + 1
			end
		end
	end)
end

return Match
