package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import js.html.Console;
import flixel.util.FlxSpriteUtil; // For drawing call radius

class Player extends Entity
{
    /* Hitbox id constants */
    static final INTERACT_HITBOX_ID = 0;
    static final STICK_HITBOX_ID    = 1;

    var speed:Float = 70.0;

    // Array of followers. TODO: Should be linked list.
    var followers:Array<Dino>;
    var primaryFollower:Dino;

    // State variables
    var depositingToCave:Bool = false;
    var cave:Cave;
    var inRangeOfCave:Bool = false;

    var frameCounter:Int = 0;

    var stepSound:FlxSound;
    var killedSound:FlxSound;
    var cliffJumpSound:FlxSound;
    var callSound:FlxSound;
    var swipeSound:FlxSound;

    final MIN_CALL_RADIUS:Int = 1;
    final MAX_CALL_RADIUS:Int = 100;
    final CALL_GROWTH_RATE:Int = 3;
    var callRadius:Int = 0;
    var isCalling:Bool = false;

    var inCancellableAnimation:Bool=true;

    // The item the player is currently holding. Null means nothing is held.
    var heldItem:GroundItem;

    var interactHitbox:Hitbox;
    var stickHitbox:Hitbox;

    public function new()
    {
        super();

        this.type = EntityPlayer;

        setGraphic(16, 16, AssetPaths.player__png, true);

        sprite.setFacingFlip(FlxObject.LEFT, false, false);
        sprite.setFacingFlip(FlxObject.RIGHT, true, false);

        sprite.animation.add("slr", [18], 15, false);
        sprite.animation.add("su", [6], 15, false);
        sprite.animation.add("sd", [2], 15, false);

        sprite.animation.add("lr", [19, 20, 21, 22], 10, false);
        sprite.animation.add("u", [7, 8, 9, 10], 10, false);
        sprite.animation.add("d", [1, 2, 3, 4], 10, false);

        sprite.animation.add("itemu", [30, 31, 32, 33, 34, 35], 20, false);
        sprite.animation.add("itemlr", [42, 43, 44, 45, 46, 47], 20, false);
        sprite.animation.add("itemd", [24, 25, 26, 27, 28, 29], 20, false);

        sprite.setSize(6, 6);
        sprite.offset.set(4, 6);
        
        sprite.facing = FlxObject.DOWN;
        sprite.animation.play("sd");

        interactHitbox = new Hitbox(this, INTERACT_HITBOX_ID);
        interactHitbox.setSize(24, 24);
        interactHitbox.setOffset(0,0);
        interactHitbox.setActive();
        addHitbox(interactHitbox);

        stickHitbox = new Hitbox(this, STICK_HITBOX_ID);
        stickHitbox.setSize(20, 20);
        stickHitbox.setOffset(0,0);
        stickHitbox.setActive(false);
        addHitbox(stickHitbox);

        followers = new Array<Dino>();

        this.SIGHT_ANGLE = GameWorld.toRadians(45);
        this.SIGHT_RANGE = 120.0;
        this.NEARBY_SIGHT_RADIUS = 120.0;

        this.stepSound = FlxG.sound.load(AssetPaths.GrassFootstep__mp3, 0.4);
        this.killedSound = FlxG.sound.load(AssetPaths.lose__mp3, 1.0);
        this.cliffJumpSound = FlxG.sound.load(AssetPaths.cliffjump__mp3, 0.85);
        this.callSound = FlxG.sound.load(AssetPaths.call__mp3, 0.8);
        this.swipeSound = FlxG.sound.load(AssetPaths.PlayerSwipe__mp3, 0.8);
    }

    public override function update(elapsed:Float)
    {
        call();
        move();
        updateItem();
        
        frameCounter++;
        if (frameCounter % 10 == 0)
            reorganizeHerd();

        // Cave depositing logic
        if (!inRangeOfCave && depositingToCave)
        {
            // We are no longer in range of cave. Set herd back to normal order.
            depositingToCave = false;
            reorganizeHerd();
            for (dino in followers)
            {
                dino.herdedDisableFollowingRadius = false;
            }
        }

        if (depositingToCave)
        {
            if (followers.length > 0 && primaryFollower != null)
            {
                primaryFollower.setLeader(cave);
                primaryFollower.herdedDisableFollowingRadius = true;
            }
        }


        // Assume that we are now out of range of the cave.
        // If we're still in range, we'll be notified within the following collision checking cycle.
        inRangeOfCave = false;


        if (isJumpingCliff)
        {
            // TODO: Jumping animation
            cliffJumpSound.play();
            FlxG.camera.shake(0.0001, 0.2);
            switch (sprite.facing)
            {
                case FlxObject.LEFT, FlxObject.RIGHT:
                    sprite.animation.play("slr");
                case FlxObject.UP:
                    sprite.animation.play("su");
                case FlxObject.DOWN:
                    sprite.animation.play("sd");
            }
        }

        if (sprite.animation.finished)
        {
            inCancellableAnimation = true;
        }

        super.update(elapsed);
    }

