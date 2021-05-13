import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.addons.ui.FlxButtonPlus;
import flixel.ui.FlxButton;
import openfl.media.Sound;
import flixel.util.FlxColor;

class MenuState extends FlxState
{
    var playButton:FlxButton;
    var titleText:FlxText;
    var optionsButton:FlxButton;

    static final BASE_VOLUME = 0.7;

    override public function create()
    {
        super.create();

        if (!PlayLogger.loggerInitialized())
        {
            PlayLogger.initializeLogger();
        }

        titleText = new FlxText(210, 180, 400, "Dino Herder", 70);
        titleText.alignment = CENTER;
        add(titleText);

        var textColor = 0xFF404040;

        playButton = new FlxButton(0, 0, "Play", clickPlay);
        playButton.scale.x = playButton.scale.y = 2.0;
        playButton.updateHitbox();
        playButton.label.setFormat(null, 24, textColor);
        playButton.label.fieldWidth *= 2;

        playButton.x = (FlxG.width / 2) - playButton.width - 10;
        playButton.y = FlxG.height - playButton.height - 10;
        add(playButton);

        //playButton.onUp.sound = FlxG.sound.load(AssetPaths.select__wav);

        optionsButton = new FlxButton(0, 0, "Options", clickOptions);
        optionsButton.scale.x = optionsButton.scale.y = 2.0;
        optionsButton.updateHitbox();
        optionsButton.label.setFormat(null, 24, textColor);
        optionsButton.label.fieldWidth *= 2;
        
        optionsButton.x = (FlxG.width / 2) + 10;
        optionsButton.y = FlxG.height - optionsButton.height - 10;
        add(optionsButton);

        //optionsButton.onUp.sound = FlxG.sound.load(AssetPaths.select__wav);

        if (FlxG.sound.music == null)
        {
            FlxG.sound.playMusic(AssetPaths.Theme__mp3, 0.5, true);
        }

        FlxG.sound.volume = BASE_VOLUME;
    }

    override public function update(elapsed:Float)
    {
        if (FlxG.keys.anyPressed([P]))
        {
            clickPlay();
        }

        super.update(elapsed);
    }

    function clickPlay()
    {
        FlxG.switchState(new PlayState());
    }

    function clickOptions()
    {
        FlxG.switchState(new OptionsState());
    }
}
