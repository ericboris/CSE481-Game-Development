package;

import flixel.FlxG;
import flixel.util.FlxColor;

class Player extends Entity
{
	var speed:Float = 80.0;

	// Array of followers. TODO: Should be linked list.
	var followers:Array<Dino>;

	public function new()
	{
		super();

		setSprite(30, 30, FlxColor.WHITE);
		sprite.screenCenter();

		followers = new Array<Dino>();
	}

	public override function update(elapsed:Float)
	{
		move();

		super.update(elapsed);
	}

	function move()
	{
		var up = FlxG.keys.anyPressed([UP, W]);
		var down = FlxG.keys.anyPressed([DOWN, S]);
		var left = FlxG.keys.anyPressed([LEFT, A]);
		var right = FlxG.keys.anyPressed([RIGHT, D]);

		if (up && down)
			up = down = false;

		if (left && right)
			left = right = false;

		var angle = 0.0;
		if (up)
		{
			angle = 270;
			if (left)
				angle -= 45;
			if (right)
				angle += 45;
		}
		else if (down)
		{
			angle = 90;
			if (left)
				angle += 45;
			if (right)
				angle -= 45;
		}
		else if (left)
			angle = 180;
		else if (right)
			angle = 0;
		else
		{
			// Player is not moving
			sprite.velocity.set(0, 0);
			return;
		}

		angle *= Math.PI / 180;
		sprite.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
	}

	public function addDino(dino:Dino)
	{
		if (followers.length > 0)
		{
			// Update herd ordering
			followers[0].setLeader(dino);
		}

		// This operation is inefficient but just for testing.
		// Insert new dino to front of herd
		followers.insert(0, dino);
	}
}
