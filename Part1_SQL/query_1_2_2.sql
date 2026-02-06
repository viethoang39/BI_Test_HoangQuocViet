select  
  phone_model,
  avg(nps_score) AS score_avg,
  dense_rank() over (order by avg(nps_score) asc) as rank
from workspace.bi.nps_survey
where nps_score is not null
group by 1
qualify rank <=3