-- Pure rules: no client input or Roblox services.
local Rules = {}

function Rules.canDamage(mode, active, attackerId, victimId, attackerTeam, victimTeam)
	if not active or attackerId == victimId then return false end
	if mode == "TDM" then
		return attackerTeam ~= nil and victimTeam ~= nil and attackerTeam ~= victimTeam
	end
	return mode == "FFA"
end

function Rules.winner(mode, teamScores, scores)
	if mode == "TDM" then
		if teamScores.Red == teamScores.Blue then return "Draw" end
		return teamScores.Red > teamScores.Blue and "Red" or "Blue"
	end
	local best, winner = 0, "Draw"
	for id, score in pairs(scores) do
		if score > best then
			best, winner = score, tostring(id)
		elseif score == best then
			winner = "Draw"
		end
	end
	return winner
end

return Rules
