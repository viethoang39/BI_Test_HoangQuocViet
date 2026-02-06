select 
  case
    when phone_model like 'iPhone%' then 'iPhone'
    when phone_model like 'SM%' then 'Samsung'
    when phone_model like 'CPH%' then 'Oppo'
    else 'Other'
  end as phone_brand, 
  percentile_approx(nps_score, 0.25) AS Q1,
  median(nps_score) AS score_median,
  percentile_approx(nps_score, 0.75) AS Q3,
  avg(nps_score) AS score_avg,
  mode(nps_score) AS score_mode,
  stddev(nps_score) AS score_std,
  count(1) AS count_nps_cmt,
  count(distinct phone_model) as count_phone_model
from workspace.bi.nps_survey
where nps_score is not null
group by 1