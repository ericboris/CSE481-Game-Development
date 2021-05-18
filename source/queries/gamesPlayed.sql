SELECT count AS gamesPlayed,
       COUNT(count) AS times
  FROM (SELECT uid, COUNT(*) AS count
          FROM player_pageload_log
         WHERE cid = 2
         GROUP BY uid) AS t
 GROUP BY count;
