-- Execute the real server handler against small service doubles.
local function signal()
 return {Connect=function(self, fn) self.callback=fn end}
end
local objects = {}
Instance = {new=function(class)
 local obj = {ClassName=class}
 if class=='RemoteEvent' then obj.OnServerEvent=signal() end
 setmetatable(obj, {__newindex=function(t,k,v) rawset(t,k,v); if k=='Name' then objects[v]=t end end})
 return obj
end}
local function vector(x,y,z)
 local v={X=x,Y=y,Z=z}
 return setmetatable(v, {__index=function(t,k)
  if k=='Magnitude' then return math.sqrt(t.X^2+t.Y^2+t.Z^2) end
  if k=='Unit' then local m=t.Magnitude;return vector(t.X/m,t.Y/m,t.Z/m) end
 end,__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end,
 __mul=function(a,b)return vector(a.X*b,a.Y*b,a.Z*b)end})
end
function typeof(v) return type(v)=='table' and v.X and 'Vector3' or type(v) end
RaycastParams={new=function()return {}end}
Enum={RaycastFilterType={Exclude=1}}
local active, allowed, kills, protected, wall = true, true, 0, false, false
local victim = {}
local humanoid={Health=100,SetAttribute=function()end}
local model={FindFirstChildOfClass=function(_,name)
 if name=='Humanoid' then return humanoid end
 if name=='ForceField' and protected then return {} end
end}
local hit={Instance={FindFirstAncestorOfClass=function()return model end}}
workspace={Raycast=function(_,_,direction)
 if direction.Magnitude < 100 then return wall and hit or nil end
 return hit
end}
local tool={attributes={},Destroying=signal(),IsA=function()return true end}
function tool:SetAttribute(k,v) self.attributes[k]=v end
local character={ChildAdded=signal()}
function character:FindFirstChildOfClass()return {Health=100}end
function character:FindFirstChild(name)
 if name=='Rifle' then
  if self.unequipped then return nil end
  return tool
 end
 return {Position=vector(0,0,0)}
end
function character:GetChildren()return {}end
local player={Character=character,CharacterAdded=signal()}
local players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return {player}end,
 GetPlayerFromCharacter=function()return victim end}
local replicated={WaitForChild=function(_,name)return name end}
game={GetService=function(_,name)return name=='Players' and players or replicated end}
script={Parent={MatchService='MatchService'}}
local originalRequire=require
require=function(name)
 if name=='WeaponConfig' then return dofile(ROOT .. '/src/ReplicatedStorage/WeaponConfig.lua') end
 return {Start=function()end,IsActive=function()return active end,
 CanDamage=function()return allowed end,RecordKill=function()kills=kills+1 end}
end
local delayed
task={delay=function(_,fn)delayed=fn end}
local clock=1
os.clock=function()return clock end
dofile(ROOT .. '/src/ServerScriptService/GameServer.server.lua')
local fire=objects.FireWeapon.OnServerEvent.callback
local origin, aim=vector(0,0,0),vector(0,0,-1)
local function shot()clock=clock+1;fire(player,origin,aim)end
fire(player, origin, vector(0,0,0));assert(kills==0)
fire(player, origin, vector(0/0,0,1));assert(kills==0)
fire(player, origin, vector(math.huge,0,1));assert(kills==0)
active=false;shot();assert(kills==0)
active=true;character.unequipped=true;shot();assert(kills==0)
character.unequipped=false;allowed=false;shot();assert(kills==0)
allowed=true;protected=true;shot();assert(kills==0)
protected=false;wall=true;origin=vector(1,0,0);shot();assert(kills==0)
wall=false;origin=vector(0,0,0);shot();assert(kills==1 and humanoid.Health==0)
shot();assert(kills==1) -- corpse cannot award another kill
humanoid.Health=100
fire(player,origin,aim);assert(kills==1) -- fire-rate spam
for i=1,35 do shot() end
assert(tool.attributes.Ammo==0)
humanoid.Health=100;shot();assert(humanoid.Health==100)
objects.ReloadWeapon.OnServerEvent.callback(player)
assert(tool.attributes.Reloading)
shot();assert(humanoid.Health==100)
delayed();assert(tool.attributes.Ammo==30 and not tool.attributes.Reloading)
shot();assert(kills==3)
require=originalRequire
