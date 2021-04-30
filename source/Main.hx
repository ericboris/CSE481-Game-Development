package;

import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(320, 240, MenuState, 1.0, 60, 60, true, false));

		// For debugging purposes
		addChild(new FPS(10, 10, 0xffffff));
	}
}
