--!strict
--[[
	StatsService
	Traduit le profil en caractéristiques concrètes (PV, énergie, dégâts,
	vitesse) et les applique au personnage. Gère aussi la régénération et
	l'énergie maudite, qui reste 100 % côté serveur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local ShopCatalog = require(Shared.ShopCatalog)
local Signal = require(Shared.Signal)

local DataService = require(script.Parent.DataService)

export type Derived = {
	maxHealth: number,
	maxEnergy: number,
	damage: number, -- attaques physiques (Force)
	magicDamage: number, -- techniques maudites (Magie)
	walkSpeed: number,
	cooldownMultiplier: number,
}

local StatsService = {}

StatsService.EnergyChanged = Signal.new()

local energy: { [Player]: number } = {}
local lastCombat: { [Player]: number } = {}
local derivedCache: { [Player]: Derived } = {}

--- Calcule les caractéristiques dérivées à partir du profil (stats + objets).
function StatsService.derive(profile: any): Derived
	local stats = profile.stats
	local bonus = { damage = 0, health = 0, energy = 0, speed = 0 }

	for _, itemId in pairs(profile.equipped) do
		local item = if itemId ~= "" then ShopCatalog.get(itemId) else nil
		if item and item.bonus then
			bonus.damage += item.bonus.damage or 0
			bonus.health += item.bonus.health or 0
			bonus.energy += item.bonus.energy or 0
			bonus.speed += item.bonus.speed or 0
		end
	end

	-- Les reliques sont des bonus permanents : elles comptent dès qu'on les
	-- possède, sans avoir à les équiper.
	for itemId, owned in pairs(profile.owned) do
		local item = ShopCatalog.get(itemId)
		if owned and item and item.category == "relique" and item.bonus then
			bonus.damage += item.bonus.damage or 0
			bonus.health += item.bonus.health or 0
			bonus.energy += item.bonus.energy or 0
			bonus.speed += item.bonus.speed or 0
		end
	end

	local level = profile.level
	local cooldownReduction =
		math.min(stats.agilite * GameConfig.CooldownReductionPerAgility, GameConfig.MaxCooldownReduction)

	return {
		maxHealth = GameConfig.BaseHealth + level * 6 + stats.vie * GameConfig.HealthPerVie + bonus.health,
		maxEnergy = GameConfig.BaseEnergy + stats.magie * GameConfig.EnergyPerMagie + bonus.energy,
		damage = GameConfig.BaseDamage + level * 1.5 + stats.force * GameConfig.DamagePerStrength + bonus.damage,
		magicDamage = GameConfig.BaseMagicDamage
			+ level * 2
			+ stats.magie * GameConfig.MagicDamagePerMagie
			+ bonus.damage,
		walkSpeed = GameConfig.BaseWalkSpeed + stats.agilite * GameConfig.SpeedPerAgility + bonus.speed,
		cooldownMultiplier = 1 - cooldownReduction,
	}
end

function StatsService.getDerived(player: Player): Derived?
	local cached = derivedCache[player]
	if cached then
		return cached
	end
	local profile = DataService.get(player)
	if not profile then
		return nil
	end
	local derived = StatsService.derive(profile)
	derivedCache[player] = derived
	return derived
end

--- Publie les valeurs live sur le joueur : les attributs se répliquent
--- automatiquement au client, pas besoin de remote dédié.
local function publish(player: Player)
	local derived = derivedCache[player]
	if not derived then
		return
	end
	player:SetAttribute("Energie", math.floor(energy[player] or 0))
	player:SetAttribute("EnergieMax", math.floor(derived.maxEnergy))
	player:SetAttribute("Degats", math.floor(derived.damage))
	player:SetAttribute("DegatsMagie", math.floor(derived.magicDamage))
	player:SetAttribute("Vitesse", derived.walkSpeed)
	player:SetAttribute("ReductionCooldown", 1 - derived.cooldownMultiplier)
end

StatsService.publish = publish

function StatsService.getEnergy(player: Player): number
	return energy[player] or 0
end

function StatsService.consumeEnergy(player: Player, amount: number): boolean
	local current = energy[player] or 0
	if current < amount then
		return false
	end
	energy[player] = current - amount
	StatsService.EnergyChanged:fire(player, energy[player])
	publish(player)
	return true
end

function StatsService.markCombat(player: Player)
	lastCombat[player] = os.clock()
end

--- Applique les caractéristiques au personnage (appelé au spawn et à chaque
--- changement de profil).
function StatsService.apply(player: Player)
	local profile = DataService.get(player)
	if not profile then
		return
	end

	local derived = StatsService.derive(profile)
	derivedCache[player] = derived

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ratio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 1
		humanoid.MaxHealth = derived.maxHealth
		humanoid.Health = math.clamp(derived.maxHealth * ratio, 1, derived.maxHealth)
		humanoid.WalkSpeed = derived.walkSpeed
		humanoid.UseJumpPower = true
		humanoid.JumpPower = 55
	end

	energy[player] = math.min(energy[player] or derived.maxEnergy, derived.maxEnergy)
	StatsService.EnergyChanged:fire(player, energy[player])
	publish(player)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end

	local derived = StatsService.getDerived(player)
	if derived then
		energy[player] = derived.maxEnergy
	end

	StatsService.apply(player)

	humanoid.Died:Connect(function()
		local profile = DataService.get(player)
		if profile then
			profile.totals.deaths += 1
			DataService.push(player)
		end
	end)
end

function StatsService.init()
	local spendRemote = Remotes.event("SpendStatPoint")

	spendRemote.OnServerEvent:Connect(function(player, statId, amount)
		if typeof(statId) ~= "string" then
			return
		end
		local count = if typeof(amount) == "number" then math.floor(amount) else 1
		count = math.clamp(count, 1, 100)

		local profile = DataService.get(player)
		if not profile or profile.stats[statId] == nil then
			return
		end

		count = math.min(count, profile.statPoints)
		if count <= 0 then
			return
		end

		profile.statPoints -= count
		profile.stats[statId] += count
		StatsService.apply(player)
		DataService.push(player)
	end)

	DataService.ProfileLoaded:connect(function(player: Player)
		local derived = StatsService.getDerived(player)
		if derived then
			energy[player] = derived.maxEnergy
		end
		if player.Character then
			StatsService.apply(player)
		end
	end)

	DataService.ProfileChanged:connect(function(player: Player)
		derivedCache[player] = nil
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		energy[player] = nil
		lastCombat[player] = nil
		derivedCache[player] = nil
	end)

	-- Régénération hors combat.
	task.spawn(function()
		while true do
			local delta = task.wait(0.5)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local derived = StatsService.getDerived(player)
				if not derived then
					continue
				end

				local current = energy[player] or derived.maxEnergy
				if current < derived.maxEnergy then
					energy[player] = math.min(derived.maxEnergy, current + GameConfig.EnergyRegenPerSecond * delta)
					StatsService.EnergyChanged:fire(player, energy[player])
					publish(player)
				end

				local outOfCombat = now - (lastCombat[player] or 0) > GameConfig.OutOfCombatDelay
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if outOfCombat and humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
					humanoid.Health = math.min(
						humanoid.MaxHealth,
						humanoid.Health + GameConfig.HealthRegenPerSecond * delta
					)
				end
			end
		end
	end)

	Players.RespawnTime = GameConfig.RespawnTime
end

return StatsService
