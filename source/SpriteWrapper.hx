import flixel.FlxSprite;

class SpriteWrapper<T> extends FlxSprite
{
	public var entity:T;

	public function new(entity:T)
	{
		super();
		this.entity = entity;
	}
}
