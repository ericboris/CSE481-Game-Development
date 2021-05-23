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
import flixel.FlxCamera;

class GameWinState extends FlxSubState
{
    var overlayCamera:FlxCamera;
    public override function create()
    {
        super.create();

        overlayCamera = new FlxCamera(0, 0, PlayState.SCREEN_WIDTH, PlayState.SCREEN_HEIGHT);
        overlayCamera.fade(FlxColor.BLACK, 1.0, true);
        overlayCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(overlayCamera, false);

        var camera = overlayCamera;
        
        var gameOver = new FlxText(0, 0, 300, "YOU WIN!", 36);
        setOverlay(gameOver);
        gameOver.x = camera.width/2 - gameOver.width/2 + 50;
        gameOver.y = camera.height/2 - gameOver.height - 40;
        add(gameOver);

        var saved  = "" + Score.getCount() + " creatures saved.";
        var savedText = new FlxText(0, 0, 0, saved, 30);
        setOverlay(savedText);
        savedText.x = camera.width/2 - savedText.width/2;
        savedText.y = gameOver.y + gameOver.height + 30;
        add(savedText);
        
        var score  = "Score: " + Score.getScore();
        var scoreText = new FlxText(0, 0, 0, score, 24);
        setOverlay(scoreText);
        scoreText.x = camera.width - scoreText.width - 16;
        scoreText.y = 8;
        add(scoreText);

        var tryAgainText = new FlxText(0, 0, 0, "Thanks for playing!", 30);
        setOverlay(tryAgainText);
        tryAgainText.x = camera.width/2 - tryAgainText.width/2;
        tryAgainText.y = savedText.y + savedText.height + 10;
        tryAgainText.alpha = 1.0;
        add(tryAgainText);

        var restartText = new FlxText(0, 0, 0, "Space to restart", 16);
        setOverlay(restartText);
        restartText.x = 8;
        restartText.y = camera.height - restartText.height - 8;
        restartText.alpha = 0.0;
        add(restartText);
        
        setShadow(gameOver);
        setShadow(savedText);
        setShadow(tryAgainText);
        setShadow(scoreText);
        setShadow(restartText, 3);

        transitioning = true;
        new FlxTimer().start(1.5, function(timer:FlxTimer) {
            var options = { ease: FlxEase.expoIn }
            transitioning = false;
            FlxTween.num(0.0, 1.0, 0.9, options, function (f:Float) {
                restartText.alpha = f;
            });
        });

        PlayLogger.recordGameWin();
    }

    function setOverlay(sprite:FlxSprite)
    {
        sprite.camera = overlayCamera;
        sprite.scrollFactor.x = 0;
        sprite.scrollFactor.y = 0;
    }

    function setShadow(text:FlxText, shadow:Int = 4)
    {
        text.setBorderStyle(SHADOW, FlxColor.BLACK, shadow, 1);
    }

    var transitioning:Bool = false;
    public override function update(elapsed:Float)
    {
        PlayLogger.recordGameOverTryAgain();
        if (FlxG.keys.anyPressed([N, R, SPACE]) && !transitioning)
        {
            transitioning = true;
            overlayCamera.fade(FlxColor.BLACK, 0.35, false, function () {
                GameWorld.restart();
                FlxG.switchState(new PlayState());
            }, true);
        }
    }
}
