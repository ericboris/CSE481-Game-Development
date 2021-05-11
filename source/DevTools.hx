package;

import entities.*;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.util.*;

class DevTools
{
    private var circle:FlxShapeCircle;

    public static function visualizeCircle(e:Entity, radius:Float):FlxShapeCircle
    {
        var x = e.getX() - radius;
        var y = e.getY() - radius;
        var circle = new FlxShapeCircle(x, y, radius, null, 0xFFFFFFFF);
        return circle;
    }
}
