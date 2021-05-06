package;

import flixel.text.FlxText;

class Score
{
    static var _score:Int = 0;

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

    static public function reset():Void
    {
        _score = 0;
    }

    static public function get():Int
    {
        return _score;
    }
}
