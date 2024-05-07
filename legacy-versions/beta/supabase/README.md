# Pal Backend (Supabase)

```
supabase link --project-ref XXX
supabase secrets set --env-file ./supabase/.env
supabase functions deploy store-user-avatar
supabase functions deploy new-wallet-linking-nonce
supabase functions deploy link-wallet-to-user
supabase functions deploy track-contract-events
supabase db dump -f supabase/seed.sql
```

```sql
select * from cron.job;
```

```sql
select * from cron.job_run_details;
```

```sql
select
  cron.schedule(
    'track-creator-key-events',
    '*/10 * * * *',
    $$
    select net.http_post(
        'https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/track-contract-events',
        body := '{"contractType":0}'::JSONB,
        headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc"}'::JSONB
    ) AS request_id;
    $$
  );

select
  cron.schedule(
    'track-group-key-events',
    '1,11,21,31,41,51 * * * *',
    $$
    select net.http_post(
        'https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/track-contract-events',
        body := '{"contractType":1}'::JSONB,
        headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc"}'::JSONB
    ) AS request_id;
    $$
  );

select
  cron.schedule(
    'track-hashtag-key-events',
    '2,12,22,32,42,52 * * * *',
    $$
    select net.http_post(
        'https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/track-contract-events',
        body := '{"contractType":2}'::JSONB,
        headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc"}'::JSONB
    ) AS request_id;
    $$
  );
```
