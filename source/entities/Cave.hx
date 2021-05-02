package entities;

import flixel.util.FlxColor;
import flixel.FlxObject;

class Cave extends Obstacle
{
	public function new()
	{
		super(16, 16, FlxColor.BLACK);

        sprite.visible = false;

		this.type = EntityCave;
	}
}
