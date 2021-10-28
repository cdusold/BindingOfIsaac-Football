local SportsballMod = RegisterMod("Football", 1)
local game = Game()
local MIN_TEAR_DELAY = 5

--Sorry for the mess, this is temporary.

local TearFlags = {
	FLAG_NO_EFFECT = 0,
	FLAG_SPECTRAL = 1,
	FLAG_PIERCING = 1<<1,
	FLAG_HOMING = 1<<2,
	FLAG_SLOWING = 1<<3,
	FLAG_POISONING = 1<<4,
	FLAG_FREEZING = 1<<5,
	FLAG_COAL = 1<<6,
	FLAG_PARASITE = 1<<7,
	FLAG_MAGIC_MIRROR = 1<<8,
	FLAG_POLYPHEMUS = 1<<9,
	FLAG_WIGGLE_WORM = 1<<10,
	FLAG_UNK1 = 1<<11, --No noticeable effect
	FLAG_IPECAC = 1<<12,
	FLAG_CHARMING = 1<<13,
	FLAG_CONFUSING = 1<<14,
	FLAG_ENEMIES_DROP_HEARTS = 1<<15,
	FLAG_TINY_PLANET = 1<<16,
	FLAG_ANTI_GRAVITY = 1<<17,
	FLAG_CRICKETS_BODY = 1<<18,
	FLAG_RUBBER_CEMENT = 1<<19,
	FLAG_FEAR = 1<<20,
	FLAG_PROPTOSIS = 1<<21,
	FLAG_FIRE = 1<<22,
	FLAG_STRANGE_ATTRACTOR = 1<<23,
	FLAG_UNK2 = 1<<24, --Possible worm?
	FLAG_PULSE_WORM = 1<<25,
	FLAG_RING_WORM = 1<<26,
	FLAG_FLAT_WORM = 1<<27,
	FLAG_UNK3 = 1<<28, --Possible worm?
	FLAG_UNK4 = 1<<29, --Possible worm?
	FLAG_UNK5 = 1<<30, --Possible worm?
	FLAG_HOOK_WORM = 1<<31,
	FLAG_GODHEAD = 1<<32,
	FLAG_UNK6 = 1<<33, --No noticeable effect
	FLAG_UNK7 = 1<<34, --No noticeable effect
	FLAG_EXPLOSIVO = 1<<35,
	FLAG_CONTINUUM = 1<<36,
	FLAG_HOLY_LIGHT = 1<<37,
	FLAG_KEEPER_HEAD = 1<<38,
	FLAG_ENEMIES_DROP_BLACK_HEARTS = 1<<39,
	FLAG_ENEMIES_DROP_BLACK_HEARTS2 = 1<<40,
	FLAG_GODS_FLESH = 1<<41,
	FLAG_UNK8 = 1<<42, --No noticeable effect
	FLAG_TOXIC_LIQUID = 1<<43,
	FLAG_OUROBOROS_WORM = 1<<44,
	FLAG_GLAUCOMA = 1<<45,
	FLAG_BOOGERS = 1<<46,
	FLAG_PARASITOID = 1<<47,
	FLAG_UNK9 = 1<<48, --No noticeable effect
	FLAG_SPLIT = 1<<49,
	FLAG_DEADSHOT = 1<<50,
	FLAG_MIDAS = 1<<51,
	FLAG_EUTHANASIA = 1<<52,
	FLAG_JACOBS_LADDER = 1<<53,
	FLAG_LITTLE_HORN = 1<<54,
	FLAG_GHOST_PEPPER = 1<<55,
	FLAG_FOOTBALL = 1<<60
}

local BallId = {
	FOOTBALL = Isaac.GetItemIdByName("Football")
}

local BounceId = {
	NONE = nil,
	STOPPED = 0,
	RUBBER = 1,
	FOOTBALL = 1<<1
}

--Here's some code to keep tracks of variables for different tear variants

local TearBallId = {
	FOOTBALL = Isaac.GetEntityVariantByName("Football Tear")
}

local NormalizedDirection = {}
NormalizedDirection[Direction.NO_DIRECTION] = Vector(0,0)
NormalizedDirection[Direction.LEFT] = Vector(-1,0)
NormalizedDirection[Direction.RIGHT] = Vector(1,0)
NormalizedDirection[Direction.UP] = Vector(0,-1)
NormalizedDirection[Direction.DOWN] = Vector(0,1)

