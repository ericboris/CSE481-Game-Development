package entities;

import flixel.FlxObject;
import js.html.Console;

class Boulder extends Entity
{
    final PUSH_SPEED = 0.4;

    public function new()
    {
        super();

        this.sprite.immovable = true;
        this.type = EntityBoulder;
        this.sprite.mass = 1000;
    }

    public function push(direction:Int)
    {
        var prevX = this.sprite.x;
        var prevY = this.sprite.y;
        switch (direction)
        {
            case FlxObject.UP:
                Console.log("Up!");
                this.sprite.y -= PUSH_SPEED;
            case FlxObject.DOWN:
                this.sprite.y += PUSH_SPEED;
            case FlxObject.RIGHT:
                this.sprite.x += PUSH_SPEED;
            case FlxObject.LEFT:
                this.sprite.x -= PUSH_SPEED;
            default:
        }

        if (GameWorld.collidingWithObstacles(this))
        {
            this.sprite.x = prevX;
            this.sprite.y = prevY;
        }
    }
}
