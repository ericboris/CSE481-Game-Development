package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class TransitionState extends FlxState
{
    public override function create()
    {
        // Display the score for this level.
        var numPreyCollected = PlayState.world.numPreyCollected;
        var numPredsCollected = PlayState.world.numPredatorsCollected;
        var numPrey:Int = PlayState.world.numPrey;

        camera.fade(FlxColor.BLACK, 0.33, true);

        var background = new FlxSprite();
        background.loadGraphic(AssetPaths.cavebackground__png);
        add(background);
        
        var scoreString = "Saved:\n" + PlayState.world.numPreyCollected + " mammoth";
        if (numPrey != 1) scoreString += "s";
        if (numPredsCollected > 0)
        {
            scoreString += "\n" + numPredsCollected + " predator";
            if (numPredsCollected != 1) scoreString += "s";
            scoreString += "!";
        }

        var rate:Int = Std.int(100 * (numPreyCollected + numPredsCollected) / numPrey);
        var survivalRate = "Survival Rate: " + rate + "%";

        var levelScoreText = new FlxText(0, 0, 0, scoreString, 36);
        setShadow(levelScoreText);
        levelScoreText.alpha = 0;

        var rateText = new FlxText(0, 0, 0, survivalRate, 36);
        setShadow(rateText);
        rateText.alpha = 0;

        var nextText = new FlxText(0, 0, 0, "Space to move on", 20);
        setShadow(nextText);
        nextText.alpha = 0;

        var restartText = new FlxText(0, 0, 0, "R to restart", 20); 
        setShadow(restartText);
        restartText.alpha = 0;

        this.add(levelScoreText);
        this.add(rateText);
        this.add(nextText);
        this.add(restartText);

        var midx = camera.scroll.x + PlayState.SCREEN_WIDTH/2;
        var midy = camera.scroll.y + PlayState.SCREEN_HEIGHT/2;
        rateText.setPosition(midx - rateText.width/2, midy - rateText.height/2);
        levelScoreText.setPosition(midx - rateText.width/2, rateText.y - levelScoreText.height - 30);

        var bottomy = camera.scroll.y + PlayState.SCREEN_HEIGHT;
        nextText.setPosition(camera.scroll.x + 20, bottomy - 50);
        restartText.setPosition(camera.scroll.x + 20, bottomy - 80);

        var setAlpha = function (texts:Array<FlxText>, f:Float) {
            for (text in texts)
            {
                text.alpha = f;
            }
        };

        var fadeOutDuration = 2.0;

        var fadeScoreOptions = {ease: FlxEase.quadIn, onComplete: function (tween:FlxTween) {
            var fadeRateOptions = {ease:FlxEase.quadIn, onComplete: function (tween:FlxTween) {
                var fadeOutOptions = {ease:FlxEase.expoIn, onComplete: function (tween:FlxTween) {
                    camera.fade(FlxColor.BLACK, 0.3, false, function() {
                        FlxG.switchState(new PlayState());
                    });
                }};

                var setAlpha3 = setAlpha.bind([levelScoreText, rateText, nextText, restartText]);
                FlxTween.num(1.0, 0, fadeOutDuration, fadeOutOptions, setAlpha3);
            }};

            var duration:Float;
            var soundEffect:FlxSound;
            if (rate <= 50)
            {
                duration = 1.5;
                fadeOutDuration = 3.0;
                soundEffect = FlxG.sound.load(AssetPaths.BadJob__mp3, 0.85);
            }
            else
            {
                duration = 1.0;
                fadeOutDuration = 2.0;
                soundEffect = FlxG.sound.load(AssetPaths.GoodJob__mp3, 0.8);
            }

            new FlxTimer().start(0.5, function (timer) {
                soundEffect.play();
            }, 1);

            var setAlpha2 = setAlpha.bind([rateText]);
            FlxTween.num(0, 1.0, duration, fadeRateOptions, setAlpha2);
        }};

        var setAlpha1 = setAlpha.bind([levelScoreText, nextText, restartText]);
        FlxTween.num(0, 1.0, 0.5, fadeScoreOptions, setAlpha1);
    }

    function setShadow(text:FlxText)
    {
        text.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
    }

    public override function update(elapsed:Float)
    {
        if (FlxG.keys.anyPressed([N, SPACE]))
        {
            FlxG.switchState(new PlayState());
        }
        else if (FlxG.keys.anyPressed([R]))
        {
            GameWorld.restartLevel();
            FlxG.switchState(new PlayState());
        }
    }
}
