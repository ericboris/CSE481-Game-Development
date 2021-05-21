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

    // Reset each level
    static var logTimer: Float = 0.0;
    static var playerDeaths: Int = 0;

    static var lastTimestamp:Float;
    static var averageFramerate:Float = 0.0;
    static var averageFramerateCount:Int = 0;

    static var unherdedPreyTimer:Float = 0.5;
    static var unherdedPrey:Int = 0;
    static var unherdedDistanceAverage:Float = 0.0;

    // Time until next heartbeat, in seconds
    static var heartbeatTimer:Float = 0.0;

    static final HERDED_PREY_TIMER = 8.0;
    static var herdedPreyTimer:Float = HERDED_PREY_TIMER;

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
                    unherdedPreyTimer = 0.5;
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
        }
    }

    public static function startLevel(levelId: Int)
    {
        // Reset logging variables
        playerDeaths = 0;
        logTimer = 0;

        var details = {score: Score.get()}
        logger.logLevelStart(levelId, details);
    }

    public static function endLevel()
    {
        var details = {deathCount: playerDeaths, score: Score.get(), time: logTimer,
                       preyCollected: PlayState.world.numPreyCollected, predCollected: PlayState.world.numPredatorsCollected,
                       preyDeaths: PlayState.world.numPreyDeaths};
        logger.logLevelEnd(details);
    }

    public static function recordPlayerDeath(player: Player)
    {
        playerDeaths++;
        var details = {playerX: player.getX(), playerY: player.getY()};
        logger.logLevelAction(PLAYER_DEATH_ACTION, details);
    }

    public static function recordPlayerCallStart(player: Player)
    {
        var details = {playerX: player.getX(), playerY: player.getY()};
        logger.logLevelAction(PLAYER_CALL_ACTION, details);
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
        unherdedPreyTimer = 0.5;
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
}
