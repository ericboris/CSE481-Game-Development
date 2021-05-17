SELECT uid, 
       sessionid, 
       MAX(qid) AS max_level 
  FROM player_quests_log 
 WHERE cid = 2 
 GROUP BY uid, 
       sessionid;
