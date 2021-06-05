package;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxRandom;

/**
 * @author Shaun Stone (SMKS) <http://www.smks.co.uk>
 */
class Confetti extends FlxTypedGroup<FlxEmitter>
{
	private static inline var MAX_COUNT:Int = 50;
	
	var emitter:FlxEmitter;

	public function new(x:Float, y:Float)
	{ 
		super(MAX_COUNT);
		
		emitter = new FlxEmitter(x, y, MAX_COUNT);
		
		emitter.acceleration.set(0, 100, 0, 100, 0, 100, 0, 100);
		
		for (i in 0...MAX_COUNT) {
			var p = new ConfettiParticle();
        	emitter.add(p);
			emitter.kill();
		}
		
		emitter.setSize(10, 10);
		
		add(emitter);
	}

    public function getEmitter():FlxEmitter { return emitter; }
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
	}

	public function trigger():Void
	{
		emitter.start(true, 0, 7);
	}

    public function emit():Void
    {
        emitter.start(false, 0.05, 100);
    }
	
}
