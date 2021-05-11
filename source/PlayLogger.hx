package;

import entities.*;
import js.html.Console;

class PlayLogger
{
    // Logging variables
    static final GAME_ID = 202107;
    static final GAME_KEY = "4fc8038359b26ec7a1044c1c6bc85745";
    static final GAME_NAME = "dinosaurherd";
 
    static final DEBUG_VERSION = 1;
    static final MAY_11_VERSION = 2;

    static final GAME_VERSION = MAY_11_VERSION;    

    static var logger = new CapstoneLogger(GAME_ID, GAME_NAME, GAME_KEY, GAME_VERSION);
    static var createdLoggerSession = false;

    // Constant IDs for logged actions
    static final PLAYER_DEATH_ACTION = 1;

    // Reset each level
    static var logTimer: Float = 0.0;
    static var playerDeaths: Int = 0;

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
    }

    public static function loggerInitialized()
    {
        return createdLoggerSession;
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
        var details = {deathCount: playerDeaths, score: Score.get(), time: logTimer};
        logger.logLevelEnd(details);
    }

    public static function recordPlayerDeath(player: Player)
    {
        playerDeaths++;
        var details = {playerX: player.getX(), playerY: player.getY()}
        logger.logLevelAction(PLAYER_DEATH_ACTION, details);
    }

    public static function incrementTime(elapsed:Float)
    {
        logTimer += elapsed;
    }
}
