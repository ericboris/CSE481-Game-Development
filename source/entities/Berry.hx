package entities;

import flixel.FlxObject;

class Berry extends Entity
{
    var consumed:Bool = false;
    public function new()
    {
        super();
        sprite.loadGraphic(AssetPaths.berry__png, 16, 16, false);
        sprite.immovable = true;

        setHitboxSize(12, 12);

        type = EntityPickup;
    }

    public override function handlePlayerCollision(player:Player)
    {
        if (!consumed)
        {
            player.triggerSpeedBoost();
            consumed = true;
            PlayState.world.removeEntity(this);
        }
    }
}
