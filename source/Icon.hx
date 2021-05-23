package;

import entities.*;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import js.html.Console;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import flixel.tweens.FlxEase;
import flash.display.BlendMode;
import flixel.math.FlxMath;

class Icon
{
    var center:Entity;
    var offsetX:Int;
    var offsetY:Int;
    var tweenY:Float = 0.0;

    var alphaRate:Float = 0.0;

    var fadeOutDelay:Float = 3.0;
    var shouldFadeOut:Bool = false;

    public var sprite:FlxSprite;
    var width:Float = 0;
    var height:Float = 0;

    var tween:NumTween;

    public function new(centeredOn:Entity, x:Int, y:Int)
    {
        this.center = centeredOn;
        var offset = FlxG.random.float(-0.1, 0.1);
        this.tween = FlxTween.num(-1, 5, 2.5 + offset, {ease: FlxEase.linear, type: FlxTweenType.PINGPONG}, updateTween);
        setOffset(x, y);
        setText("");
    }

    function updateTween(val:Float)
    {
        tweenY = val;
    }

    public function setOffset(x:Int, y:Int)
    {
        this.offsetX = x;
        this.offsetY = y;
    }

    function setNewFlxSprite(newSprite:FlxSprite)
    {
        if (sprite != null)
        {
            PlayState.world.remove(sprite, true);
        }
        this.sprite = newSprite;
        PlayState.world.add(sprite);
        sprite.alpha = 0;
        // This is a hacky workaround to indicate that this sprite should be drawn on top.
        sprite.health = PlayState.world.topLayerSortIndex();
 
        width = sprite.width;
        height = sprite.height;
    }

    public function setSprite(width:Int, height:Int, asset:String)
    {
        var sprite = new FlxSprite();
        sprite.loadGraphic(asset, false, width, height);
        sprite.setGraphicSize(width, height);

        setNewFlxSprite(sprite);
    }

    public function setText(content:String, size:Int=11)
    {
        var text = new FlxText(0, 0, -1, content, size);
        setNewFlxSprite(text);
        setContent(content, 0);
        text.setBorderStyle(SHADOW, FlxColor.BLACK, 1, 1);
    }

    public function setContent(content:String, fadeOutDelay:Float=3.5, force:Bool = false)
    {
        if (!force && shouldFadeOut)
        {
            return;
        }

        if (!Std.is(sprite, FlxText))
        {
            setText(content);
        }
        var text:FlxText = cast sprite;
        text.text = content;
        this.width = text.width;
        this.height = text.height;

        if (!shouldFadeOut)
        {
            this.appear(fadeOutDelay);
        }
        else
        {
            this.fadeOutDelay = fadeOutDelay;
        }
    }

    public function appear(fadeOutDelay:Float=3.5)
    {
        if (fadeOutDelay > 0)
        {
            fadeIn();
            this.fadeOutDelay = fadeOutDelay;
            this.shouldFadeOut = true;
        }
    }

    public function update(elapsed:Float)
    {
        sprite.x = center.getX() - width/2 + offsetX;
        sprite.y = center.getY() - height/2 + offsetY - tweenY;

        fadeOutDelay -= elapsed;
        if (alphaRate == 0 && shouldFadeOut && fadeOutDelay <= 0)
        {
            fadeOut();
        }

        sprite.alpha += alphaRate;
        if (sprite.alpha <= 0)
        {
            sprite.alpha = 0;
            alphaRate = 0;
            shouldFadeOut = false;
        }
        else if (sprite.alpha >= 1)
        {
            sprite.alpha = 1;
            alphaRate = 0;
        }
    }

    public function fadeIn(rate:Float = 0.09)
    {
        sprite.alpha = 0;
        alphaRate = rate;
    }

    public function fadeOut(rate:Float = -0.09)
    {
        sprite.alpha = 1;
        alphaRate = rate;
        shouldFadeOut = false;
    }
}
