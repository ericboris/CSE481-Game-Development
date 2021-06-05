package;

import flixel.effects.particles.FlxParticle;
import flixel.FlxG;
import flixel.math.FlxRandom;

/**
 * @author Shaun Stone (SMKS) <http://www.smks.co.uk>
 */
class ConfettiParticle extends FlxParticle implements IFlxParticle
{
	var spinRotation:Float;
	
	public function new()
	{
		super();
		
        var colors = [0xFF0048B6, 0xFF01AD61, 0xFF7CC53E, 0xFFFFD23D, 0xFFF97C25, 0xFFE82C31];
		
        var size = FlxG.random.int(8, 10);
        this.makeGraphic(size, size, colors[FlxG.random.int(0, colors.length-1)]);
		this.x = FlxG.random.float(-20, 20);
		this.y = FlxG.random.float(-10, -10) + 5;
		this.exists = false;
		this.angularVelocity = 0.2;
		
		this.spinRotation = FlxG.random.float(0.008, 0.02);
	}

    override public function onEmit()
    {
        this.alpha = 1.0;
    }
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		this.scale.x = 1;
		this.scale.y = this.scale.y - spinRotation;
		this.alpha -= 0.01;

		if (this.scale.y <= -1) {
			this.scale.y = 1;
		}
	}
}
