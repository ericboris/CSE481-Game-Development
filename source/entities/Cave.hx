package entities;

import flixel.FlxObject;
import flixel.util.FlxColor;
import js.html.Console;

class Cave extends Obstacle
{
    public function new()
    {
        super(16, 16, FlxColor.BLACK);
        sprite.visible = false;

        this.type = EntityCave;
        this.thought.setOffset(0, -32);
        this.thought.setSprite(16, 16, AssetPaths.down_arrow__png);
    }
}
