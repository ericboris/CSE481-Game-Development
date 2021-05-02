package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import js.html.Console;

class Predator extends Dino
{
	/* Unherded state */
	final PREDATOR_SPEED = 85.0;
	final PREDATOR_ACCELERATION = 30.0;
	final PREDATOR_ELASTICITY = 0.6;

	public function new()
	{
		super();

		this.type = EntityPredator;

		setGraphic(16, 16, AssetPaths.boss__png, true);

		sprite.setFacingFlip(FlxObject.LEFT, false, false);
		sprite.setFacingFlip(FlxObject.RIGHT, true, false);

		sprite.animation.add("lr", [0], 0, false);
		// sprite.animation.add("u", [6, 7, 6, 8], 6, false);
		// sprite.animation.add("d", [0, 1, 0, 2], 6, false);

		var angle = GameWorld.random(0, Math.PI * 2.0);
		this.sprite.velocity.x = Math.cos(angle) * PREDATOR_SPEED;
		this.sprite.velocity.y = Math.sin(angle) * PREDATOR_SPEED;
		this.sprite.elasticity = PREDATOR_ELASTICITY;

		sprite.screenCenter();

		sprite.setSize(8, 8);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	private override function unherded(elapsed:Float)
	{
		// idle(elapsed);

		// Bounce off walls if colliding
		var horizontalCollision = sprite.touching & (FlxObject.LEFT | FlxObject.RIGHT);
		var verticalCollision = sprite.touching & (FlxObject.UP | FlxObject.DOWN);
		if (horizontalCollision > 0)
		{
			sprite.velocity.x *= -1;
		}

		if (verticalCollision > 0)
		{
			sprite.velocity.y *= -1;
		}

		if (GameWorld.magnitude(sprite.velocity) < PREDATOR_SPEED)
		{
			// Set sprite's acceleration to speed up in the same direction
			var v1 = sprite.velocity;
			var v2 = new FlxPoint(PREDATOR_SPEED + PREDATOR_ACCELERATION, 0);

			var dot = v1.x * v2.x + v1.y * v2.y;
			var cross = v1.x * v2.y - v2.x * v1.y;
			var angle = Math.atan2(cross, dot);

			sprite.acceleration.x = Math.cos(angle) * PREDATOR_ACCELERATION;
			sprite.acceleration.y = Math.sin(angle) * PREDATOR_ACCELERATION;
		}
		else
		{
			sprite.acceleration.x = 0;
			sprite.acceleration.y = 0;
		}
	}
}
