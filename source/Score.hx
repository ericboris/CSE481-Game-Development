package;

import flixel.text.FlxText;

class Score
{
    static var _score:Int = 0;
    static var _totalScore:Int = 0;

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
        _score = 0;
        _totalScore = 0;
    }

    static public function resetLevelScore():Void
    {
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
}
