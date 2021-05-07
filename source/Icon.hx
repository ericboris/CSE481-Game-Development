package;

import entities.*;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;

class Icon
{
    var center:Entity;
    var offsetX:Int;
    var offsetY:Int;

    var alphaRate:Float = 0.0;

    public var sprite:FlxSprite;

    public function new(centeredOn:Entity, x:Int, y:Int)
    {
        this.center = centeredOn;
        this.offsetX = x;
        this.offsetY = y;
    }

    public function setSprite(width:Int, height:Int, asset:String)
    {
        sprite = new FlxSprite();
        sprite.loadGraphic(asset, false, width, height);
        sprite.setGraphicSize(width, height);
    }

    public function setText(size:Int, content:String)
    {
        sprite = new FlxText(0, 0, -1, content, size);
    }

    public function setContent(content:String)
    {
        if (Std.is(sprite, FlxText))
        {
            var text:FlxText = cast sprite;
            text.text = content;
        }
    }

    public function update(elapsed:Float)
    {
        sprite.x = center.getX() + offsetX;
        sprite.y = center.getY() + offsetY;

        sprite.alpha += alphaRate;
        if (sprite.alpha < 0)
        {
            sprite.alpha = 0;
            alphaRate = 0;
        }
        else if (sprite.alpha > 1)
        {
            sprite.alpha = 1;
            alphaRate = 0;
        }
    }

    public function fadeIn(rate:Float = 0.05)
    {
        sprite.alpha = 0;
        alphaRate = rate;
    }

    public function fadeOut(rate:Float = -0.05)
    {
        sprite.alpha = 1;
        alphaRate = rate;
    }
}
