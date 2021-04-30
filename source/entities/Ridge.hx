package entities;

import flixel.FlxObject;
import flixel.util.FlxColor;

class Ridge extends Obstacle
{
	public function new(width:Int, height:Int, facing:Int)
	{
		super(width, height, FlxColor.BROWN);

		this.type = EntityRidge;

		// Set collisions to be active on all directions besides `facing`
		var allDirections = FlxObject.UP | FlxObject.DOWN | FlxObject.LEFT | FlxObject.RIGHT;
		allDirections ^= facing;
		this.sprite.allowCollisions = allDirections;
	}
}
