-- Return statistics about play time on a per-level basis.
SELECT level,
       MIN(time) AS minTime,
       MAX(time) AS maxTime,
       AVG(time) AS avgTime
  FROM (SELECT P1.qid AS level,
               (P2.log_q_ts - P1.log_q_ts) AS time
          FROM player_quests_log AS P1,
               player_quests_log AS P2
         WHERE P1.uid = P2.uid
           AND P1.sessionid = P2.sessionid
           AND P1.qid = P2.qid
           AND P1.q_s_id = 1
           AND P2.q_s_id = 0
           AND P1.cid = 2
           AND (P2.log_q_ts - P1.log_q_ts) > 0.5
         ORDER BY P1.log_q_ts DESC) AS t
 GROUP BY level
 ORDER BY level ASC;
