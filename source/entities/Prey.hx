package entities;

import flixel.FlxObject;
import flixel.FlxG;
import js.html.Console;
import flixel.system.FlxSound;

class Prey extends Dino
{
    final PREY_ELASTICITY = 0.9;

    var herdedSound:FlxSound;
    var killedSound:FlxSound;

    var touchingCaveCount:Int = 0;

    var facing:String;

    public function new()
    {
        super();

        this.type = EntityPrey;

        /**
        setGraphic(16, 16, AssetPaths.SlimeBlue__png, true);
        sprite.animation.add("d", [0, 0, 0, 1, 2, 3, 4, 5], 12, false);
        sprite.animation.add("l", [6, 6, 6, 7, 8, 9, 10, 11], 12, false);
        sprite.animation.add("r", [12, 12, 12, 13, 14, 15, 16, 17], 12, false);
        sprite.animation.add("u", [18, 18, 18, 19, 20, 21, 22, 23], 12, false);
        */

        setGraphic(16, 16, AssetPaths.Mammoth__png, true);
        sprite.animation.add("d", [8, 9, 10, 11], 6, false);
        sprite.animation.add("l", [4, 5, 6, 7], 6, false);
        sprite.animation.add("r", [0, 1, 2, 3], 6, false);
        sprite.animation.add("u", [12, 13, 14, 15], 6, false);
        sprite.animation.add("ds", [8], 0, false);
        sprite.animation.add("ls", [4], 0, false);
        sprite.animation.add("rs", [0], 0, false);
        sprite.animation.add("us", [1], 0, false);

        setHitboxSize(7, 7);


        sprite.elasticity = PREY_ELASTICITY;

        herdedSound = FlxG.sound.load(AssetPaths.addedToHerd__mp3, 0.6);
        killedSound = FlxG.sound.load(AssetPaths.preyKilled__mp3, 0.3);
        killedSound.proximity(sprite.x, sprite.y, FlxG.camera.target, FlxG.width * 0.6);

        thought.setOffset(0, -13);

        canJumpCliffs = false;

        this.SIGHT_ANGLE = GameWorld.toRadians(360);
        this.SIGHT_RANGE = 100;

        this.facing = "down";
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
        if (Math.abs(sprite.velocity.y) > 0 || Math.abs(sprite.velocity.x) > 0)
        {
            if (Math.abs(sprite.velocity.y) > Math.abs(sprite.velocity.x))
            {
                if (sprite.velocity.y >= 0)
                {
                    facing = "down";
                    sprite.animation.play("d");
                }
                else
                {
                    facing = "up";
                    sprite.animation.play("u");
                }
            }
            else
            {
                if (sprite.velocity.x >= 0)
                {
                    facing = "right";
                    sprite.animation.play("r");
                }
                else
                {
                    facing = "left";
                    sprite.animation.play("l");
                }
            }
        }
        else 
        {
            switch (facing)
            {  
                case "left":
                    sprite.animation.play("ls");
                case "right":
                    sprite.animation.play("rs");
                case "up":
                    sprite.animation.play("us");
                case "down":
                    sprite.animation.play("down");
            }
        }
    }

    public override function setUnherded(notify:Bool = false)
    {
        super.setUnherded(notify);

        canJumpCliffs = false;
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
           
            var player = PlayState.world.getPlayer();
            if (GameWorld.entityDistance(player, this) < 200) 
            {
                FlxG.camera.shake(0.01, 0.1);
            }

            var isHerded = state == Herded;
            PlayLogger.recordPreyDeath(getX(), getY(), isHerded);
            //PlayLogger.recordPreyRemoved(getX(), getY(), isHerded, true, PlayState.world.getNumPreyRemaining());

            // Die instantly!
            PlayState.world.numPreyDeaths++;
            PlayState.world.removeEntity(this);
            killedSound.play();
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
            canJumpCliffs = true;
            
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

    override function canBeCollected()
    {
        return state == Herded;
    }

    private override function unherded(elapsed:Float)
    {
        idle(elapsed);
    }

    public override function handleCaveDeposit(cave:Cave)
    {
        if (state == Herded)
        {
            herdedPlayer.notifyCaveDeposit(this, cave);
            PlayLogger.recordCaveDeposit();
        }
    }
}