local function EvaluateCache(_, _, cacheFlag)
	local player = Isaac.GetPlayer(0)
	local roomEntities = Isaac.GetRoomEntities()

	if cacheFlag == CacheFlag.CACHE_TEARFLAG then
		if player:HasCollectible(BallId.FOOTBALL) then
			player.TearFlags = player.TearFlags | TearFlags.FLAG_RUBBER_CEMENT
			tearParams = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1.0, 0)
			tearParams.TearVariant = TearBallId.FOOTBALL
			--We'll have to add the tear flag later. Or do something else
			--player.TearFlags = player.TearFlags | TearFlags.FLAG_FOOTBALL
		end
	end

	if cacheFlag == CacheFlag.CACHE_RANGE then
		if player:HasCollectible(BallId.FOOTBALL) then
			-- There is no range stat in the lua.
			player.TearHeight = player.TearHeight /2
		end
	end
end


function SportsballMod:PostUpdate()
	local player = Isaac.GetPlayer(0)
	local roomEntities = Isaac.GetRoomEntities()

	--code for custom entity effects in this mod.
	for i,entity in ipairs(roomEntities) do
		--code for custom tear effects in this mod.
		local tear = entity:ToTear()
		if tear ~= nil then
			local tearData = tear:GetData()
			local tearSprite = tear:GetSprite()
			--code to change tear sprite and add stats.
			if player:HasCollectible(BallId.FOOTBALL)
			and tear.Parent.Type == EntityType.ENTITY_PLAYER
			and entity.FrameCount == 1
			then
				tear:ChangeVariant(TearBallId.FOOTBALL)
				if tearData.Bounces ~= nil then
					tearData.Bounces = tearData.Bounces -1
				else
					--Guarantee one bounce
					tearData.Bounces = -1
				end
				tearSprite.Rotation = entity.Velocity:GetAngleDegrees() + 90.0
				tearData.FootballBounced = false
				tearData.Spin = 1
				if tearData.BounceType ~= nil then
					tearData.BounceType = tearData.BounceType | BounceId.FOOTBALL
				else
					tearData.BounceType = BounceId.FOOTBALL
				end
			end

			--code to implement bounces
			if tearData.Bounces ~= nil then
				tearData.Bouncing = false
				--on ANY kind of bounce, increase the counter.
				--if tearData.BounceType > 0
				--and tear:CollidesWithGrid() --TODO get entity bounces.
				--then
				--	tearData.Bounces = tearData.Bounces + 1
				--end

				--different bounces do different things, other than the initial bounce effect
				if tearData.BounceType ~= BounceId.STOPPED
				and (tear.Height >= -5 and tear.FallingSpeed > 0)
				then
					--limit the bounces, unless bounces = -inf
					if tearData.Bounces < 0  or (1+math.max(player.Luck, 1)) * math.random() > 1 then
						tearData.Bouncing = true
						tear.Height = -5
						tear.FallingSpeed = -tear.FallingSpeed
						tearData.Bounces = tearData.Bounces + 1
					else
						tearData.BounceType = BounceId.STOPPED
					end
				end
				--rubberballs just do the above bounce.

				--footballs bounce irratically
				if tearData.Bouncing
				and tearData.BounceType & BounceId.FOOTBALL == BounceId.FOOTBALL
				then
					--tear.FallingSpeed = tear.FallingSpeed * (1 + math.random())
					--entity.Velocity = entity.Velocity:Rotated(360*math.random()) * (0.5 + math.random())
					-- TODO Maintain velocity, transfering vertical and horizontal momentum.
					-- TODO this will prevent footballs suddenly becoming bottle rockets for no reason.
					--Isaac.DebugString("Bounce Frame:")
					--Isaac.DebugString(entity.Velocity.X)
					--Isaac.DebugString(entity.Velocity.Y)
					--Isaac.DebugString(tear.FallingSpeed)
					local oldVelocitySquared = entity.Velocity:LengthSquared() + (tear.FallingSpeed*tear.FallingSpeed*25)

					local randTemp = math.random()
					--Isaac.DebugString(randTemp)
					--tear.FallingSpeed = tear.FallingSpeed * (1 + randTemp)
					entity.Velocity = entity.Velocity*0.5 + (entity.Velocity:Rotated(360*math.random()):Normalized() * (math.sqrt(oldVelocitySquared) * randTemp))
					tear.FallingSpeed = -math.sqrt(math.max(1, (oldVelocitySquared - entity.Velocity:LengthSquared())/25))

					--Isaac.DebugString(entity.Velocity.X)
					--Isaac.DebugString(entity.Velocity.Y)
					--Isaac.DebugString(tear.FallingSpeed)

					tear.FootballBounced = true
					tearData.Spin = -tearData.Spin
				end

				--Spin football
				if tear.FootballBounced and tear.Variant == TearBallId.FOOTBALL then
					tearSprite.Rotation = tearSprite.Rotation + 10.0 * tearData.Spin
				end
			end
		end
	end

end

SportsballMod:AddCallback(ModCallbacks.MC_POST_UPDATE, SportsballMod.PostUpdate)
SportsballMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, EvaluateCache)
