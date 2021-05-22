package;

import entities.*;
import js.html.Console;
import flixel.util.FlxTimer;

class PlayLogger
{
    // Logging variables
    static final GAME_ID = 202107;
    static final GAME_KEY = "4fc8038359b26ec7a1044c1c6bc85745";
    static final GAME_NAME = "dinosaurherd";
 
    static final HEARTBEAT_TIME = 4.0;

    static final DEBUG_VERSION = 1;
    static final MAY_11_VERSION = 2;
    static final MAY_16_VERSION = 3;

    static final GAME_VERSION = DEBUG_VERSION;

    static var logger = new CapstoneLogger(GAME_ID, GAME_NAME, GAME_KEY, GAME_VERSION);
    static var createdLoggerSession = false;

    // Constant IDs for logged actions
    static final PLAYER_DEATH_ACTION = 1;
    static final PLAYER_CALL_ACTION  = 2;
    static final PLAYER_SKIPPED_LEVEL = 3;
    static final HEARTBEAT = 4;
    static final PREY_UNHERDED = 5;
    static final PREY_HERDED = 6;
    static final NO_PREY_HERDED = 7;
    static final PREY_DEATH = 8;
    static final BERRY_COLLECT = 9;
    static final PREDATOR_SWIPE = 10;
    static final CAVE_DEPOSIT = 11;
    static final PREY_SWIPE = 12;
<<<<<<< HEAD
    static final PLAYER_LIVES = 13;
    static final PLAYER_LOCATION = 14;
=======
    static final GAME_OVER = 13;
    static final GAME_OVER_TRY_AGAIN = 14;
>>>>>>> 1aee6d20f90d66f76259344f1186384a0653795b

    // Reset each level
    static var logTimer: Float = 0.0;
    static var playerDeaths: Int = 0;

    static var lastTimestamp:Float;
    static var averageFramerate:Float = 0.0;
    static var averageFramerateCount:Int = 0;

    static final UNHERDED_PREY_TIMER_DEFAULT = 0.5;
    static var unherdedPreyTimer:Float = UNHERDED_PREY_TIMER_DEFAULT;
    static var unherdedPrey:Int = 0;
    static var unherdedDistanceAverage:Float = 0.0;

    static final CAVE_DEPOSIT_TIMER_DEFAULT:Float = 2.0;
    static var caveDepositTimer:Float = CAVE_DEPOSIT_TIMER_DEFAULT;
    static var caveDepositCount:Int = 0;

    // Time until next heartbeat, in seconds
    static var heartbeatTimer:Float = 0.0;

    static final HERDED_PREY_TIMER = 8.0;
    static var herdedPreyTimer:Float = HERDED_PREY_TIMER;

    static var callStartTimestamp:Float;

    static final PLAYER_LOCATION_TIMER_DEFAULT:Float = 1.0;
    static var playerLocationTimer = PLAYER_LOCATION_TIMER_DEFAULT;
    static var playerX:Float = 0;
    static var playerY:Float = 0;

    public static function initializeLogger()
    {
        if (!createdLoggerSession)
        {
            // Get user id
            var userId = logger.getSavedUserId();
            if (userId == null)
            {
                // Generate new user id
                userId = logger.generateUuid();
                logger.setSavedUserId(userId);
            }

            // Start a new logging session.
            // Only start the game once the callback has been called.
            logger.startNewSession(userId, logNewSessionCallback);
        }
    }

    static function logNewSessionCallback(initialized: Bool)
    {
        if (initialized)
        {
            Console.log("Logger session initialized succesfully.");
        }
        else
        {
            Console.log("Logger session failed to initialize.");
        }
        createdLoggerSession = true;

        lastTimestamp = haxe.Timer.stamp();
    }

    public static function loggerInitialized()
    {
        return createdLoggerSession;
    }
    
    public static function update()
    {
        if (createdLoggerSession)
        {
            var timestamp = haxe.Timer.stamp();
            var timestep = timestamp - lastTimestamp;
            lastTimestamp = timestamp;
            
            averageFramerate += timestep;
            averageFramerateCount++;

            /* HEARTBEAT LOGGING */
            heartbeatTimer -= timestep;
            if (heartbeatTimer <= 0)
            {
                var framerate = averageFramerate / averageFramerateCount;
                averageFramerate = averageFramerateCount = 0;
                var details = {fps: Std.int(1 / framerate)};
                heartbeatTimer = HEARTBEAT_TIME;
            }
            
            /* UNHERDED PREY LOGGING */
            if (unherdedPrey > 0)
            {
                unherdedPreyTimer -= timestep;
                if (unherdedPreyTimer <= 0)
                {
                    var details = {unherded: unherdedPrey, distance:unherdedDistanceAverage / unherdedPrey};
                    logger.logLevelAction(PREY_UNHERDED, details);
                 
                    unherdedPrey = 0;
                    unherdedDistanceAverage = 0.0;
                    unherdedPreyTimer = UNHERDED_PREY_TIMER_DEFAULT;
                }
            }

            /* CAVE DEPOSIT LOGGINT */
            if (caveDepositCount > 0)
            {
                caveDepositTimer -= timestep;
                if (caveDepositTimer <= 0)
                {
                    var details = {caveDepositCount:caveDepositCount}
                    logger.logLevelAction(CAVE_DEPOSIT, details);

                    caveDepositCount = 0;
                    caveDepositTimer = CAVE_DEPOSIT_TIMER_DEFAULT;
                }

            }

            /* HERDED PREY LOGGING */
            herdedPreyTimer -= timestep;
            if (herdedPreyTimer <= 0)
            {
                herdedPreyTimer = HERDED_PREY_TIMER;

                var details = {};
                logger.logLevelAction(NO_PREY_HERDED, details);
            }

            /* PLAYER LOCATION LOGGING */
            playerLocationTimer -= timestep;
            if (playerLocationTimer <= 0)
            {
                var details = {playerX:playerX, playerY:playerY};
                logger.logLevelAction(PLAYER_LOCATION, details);
                playerLocationTimer = PLAYER_LOCATION_TIMER_DEFAULT;
            }
        }
    }

