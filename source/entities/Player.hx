package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.addons.display.shapes.FlxShapeArrow;
import js.html.Console;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

class Player extends Entity
{
    /* Hitbox id constants */
    static final INTERACT_HITBOX_ID = 0;
    static final STICK_HITBOX_ID    = 1;

    static final SPEED = 100.0;
    static final SPEED_BOOST_MULTIPLIER = 1.35;
    static final SWIPE_SPEED = 45.0;
    static final CALL_SPEED = 82.0;
    
    static final DEBUG_SPEED = 120.0;

    static final CALL_VOLUME = 0.55;

    static final FRAMERATE = 10;
    static final MIN_FRAMERATE = 0;

    static var numLives:Int = 3;

    var speed:Float = SPEED;

    // Array of followers. TODO: Should be linked list.
    public var followers:Array<Dino>;
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
    var berrySound:FlxSound;

    final MIN_CALL_RADIUS:Int = 1;
    final MAX_CALL_RADIUS:Int = 120;
    final CALL_GROWTH_RATE:Int = 2;
    var callRadius:Int = 0;
    var isCalling:Bool = false;

    var callCircle:FlxShapeCircle;
    // An arrow that appears on calling and points towards nearest cave
    var caveArrow:FlxSprite;
    //var cavePointer:FlxShapeArrow;

    var inCancellableAnimation:Bool=true;

    // The item the player is currently holding. Null means nothing is held.
    var heldItem:GroundItem;

    var interactHitbox:Hitbox;
    var stickHitbox:Hitbox;

    // Speed boost for player
    static final SPEED_BOOST_DURATION = 10.0;

    var speedBoost:Bool = false;
    var speedBoostTimer:Float = 0;
    var alphaRate = 0.04;

    var BERRY_SHIFT = 48;

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

        sprite.animation.add("lr", [19, 20, 21, 22], FRAMERATE, false);
        sprite.animation.add("u", [7, 8, 9, 10], FRAMERATE, false);
        sprite.animation.add("d", [1, 2, 3, 4], FRAMERATE, false);

        sprite.animation.add("itemu", [30, 31, 32, 33, 34, 35], 20, false);
        sprite.animation.add("itemlr", [42, 43, 44, 45, 46, 47], 20, false);
        sprite.animation.add("itemd", [24, 25, 26, 27, 28, 29], 20, false);

        sprite.animation.add("slr_berry", [18+BERRY_SHIFT], 15, false);
        sprite.animation.add("su_berry", [6+BERRY_SHIFT], 15, false);
        sprite.animation.add("sd_berry", [2+BERRY_SHIFT], 15, false);

        sprite.animation.add("lr_berry", [19+BERRY_SHIFT, 20+BERRY_SHIFT, 21+BERRY_SHIFT, 22+BERRY_SHIFT], FRAMERATE, false);
        sprite.animation.add("u_berry", [7+BERRY_SHIFT, 8+BERRY_SHIFT, 9+BERRY_SHIFT, 10+BERRY_SHIFT], FRAMERATE, false);
        sprite.animation.add("d_berry", [1+BERRY_SHIFT, 2+BERRY_SHIFT, 3+BERRY_SHIFT, 4+BERRY_SHIFT], FRAMERATE, false);

        sprite.animation.add("itemu_berry", [30+BERRY_SHIFT, 31+BERRY_SHIFT, 32+BERRY_SHIFT, 33+BERRY_SHIFT, 34+BERRY_SHIFT, 35+BERRY_SHIFT], 20, false);
        sprite.animation.add("itemlr_berry", [42+BERRY_SHIFT, 43+BERRY_SHIFT, 44+BERRY_SHIFT, 45+BERRY_SHIFT, 46+BERRY_SHIFT, 47+BERRY_SHIFT], 20, false);
        sprite.animation.add("itemd_berry", [24+BERRY_SHIFT, 25+BERRY_SHIFT, 26+BERRY_SHIFT, 27+BERRY_SHIFT, 28+BERRY_SHIFT, 29+BERRY_SHIFT], 20, false);


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
        this.callStartSound = FlxG.sound.load(AssetPaths.call_start__mp3, CALL_VOLUME);
        this.callLoopSound = FlxG.sound.load(AssetPaths.call_loop__mp3, CALL_VOLUME);
        this.callEndSound = FlxG.sound.load(AssetPaths.call_end__mp3, CALL_VOLUME);
        this.swipeSound = FlxG.sound.load(AssetPaths.PlayerSwipe__mp3, 0.8);
        this.berrySound = FlxG.sound.load(AssetPaths.berryEat__mp3, 0.8);

