package entities;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import js.html.Console;

enum DinoState
{
	Herded;
	Unherded;
}

class Dino extends Entity
{
	var state:DinoState;

	/* State for herded behavior */
	var herdedPlayer:Player;
	var herdedLeader:Entity;
	var herdedSpeed = 80.0;
	var herdedMaxFollowingRadius = 105.0;
	var herdedFollowingRadius = 35.0;

	/* State for unherded behavior */
	// --

	public function new()
	{
		super();

		setSprite(20, 20, FlxColor.YELLOW);
		sprite.mass = 0.5; // Make the dino easier to push by player.
		state = Unherded;
	}

	public override function update(elapsed:Float)
	{
		switch (state)
		{
			case Unherded:
				unherded();
			case Herded:
				herded();
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
	function unherded()
	{
		sprite.velocity.set(0, 0);
	}

	function herded()
	{
		var pos1 = herdedLeader.sprite.getPosition();
		var pos2 = sprite.getPosition();
		var dist = pos1.distanceTo(pos2);

		if (dist > herdedMaxFollowingRadius)
		{
			setUnherded(true);
			return;
		}
		else if (dist > herdedFollowingRadius)
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

	/* State transition methods */
	public function setUnherded(notify:Bool = false)
	{
		var player = herdedPlayer;
		herdedLeader = null;
		herdedPlayer = null;
		state = Unherded;

		if (notify)
		{
			player.notifyUnherded();
		}
	}

	/* Getters */
	public function getState()
	{
		return state;
	}
}
