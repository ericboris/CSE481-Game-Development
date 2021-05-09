package entities;

import flixel.FlxObject;
import flixel.util.FlxColor;

class Cave extends Obstacle
{
    public function new()
    {
        super(16, 16, FlxColor.BLACK);
        sprite.visible = false;

        this.type = EntityCave;
    }
}
