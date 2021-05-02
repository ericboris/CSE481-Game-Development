package;

import entities.*;
import flixel.math.FlxMath;

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
}