        var lineStyle = {thickness: 1.0, color: FlxColor.WHITE};
        callCircle = new FlxShapeCircle(0, 0, 0, lineStyle, FlxColor.TRANSPARENT);
        callCircle.alpha = 0.0;
        callCircle.health = PlayState.world.bottomLayerSortIndex() + 2;
        PlayState.world.add(callCircle);

        caveArrow = new FlxSprite(0, 0);
        caveArrow.loadRotatedGraphic(AssetPaths.down_arrow__png, 32);
        caveArrow.alpha = 0.0;
        caveArrow.health = PlayState.world.topLayerSortIndex();
        PlayState.world.add(caveArrow);

        PlayLogger.recordPlayerLives(numLives);
    }

    public override function update(elapsed:Float)
    {
        updateCallCircle();
        updateSpeedBoost(elapsed);
        call();
        updateItem();
        move();

        PlayLogger.recordPlayerMovement(this);
 
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

        if (!runningIntoCave)
        {
            nearCaveCounter = 0;
        }
        
        var isMoving = sprite.velocity.x != 0 || sprite.velocity.y != 0;
        if ((!runningIntoCave && isMoving) || isCalling || !inCancellableAnimation)
        {
            nearCaveCounter = 0;
            PlayState.world.closeLevelMenu();
        }
        runningIntoCave = false;


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
                    if (speedBoost)
                    {
                        sprite.animation.play("slr_berry");
                    }
                    else
                    {
                        sprite.animation.play("slr");
                    }
                case FlxObject.UP:
                    if (speedBoost)
                    {
                        sprite.animation.play("su_berry");
                    }
                    else
                    {
                        sprite.animation.play("su");
                    }
                case FlxObject.DOWN:
                    if (speedBoost)
                    {
                        sprite.animation.play("sd_berry");
                    }
                    else
                    {
                        sprite.animation.play("sd");
                    }
            }
        }

        if (sprite.animation.finished)
        {
            inCancellableAnimation = true;
        }

        super.update(elapsed);
    }

    function updateCallCircle()
    {
        if (isCalling)
        {
            if (callCircle.alpha < 0.7)
            {
                callCircle.alpha += 0.05;
            }

            if (callRadius > MAX_CALL_RADIUS / 3 && caveArrow.alpha < 1.0)
            {
                caveArrow.alpha += 0.03;
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
            caveArrow.alpha -= 0.2;
        }

        // Center call circle on player
        callCircle.setPosition(getX() - callCircle.width/2, getY() - callCircle.height/2);

        
        // Update cave arrow pointer
        if (caveArrow.alpha > 0)
        {
            // Get nearest cave
            var cave = GameWorld.getNearestEntity(this, cast PlayState.world.getCaves());
            if (cave == null)
            {
                caveArrow.alpha = 0;
            }
            else
            {
                var distance = GameWorld.entityDistance(this, cave);
         
                // Position along circle
                var angle = GameWorld.entityAngle(this, cave);
                var circleX = getX() + Math.cos(angle) * callRadius;
                var circleY = getY() + Math.sin(angle) * callRadius;
                
                // Interpolate between position along circle and the position above the cave
                // This creates a smooth transition of position when the cave enters the call radius
                var interpolation:Float = GameWorld.map(callRadius * 7/8, callRadius * 9/8, 0.0, 1.0, distance);
                var bounded:Float = Math.min(Math.max(interpolation, 0.0), 1.0);
                
                // Interpolate between circle position and indicator over cave
                var arrowX = bounded * circleX + (1.0 - bounded) * cave.getX();
                var arrowY = bounded * circleY + (1.0 - bounded) * (cave.getY() - 16);

                // Interpolate between angle towards cave and pointing straight down at cave
                var angle = bounded * (GameWorld.toDegrees(angle) - 90);

                // Update position and angle
                caveArrow.setPosition(arrowX - caveArrow.width/2, arrowY - caveArrow.height/2);
                caveArrow.angle = angle;
            }
        }
    }

    function updateSpeedBoost(elapsed:Float)
    {
        if (speedBoost)
        {
            speedBoostTimer -= elapsed;
            if (speedBoostTimer < 0)
            {
                speedBoost = false;
            }

            sprite.alpha += alphaRate;
            if (sprite.alpha <= 0.5)
            {
                alphaRate *= -1;
            }
            else if (sprite.alpha >= 1.0)
            {
                alphaRate *= -1;
            }
        }
        else
        {
            if (sprite.alpha < 1.0)
            {
                sprite.alpha += 0.04;
            }
        }


    }

    function call():Void
    {
        if (FlxG.keys.pressed.C)
        {
            // Sound playing logic
            if (!isCalling)
            {
                PlayLogger.recordCallStart();
                var duration = callStartSound.length / 1000;
                callStartSound.fadeIn(duration, 0.0, CALL_VOLUME/2);
                callStartSound.play(true);
                callStartSound.onComplete = function () {
                    var duration = callLoopSound.length / 1000;
                    callLoopSound.fadeIn(duration, CALL_VOLUME/2, CALL_VOLUME);
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
                PlayLogger.recordCallEnd();
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
            callRadius -= CALL_GROWTH_RATE * 2;
            if (callRadius < 0)
            {
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
            dino.herdedFollower = null;
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

            if (Std.is(lastEntity, Dino))
            {
                var lastDino:Dino = cast lastEntity;
                lastDino.herdedFollower = dino;
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
            movementSpeed = SWIPE_SPEED;
        }
        else if (isCalling)
        {
            movementSpeed = CALL_SPEED;
        }
        
        if (speedBoost)
        {
            movementSpeed *= SPEED_BOOST_MULTIPLIER;    
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
                        if (speedBoost)
                        {
                            sprite.animation.play("slr_berry");
                        }
                        else
                        {
                            sprite.animation.play("slr");
                        }
                    case FlxObject.UP:
                        if (speedBoost)
                        {
                            sprite.animation.play("su_berry");
                        }
                        else
                        {
                            sprite.animation.play("su");
                        }
                    case FlxObject.DOWN:
                        if (speedBoost)
                        {
                            sprite.animation.play("sd_berry");
                        }
                        else
                        {
                            sprite.animation.play("sd");
                        }
                }
                inCancellableAnimation = true;
                var frameRate = Std.int(movementSpeed / speed * (FRAMERATE - MIN_FRAMERATE) + MIN_FRAMERATE);
                sprite.animation.curAnim.frameRate = frameRate;
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
                    if (speedBoost)
                    {
                        sprite.animation.play("lr_berry");
                    }
                    else
                    {
                        sprite.animation.play("lr");
                    }
                case FlxObject.UP:
                    if (speedBoost)
                    {
                        sprite.animation.play("u_berry");
                    }
                    else
                    {
                        sprite.animation.play("u");
                    }
                case FlxObject.DOWN:
                    if (speedBoost)
                    {
                        sprite.animation.play("d_berry");
                    }
                    else
                    {
                        sprite.animation.play("d");
                    }

            }
            inCancellableAnimation = true;
            var frameRate = Std.int(movementSpeed / speed * (FRAMERATE - MIN_FRAMERATE) + MIN_FRAMERATE);
            sprite.animation.curAnim.frameRate = frameRate;
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
                        if (speedBoost)
                        {
                            sprite.animation.play("itemlr_berry");
                        }
                        else
                        {
                            sprite.animation.play("itemlr");
                        }
                    case FlxObject.UP:
                        if (speedBoost)
                        {
                            sprite.animation.play("itemu_berry");
                        }
                        else
                        {
                            sprite.animation.play("itemu");
                        }
                    case FlxObject.DOWN:
                        if (speedBoost)
                        {
                            sprite.animation.play("itemd_berry");
                        }
                        else
                        {
                            sprite.animation.play("itemd");
                        }

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
        followers.remove(dino);
    }

    public function notifyCaveDeposit(dino:Dino, cave:Cave)
    {
        if (depositingToCave)
        { 
            // Remove entity from world
            followers.remove(dino);
            PlayState.world.collectDino(dino, cave);
            depositingToCave = false;
        }
    }

    public function notifyDeadFollower(dino:Dino)
    {
        // TODO: Scatter any following herd
        var nextDino:Dino = dino;
        while (nextDino != null)
        {
            followers.remove(nextDino);
            var next = nextDino.herdedFollower;
            nextDino.setUnherded(false);
            nextDino = next;
        }
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
                PlayLogger.recordPreySwipe(prey);
            }
            else if (entity.type == EntityPredator)
            {
                var predator:Predator = cast entity;
                predator.hitWithStick();
            }
            else if (entity.type == EntityBerryBush)
            {
                var bush:BerryBush = cast entity;
                bush.swipe();
            }
        }
    }

    public function isInRangeOfCave()
    {
        return this.inRangeOfCave;
    }

    public override function handleCaveCollision(cave:Cave)
    {
        this.cave = cave;
        depositingToCave = true;
        inRangeOfCave = true;
        PlayState.world.setRespawnCave(cave);
    }

    var runningIntoCave:Bool = false;
    var nearCaveCounter:Int = 0;
    public function handleCaveTileCollision()
    {
        runningIntoCave = true;
        nearCaveCounter++;
        if (nearCaveCounter > 3)
        {
            PlayState.world.openLevelMenu(cave);
        }
    }

    public override function handlePredatorCollision(predator:Predator)
    {
        if (predator.canEat(this))
        {
            death();
            // Unherd all dinosaurs.
            for (follower in followers)
            {
                follower.setUnherded();
            }
            followers.resize(0);
        }
    }

    public function death():Void
    {
        PlayState.world.numPlayerDeaths++;
        PlayLogger.recordPlayerDeath(this, followers.length);

        // Camera effects
        var camera = FlxG.camera;

        var baseLerp = camera.followLerp;
        camera.followLerp = 0.08;
        new FlxTimer().start(1.5, function (timer) {
            camera.followLerp = baseLerp;
        }, 1);
        var color = 0x88000000;
        camera.shake(0.01, 0.3);
        camera.fade(color, 0.16, false, function() {
            camera.fade(color, 0.16, true);
        });
        
        killedSound.play();

        if (numLives == 0) 
        {
            // TODO - GAME OVER STATE
        }
        else
        {
            decrementLives();
            respawn();
        }
    }

    public function respawn()
    {
       // Move player to nearest cave.
        var respawnCave = PlayState.world.getRespawnCave();
        this.setPosition(respawnCave.getX(), respawnCave.getY());
        
        triggerSpeedBoost();
        
        think(getLives() + " x <3", 2.0);
        
        PlayLogger.recordPlayerLives(numLives);
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
        if (speedBoost)
        {
            return this.speed * SPEED_BOOST_MULTIPLIER;
        }
        return this.speed;
    }

    // Return whether the player is calling.
    public function isPlayerCalling():Bool
    {
        return isCalling;
    }

    public function getCallRadius():Float
    {
        return callRadius;
    }

    public function triggerSpeedBoost()
    {
        speedBoost = true;
        speedBoostTimer += SPEED_BOOST_DURATION;
        berrySound.play();
    }

    public function setLives(amount:Int):Void
    {
        numLives = amount;
    }

    public function incrementLives(amount:Int=1):Void
    {
        numLives += amount;
    }

    public function decrementLives(amount:Int=1):Void
    {
        numLives -= amount;
    }

    public function getLives():Int
    {
        return numLives;
    }
}
