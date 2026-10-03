local time, threads, objects = 0, {}, {}
local function signal()return {Connect=function(self, fn) self.fn=fn end}end
local methods={}
function methods:SetAttribute(k,v)self.attrs[k]=v end
function methods:GetAttribute(k)return self.attrs[k]end
function methods:GetPlayers()return self.roster end
function methods:WaitForChild(name)return self[name]end
Instance={new=function(class)
 local o={attrs={},Value=0}
 return setmetatable(o,{__index=methods,__newindex=function(t,k,v)
  rawset(t,k,v)
  if k=='Name' then objects[v]=t end
  if k=='Parent' and v then rawset(v,t.Name,t) end
 end})
end}
local players={roster={},PlayerAdded=signal(),PlayerRemoving=signal()}
local replicated={MatchConfig='Config'}
setmetatable(players,{__index=methods});setmetatable(replicated,{__index=methods})
local teams={}
game={GetService=function(_,name)
 return ({Players=players,ReplicatedStorage=replicated,Teams=teams})[name]
end}
workspace={GetServerTimeNow=function()return time end}
BrickColor={new=function(v)return v end}
Vector3={new=function(...)return {...}end}
script={Parent={MatchRules='Rules'}}
require=function(name)
 if name=='Rules' then return dofile(ROOT .. '/src/ServerScriptService/MatchRules.lua') end
 return {Rotation={'TDM','FFA'},MinPlayers=2,Intermission=1,RoundDuration=3,
 ResultsDuration=1,ScoreLimits={TDM=1,FFA=1},SpawnProtection=3}
end
function warn(err)error(err)end
task={wait=function()coroutine.yield()end,spawn=function(fn,...)
 local co=coroutine.create(fn);local ok,err=coroutine.resume(co,...);assert(ok,err)
 if coroutine.status(co)~='dead' then table.insert(threads,co) end
end}
local function player(id)
 local p={UserId=id,CharacterAdded=signal(),Parent=players}
 function p:LoadCharacterAsync()
  local char=Instance.new('Model')
  char.Humanoid={Died=signal()}
  self.Character=char
  self.CharacterAdded.fn(char)
 end
 return p
end
players.roster={player(1),player(2),player(3)}
local function tick()
 time=time+0.25
 for i=#threads,1,-1 do
  local co=threads[i];local ok,err=coroutine.resume(co);assert(ok,err)
  if coroutine.status(co)=='dead' then table.remove(threads,i) end
 end
end
local function untilPhase(phase)
 for i=1,100 do
  if objects.OneTapMatch:GetAttribute('Phase')==phase then return end
  tick()
 end
 error('phase not reached: '..phase)
end
local match=dofile(ROOT .. '/src/ServerScriptService/MatchService.lua')
match.Start()
untilPhase('Active')
local a,b,c=table.unpack(players.roster)
assert(a.Team~=b.Team and a.Team==c.Team)
assert(match.CanDamage(a,b) and not match.CanDamage(a,c))
match.RecordKill(a,b)
assert(a.leaderstats.Kills.Value==1 and objects.OneTapMatch:GetAttribute('RedScore')==1)
assert(objects.OneTapMatch:GetAttribute('Phase')=='Results')
assert(objects.OneTapMatch:GetAttribute('Winner')=='Red')
match.RecordKill(a,b);assert(a.leaderstats.Kills.Value==1)
untilPhase('Intermission');untilPhase('Active')
assert(objects.OneTapMatch:GetAttribute('Mode')=='FFA')
assert(a.Neutral and b.Neutral and not a.Team and a.leaderstats.Kills.Value==0)
assert(match.CanDamage(a,b) and match.CanDamage(a,c))
-- All-zero timeout is a draw, then a fresh TDM round starts.
untilPhase('Results');assert(objects.OneTapMatch:GetAttribute('Winner')=='Draw')
untilPhase('Intermission');untilPhase('Active')
local late=player(4);table.insert(players.roster,late);players.PlayerAdded.fn(late)
assert(late.Team==b.Team)
late:LoadCharacterAsync();assert(match.CanDamage(a,late))
players.roster={a};players.PlayerRemoving.fn(b);players.PlayerRemoving.fn(c);players.PlayerRemoving.fn(late)
untilPhase('Results');untilPhase('Waiting');assert(not match.IsActive())
