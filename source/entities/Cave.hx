package entities;

import flixel.util.FlxColor;

class Cave extends Obstacle
{
	public function new()
	{
		super(40, 25, FlxColor.BLACK);

		this.type = EntityCave;
	}
}
