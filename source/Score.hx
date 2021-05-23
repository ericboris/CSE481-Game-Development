package;

import entities.*;
import js.html.Console;

class Score
{
    static var _score:Int = 0;
    static var _preyCount:Int = 0;
    static var _predatorCount:Int = 0;
    

    // Track score per delivery
    static final COLLECTED_TIMER = 1.5;
    static var _collectedTimer:Float = COLLECTED_TIMER;
    static var _collectedScore:Int = 0;
    static var _collectedMultiplier:Float = 1.0;

    // Used to track time for multiplier
    static var _lastTimestamp = 0.0;

    static public function collectDino(dino:Dino)
    {
        var score:Int;
        switch (dino.getType()) {
            case EntityPrey:
                _collectedScore += 1;
                _collectedMultiplier += 0.05;
                _preyCount += 1;
            case EntityPredator:
                _collectedScore += 5;
                _collectedMultiplier += 0.2;
                _predatorCount += 1;
            default:
                // This shouldn't happen.
                Console.log("herdedIncrement() : invalid entity");
        }
        
        // Reset collected timer to keep the multiplier going
        _collectedTimer = COLLECTED_TIMER;
    }

    static public function increment(amount:Int):Void
    {
        _score += amount;
    }

    static public function decrement(amount:Int):Void
    {  
        _score -= amount;
        if (_score < 0)
        {
            _score = 0;
        }
    }

    static public function resetScore():Void
    {
        _score = 0;
        _preyCount = 0;
        _predatorCount = 0;
        _collectedScore = 0;
        _collectedTimer = COLLECTED_TIMER;
        _collectedMultiplier = 1.0;
    }

    static public function getScore():Int
    {
        return _score;
    }

    static function addScore()
    {
        increment(Std.int(_collectedScore * _collectedMultiplier));

        _collectedScore = 0;
        _collectedTimer = COLLECTED_TIMER;
        _collectedMultiplier = 1.0;
    }

    static public function update()
    {
        var timestamp = haxe.Timer.stamp();
        var timestep = timestamp - _lastTimestamp;
        _lastTimestamp = timestamp;

        if (_collectedScore > 0)
        {
            _collectedTimer -= timestep;
            if (_collectedTimer <= 0.0)
            {
                addScore();
            }
        }
    }

    static public function getPreyCount()
    {
        return _preyCount;
    }

    static public function getPredatorCount()
    {
        return _predatorCount;
    }

    static public function getCount()
    {
        return _preyCount + _predatorCount;
    }
}
