SELECT P1.uid,
       P1.qid AS level,
       (P2.log_q_ts - P1.log_q_ts) AS time,
       P1.q_detail,
       P2.q_detail
  FROM player_quests_log AS P1,
       player_quests_log AS P2
 WHERE P1.uid = P2.uid
   AND P1.sessionid = P2.sessionid
   AND P1.qid = P2.qid
   AND P1.q_s_id = 1
   AND P2.q_s_id = 0
   AND P1.cid = 2
   AND (P2.log_q_ts - P1.log_q_ts) > 3
 ORDER BY P1.log_q_ts DESC;
