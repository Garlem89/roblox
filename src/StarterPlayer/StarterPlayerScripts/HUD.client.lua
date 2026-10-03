local Players = game:GetService("Players")
local player = Players.LocalPlayer
local match = game:GetService("ReplicatedStorage"):WaitForChild("OneTapMatch")

local gui = Instance.new("ScreenGui")
gui.Name = "OneTapHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cross = Instance.new("TextLabel")
cross.AnchorPoint = Vector2.new(.5,.5)
cross.Position = UDim2.fromScale(.5,.5)
cross.Size = UDim2.fromOffset(30,30)
cross.BackgroundTransparency = 1
cross.Text = "+"
cross.TextScaled = true
cross.Font = Enum.Font.GothamBold
cross.TextColor3 = Color3.new(1,1,1)
cross.Parent = gui

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(20,20)
title.Size = UDim2.fromOffset(260,40)
title.BackgroundTransparency = .25
title.Text = "ONE TAP  |  ALPHA"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.Parent = gui

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(.5, 0)
status.Position = UDim2.new(.5, 0, 0, 65)
status.Size = UDim2.new(.85, 0, 0, 65)
status.BackgroundTransparency = .25
status.Font = Enum.Font.GothamBold
status.TextScaled = true
status.TextColor3 = Color3.new(1, 1, 1)
status.Parent = gui

local ammo = Instance.new("TextLabel")
ammo.AnchorPoint = Vector2.new(1,1)
ammo.Position = UDim2.new(1,-25,1,-25)
ammo.Size = UDim2.fromOffset(180,50)
ammo.BackgroundTransparency = .25
ammo.Font = Enum.Font.GothamBold
ammo.TextScaled = true
ammo.TextColor3 = Color3.new(1,1,1)
ammo.Parent = gui

task.spawn(function()
	while true do
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		ammo.Text = tool and (tool:GetAttribute("Reloading") and "RELOADING..."
			or "AMMO  " .. tostring(tool:GetAttribute("Ammo") or 30)) or ""
		local mode = match:GetAttribute("Mode") or "TDM"
		local phase = match:GetAttribute("Phase") or "Waiting"
		local remaining = math.max(0, math.ceil((match:GetAttribute("EndsAt") or 0)
			- workspace:GetServerTimeNow()))
		title.Text = "ONE TAP | " .. mode
		local score
		if mode == "TDM" then
			score = string.format("RED %d : %d BLUE | %s",
				match:GetAttribute("RedScore") or 0, match:GetAttribute("BlueScore") or 0,
				player.Team and player.Team.Name or "Spectator")
		else
			local stats = player:FindFirstChild("leaderstats")
			score = string.format("KILLS %d | LEADER %d",
				stats and stats.Kills.Value or 0, match:GetAttribute("LeadingScore") or 0)
		end
		if phase == "Waiting" then
			status.Text = mode .. " | Waiting for players"
		elseif phase == "Results" then
			status.Text = mode .. " | Winner: " .. tostring(match:GetAttribute("Winner")) .. " | " .. remaining .. "s"
		else
			status.Text = string.format("%s | %s | %02d:%02d\n%s | LIMIT %d",
				mode, phase, math.floor(remaining / 60), remaining % 60,
				score, match:GetAttribute("ScoreLimit") or 0)
		end
		task.wait(.1)
	end
end)
