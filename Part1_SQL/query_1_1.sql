with _temp as (
SELECT
    lower(regexp_replace(nps_comment, '(?i)\\b(ko|khong co|khong|kh|khong|khum|k|hông|khôg|hong|kg|khôbg|hôg|kjoong|ki)\\b', 'không')) as step1,
    regexp_replace(step1, '(?i)\\b(tot)\\b', 'tốt') AS nps_comment
FROM workspace.bi.nps_survey
)
select 
    nps_comment,
    ai_analyze_sentiment(nps_comment) as sentiment
from _temp