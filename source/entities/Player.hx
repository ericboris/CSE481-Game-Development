package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.addons.display.shapes.FlxShapeCircle;
import js.html.Console;
import flixel.util.FlxSpriteUtil; // For drawing call radius

class Player extends Entity
{
    /* Hitbox id constants */
    static final INTERACT_HITBOX_ID = 0;
    static final STICK_HITBOX_ID    = 1;

    static final SPEED = 120.0;
    static final DEBUG_SPEED = 120.0;

    var speed:Float = SPEED;

    // Array of followers. TODO: Should be linked list.
    var followers:Array<Dino>;
    var primaryFollower:Dino;

    // State variables
    var depositingToCave:Bool = false;
    var cave:Cave;
    var inRangeOfCave:Bool = false;
    var usingItem:Bool = false;

    var frameCounter:Int = 0;

    var stepSound:FlxSound;
    var killedSound:FlxSound;
    var cliffJumpSound:FlxSound;
    var callStartSound:FlxSound;
    var callLoopSound:FlxSound;
    var callEndSound:FlxSound;
    var swipeSound:FlxSound;

    final MIN_CALL_RADIUS:Int = 1;
    final MAX_CALL_RADIUS:Int = 100;
    final CALL_GROWTH_RATE:Int = 3;
    var callRadius:Int = 0;
    var isCalling:Bool = false;

    var callCircle:FlxShapeCircle;

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
        stickHitbox.setSize(16, 25);
        stickHitbox.setOffset(0,8);
        stickHitbox.setActive(false);
        addHitbox(stickHitbox);

        followers = new Array<Dino>();

        if (PlayState.DEBUG_FAST_SPEED)
        {
            this.speed = DEBUG_SPEED;
        }
        this.SIGHT_ANGLE = GameWorld.toRadians(45);
        this.SIGHT_RANGE = 120.0;
        this.NEARBY_SIGHT_RADIUS = 120.0;

        this.stepSound = FlxG.sound.load(AssetPaths.GrassFootstep__mp3, 0.5);
        this.killedSound = FlxG.sound.load(AssetPaths.lose__mp3, 1.0);
        this.cliffJumpSound = FlxG.sound.load(AssetPaths.cliffjump__mp3, 1.0);
        this.callStartSound = FlxG.sound.load(AssetPaths.call_start__mp3, 0.5);
        this.callLoopSound = FlxG.sound.load(AssetPaths.call_loop__mp3, 0.5);
        this.callEndSound = FlxG.sound.load(AssetPaths.call_end__mp3, 0.5);
        this.swipeSound = FlxG.sound.load(AssetPaths.PlayerSwipe__mp3, 0.8);
    
        var lineStyle = {thickness: 1.0, color: FlxColor.WHITE};
        callCircle = new FlxShapeCircle(0, 0, 0, lineStyle, FlxColor.TRANSPARENT);
        callCircle.alpha = 0.7;
        callCircle.health = PlayState.world.bottomLayerSortIndex() + 2;
        PlayState.world.add(callCircle);
    }

    public override function update(elapsed:Float)
    {
        call();
        updateItem();
        move();

        if (isCalling)
        {
            if (callCircle.alpha < 0.8)
            {
                callCircle.alpha += 0.05;
            }

            if (callRadius != callCircle.radius)
            {
                callCircle.radius = callRadius;
                callCircle.redrawShape();
            }
        }
        else
        {
            callCircle.alpha -= 0.1;
        }

        callCircle.setPosition(getX() - callCircle.width/2, getY() - callCircle.height/2);
 
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


        if (isJumping)
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
        //FlxSpriteUtil.drawCircle(this.sprite, -1, -1, maxCallRadius);

        if (FlxG.keys.pressed.C)
        {
            // Sound playing logic
            if (!isCalling)
            {
                var duration = callStartSound.length / 1000;
                callStartSound.fadeIn(duration, 0.5, 0.7);
                callStartSound.play(true);
                callStartSound.onComplete = function () {
                    var duration = callLoopSound.length / 1000;
                    callLoopSound.fadeIn(duration, 0.7, 1.0);
                    callLoopSound.play(true);
                    callLoopSound.looped = true;
                };
            }

            // Grow the calling radius
            callRadius += CALL_GROWTH_RATE;
            if (callRadius > MAX_CALL_RADIUS)
            {
                callRadius = MAX_CALL_RADIUS;
            }
            isCalling = true;

            if (frameCounter % 5 == 0)
            {
                // Only call dinos once every 5 frames for performance.
                PlayState.world.callNearbyDinos(callRadius);
            }
        }
        else
        {
            // Call sound playing logic
            if (isCalling)
            {
                var volume:Float = 1.0;

                if (callStartSound.playing)
                {
                    callStartSound.fadeOut(0.1, 0.0);
                    callStartSound.onComplete = function () {}
                    volume = callStartSound.volume;
                }
                else if (callLoopSound.playing)
                {
                    callLoopSound.fadeOut(0.1, 0.0);
                    callLoopSound.onComplete = function () {}
                    volume = callLoopSound.volume;
                }

                callEndSound.volume = volume * 0.75;
                callEndSound.play(true);
            }

            isCalling = false;
            callRadius = 0;
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
            dino.herdedDisableFollowingRadius = false;
        }

        var lastEntity:Entity = this;
        var first = true;

        while (followersCopy.length > 0)
        {
            var doPathfindingCheck = first;
            
            var dino:Dino = cast GameWorld.getNearestEntity(lastEntity, cast followersCopy, doPathfindingCheck);
            if (doPathfindingCheck && (dino == null || GameWorld.entityDistance(dino, this) > Dino.MAX_FOLLOWING_RADIUS))
            {
                // We tried to find our primary leader via pathfinding, but we chose one that's far away!
                // Instead choose the closest one (no pathfinding).
                dino = cast GameWorld.getNearestEntity(lastEntity, cast followersCopy, false);
            }

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
        var movementSpeed = speed;
        if (usingItem)
        {
            movementSpeed /= 2;
        }

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
        sprite.velocity.set(Math.cos(angle) * movementSpeed, Math.sin(angle) * movementSpeed);

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
            
            if (usingItem)
            {
                if (sprite.animation.finished)
                {
                    usingItem = false;
                }
            }
            else if (useKeyPressed && inCancellableAnimation)
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

                usingItem = true;

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
            PlayState.world.collectDino(dino);
            cave.think("" + PlayState.world.getNumPreyLeft(), 2.5);
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

                var chance = prey.getState() == Herded ? 10 : 100;
                if (FlxG.random.bool(chance))
                {
                    prey.think(":(", 0.4);
                }

                var diffX = prey.getX() - getX();
                var diffY = prey.getY() - getY();
                prey.updatePosition(FlxMath.signOf(diffX), FlxMath.signOf(diffY));
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
            think("!", 2.0);
        }
    }

    public function respawn()
    {
        PlayState.world.numPlayerDeaths++;
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
        if (!boulder.isCollidable() || isJumping) return;

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
            boulder.push(this, direction);
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
        return isCalling && (getCallRadius() > MIN_CALL_RADIUS);
    }

    public function getCallRadius():Float
    {
        return callRadius;
    }
}
