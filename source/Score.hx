package;

import entities.*;
import js.html.Console;

class Score
{
    // Score per level
    static var _score:Int = 0;

    // Track score per delivery
    static final COLLECTED_TIMER = 1.5;
    static var _collectedTimer:Float = COLLECTED_TIMER;
    static var _collectedScore:Int = 0;
    static var _collectedMultiplier:Float = 1.0;

    // Total score (cumulative, between levels)
    static var _totalScore:Int = 0;
    static var _totalPreyCount:Int = 0;
    static var _totalPredatorCount:Int = 0;
    
    // Used to track time for multiplier
    static var _lastTimestamp = 0.0;

    static public function collectDino(dino:Dino)
    {
        var score:Int;
        switch (dino.getType()) {
            case EntityPrey:
                _collectedScore += 1;
                _collectedMultiplier += 0.05;
            case EntityPredator:
                _collectedScore += 5;
                _collectedMultiplier += 0.2;
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
        _totalScore += amount;
    }

    static public function decrement(amount:Int):Void
    {  
        _score -= amount;
        _totalScore -= amount;
        if (_score < 0)
        {
            _score = 0;
        }
        if (_totalScore < 0)
        {
            _totalScore = 0;
        }
    }

    static public function resetTotalScore():Void
    {
        addScore();
        _score = 0;
        _totalScore = 0;
    }

    static public function resetLevelScore():Void
    {
        addScore();
        _score = 0;
    }

    static public function getScore():Int
    {
        return _score;
    }

    static public function getTotalScore()
    {
        return _totalScore;
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
}
