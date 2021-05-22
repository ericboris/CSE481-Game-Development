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
import flixel.FlxSubState;
import js.html.Console;

class GameOverState extends FlxSubState
{
    public override function create()
    {
        super.create();

        camera.fade(0xFF800000, 1.0, true);
        
        var gameOver = new FlxText(0, 0, 300, " GAME OVER", 36);
        setOverlay(gameOver);
        gameOver.x = camera.width/2 - gameOver.width/2;
        gameOver.y = camera.height/2 - gameOver.height - 40;
        add(gameOver);

        var saved  = "" + Score.getTotalScore() + " mammoths saved.";
        var savedText = new FlxText(0, 0, 0, saved, 30);
        setOverlay(savedText);
        savedText.x = camera.width/2 - savedText.width/2;
        savedText.y = gameOver.y + gameOver.height + 30;
        add(savedText);

        var tryAgainText = new FlxText(0, 0, 0, "Try again?", 30);
        setOverlay(tryAgainText);
        tryAgainText.x = camera.width/2 - tryAgainText.width/2;
        tryAgainText.y = savedText.y + savedText.height + 10;
        add(tryAgainText);

        var restartText = new FlxText(0, 0, 0, "Space to restart", 18);
        setOverlay(restartText);
        restartText.x = restartText.width/2 + 10;
        restartText.y = tryAgainText.y + 160;
        restartText.alpha = 0.0;
        add(restartText);
        
        setShadow(gameOver);
        setShadow(savedText);
        setShadow(tryAgainText);
        setShadow(restartText);

        transitioning = true;
        new FlxTimer().start(1.0, function(timer:FlxTimer) {
            var options = { ease: FlxEase.expoIn }
            transitioning = false;
            FlxTween.num(0.0, 1.0, 0.9, options, function (f:Float) {
                restartText.alpha = f;
            });
        });

        PlayLogger.recordGameOver();
    }

    function setOverlay(sprite:FlxSprite)
    {
        sprite.scrollFactor.x = 0;
        sprite.scrollFactor.y = 0;
    }

    function setShadow(text:FlxText)
    {
        text.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
    }

    var transitioning:Bool = false;
    public override function update(elapsed:Float)
    {
        PlayLogger.recordGameOverTryAgain();
        if (FlxG.keys.anyPressed([N, R, SPACE]) && !transitioning)
        {
            transitioning = true;
            camera.fade(FlxColor.BLACK, 0.35, function () {
                GameWorld.restart();
                FlxG.switchState(new PlayState());
            }, true);
        }
    }
}
