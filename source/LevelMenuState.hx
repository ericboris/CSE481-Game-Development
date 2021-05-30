import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.addons.ui.FlxButtonPlus;
import flixel.ui.FlxButton;
import openfl.media.Sound;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import js.html.Console;

class LevelMenuState extends FlxSubState
{
    var box:FlxSprite;
    var text:FlxText;
    //var nextButton:FlxButton;

    var fadingOut:Bool = false;
    var dead:Bool = false;

    var x:Float;
    var y:Float;
    public function new(x:Float, y:Float)
    {
        super();

        this.x = x;
        this.y = y;
    }

    override public function create()
    {
        super.create();

        if (!PlayLogger.loggerInitialized())
        {
            PlayLogger.initializeLogger();
        }

        var boxWidth = 100;
        var boxHeight = 52;

        var numPrey = PlayState.world.numPreyCollected;
        var totalPrey = PlayState.world.numPrey;
        var numPreds = PlayState.world.numPredatorsCollected;

        var textString:String;
        if (GameWorld.levelId() == 1)
        {
            textString = "Press Enter at Caves to move on";
        }
        else
        {
            textString = "You've collected:\n" + numPrey + " " + makePlural("Mammoth", numPrey);
            if (numPreds > 0)
            {
                boxHeight += 16;
                textString += "\n" + numPreds + " " + makePlural("Predator", numPreds) + "!";
            }
        
            textString += "\n\n" + PlayState.world.getNumPreyLeft() + " remaining";
            textString += "\nEnter to move on";
        }
 
        text = new FlxText(0, 0, boxWidth - 8, textString, 8);
        text.alpha = 0.0;

        boxHeight = Std.int(Math.max(boxHeight, text.height + 8));

        box = new FlxSprite();
        box.makeGraphic(boxWidth, boxHeight, FlxColor.BLACK);
        box.x = (this.x - camera.scroll.x) - box.width/2;
        box.y = (this.y - camera.scroll.y) - box.height - 16;
        box.alpha = 0.0;
        box.resetSizeFromFrame();
        
        text.x = box.x + box.width/2 - text.width/2;
        text.y = box.y + 4;

        var duration = 0.5;
        fadeTween(box, 0.0, 0.8, duration);
        fadeTween(text, 0.0, 1.0, duration);

        setOverlay(box);
        setOverlay(text);

        add(box);
        add(text);
    }

    function setOverlay(sprite:FlxSprite)
    {
        sprite.scrollFactor.x = 0;
        sprite.scrollFactor.y = 0;
    }

    function fadeTween(sprite:FlxSprite, from:Float, to:Float, duration:Float, onComplete:(FlxTween) -> Void = null)
    {
        FlxTween.cancelTweensOf(sprite);
        var options = {ease: FlxEase.quartOut, onComplete:onComplete}
        var tween = FlxTween.num(from, to, duration, options, setAlpha.bind(sprite));
    }

    function makePlural(str:String, num:Int)
    {
        if (num == 1)
            return str;
        else
            return str + "s";
    }

    function setAlpha(sprite:FlxSprite, f:Float)
    {
        sprite.alpha = f;
    }    

    override public function update(elapsed:Float)
    {
        if (FlxG.keys.anyPressed([ENTER]))
        {
            clickNext();
        }

        super.update(elapsed);
    }

    function closed(tween:FlxTween)
    {
        dead = true;
        PlayState.world.levelMenu = null;
        close();
    }

    public function closeMenu()
    {
        if (!dead && box == null)
        {
            closed(null);
            return;
        }

        if (!fadingOut)
        {
            fadingOut = true;
            var duration = 0.4;
            fadeTween(box, box.alpha, 0.0, duration, closed);
            fadeTween(text, text.alpha, 0.0, duration);
        }
    }

    function clickNext()
    {
        if (!dead)
        {
            closed(null);

            PlayLogger.recordPlayerSkippedLevel();
            PlayState.world.nextLevel();
        }
    }
}
