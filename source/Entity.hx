package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;

class Entity
{
	public var sprite:FlxSprite;

	public function new()
	{
		sprite = new FlxSprite();
	}

	function setSprite(width:Int, height:Int, color:FlxColor)
	{
		sprite.makeGraphic(width, height, color);
		sprite.setSize(width, height);
	}

	public function addToWorld(state:FlxState)
	{
		state.add(sprite);
	}

	public function update(elapsed:Float)
	{
		sprite.update(elapsed);
	}
}
