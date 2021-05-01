package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxColor;
import js.html.Console;
import flixel.FlxSprite;

class Player extends Entity
{
	/* Hitbox id constants */
	static var INTERACT_HITBOX_ID = 0;

	var speed:Float = 100.0;

	// Array of followers. TODO: Should be linked list.
	var followers:Array<Dino>;

	// State variables
	var depositingToCave:Bool = false;
	var cave:Cave;
	var inRangeOfCave:Bool = false;

	public function new()
	{
		super();

		this.type = EntityPlayer;

		setGraphic(16, 16, AssetPaths.player__png, true);

        sprite.setFacingFlip(FlxObject.LEFT, false, false);
        sprite.setFacingFlip(FlxObject.RIGHT, true, false);

        sprite.animation.add("lr", [3, 4, 3, 5], 6, false);
        sprite.animation.add("u", [6, 7, 6, 8], 6, false);
        sprite.animation.add("d", [0, 1, 0, 2], 6, false);

		sprite.screenCenter();

		var interactHitbox = new Hitbox(this, INTERACT_HITBOX_ID);
		interactHitbox.getSprite().makeGraphic(24, 24, FlxColor.BLUE);
		addHitbox(interactHitbox);

		followers = new Array<Dino>();
	}

	public override function update(elapsed:Float)
	{
		move();

		// Cave depositing logic

		if (!inRangeOfCave)
		{
			// We are no longer in range of cave. Set herd back to normal order.
			depositingToCave = false;
			for (i in 0...followers.length)
			{
				if (i == 0)
					followers[i].setLeader(this);
				else
					followers[i].setLeader(followers[i - 1]);
				followers[i].herdedDisableFollowingRadius = false;
			}
		}

		if (depositingToCave && followers.length > 0)
		{
			followers[0].setLeader(cave);
			followers[0].herdedFollowingRadius = 0;
		}

		// Assume that we are now out of range of the cave.
		// If we're still in range, we'll be notified within the following collision checking cycle.
		inRangeOfCave = false;

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
			sprite.facing = FlxObject.UP;
		}
		else if (down)
		{
			angle = 90;
			if (left)
				angle += 45;
			if (right)
				angle -= 45;
			sprite.facing = FlxObject.DOWN;
		}
		else if (left)
		{
			angle = 180;
			sprite.facing = FlxObject.LEFT;
		}
		else if (right)
		{
			angle = 0;
			sprite.facing = FlxObject.RIGHT;
		}	
		else
		{
			// Player is not moving
			sprite.velocity.set(0, 0);
			return;
		}

		angle *= Math.PI / 180;
		sprite.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);

        if ((sprite.velocity.x != 0 || sprite.velocity.y != 0) && sprite.touching == FlxObject.NONE)
        {
            switch (sprite.facing)
            {
                case FlxObject.LEFT, FlxObject.RIGHT:
                    sprite.animation.play("lr");
                case FlxObject.UP:
                    sprite.animation.play("u");
                case FlxObject.DOWN:
                    sprite.animation.play("d");
            }
        }
    }

	public function notifyUnherded()
	{
		var unherdedIndex = -1;
		for (i in 0...followers.length)
		{
			if (unherdedIndex == -1 && followers[i].getState() == Unherded)
			{
				unherdedIndex = i;
			}

			if (unherdedIndex != -1 && i > unherdedIndex)
			{
				followers[i].setUnherded();
			}
		}

		if (unherdedIndex != -1)
		{
			followers.resize(unherdedIndex);
		}
	}

	public function notifyCaveDeposit(dino:Dino)
	{
		// If not depositing to cave, ignore
		if (!depositingToCave)
			return;

		for (i in 0...followers.length - 1)
		{
			if (followers[i] == dino)
			{
				followers[i + 1].setLeader(cave);
				followers[i + 1].herdedDisableFollowingRadius = true;
			}
		}

		PlayState.world.remove(dino.getSprite());
		dino.getSprite().alive = false;
		dino.getSprite().allowCollisions = FlxObject.NONE;
		followers.remove(dino);
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

	public override function notifyHitboxCollision(hitbox:Hitbox, entity:Entity)
	{
		if (hitbox.getId() == INTERACT_HITBOX_ID)
		{
			if (entity.type == EntityCave)
			{
				inRangeOfCave = true;
			}
		}
	}

	public override function handleCaveCollision(cave:Cave)
	{
		depositingToCave = true;
		inRangeOfCave = true;
		this.cave = cave;
	}
	
	// Return the Player's speed.
	public function getSpeed()
	{
		return this.speed; 
	}
}