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
    var resumeButton:FlxButton;
    var nextButton:FlxButton;

    var fadingOut:Bool = false;
    var dead:Bool = false;
    override public function create()
    {
        super.create();

        if (!PlayLogger.loggerInitialized())
        {
            PlayLogger.initializeLogger();
        }

        FlxG.mouse.visible = true;

        var boxWidth = 160;
        var boxHeight = 110;

        box = new FlxSprite();
        box.makeGraphic(boxWidth, boxHeight, FlxColor.BLACK);
        box.x = camera.width/2 - box.width/2;
        box.y = camera.height/2 - box.height/2;
        box.alpha = 0.0;
        box.resetSizeFromFrame();

        var numPrey = PlayState.world.numPreyCollected;
        var totalPrey = PlayState.world.numPrey;
        var numPreds = PlayState.world.numPredatorsCollected;

        var textString = "You've collected:\n" + numPrey + " / " + totalPrey + " mammoths";
        if (numPreds > 0)
        {
            textString += "\n" + numPreds + "! predator";
            if (numPreds > 1)
            {
                textString += "s";
            }
        }
        text = new FlxText(0, 0, boxWidth - 20, textString, 11);
        text.x = box.x + 10;
        text.y = box.y + 10;
        text.alpha = 0.0;

        var textColor = 0xFF404040;
        resumeButton = new FlxButton(0, 0, "Resume", clickResume);
        resumeButton.scale.x = resumeButton.scale.y = 0.9;
        resumeButton.updateHitbox();
        resumeButton.label.fieldWidth *= 0.9;
        resumeButton.alpha = 0.0;
        resumeButton.label.size = 8;
        resumeButton.x = box.x + 5;
        resumeButton.y = box.y + box.height - resumeButton.height - 5;

        nextButton = new FlxButton(0, 0, "Next", clickNext);
        nextButton.scale.x = nextButton.scale.y = 0.9;
        nextButton.updateHitbox();
        nextButton.label.fieldWidth *= 0.9;
        nextButton.alpha = 0.0;
        nextButton.label.size = 8;
        nextButton.x = box.x + box.width - nextButton.width - 5;
        nextButton.y = box.y + box.height - nextButton.height - 5;

        fadeTween(box, 0.0, 0.8);
        fadeTween(text, 0.0, 1.0);
        fadeTween(resumeButton, 0.0, 1.0);
        fadeTween(nextButton, 0.0, 1.0);

        setOverlay(box);
        setOverlay(text);

        add(box);
        add(text);
        add(resumeButton);
        add(nextButton);
    }

    function setOverlay(sprite:FlxSprite)
    {
        sprite.scrollFactor.x = 0;
        sprite.scrollFactor.y = 0;
    }

    function fadeTween(sprite:FlxSprite, from:Float, to:Float, onComplete:(FlxTween) -> Void = null)
    {
        var duration = 0.25;
        var options = {ease: FlxEase.sineInOut, onComplete:onComplete}
        var tween = FlxTween.num(from, to, duration, options, setAlpha.bind(sprite));
    }

    function setAlpha(sprite:FlxSprite, f:Float)
    {
        sprite.alpha = f;
    }    

    override public function update(elapsed:Float)
    {
        if (FlxG.keys.anyPressed([R]))
        {
            clickResume();
        }
        else if (FlxG.keys.anyPressed([N]))
        {
            clickNext();
        }

        super.update(elapsed);
    }

    function closed(tween:FlxTween)
    {
        dead = true;
        PlayState.world.levelMenu = null;
        FlxG.mouse.visible = false;
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
            fadeTween(box, box.alpha, 0.0, closed);
            fadeTween(text, text.alpha, 0.0);
            fadeTween(resumeButton, resumeButton.alpha, 0.0);
            fadeTween(nextButton, nextButton.alpha, 0.0);
        }
    }

    function clickNext()
    {
        close();
        PlayState.world.nextLevel();
    }

    function clickResume()
    {
        closeMenu();
    }
}
