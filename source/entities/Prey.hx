package entities;

import flixel.FlxObject;
import js.html.Console;

class Prey extends Dino
{
    final PREY_SIGHT_RANGE = 75;
    final PREY_SIGHT_ANGLE = 30;

    final PREY_ELASTICITY = 0.9;

    public function new()
    {
        super();

        this.type = EntityPrey;

        setGraphic(16, 16, AssetPaths.SlimeBlue__png, true);

        sprite.setFacingFlip(FlxObject.LEFT, false, false);
        sprite.setFacingFlip(FlxObject.RIGHT, true, false);

        sprite.animation.add("lr", [3], 3, false);
        // sprite.animation.add("u", [6, 7, 6, 8], 6, false);
        // sprite.animation.add("d", [0, 1, 0, 2], 6, false);

        sprite.screenCenter();

        sprite.setSize(8, 8);
        sprite.elasticity = PREY_ELASTICITY;
    }

    public override function update(elapsed:Float)
    {
        super.update(elapsed);
    }

    public override function handlePlayerCollision(player:Player)
    {
        if (state == Unherded)
        {
            // We only care about this collision if we are unherded.
            // Add to player's herd.
            player.addDino(this);
            herdedLeader = player;
            herdedPlayer = player;
            state = Herded;
        }
    }

    public override function handlePredatorCollision(predator:Predator)
    {
        // If Herded, notify the player that we just died
        if (state == Herded)
            herdedPlayer.notifyDeadFollower(this);
        
        // Die instantly!
        PlayState.world.removeEntity(this);
    }

    private override function unherded(elapsed:Float)
    {
        idle(elapsed);
    }

    public override function handleCaveCollision(cave:Cave)
    {
        if (state == Herded)
        {
            herdedPlayer.notifyCaveDeposit(this);
        }
    }

    public override function getSightRange()
    {   
        return PREY_SIGHT_RANGE;
    }   

    public override function getSightAngle()
    {   
        return PREY_SIGHT_ANGLE;
    }   
}
