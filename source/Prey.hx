package;

import js.html.Console;

class Prey extends Dino
{
	public function new()
	{
		super();
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
			state = Herded;
		}
	}
}
