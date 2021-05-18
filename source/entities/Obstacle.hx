package entities;

import flixel.util.FlxColor;

class Obstacle extends Entity
{
    public function new()
    {
        super();

        this.type = EntityObstacle;
        this.sprite.immovable = true;
    }
}
