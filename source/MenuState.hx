import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.addons.ui.FlxButtonPlus;
import flixel.ui.FlxButton;
import openfl.media.Sound;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxSubState;

class MenuState extends FlxSubState
{
    var playButton:FlxButton;
    var titleText:FlxText;
    var optionsButton:FlxButton;

    static final BASE_VOLUME = 0.7;

    static var delayTimer = 1.0;

    override public function create()
    {
        super.create();

        if (!PlayLogger.loggerInitialized())
        {
            PlayLogger.initializeLogger();
        }

        titleText = new FlxText(125, 130, 400, "Mammoth Herder", 60);
        titleText.alignment = CENTER;
        titleText.setBorderStyle(SHADOW, FlxColor.BLACK, 5);
        add(titleText);

        var textColor = 0xFF404040;

        /**
        playButton = new FlxButton(220, 460, "Play", clickPlay);
        playButton.scale.x = playButton.scale.y = 2.0;
        playButton.updateHitbox();
        playButton.label.setFormat(null, 24, textColor);
        playButton.label.fieldWidth *= 2;
        add(playButton);

        //playButton.onUp.sound = FlxG.sound.load(AssetPaths.select__wav);

        optionsButton = new FlxButton(420, 460, "Options", clickOptions);
        optionsButton.scale.x = optionsButton.scale.y = 2.0;
        optionsButton.updateHitbox();
        optionsButton.label.setFormat(null, 24, textColor);
        optionsButton.label.fieldWidth *= 2;
        
        add(optionsButton);
        */

        //optionsButton.onUp.sound = FlxG.sound.load(AssetPaths.select__wav);

        if (FlxG.sound.music == null)
        {
            FlxG.sound.playMusic(AssetPaths.Theme__mp3, BASE_VOLUME, true);
        }
    }

    override public function update(elapsed:Float)
    {
        if (delayTimer > 0)
        {
            delayTimer -= elapsed;
        }
        else
        {
            clickPlay();
        }

        if (FlxG.keys.anyPressed([P, SPACE]))
        {
            clickPlay();
        }

        super.update(elapsed);
    }

    
    function clickPlay()
    {
        FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
            FlxG.switchState(new PlayState());
        });
    }

    /**
    function clickOptions()
    {
        FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
            FlxG.switchState(new OptionsState());
        });
    }*/
}
