package;

import flixel.FlxGame;
import flixel.FlxG;
import openfl.display.FPS;
import openfl.display.Sprite;

class Main extends Sprite
{
    public function new()
    {
        super();
        addChild(new FlxGame(PlayState.SCREEN_WIDTH, PlayState.SCREEN_HEIGHT, MenuState, 1.0, 60, 60, true, false));

        if (PlayState.DEBUG)
        {
            // For debugging purposes
            addChild(new FPS(10, 10, 0xffffff));
        }
    }
}
