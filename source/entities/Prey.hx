package entities;

import js.html.Console;

class Prey extends Dino
{
	public function new()
	{
		super();

		this.type = EntityPrey;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public override function handlePlayerCollision(player:Player)
	{
		if (state == Unherded)
		{
			// We only care about this collision if we are unherded.
			// Add to player's herd.
			player.addDino(this);
			herdedLeader = player;
			herdedPlayer = player;
			state = Herded;
		}
	}

	public override function handleCaveCollision(cave:Cave)
	{
		if (state == Herded)
		{
			herdedPlayer.notifyCaveDeposit(this);
		}
	}
}
