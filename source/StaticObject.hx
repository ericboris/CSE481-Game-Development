package;

import flixel.FlxObject;

class StaticObject extends FlxObject
{
    var tileNum:Int;

    public function new(x:Float, y:Float, width:Float, height:Float, tileNum:Int)
    {
        super(x, y, width, height);
        this.tileNum = tileNum;
    }

    public function getTile()
    {
        return tileNum;
    }
}
