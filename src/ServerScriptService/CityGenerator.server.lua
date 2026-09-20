local Workspace = game:GetService("Workspace")

if Workspace:FindFirstChild("GeneratedCity") then return end
local city = Instance.new("Folder")
city.Name = "GeneratedCity"
city.Parent = Workspace

local function part(name, size, pos, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Material = material or Enum.Material.Concrete
	p.Parent = city
	return p
end

part("Ground", Vector3.new(700, 4, 700), Vector3.new(0,-2,0), Enum.Material.Concrete)

for x = -240, 240, 120 do
	for z = -240, 240, 120 do
		if math.abs(x) > 35 and math.abs(z) > 35 then
			local h = 45 + ((math.abs(x + z) / 120) % 4) * 18
			part("Building", Vector3.new(70,h,70), Vector3.new(x,h/2,z), Enum.Material.Brick)
		end
	end
end

for _, pos in ipairs({
	Vector3.new(-20,3,-20), Vector3.new(20,3,20),
	Vector3.new(-20,3,20), Vector3.new(20,3,-20)
}) do
	local s = Instance.new("SpawnLocation")
	s.Size = Vector3.new(8,1,8)
	s.Position = pos
	s.Anchored = true
	s.Neutral = true
	s.Parent = city
end
