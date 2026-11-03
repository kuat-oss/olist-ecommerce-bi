-- Some orders have more than one review and some review_ids repeat across
-- orders. Keep one review per order: the most recently answered one.
select
    review_id,
    order_id,
    review_score,
    review_comment_message is not null and trim(review_comment_message) <> '' as has_comment,
    review_creation_date        as review_created_at,
    review_answer_timestamp     as review_answered_at
from {{ source('raw', 'order_reviews') }}
qualify row_number() over (
    partition by order_id
    order by review_answer_timestamp desc, review_creation_date desc, review_id
) = 1
