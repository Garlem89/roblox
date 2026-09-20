local Players = game:GetService("Players")
local player = Players.LocalPlayer

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
		ammo.Text = tool and ("AMMO  " .. tostring(tool:GetAttribute("Ammo") or 0)) or ""
		task.wait(.1)
	end
end)