    function call():Void
    {
        /**
        var call = FlxG.keys.pressed.C;
        if (call)
        {
            if (!callSound.playing)
            {
                callSound.fadeIn(0.2, 0.0, 1.0);
                callSound.play();
            }
            PlayState.world.callNearbyDinos(getCallRadius());
        }
        else
        {
            if (callSound.playing)
            {
                callSound.fadeOut(0.05, 0.0);
            }
        }
        */
        //FlxSpriteUtil.drawCircle(this.sprite, -1, -1, maxCallRadius);

        if (FlxG.keys.pressed.C)
        {
            if (!callSound.playing)
            {
                callSound.fadeIn(0.2, 0.0, 1.0);
                callSound.play();
            }
            callRadius += CALL_GROWTH_RATE;
            if (callRadius > MAX_CALL_RADIUS)
            {
                callRadius = MAX_CALL_RADIUS;
            }
            isCalling = true;
            PlayState.world.callNearbyDinos(callRadius);
        }
        else
        {
            isCalling = false;
            if (callRadius > 1)
            {
                callSound.fadeOut(0.1, 0.0);
                callRadius = 0;
            }
        }
    }

    public function getIsCalling():Bool
    {
        return isCalling;
    }

    function reorganizeHerd()
    {
        var followersCopy = new Array<Dino>();
        for (dino in followers)
        {
            // Prune any Unherded dinosaurs
            if (dino.getState() == Herded)
            {
                followersCopy.push(dino);
            }
        }

        var lastEntity:Entity = this;
        var first = true;

        while (followersCopy.length > 0)
        {
            var dino:Dino = cast GameWorld.getNearestEntity(lastEntity, cast followersCopy);
            // TODO: This is inefficient
            followersCopy.remove(dino);

            if (first)
            {
                primaryFollower = dino;
                first = false;
            }

            dino.setLeader(lastEntity);
            lastEntity = dino;
        }
    }

    function move()
    {
        var up = FlxG.keys.anyPressed([UP, W]);
        var down = FlxG.keys.anyPressed([DOWN, S]);
        var left = FlxG.keys.anyPressed([LEFT, A]);
        var right = FlxG.keys.anyPressed([RIGHT, D]);

        if (up && down)
            up = down = false;

        if (left && right)
            left = right = false;

        var angle = 0.0;
        if (up)
        {
            angle = 270;
            if (left)
                angle -= 45;
            if (right)
                angle += 45;
            sprite.facing = FlxObject.UP;
        }
        else if (down)
        {
            angle = 90;
            if (left)
                angle += 45;
            if (right)
                angle -= 45;
            sprite.facing = FlxObject.DOWN;
        }
        else if (left)
        {
            angle = 180;
            sprite.facing = FlxObject.LEFT;
        }
        else if (right)
        {
            angle = 0;
            sprite.facing = FlxObject.RIGHT;
        }
        else
        {
            // Player is not moving
            sprite.velocity.set(0, 0);
            
            if (inCancellableAnimation)
            {
                switch (sprite.facing)
                {
                    case FlxObject.LEFT, FlxObject.RIGHT:
                        sprite.animation.play("slr");
                    case FlxObject.UP:
                        sprite.animation.play("su");
                    case FlxObject.DOWN:
                        sprite.animation.play("sd");
                }
                inCancellableAnimation = true;
            }
            return;
        }

        angle *= Math.PI / 180;
        sprite.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);

