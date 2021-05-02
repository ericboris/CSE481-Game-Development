package;

import entities.*;
import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import js.html.Console;

class GameWorld
{
    static public function getNearestEntity(src:Entity, dst:Array<Entity>)
    {
        var nearestEntity = null;
        var minDistance = FlxMath.MAX_VALUE_FLOAT;

        for (e in dst)
        {
            var srcSprite = src.getSprite();
            var dstSprite = e.getSprite();
            var distance = distance(srcSprite.x, srcSprite.y, dstSprite.x, dstSprite.y);
            if (distance < minDistance)
            {
                minDistance = distance;
                nearestEntity = e;
            }
        }
        return nearestEntity;
    }

    static public function distance(x1:Float, y1:Float, x2:Float, y2:Float)
    {
        return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
    }

    static public function handleDownCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.UP);
    }

    static public function handleUpCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.DOWN);
    }

    static public function handleRightCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.LEFT);
    }

    static public function handleLeftCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.RIGHT);
    }

    static function handleCliff(entity:FlxObject, direction:Int)
    {
        if (Std.is(entity, SpriteWrapper))
        {
            var sprite:SpriteWrapper<Entity> = cast entity;
            var entity = sprite.entity;
            if (entity.getSprite().facing == direction)
            {
                entity.handleCliffCollision(direction);
            }
        }
    }

    static public function radians(degrees:Int)
    {
        return degrees * Math.PI / 180.0;
    }

    static public function magnitude(vector:FlxPoint)
    {
        return GameWorld.distance(0, 0, vector.x, vector.y);
    }

    static public function random(min:Float, max:Float)
    {
        return Math.random() * (max - min) + min;
    }
}
