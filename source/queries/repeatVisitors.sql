SELECT uid, COUNT(*)
  FROM player_pageload_log
 WHERE cid = 2
 GROUP BY uid;
