package entities;

import flixel.FlxObject;
import flixel.util.FlxColor;
import js.html.Console;

class Cave extends Obstacle
{
    public function new()
    {
        super();
        sprite.visible = false;
        this.setHitboxSize(16 * 3, 16 * 3);

        this.collidable = false;

        this.type = EntityCave;
        this.thought.setOffset(0, -16);
        this.thought.setSprite(16, 16, AssetPaths.down_arrow__png);
    }
}