        var canCancelAnimation = inCancellableAnimation || sprite.animation.finished;
        var isMoving = sprite.velocity.x != 0 || sprite.velocity.y != 0;
        if (isMoving && canCancelAnimation)
        {
            stepSound.play();
            switch (sprite.facing)
            {
                case FlxObject.LEFT, FlxObject.RIGHT:
                    sprite.animation.play("lr");
                case FlxObject.UP:
                    sprite.animation.play("u");
                case FlxObject.DOWN:
                    sprite.animation.play("d");
            }
            inCancellableAnimation = true;
        }
    }

    function updateItem()
    {
        if (heldItem != null)
        {
            var useKeyPressed = FlxG.keys.anyPressed([SPACE]);
            if (useKeyPressed && inCancellableAnimation)
            {
                switch (sprite.facing)
                {
                    case FlxObject.LEFT, FlxObject.RIGHT:
                        sprite.animation.play("itemlr");
                    case FlxObject.UP:
                        sprite.animation.play("itemu");
                    case FlxObject.DOWN:
                        sprite.animation.play("itemd");
                }
                inCancellableAnimation = false;

                stickHitbox.setActive(true, 8);
                swipeSound.stop();
                swipeSound.play();
            }
        }
        else
        {
            heldItem = new GroundItem();
        }
    }

    public function notifyUnherded(dino:Dino)
    {
        // TODO: Scatter the line of prey that is following this player
        followers.remove(dino);
    }

    public function notifyCaveDeposit(dino:Dino)
    {
        if (depositingToCave)
        { 
            // Remove entity from world
            followers.remove(dino);
            PlayState.world.incrementScore(1);
            PlayState.world.removeEntity(dino);
            depositingToCave = false;
        }
    }

    public function notifyDeadFollower(dino:Dino)
    {
        // TODO: Scatter any following herd
        followers.remove(dino);
    }

    public function addDino(dino:Dino)
    {
        // Insert new dino to herd
        followers.push(dino);
    }

    public override function notifyHitboxCollision(hitbox:Hitbox, entity:Entity)
    {
        if (hitbox.getId() == INTERACT_HITBOX_ID)
        {
            if (entity.type == EntityCave)
            {
                handleCaveCollision(cast entity);
            }
        }
        else if (hitbox.getId() == STICK_HITBOX_ID)
        {
            if (entity.type == EntityPrey)
            {
                var prey:Prey = cast entity;
            }
            else if (entity.type == EntityPredator)
            {
                var predator:Predator = cast entity;
                predator.hitWithStick();
            }
        }
    }

    public function isInRangeOfCave()
    {
        return this.inRangeOfCave;
    }

    public override function handleCaveCollision(cave:Cave)
    {
        depositingToCave = true;
        inRangeOfCave = true;
        this.cave = cave;
        PlayState.world.setRespawnCave(cave);
    }

    public override function handlePredatorCollision(predator:Predator)
    {
        if (predator.canEat(this))
        {
            // Unherd all dinosaurs.
            for (follower in followers)
            {
                follower.setUnherded();
            }
            followers.resize(0);
            respawn();
        }
    }

    public function respawn()
    {
        PlayLogger.recordPlayerDeath(this);

        // Move player to nearest cave.
        FlxG.camera.shake(0.01, 0.2);
        FlxG.camera.fade(FlxColor.BLACK, 0.33, true);
        
        var respawnCave = PlayState.world.getRespawnCave();
        this.setPosition(respawnCave.getX(), respawnCave.getY());
        killedSound.play();
    }

    public override function handleBoulderCollision(boulder:Boulder)
    {
        if (!boulder.isCollidable()) return;

        var direction = 0;

        FlxG.collide(this.getSprite(), boulder.getSprite());
        var diffX = boulder.getX() - getX();
        var diffY = boulder.getY() - getY();

        if (sprite.touching & FlxObject.RIGHT > 0)
            direction = FlxObject.RIGHT;
        else if (sprite.touching & FlxObject.LEFT > 0)
            direction = FlxObject.LEFT;
        else if (sprite.touching & FlxObject.DOWN > 0)
            direction = FlxObject.DOWN;
        else if (sprite.touching & FlxObject.UP > 0)
            direction = FlxObject.UP;

        if (direction != 0)
        {
            boulder.push(direction);
        }
    }

    public override function handleGroundItemCollision(item:GroundItem)
    {
        if (heldItem == null)
        {
            heldItem = item;
        }
    }

    // Return the Player's speed.
    public function getSpeed()
    {
        return this.speed;
    }

    // Return whether the player is calling.
    public function isPlayerCalling():Bool
    {
        return callSound.playing && (getCallRadius() > MIN_CALL_RADIUS);
    }

    public function getCallRadius():Float
    {
        return callSound.volume * MAX_CALL_RADIUS;
    }
}
