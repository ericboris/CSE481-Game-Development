package;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;

enum DinoState
{
	Herded;
	Unherded;
}

class Dino extends Entity
{
	public var state:DinoState;

	/* State for herded behavior */
	var herdedLeader:Entity;
	var herdedSpeed = 80.0;
	var herdedFollowingRadius = 70.0;

	/* State for unherded behavior */
	// --

	public function new()
	{
		super();

		setSprite(45, 45, FlxColor.YELLOW);
		state = Unherded;
	}

	public override function update(elapsed:Float)
	{
		switch (state)
		{
			case Unherded:
				unherdedBehavior();
			case Herded:
				herdedBehavior();
		}

		super.update(elapsed);
	}

	// Used by Player class to update herd ordering.
	public function setLeader(entity:Entity)
	{
		herdedLeader = entity;
	}

	/* ----------------------
		State behavior methods
		---------------------- */
	function unherdedBehavior()
	{
		sprite.velocity.set(0, 0);
	}

	function herdedBehavior()
	{
		var pos1 = herdedLeader.sprite.getPosition();
		var pos2 = sprite.getPosition();

		if (pos1.distanceTo(pos2) > herdedFollowingRadius)
		{
			var dir = new FlxPoint(pos1.x - pos2.x, pos1.y - pos2.y);
			var angle = Math.atan2(dir.y, dir.x);
			sprite.velocity.set(Math.cos(angle) * herdedSpeed, Math.sin(angle) * herdedSpeed);
		}
		else
		{
			sprite.velocity.set(0, 0);
		}
	}
}