    public static function startLevel(levelId: Int)
    {
        // Reset logging variables
        playerDeaths = 0;
        logTimer = 0;

        var details = {score: Score.getScore()}
        logger.logLevelStart(levelId, details);
    }

    public static function endLevel()
    {
        var details = {deathCount: playerDeaths, score: Score.getScore(), time: logTimer,
                       preyCollected: PlayState.world.numPreyCollected, predCollected: PlayState.world.numPredatorsCollected,
                       preyDeaths: PlayState.world.numPreyDeaths};
        logger.logLevelEnd(details);
    }

    public static function recordPlayerDeath(player:Player, herdSizeOnDeath:Int)
    {
        playerDeaths++;
        var details = {playerX: player.getX(), playerY: player.getY(), herdSizeOnDeath:herdSizeOnDeath};
        logger.logLevelAction(PLAYER_DEATH_ACTION, details);
    }

    public static function recordPlayerSkippedLevel()
    {
        var details = {levelId: GameWorld.levelId()};
        logger.logLevelAction(PLAYER_SKIPPED_LEVEL, details);
    }

    public static function incrementTime(elapsed:Float)
    {
        logTimer += elapsed;
    }

    public static function recordUnherded(dino:Dino)
    {
        unherdedPrey++;
        unherdedDistanceAverage += GameWorld.entityDistance(dino, PlayState.world.getPlayer());
        unherdedPreyTimer = UNHERDED_PREY_TIMER_DEFAULT;
    }

    public static function recordHerded(player:Player)
    {
        var details = {numInHerd: player.followers.length};
        logger.logLevelAction(PREY_HERDED, details);

        herdedPreyTimer = HERDED_PREY_TIMER;
    }

    public static function recordPreyDeath(x:Float, y:Float, isHerded:Bool)
    {
        var details = {x:x, y:y, isHerded:isHerded};
        logger.logLevelAction(PREY_DEATH, details);
    }

    public static function recordCaveDeposit():Void
    {
        caveDepositCount++;
        caveDepositTimer = CAVE_DEPOSIT_TIMER_DEFAULT;
    }

    public static function recordCallStart()
    {
        callStartTimestamp = haxe.Timer.stamp();
    }

    public static function recordCallEnd()
    {
        var timestamp = haxe.Timer.stamp();
        var details = {time: timestamp - callStartTimestamp};
        logger.logLevelAction(PLAYER_CALL_ACTION, details);
    }

    public static function recordBerryCollect(bush:BerryBush)
    {
        var details = {x: bush.getX(), y: bush.getY()};
        logger.logLevelAction(BERRY_COLLECT, details);
    }

    public static function recordPredatorSwipe(pred:Predator)
    {
        var details = {x: pred.getX(), y: pred.getY()};
        logger.logLevelAction(PREDATOR_SWIPE, details);
    }

    public static function recordPreySwipe(prey:Prey)
    {
        var details = {x: prey.getX(), y: prey.getY()};
        logger.logLevelAction(PREY_SWIPE, details);
<<<<<<< HEAD
    }

    public static function recordPlayerLives(livesRemaining:Int):Void
    {
        var details = {livesRemaining:livesRemaining};
        logger.logLevelAction(PLAYER_LIVES, details);
        Console.log("LIVES REMAINING: " + livesRemaining);
    }

    public static function recordPlayerMovement(player:Player):Void
    {
        playerX = player.getX();
        playerY = player.getY();
=======
>>>>>>> 1aee6d20f90d66f76259344f1186384a0653795b
    }

    public static function recordGameOver()
    {
        var details = { level: GameWorld.levelId() };
        logger.logLevelAction(GAME_OVER, details);
    }

    public static function recordGameOverTryAgain()
    {
        var details = {};
        logger.logLevelAction(GAME_OVER_TRY_AGAIN, null);
    }
}
