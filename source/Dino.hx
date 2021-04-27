package;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import js.html.Console;

enum DinoState
{
	Roaming;
	Following();
}

class Dino extends Entity
{
	var speed:Float = 80.0;

	public var state:DinoState;

	/* State for following behavior */
	var leader:Entity;
	var followingRadius = 70.0;

	public function new()
	{
		super();

		setSprite(45, 45, FlxColor.YELLOW);

		state = Roaming;
	}

	public override function update(elapsed:Float)
	{
		switch (state)
		{
			case Roaming:
				Console.log("Roaming");
				sprite.velocity.set(0, 0);
			case Following:
				Console.log("Following");

				var pos1 = leader.sprite.getPosition();
				var pos2 = sprite.getPosition();

				if (pos1.distanceTo(pos2) > followingRadius)
				{
					var dir = new FlxPoint(pos1.x - pos2.x, pos1.y - pos2.y);
					var angle = Math.atan2(dir.y, dir.x);
					sprite.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
				}
				else
				{
					sprite.velocity.set(0, 0);
				}
		}
		super.update(elapsed);
	}

	public function setFollowing(newLeader:Entity)
	{
		leader = newLeader;
		state = Following;
	}
}
