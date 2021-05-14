package entities;

import flixel.FlxObject;
import flixel.FlxG;
import js.html.Console;
import flixel.system.FlxSound;

class Prey extends Dino
{
    final PREY_ELASTICITY = 0.9;

    var herdedSound:FlxSound;

    public function new()
    {
        super();

        this.type = EntityPrey;

        setGraphic(16, 16, AssetPaths.SlimeBlue__png, true);
        sprite.animation.add("d", [0, 0, 0, 1, 2, 3, 4, 5], 12, false);
        sprite.animation.add("l", [6, 6, 6, 7, 8, 9, 10, 11], 12, false);
        sprite.animation.add("r", [12, 12, 12, 13, 14, 15, 16, 17], 12, false);
        sprite.animation.add("u", [18, 18, 18, 19, 20, 21, 22, 23], 12, false);
        sprite.setSize(10, 10);

        /*
        setGraphic(32, 32, AssetPaths.BlueDragon__png, true);
        sprite.animation.add("d", [0, 1, 2, 3], 4, false);
        sprite.animation.add("u", [4, 5, 6, 7], 4, false);
        sprite.animation.add("l", [8, 9, 10, 11], 4, false);
        sprite.animation.add("r", [12, 13, 14, 15], 4, false);
        sprite.setSize(30, 30);
        */

        sprite.screenCenter();
        sprite.mass = 0.4;

        sprite.elasticity = PREY_ELASTICITY;

        herdedSound = FlxG.sound.load(AssetPaths.addedToHerd__mp3, 0.5);

        thought.setOffset(0, -11);

        this.SIGHT_ANGLE = GameWorld.toRadians(360);
        this.SIGHT_RANGE = 100;
    }

    public override function update(elapsed:Float)
    {
        if (state == Unherded && seenEntities.length > 0)
        {
            state = Fleeing;
        }

        move(elapsed);

        super.update(elapsed);
    }

    function move(elapsed:Float)
    {
        if (Math.abs(sprite.velocity.y) > Math.abs(sprite.velocity.x))
        {
            if (sprite.velocity.y >= 0)
            {
                sprite.animation.play("d");
            }
            else
            {
                sprite.animation.play("u");
            }
        }
        else
        {
            if (sprite.velocity.x >= 0)
            {
                sprite.animation.play("r");
            }
            else
            {
                sprite.animation.play("l");
            }
        }
    }

    public override function handlePlayerCollision(player:Player)
    {
        if (state == Unherded || state == Fleeing)
        {
            // We only care about this collision if we are unherded.
            // Add to player's herd.
            addToHerd(player);
        }
    }

    public override function handlePredatorCollision(predator:Predator)
    {
        if (predator.canEat(this))
        {
            // If Herded, notify the player that we just died
            if (state == Herded)
                herdedPlayer.notifyDeadFollower(this);
            
            FlxG.camera.shake(0.005, 0.1);

            // Die instantly!
            PlayState.world.numPreyDeaths++;
            PlayState.world.removeEntity(this);
        }
    }

    public function addToHerd(player:Player)
    {
        if (state == Unherded)
        {
            player.addDino(this);
            herdedSound.play();
            herdedLeader = player;
            herdedPlayer = player;
            state = Herded;
            think("<3", 0.8);
        }
    }

    public override function handlePreyCollision(prey: Prey)
    {
        /* Collision with prey herds this prey
        if ((state == Unherded || state == Fleeing) && prey.getState() == Herded)
        {
            var player = prey.getHerdedPlayer();
            addToHerd(player);
        }
        */
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
}
