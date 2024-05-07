
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE SCHEMA IF NOT EXISTS "public";

ALTER SCHEMA "public" OWNER TO "pg_database_owner";

CREATE OR REPLACE FUNCTION "public"."create_creator_key"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  insert into creator_keys (
    creator_address
  ) values (
    new.wallet_address
  ) on conflict (creator_address) do nothing;
  return null;
end;$$;

ALTER FUNCTION "public"."create_creator_key"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_creator_key"(p_creator_address text) RETURNS TABLE(creator_address text, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, creator_user_id uuid, creator_wallet_address text, creator_display_name text, creator_avatar text, creator_avatar_thumb text, creator_stored_avatar text, creator_stored_avatar_thumb text, creator_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.creator_address,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS owner_user_id,
        u.wallet_address AS owner_wallet_address,
        u.display_name AS owner_display_name,
        u.avatar AS owner_avatar,
        u.avatar_thumb AS owner_avatar_thumb,
        u.stored_avatar AS owner_stored_avatar,
        u.stored_avatar_thumb AS owner_stored_avatar_thumb,
        u.x_username AS owner_x_username
    FROM 
        public.creator_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.creator_address = u.wallet_address
    WHERE 
        t.creator_address = p_creator_address;
END;
$$;

ALTER FUNCTION "public"."get_creator_key"(p_creator_address text) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_global_activities"(last_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(block_number bigint, log_index bigint, tx text, wallet_address text, key_type smallint, reference_key text, activity_name text, args text[], created_at timestamp with time zone, user_id uuid, user_wallet_address text, user_display_name text, user_avatar text, user_avatar_thumb text, user_stored_avatar text, user_stored_avatar_thumb text, user_x_username text, key_name text, key_image_thumb text, key_stored_image_thumb text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.block_number,
        a.log_index,
        a.tx,
        a.wallet_address,
        a.key_type,
        a.reference_key,
        a.activity_name,
        a.args,
        a.created_at,
        u.user_id,
        u.wallet_address as user_wallet_address,
        u.display_name as user_display_name,
        u.avatar as user_avatar,
        u.avatar_thumb as user_avatar_thumb,
        u.stored_avatar as user_stored_avatar,
        u.stored_avatar_thumb as user_stored_avatar_thumb,
        u.x_username as user_x_username,
        k.key_name,
        k.key_image_thumb,
        k.key_stored_image_thumb
    FROM 
        "public"."activities" a
    LEFT JOIN 
        "public"."users_public" u ON a.wallet_address = u.wallet_address
    LEFT JOIN 
        LATERAL (
            SELECT
                users_public.wallet_address as reference_key,
                display_name as key_name,
                avatar_thumb as key_image_thumb,
                stored_avatar_thumb as key_stored_image_thumb
            FROM public.users_public WHERE a.key_type = 0 AND users_public.wallet_address = a.reference_key
            UNION ALL
            SELECT
                group_id as reference_key,
                name as key_name,
                image_thumb as key_image_thumb,
                image_thumb as key_stored_image_thumb
            FROM public.group_keys WHERE a.key_type = 1 AND group_id = a.reference_key
            UNION ALL
            SELECT
                topic as reference_key,
                topic as key_name,
                image_thumb as key_image_thumb,
                image_thumb as key_stored_image_thumb
            FROM public.topic_keys WHERE a.key_type = 2 AND topic = a.reference_key
        ) k ON a.reference_key = k.reference_key
    WHERE
        (last_created_at IS NULL OR a.created_at < last_created_at)
    ORDER BY 
        a.created_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_global_activities"(last_created_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_group_key"(p_group_id text) RETURNS TABLE(group_id text, owner text, name text, image text, image_thumb text, metadata jsonb, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, owner_user_id uuid, owner_wallet_address text, owner_display_name text, owner_avatar text, owner_avatar_thumb text, owner_stored_avatar text, owner_stored_avatar_thumb text, owner_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.group_id,
        t.owner,
        t.name,
        t.image,
        t.image_thumb,
        t.metadata,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS owner_user_id,
        u.wallet_address AS owner_wallet_address,
        u.display_name AS owner_display_name,
        u.avatar AS owner_avatar,
        u.avatar_thumb AS owner_avatar_thumb,
        u.stored_avatar AS owner_stored_avatar,
        u.stored_avatar_thumb AS owner_stored_avatar_thumb,
        u.x_username AS owner_x_username
    FROM 
        public.group_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.owner = u.wallet_address
    WHERE 
        t.group_id = p_group_id;
END;
$$;

ALTER FUNCTION "public"."get_group_key"(p_group_id text) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_held_or_owned_creator_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(creator_address text, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, creator_user_id uuid, creator_wallet_address text, creator_display_name text, creator_avatar text, creator_avatar_thumb text, creator_stored_avatar text, creator_stored_avatar_thumb text, creator_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.creator_address,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS owner_user_id,
        u.wallet_address AS owner_wallet_address,
        u.display_name AS owner_display_name,
        u.avatar AS owner_avatar,
        u.avatar_thumb AS owner_avatar_thumb,
        u.stored_avatar AS owner_stored_avatar,
        u.stored_avatar_thumb AS owner_stored_avatar_thumb,
        u.x_username AS owner_x_username
    FROM 
        public.creator_keys t
    LEFT JOIN 
        public.creator_key_holders th ON t.creator_address = th.creator_address AND th.wallet_address = p_wallet_address
    LEFT JOIN 
        "public"."users_public" u ON t.creator_address = u.wallet_address
    WHERE 
        (t.creator_address = p_wallet_address OR th.wallet_address = p_wallet_address)
        AND (p_last_message_sent_at IS NULL OR t.last_message_sent_at < p_last_message_sent_at)
    ORDER BY 
        t.last_message_sent_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_held_or_owned_creator_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_held_or_owned_group_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(group_id text, owner text, name text, image text, image_thumb text, metadata jsonb, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, owner_user_id uuid, owner_wallet_address text, owner_display_name text, owner_avatar text, owner_avatar_thumb text, owner_stored_avatar text, owner_stored_avatar_thumb text, owner_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.group_id,
        t.owner,
        t.name,
        t.image,
        t.image_thumb,
        t.metadata,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS owner_user_id,
        u.wallet_address AS owner_wallet_address,
        u.display_name AS owner_display_name,
        u.avatar AS owner_avatar,
        u.avatar_thumb AS owner_avatar_thumb,
        u.stored_avatar AS owner_stored_avatar,
        u.stored_avatar_thumb AS owner_stored_avatar_thumb,
        u.x_username AS owner_x_username
    FROM 
        public.group_keys t
    LEFT JOIN 
        public.group_key_holders th ON t.group_id = th.group_id AND th.wallet_address = p_wallet_address
    LEFT JOIN 
        "public"."users_public" u ON t.owner = u.wallet_address
    WHERE 
        (t.owner = p_wallet_address OR th.wallet_address = p_wallet_address)
        AND (p_last_message_sent_at IS NULL OR t.last_message_sent_at < p_last_message_sent_at)
    ORDER BY 
        t.last_message_sent_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_held_or_owned_group_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_held_topic_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(topic text, image text, image_thumb text, metadata jsonb, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.topic,
        t.image,
        t.image_thumb,
        t.metadata,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at
    FROM 
        public.topic_keys t
    JOIN 
        public.topic_key_holders th ON t.topic = th.topic AND th.wallet_address = p_wallet_address
    WHERE 
        th.wallet_address = p_wallet_address
        AND (p_last_message_sent_at IS NULL OR t.last_message_sent_at < p_last_message_sent_at)
    ORDER BY 
        t.last_message_sent_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_held_topic_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_key_holders"(p_key_type smallint, p_reference_key text, last_balance numeric DEFAULT NULL::numeric, max_count integer DEFAULT 50) RETURNS TABLE(user_id uuid, wallet_address text, total_earned_trading_fees numeric, display_name text, avatar text, avatar_thumb text, avatar_stored boolean, stored_avatar text, stored_avatar_thumb text, x_username text, metadata jsonb, points integer, blocked boolean, created_at timestamp with time zone, updated_at timestamp with time zone, balance text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.user_id,
        u.wallet_address,
        u.total_earned_trading_fees,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.avatar_stored,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,
        u.metadata,
        u.points,
        u.blocked,
        u.created_at,
        u.updated_at,
        kh.last_fetched_balance::text AS balance
    FROM 
        public.users_public u
    INNER JOIN 
        LATERAL (
            SELECT * FROM public.creator_key_holders WHERE p_key_type = 0 AND creator_address = p_reference_key
            UNION ALL
            SELECT * FROM public.group_key_holders WHERE p_key_type = 1 AND group_id = p_reference_key
            UNION ALL
            SELECT * FROM public.topic_key_holders WHERE p_key_type = 2 AND topic = p_reference_key
        ) kh ON u.wallet_address = kh.wallet_address
    WHERE 
        last_balance IS NULL OR kh.last_fetched_balance > last_balance
    ORDER BY 
        kh.last_fetched_balance DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_key_holders"(p_key_type smallint, p_reference_key text, last_balance numeric, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_new_creator_keys"(last_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(creator_address text, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, creator_user_id uuid, creator_wallet_address text, creator_display_name text, creator_avatar text, creator_avatar_thumb text, creator_stored_avatar text, creator_stored_avatar_thumb text, creator_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.creator_address,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS creator_user_id,
        u.wallet_address AS creator_wallet_address,
        u.display_name AS creator_display_name,
        u.avatar AS creator_avatar,
        u.avatar_thumb AS creator_avatar_thumb,
        u.stored_avatar AS creator_stored_avatar,
        u.stored_avatar_thumb AS creator_stored_avatar_thumb,
        u.x_username AS creator_x_username
    FROM 
        public.creator_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.creator_address = u.wallet_address
    WHERE 
        (last_created_at IS NULL OR t.created_at > last_created_at)
    ORDER BY 
        t.created_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_new_creator_keys"(last_created_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_new_group_keys"(last_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(group_id text, owner text, name text, image text, image_thumb text, metadata jsonb, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, owner_user_id uuid, owner_wallet_address text, owner_display_name text, owner_avatar text, owner_avatar_thumb text, owner_stored_avatar text, owner_stored_avatar_thumb text, owner_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.group_id,
        t.owner,
        t.name,
        t.image,
        t.image_thumb,
        t.metadata,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS owner_user_id,
        u.wallet_address AS owner_wallet_address,
        u.display_name AS owner_display_name,
        u.avatar AS owner_avatar,
        u.avatar_thumb AS owner_avatar_thumb,
        u.stored_avatar AS owner_stored_avatar,
        u.stored_avatar_thumb AS owner_stored_avatar_thumb,
        u.x_username AS owner_x_username
    FROM 
        public.group_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.owner = u.wallet_address
    WHERE 
        (last_created_at IS NULL OR t.created_at > last_created_at)
    ORDER BY 
        t.created_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_new_group_keys"(last_created_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_point_rank"(p_user_id uuid) RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    user_points integer;
    rank integer;
BEGIN
    SELECT points INTO user_points FROM "public"."users_public" WHERE "user_id" = "p_user_id";
    SELECT COUNT(*) INTO rank FROM "public"."users_public" WHERE points > user_points;
    RETURN rank + 1;
END;
$$;

ALTER FUNCTION "public"."get_point_rank"(p_user_id uuid) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_target_activities"(p_key_type smallint, p_reference_key text, last_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(block_number bigint, log_index bigint, tx text, wallet_address text, key_type smallint, reference_key text, activity_name text, args text[], created_at timestamp with time zone, user_id uuid, user_wallet_address text, user_display_name text, user_avatar text, user_avatar_thumb text, user_stored_avatar text, user_stored_avatar_thumb text, user_x_username text, key_name text, key_image_thumb text, key_stored_image_thumb text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.block_number,
        a.log_index,
        a.tx,
        a.wallet_address,
        a.key_type,
        a.reference_key,
        a.activity_name,
        a.args,
        a.created_at,
        u.user_id,
        u.wallet_address as user_wallet_address,
        u.display_name as user_display_name,
        u.avatar as user_avatar,
        u.avatar_thumb as user_avatar_thumb,
        u.stored_avatar as user_stored_avatar,
        u.stored_avatar_thumb as user_stored_avatar_thumb,
        u.x_username as user_x_username,
        k.key_name,
        k.key_image_thumb,
        k.key_stored_image_thumb
    FROM 
        "public"."activities" a
    LEFT JOIN 
        "public"."users_public" u ON a.wallet_address = u.wallet_address
    INNER JOIN 
        LATERAL (
            SELECT
                users_public.wallet_address as reference_key,
                display_name as key_name,
                avatar_thumb as key_image_thumb,
                stored_avatar_thumb as key_stored_image_thumb
            FROM public.users_public WHERE p_key_type = 0 AND users_public.wallet_address = p_reference_key
            UNION ALL
            SELECT
                group_id as reference_key,
                name as key_name,
                image_thumb as key_image_thumb,
                image_thumb as key_stored_image_thumb
            FROM public.group_keys WHERE p_key_type = 1 AND group_id = p_reference_key
            UNION ALL
            SELECT
                topic as reference_key,
                topic as key_name,
                image_thumb as key_image_thumb,
                image_thumb as key_stored_image_thumb
            FROM public.topic_keys WHERE p_key_type = 2 AND topic = p_reference_key
        ) k ON a.reference_key = k.reference_key
    WHERE
        a.key_type = p_key_type AND a.reference_key = p_reference_key
        AND (last_created_at IS NULL OR a.created_at < last_created_at)
    ORDER BY 
        a.created_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_target_activities"(p_key_type smallint, p_reference_key text, last_created_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_top_creator_keys"(last_rank integer DEFAULT NULL::integer, max_count integer DEFAULT 100) RETURNS TABLE(rank integer, creator_address text, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, creator_user_id uuid, creator_wallet_address text, creator_display_name text, creator_avatar text, creator_avatar_thumb text, creator_stored_avatar text, creator_stored_avatar_thumb text, creator_x_username text)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    row_rank integer;
BEGIN
    row_rank := COALESCE(last_rank, 0);
    RETURN QUERY
    SELECT
        (row_number() OVER (ORDER BY t.last_fetched_price DESC) + row_rank)::integer AS rank,
        t.creator_address,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS creator_user_id,
        u.wallet_address AS creator_wallet_address,
        u.display_name AS creator_display_name,
        u.avatar AS creator_avatar,
        u.avatar_thumb AS creator_avatar_thumb,
        u.stored_avatar AS creator_stored_avatar,
        u.stored_avatar_thumb AS creator_stored_avatar_thumb,
        u.x_username AS creator_x_username
    FROM 
        public.creator_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.creator_address = u.wallet_address
    ORDER BY 
        t.last_fetched_price DESC
    OFFSET 
        row_rank
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_top_creator_keys"(last_rank integer, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_top_group_keys"(last_rank integer DEFAULT NULL::integer, max_count integer DEFAULT 100) RETURNS TABLE(rank integer, group_id text, owner text, name text, image text, image_thumb text, metadata jsonb, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, owner_user_id uuid, owner_wallet_address text, owner_display_name text, owner_avatar text, owner_avatar_thumb text, owner_stored_avatar text, owner_stored_avatar_thumb text, owner_x_username text)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    row_rank integer;
BEGIN
    row_rank := COALESCE(last_rank, 0);
    RETURN QUERY
    SELECT
        (row_number() OVER (ORDER BY t.last_fetched_price DESC) + row_rank)::integer AS rank,
        t.group_id,
        t.owner,
        t.name,
        t.image,
        t.image_thumb,
        t.metadata,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS owner_user_id,
        u.wallet_address AS owner_wallet_address,
        u.display_name AS owner_display_name,
        u.avatar AS owner_avatar,
        u.avatar_thumb AS owner_avatar_thumb,
        u.stored_avatar AS owner_stored_avatar,
        u.stored_avatar_thumb AS owner_stored_avatar_thumb,
        u.x_username AS owner_x_username
    FROM 
        public.group_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.owner = u.wallet_address
    ORDER BY 
        t.last_fetched_price DESC
    OFFSET 
        row_rank
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_top_group_keys"(last_rank integer, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_trending_creator_keys"(p_last_purchased_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(creator_address text, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, creator_user_id uuid, creator_wallet_address text, creator_display_name text, creator_avatar text, creator_avatar_thumb text, creator_stored_avatar text, creator_stored_avatar_thumb text, creator_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.creator_address,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS creator_user_id,
        u.wallet_address AS creator_wallet_address,
        u.display_name AS creator_display_name,
        u.avatar AS creator_avatar,
        u.avatar_thumb AS creator_avatar_thumb,
        u.stored_avatar AS creator_stored_avatar,
        u.stored_avatar_thumb AS creator_stored_avatar_thumb,
        u.x_username AS creator_x_username
    FROM 
        public.creator_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.creator_address = u.wallet_address
    WHERE 
        (p_last_purchased_at IS NULL OR t.last_purchased_at > p_last_purchased_at)
    ORDER BY 
        t.last_purchased_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_trending_creator_keys"(p_last_purchased_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_trending_group_keys"(p_last_purchased_at timestamp with time zone DEFAULT NULL::timestamp with time zone, max_count integer DEFAULT 100) RETURNS TABLE(group_id text, owner text, name text, image text, image_thumb text, metadata jsonb, supply text, last_fetched_price text, total_trading_volume text, is_price_up boolean, last_message text, last_message_sent_at timestamp with time zone, holder_count integer, last_purchased_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, owner_user_id uuid, owner_wallet_address text, owner_display_name text, owner_avatar text, owner_avatar_thumb text, owner_stored_avatar text, owner_stored_avatar_thumb text, owner_x_username text)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.group_id,
        t.owner,
        t.name,
        t.image,
        t.image_thumb,
        t.metadata,
        t.supply::text,
        t.last_fetched_price::text,
        t.total_trading_volume::text,
        t.is_price_up,
        t.last_message,
        t.last_message_sent_at,
        t.holder_count,
        t.last_purchased_at,
        t.created_at,
        t.updated_at,
        u.user_id AS owner_user_id,
        u.wallet_address AS owner_wallet_address,
        u.display_name AS owner_display_name,
        u.avatar AS owner_avatar,
        u.avatar_thumb AS owner_avatar_thumb,
        u.stored_avatar AS owner_stored_avatar,
        u.stored_avatar_thumb AS owner_stored_avatar_thumb,
        u.x_username AS owner_x_username
    FROM 
        public.group_keys t
    LEFT JOIN 
        "public"."users_public" u ON t.owner = u.wallet_address
    WHERE 
        (p_last_purchased_at IS NULL OR t.last_purchased_at > p_last_purchased_at)
    ORDER BY 
        t.last_purchased_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_trending_group_keys"(p_last_purchased_at timestamp with time zone, max_count integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."parse_contract_event"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
    v_receiver UUID;
    v_triggerer UUID;
    owner_data RECORD;
BEGIN
    IF new.event_name = 'GroupCreated' AND new.key_type = 1 THEN
        
        -- add activity
        insert into activities (
            block_number, log_index, tx, wallet_address, key_type, reference_key, activity_name, args
        ) values (
            new.block_number, new.log_index, new.tx, new.args[2], new.key_type, new.reference_key, new.event_name, new.args
        );

        -- add key info
        insert into group_keys (
            group_id, owner
        ) values (
            new.reference_key, new.args[2]
        );

        -- add key holder info
        insert into group_key_holders (
            group_id, wallet_address, last_fetched_balance
        ) values (
            new.reference_key, new.args[2], 1
        );
        
        -- update wallet's total key balance
        insert into user_wallets (
            wallet_address, total_key_balance
        ) values (
            new.args[2], 1
        ) on conflict (wallet_address) do update
            set total_key_balance = user_wallets.total_key_balance + 1;

        -- notify
        v_receiver := (SELECT user_id FROM users_public WHERE wallet_address = new.args[1]);
        IF v_receiver IS NOT NULL THEN
            insert into notifications (
                user_id, type, key_type, reference_key
            ) values (
                v_receiver, 0, new.key_type, new.reference_key
            );
        END IF;

    ELSIF new.event_name = 'Trade' AND (
        new.key_type = 0 OR new.key_type = 1 OR new.key_type = 2
    ) THEN

        -- add activity
        insert into activities (
            block_number, log_index, tx, wallet_address, key_type, reference_key, activity_name, args
        ) values (
            new.block_number, new.log_index, new.tx, new.args[1], new.key_type, new.reference_key, new.event_name, new.args
        );

        -- notify
        IF new.key_type = 0 THEN
            --TODO:
        ELSIF new.key_type = 1 THEN
            v_receiver := (SELECT user_id FROM users_public WHERE wallet_address = (
                SELECT owner FROM group_keys WHERE group_id = new.reference_key
            ));
        ELSIF new.key_type = 2 THEN
            --TODO:
        END IF;

        v_triggerer := (SELECT user_id FROM users_public WHERE wallet_address = new.args[1]);
        IF v_receiver IS NOT NULL AND v_receiver != v_triggerer THEN
            insert into notifications (
                user_id, triggerer, type, key_type, reference_key, amount
            ) values (
                v_receiver, v_triggerer, CASE WHEN new.args[3] = 'true' THEN 1 ELSE 2 END, new.key_type, new.reference_key, new.args[4]::numeric
            );
        END IF;

        -- buy
        IF new.args[3] = 'true' THEN

            IF new.key_type = 0 THEN
                
                -- update key info
                insert into creator_keys (
                    creator_address, supply, last_fetched_price, total_trading_volume, is_price_up, last_purchased_at
                ) values (
                    new.reference_key, new.args[8]::numeric, new.args[5]::numeric, new.args[5]::numeric, true, now()
                ) on conflict (creator_address) do update
                    set supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = creator_keys.total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now();

                -- update key holder info
                insert into creator_key_holders (
                    creator_address, wallet_address, last_fetched_balance
                ) values (
                    new.reference_key, new.args[1], new.args[4]::numeric
                ) on conflict (creator_address, wallet_address) do update
                    set last_fetched_balance = creator_key_holders.last_fetched_balance + new.args[4]::numeric;
                
                -- if key holder is new, add to key holder count
                IF NOT FOUND THEN
                    update creator_keys set
                        holder_count = holder_count + 1
                    where creator_address = new.reference_key;
                END IF;
                
            ELSIF new.key_type = 1 THEN
                
                -- update key info
                update group_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = group_keys.total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now()
                where group_id = new.reference_key;

                -- update key holder info
                insert into group_key_holders (
                    group_id, wallet_address, last_fetched_balance
                ) values (
                    new.reference_key, new.args[1], new.args[4]::numeric
                ) on conflict (group_id, wallet_address) do update
                    set last_fetched_balance = group_key_holders.last_fetched_balance + new.args[4]::numeric;
                
                -- if key holder is new, add to key holder count
                IF NOT FOUND THEN
                    update group_keys set
                        holder_count = holder_count + 1
                    where group_id = new.reference_key;
                END IF;
            
            ELSIF new.key_type = 2 THEN
                
                -- update key info
                insert into topic_keys (
                    topic, supply, last_fetched_price, total_trading_volume, is_price_up, last_purchased_at
                ) values (
                    new.reference_key, new.args[8]::numeric, new.args[5]::numeric, new.args[5]::numeric, true, now()
                ) on conflict (topic) do update
                    set supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = topic_keys.total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now();

                -- update key holder info
                insert into topic_key_holders (
                    topic, wallet_address, last_fetched_balance
                ) values (
                    new.reference_key, new.args[1], new.args[4]::numeric
                ) on conflict (topic, wallet_address) do update
                    set last_fetched_balance = topic_key_holders.last_fetched_balance + new.args[4]::numeric;
                
                -- if key holder is new, add to key holder count
                IF NOT FOUND THEN
                    update topic_keys set
                        holder_count = holder_count + 1
                    where topic = new.reference_key;
                END IF;
                
            END IF;
            
            -- update wallet's total key balance
            insert into user_wallets (
                wallet_address, total_key_balance
            ) values (
                new.args[1], new.args[4]::numeric
            ) on conflict (wallet_address) do update
                set total_key_balance = user_wallets.total_key_balance + new.args[4]::numeric;

        -- sell
        ELSE

            IF new.key_type = 0 THEN
                
                -- update key info
                update creator_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = creator_keys.total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where creator_address = new.reference_key;

                -- update key holder info
                WITH updated AS (
                    UPDATE creator_key_holders
                    SET last_fetched_balance = last_fetched_balance - new.args[4]::numeric
                    WHERE creator_address = new.reference_key
                    AND wallet_address = new.args[1]
                    RETURNING wallet_address, last_fetched_balance
                )
                DELETE FROM creator_key_holders
                WHERE (wallet_address, last_fetched_balance) IN (
                    SELECT wallet_address, last_fetched_balance FROM updated WHERE last_fetched_balance = 0
                );

                -- if key holder is gone, subtract from key holder count
                IF FOUND THEN
                    update creator_keys set
                        holder_count = holder_count - 1
                    where creator_address = new.reference_key;
                END IF;

            ELSIF new.key_type = 1 THEN
                
                -- update key info
                update group_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = group_keys.total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where group_id = new.reference_key;

                -- update key holder info
                WITH updated AS (
                    UPDATE group_key_holders
                    SET last_fetched_balance = last_fetched_balance - new.args[4]::numeric
                    WHERE group_id = new.reference_key
                    AND wallet_address = new.args[1]
                    RETURNING wallet_address, last_fetched_balance
                )
                DELETE FROM group_key_holders
                WHERE (wallet_address, last_fetched_balance) IN (
                    SELECT wallet_address, last_fetched_balance FROM updated WHERE last_fetched_balance = 0
                );

                -- if key holder is gone, subtract from key holder count
                IF FOUND THEN
                    update group_keys set
                        holder_count = holder_count - 1
                    where group_id = new.reference_key;
                END IF;
            
            ELSIF new.key_type = 2 THEN
                
                -- update key info
                update topic_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = topic_keys.total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where topic = new.reference_key;

                -- update key holder info
                WITH updated AS (
                    UPDATE topic_key_holders
                    SET last_fetched_balance = last_fetched_balance - new.args[4]::numeric
                    WHERE topic = new.reference_key
                    AND wallet_address = new.args[1]
                    RETURNING wallet_address, last_fetched_balance
                )
                DELETE FROM topic_key_holders
                WHERE (wallet_address, last_fetched_balance) IN (
                    SELECT wallet_address, last_fetched_balance FROM updated WHERE last_fetched_balance = 0
                );

                -- if key holder is gone, subtract from key holder count
                IF FOUND THEN
                    update topic_keys set
                        holder_count = holder_count - 1
                    where topic = new.reference_key;
                END IF;
                
            END IF;
            
            -- update wallet's total key balance
            update user_wallets set
                total_key_balance = total_key_balance - new.args[4]::numeric
            where wallet_address = new.args[1];
        END IF;
    END IF;
    RETURN NULL;
end;$$;

ALTER FUNCTION "public"."parse_contract_event"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_creator_key_last_message"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update creator_keys
    set
        last_message = (SELECT display_name FROM public.users_public WHERE user_id = new.author) || ': ' || new.message,
        last_message_sent_at = now()
    where
        creator_address = new.creator_address;
  return null;
end;$$;

ALTER FUNCTION "public"."set_creator_key_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_group_key_last_message"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update group_keys
    set
        last_message = (SELECT display_name FROM public.users_public WHERE user_id = new.author) || ': ' || new.message,
        last_message_sent_at = now()
    where
        group_id = new.group_id;
  return null;
end;$$;

ALTER FUNCTION "public"."set_group_key_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_topic_key_last_message"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  insert into topic_keys (
    topic,
    last_message,
    last_message_sent_at
  ) values (
    new.topic,
    (SELECT display_name FROM public.users_public WHERE user_id = new.author) || ': ' || new.message,
    now()
  ) on conflict (topic) do update
    set
        last_message = (SELECT display_name FROM public.users_public WHERE user_id = new.author) || ': ' || new.message,
        last_message_sent_at = now();
  return null;
end;$$;

ALTER FUNCTION "public"."set_topic_key_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  new.updated_at := now();
  RETURN new;
END;$$;

ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_user_metadata_to_public"() RETURNS trigger
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if strpos(new.raw_user_meta_data ->> 'iss', 'twitter') > 0 then
    insert into public.users_public (user_id, display_name, avatar, avatar_thumb, avatar_stored, x_username)
    values (
      new.id,
      new.raw_user_meta_data ->> 'full_name',
      case 
        when strpos(new.raw_user_meta_data ->> 'avatar_url', '_normal') > 0 then
          replace(new.raw_user_meta_data ->> 'avatar_url', '_normal', '')
        else
          new.raw_user_meta_data ->> 'avatar_url'
      end,
      new.raw_user_meta_data ->> 'avatar_url',
      false,
      new.raw_user_meta_data ->> 'user_name'
    ) on conflict (user_id) do update
    set
      display_name = new.raw_user_meta_data ->> 'full_name',
      avatar = case 
        when strpos(new.raw_user_meta_data ->> 'avatar_url', '_normal') > 0 then
          replace(new.raw_user_meta_data ->> 'avatar_url', '_normal', '')
        else
          new.raw_user_meta_data ->> 'avatar_url'
      end,
      avatar_thumb = new.raw_user_meta_data ->> 'avatar_url',
      avatar_stored = false,
      x_username = new.raw_user_meta_data ->> 'user_name';
  else
    insert into public.users_public (user_id, display_name, avatar, avatar_thumb, avatar_stored)
    values (
      new.id,
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'avatar_url',
      false
    ) on conflict (user_id) do update
    set
      display_name = new.raw_user_meta_data ->> 'full_name',
      avatar = new.raw_user_meta_data ->> 'avatar_url',
      avatar_thumb = new.raw_user_meta_data ->> 'avatar_url',
      avatar_stored = false;
  end if;
  return new;
end;
$$;

ALTER FUNCTION "public"."set_user_metadata_to_public"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."activities" (
    "block_number" bigint NOT NULL,
    "log_index" bigint NOT NULL,
    "tx" text NOT NULL,
    "wallet_address" text NOT NULL,
    "key_type" smallint,
    "reference_key" text,
    "activity_name" text NOT NULL,
    "args" text[],
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."activities" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."contract_events" (
    "block_number" bigint NOT NULL,
    "log_index" bigint NOT NULL,
    "event_name" text NOT NULL,
    "args" text[] DEFAULT '{}'::text[] NOT NULL,
    "wallet_address" text,
    "key_type" smallint,
    "reference_key" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "tx" text NOT NULL
);

ALTER TABLE "public"."contract_events" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."creator_chat_messages" (
    "id" bigint NOT NULL,
    "creator_address" text NOT NULL,
    "author" uuid DEFAULT auth.uid(),
    "message" text,
    "translated" jsonb,
    "rich" jsonb,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."creator_chat_messages" OWNER TO "postgres";

ALTER TABLE "public"."creator_chat_messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."creator_chat_messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."creator_key_holders" (
    "creator_address" text NOT NULL,
    "wallet_address" text NOT NULL,
    "last_fetched_balance" numeric DEFAULT '0'::numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."creator_key_holders" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."creator_keys" (
    "creator_address" text NOT NULL,
    "supply" numeric DEFAULT '0'::numeric NOT NULL,
    "last_fetched_price" numeric DEFAULT '1000000000000000000'::numeric NOT NULL,
    "total_trading_volume" numeric DEFAULT '0'::numeric NOT NULL,
    "is_price_up" boolean,
    "last_message" text,
    "last_message_sent_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "holder_count" integer DEFAULT 0 NOT NULL,
    "last_purchased_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."creator_keys" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."group_chat_messages" (
    "id" bigint NOT NULL,
    "group_id" text NOT NULL,
    "author" uuid DEFAULT auth.uid(),
    "message" text,
    "translated" jsonb,
    "rich" jsonb,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."group_chat_messages" OWNER TO "postgres";

ALTER TABLE "public"."group_chat_messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."group_chat_messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."group_key_holders" (
    "group_id" text NOT NULL,
    "wallet_address" text NOT NULL,
    "last_fetched_balance" numeric DEFAULT '0'::numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."group_key_holders" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."group_keys" (
    "group_id" text NOT NULL,
    "owner" text NOT NULL,
    "name" text,
    "image" text,
    "image_thumb" text,
    "metadata" jsonb,
    "supply" numeric DEFAULT '0'::numeric NOT NULL,
    "last_fetched_price" numeric DEFAULT '1000000000000000000'::numeric NOT NULL,
    "total_trading_volume" numeric DEFAULT '0'::numeric NOT NULL,
    "is_price_up" boolean,
    "last_message" text,
    "last_message_sent_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "holder_count" integer DEFAULT 1 NOT NULL,
    "last_purchased_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."group_keys" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" bigint NOT NULL,
    "user_id" uuid NOT NULL,
    "triggerer" uuid,
    "type" smallint NOT NULL,
    "key_type" smallint,
    "reference_key" text,
    "amount" bigint,
    "read" boolean DEFAULT false NOT NULL,
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."notifications" OWNER TO "postgres";

ALTER TABLE "public"."notifications" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."notifications_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."topic_chat_messages" (
    "id" bigint NOT NULL,
    "source" text NOT NULL,
    "topic" text NOT NULL,
    "author" uuid DEFAULT auth.uid(),
    "external_author_id" text,
    "external_author_name" text,
    "external_author_avatar" text,
    "message" text,
    "external_message_id" text,
    "translated" jsonb,
    "rich" jsonb,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."topic_chat_messages" OWNER TO "postgres";

ALTER TABLE "public"."topic_chat_messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."topic_chat_messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."topic_key_holders" (
    "topic" text NOT NULL,
    "wallet_address" text NOT NULL,
    "last_fetched_balance" numeric DEFAULT '0'::numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."topic_key_holders" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."topic_keys" (
    "topic" text NOT NULL,
    "image" text,
    "image_thumb" text,
    "metadata" jsonb,
    "supply" numeric DEFAULT '0'::numeric NOT NULL,
    "last_fetched_price" numeric DEFAULT '1000000000000000000'::numeric NOT NULL,
    "total_trading_volume" numeric DEFAULT '0'::numeric NOT NULL,
    "is_price_up" boolean,
    "last_message" text,
    "last_message_sent_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "holder_count" integer DEFAULT 0 NOT NULL,
    "last_purchased_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."topic_keys" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."tracked_event_blocks" (
    "contract_type" smallint NOT NULL,
    "block_number" bigint NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."tracked_event_blocks" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."user_wallets" (
    "wallet_address" text NOT NULL,
    "total_key_balance" numeric DEFAULT '0'::numeric NOT NULL,
    "total_earned_trading_fees" numeric DEFAULT '0'::numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."user_wallets" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."users_public" (
    "user_id" uuid DEFAULT auth.uid() NOT NULL,
    "wallet_address" text,
    "total_earned_trading_fees" numeric DEFAULT '0'::numeric NOT NULL,
    "display_name" text,
    "avatar" text,
    "avatar_thumb" text,
    "avatar_stored" boolean DEFAULT false NOT NULL,
    "stored_avatar" text,
    "stored_avatar_thumb" text,
    "x_username" text,
    "metadata" jsonb,
    "points" integer DEFAULT 0 NOT NULL,
    "blocked" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."users_public" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."wallet_linking_nonces" (
    "user_id" uuid DEFAULT auth.uid() NOT NULL,
    "wallet_address" text NOT NULL,
    "nonce" uuid DEFAULT gen_random_uuid() NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."wallet_linking_nonces" OWNER TO "postgres";

ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_pkey" PRIMARY KEY ("block_number", "log_index");

ALTER TABLE ONLY "public"."contract_events"
    ADD CONSTRAINT "contract_events_pkey" PRIMARY KEY ("block_number", "log_index");

ALTER TABLE ONLY "public"."creator_chat_messages"
    ADD CONSTRAINT "creator_chat_messages_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."creator_key_holders"
    ADD CONSTRAINT "creator_key_holders_pkey" PRIMARY KEY ("creator_address", "wallet_address");

ALTER TABLE ONLY "public"."creator_keys"
    ADD CONSTRAINT "creator_keys_pkey" PRIMARY KEY ("creator_address");

ALTER TABLE ONLY "public"."group_chat_messages"
    ADD CONSTRAINT "group_chat_messages_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."group_key_holders"
    ADD CONSTRAINT "group_key_holders_pkey" PRIMARY KEY ("group_id", "wallet_address");

ALTER TABLE ONLY "public"."group_keys"
    ADD CONSTRAINT "group_keys_pkey" PRIMARY KEY ("group_id");

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."topic_chat_messages"
    ADD CONSTRAINT "topic_chat_messages_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."topic_key_holders"
    ADD CONSTRAINT "topic_key_holders_pkey" PRIMARY KEY ("topic", "wallet_address");

ALTER TABLE ONLY "public"."topic_keys"
    ADD CONSTRAINT "topic_keys_pkey" PRIMARY KEY ("topic");

ALTER TABLE ONLY "public"."tracked_event_blocks"
    ADD CONSTRAINT "tracked_event_blocks_pkey" PRIMARY KEY ("contract_type");

ALTER TABLE ONLY "public"."user_wallets"
    ADD CONSTRAINT "user_wallets_pkey" PRIMARY KEY ("wallet_address");

ALTER TABLE ONLY "public"."users_public"
    ADD CONSTRAINT "users_public_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."users_public"
    ADD CONSTRAINT "users_public_wallet_address_key" UNIQUE ("wallet_address");

ALTER TABLE ONLY "public"."wallet_linking_nonces"
    ADD CONSTRAINT "wallet_linking_nonces_pkey" PRIMARY KEY ("user_id");

CREATE TRIGGER create_creator_key AFTER UPDATE ON public.users_public FOR EACH ROW EXECUTE FUNCTION public.create_creator_key();

CREATE TRIGGER parse_contract_event AFTER INSERT ON public.contract_events FOR EACH ROW EXECUTE FUNCTION public.parse_contract_event();

CREATE TRIGGER set_creator_key_holders_updated_at BEFORE UPDATE ON public.creator_key_holders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_creator_key_last_message AFTER INSERT ON public.creator_chat_messages FOR EACH ROW EXECUTE FUNCTION public.set_creator_key_last_message();

CREATE TRIGGER set_creator_keys_updated_at BEFORE UPDATE ON public.creator_keys FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_group_key_holders_updated_at BEFORE UPDATE ON public.group_key_holders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_group_key_last_message AFTER INSERT ON public.group_chat_messages FOR EACH ROW EXECUTE FUNCTION public.set_group_key_last_message();

CREATE TRIGGER set_group_keys_updated_at BEFORE UPDATE ON public.group_keys FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_topic_key_holders_updated_at BEFORE UPDATE ON public.topic_key_holders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_topic_key_last_message AFTER INSERT ON public.topic_chat_messages FOR EACH ROW EXECUTE FUNCTION public.set_topic_key_last_message();

CREATE TRIGGER set_topic_keys_updated_at BEFORE UPDATE ON public.topic_keys FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_tracked_event_blocks_updated_at BEFORE UPDATE ON public.tracked_event_blocks FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_user_wallets_updated_at BEFORE UPDATE ON public.user_wallets FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_users_public_updated_at BEFORE UPDATE ON public.users_public FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE ONLY "public"."creator_chat_messages"
    ADD CONSTRAINT "creator_chat_messages_author_fkey" FOREIGN KEY (author) REFERENCES public.users_public(user_id);

ALTER TABLE ONLY "public"."group_chat_messages"
    ADD CONSTRAINT "group_chat_messages_author_fkey" FOREIGN KEY (author) REFERENCES public.users_public(user_id);

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_triggerer_fkey" FOREIGN KEY (triggerer) REFERENCES public.users_public(user_id);

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users_public(user_id);

ALTER TABLE ONLY "public"."topic_chat_messages"
    ADD CONSTRAINT "topic_chat_messages_author_fkey" FOREIGN KEY (author) REFERENCES public.users_public(user_id);

ALTER TABLE ONLY "public"."users_public"
    ADD CONSTRAINT "users_public_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id);

ALTER TABLE ONLY "public"."wallet_linking_nonces"
    ADD CONSTRAINT "wallet_linking_nonces_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users_public(user_id);

ALTER TABLE "public"."activities" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "can update only owner" ON "public"."group_keys" FOR UPDATE TO authenticated USING ((owner = ( SELECT users_public.wallet_address
   FROM public.users_public
  WHERE (users_public.user_id = auth.uid())))) WITH CHECK ((owner = ( SELECT users_public.wallet_address
   FROM public.users_public
  WHERE (users_public.user_id = auth.uid()))));

CREATE POLICY "can view only holder or owner" ON "public"."group_chat_messages" FOR SELECT TO authenticated USING (((( SELECT group_keys.owner
   FROM public.group_keys
  WHERE (group_keys.group_id = group_chat_messages.group_id)) = ( SELECT users_public.wallet_address
   FROM public.users_public
  WHERE (users_public.user_id = auth.uid()))) OR ((1)::numeric <= ( SELECT group_key_holders.last_fetched_balance
   FROM public.group_key_holders
  WHERE ((group_key_holders.group_id = group_chat_messages.group_id) AND (group_key_holders.wallet_address = ( SELECT users_public.wallet_address
           FROM public.users_public
          WHERE (users_public.user_id = auth.uid()))))))));

CREATE POLICY "can view only user" ON "public"."notifications" FOR SELECT TO authenticated USING ((user_id = auth.uid()));

CREATE POLICY "can write only authed" ON "public"."topic_chat_messages" FOR INSERT TO authenticated WITH CHECK (((((message IS NOT NULL) AND (message <> ''::text) AND (length(message) <= 1000)) OR ((message IS NULL) AND (rich IS NOT NULL))) AND (author = auth.uid())));

CREATE POLICY "can write only holder or owner" ON "public"."group_chat_messages" FOR INSERT TO authenticated WITH CHECK (((((message <> ''::text) AND (length(message) < 1000)) OR (rich IS NOT NULL)) AND (author = auth.uid()) AND ((( SELECT group_keys.owner
   FROM public.group_keys
  WHERE (group_keys.group_id = group_chat_messages.group_id)) = ( SELECT users_public.wallet_address
   FROM public.users_public
  WHERE (users_public.user_id = auth.uid()))) OR ((1)::numeric <= ( SELECT group_key_holders.last_fetched_balance
   FROM public.group_key_holders
  WHERE ((group_key_holders.group_id = group_chat_messages.group_id) AND (group_key_holders.wallet_address = ( SELECT users_public.wallet_address
           FROM public.users_public
          WHERE (users_public.user_id = auth.uid())))))))));

ALTER TABLE "public"."contract_events" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creator_chat_messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creator_key_holders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creator_keys" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."group_chat_messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."group_key_holders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."group_keys" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."topic_chat_messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."topic_key_holders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."topic_keys" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tracked_event_blocks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."user_wallets" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."users_public" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "view everyone" ON "public"."activities" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."contract_events" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."creator_key_holders" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."creator_keys" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."group_key_holders" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."group_keys" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."topic_chat_messages" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."topic_key_holders" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."topic_keys" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."user_wallets" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."users_public" FOR SELECT USING (true);

CREATE POLICY "view only holder or owner" ON "public"."creator_chat_messages" FOR SELECT TO authenticated USING (((creator_address = ( SELECT users_public.wallet_address
   FROM public.users_public
  WHERE (users_public.user_id = auth.uid()))) OR ((1)::numeric <= ( SELECT creator_key_holders.last_fetched_balance
   FROM public.creator_key_holders
  WHERE ((creator_key_holders.creator_address = creator_chat_messages.creator_address) AND (creator_key_holders.wallet_address = ( SELECT users_public.wallet_address
           FROM public.users_public
          WHERE (users_public.user_id = auth.uid()))))))));

ALTER TABLE "public"."wallet_linking_nonces" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "write only holder or owner" ON "public"."creator_chat_messages" FOR INSERT TO authenticated WITH CHECK (((((message <> ''::text) AND (length(message) < 1000)) OR (rich IS NOT NULL)) AND (author = auth.uid()) AND ((creator_address = ( SELECT users_public.wallet_address
   FROM public.users_public
  WHERE (users_public.user_id = auth.uid()))) OR ((1)::numeric <= ( SELECT creator_key_holders.last_fetched_balance
   FROM public.creator_key_holders
  WHERE ((creator_key_holders.creator_address = creator_chat_messages.creator_address) AND (creator_key_holders.wallet_address = ( SELECT users_public.wallet_address
           FROM public.users_public
          WHERE (users_public.user_id = auth.uid())))))))));

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."create_creator_key"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_creator_key"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_creator_key"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_creator_key"(p_creator_address text) TO "anon";
GRANT ALL ON FUNCTION "public"."get_creator_key"(p_creator_address text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_creator_key"(p_creator_address text) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_global_activities"(last_created_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_global_activities"(last_created_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_global_activities"(last_created_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_group_key"(p_group_id text) TO "anon";
GRANT ALL ON FUNCTION "public"."get_group_key"(p_group_id text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_group_key"(p_group_id text) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_held_or_owned_creator_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_held_or_owned_creator_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_held_or_owned_creator_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_held_or_owned_group_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_held_or_owned_group_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_held_or_owned_group_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_held_topic_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_held_topic_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_held_topic_keys"(p_wallet_address text, p_last_message_sent_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_key_holders"(p_key_type smallint, p_reference_key text, last_balance numeric, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_key_holders"(p_key_type smallint, p_reference_key text, last_balance numeric, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_key_holders"(p_key_type smallint, p_reference_key text, last_balance numeric, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_new_creator_keys"(last_created_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_new_creator_keys"(last_created_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_new_creator_keys"(last_created_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_new_group_keys"(last_created_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_new_group_keys"(last_created_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_new_group_keys"(last_created_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_point_rank"(p_user_id uuid) TO "anon";
GRANT ALL ON FUNCTION "public"."get_point_rank"(p_user_id uuid) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_point_rank"(p_user_id uuid) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_target_activities"(p_key_type smallint, p_reference_key text, last_created_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_target_activities"(p_key_type smallint, p_reference_key text, last_created_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_target_activities"(p_key_type smallint, p_reference_key text, last_created_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_top_creator_keys"(last_rank integer, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_top_creator_keys"(last_rank integer, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_top_creator_keys"(last_rank integer, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_top_group_keys"(last_rank integer, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_top_group_keys"(last_rank integer, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_top_group_keys"(last_rank integer, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_trending_creator_keys"(p_last_purchased_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_trending_creator_keys"(p_last_purchased_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_trending_creator_keys"(p_last_purchased_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_trending_group_keys"(p_last_purchased_at timestamp with time zone, max_count integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_trending_group_keys"(p_last_purchased_at timestamp with time zone, max_count integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_trending_group_keys"(p_last_purchased_at timestamp with time zone, max_count integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."parse_contract_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."parse_contract_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."parse_contract_event"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_creator_key_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_creator_key_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_creator_key_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_group_key_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_group_key_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_group_key_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_topic_key_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_topic_key_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_topic_key_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_user_metadata_to_public"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_user_metadata_to_public"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_user_metadata_to_public"() TO "service_role";

GRANT ALL ON TABLE "public"."activities" TO "anon";
GRANT ALL ON TABLE "public"."activities" TO "authenticated";
GRANT ALL ON TABLE "public"."activities" TO "service_role";

GRANT ALL ON TABLE "public"."contract_events" TO "anon";
GRANT ALL ON TABLE "public"."contract_events" TO "authenticated";
GRANT ALL ON TABLE "public"."contract_events" TO "service_role";

GRANT ALL ON TABLE "public"."creator_chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."creator_chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_chat_messages" TO "service_role";

GRANT ALL ON SEQUENCE "public"."creator_chat_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."creator_chat_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."creator_chat_messages_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."creator_key_holders" TO "anon";
GRANT ALL ON TABLE "public"."creator_key_holders" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_key_holders" TO "service_role";

GRANT ALL ON TABLE "public"."creator_keys" TO "anon";
GRANT ALL ON TABLE "public"."creator_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_keys" TO "service_role";

GRANT ALL ON TABLE "public"."group_chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."group_chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."group_chat_messages" TO "service_role";

GRANT ALL ON SEQUENCE "public"."group_chat_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."group_chat_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."group_chat_messages_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."group_key_holders" TO "anon";
GRANT ALL ON TABLE "public"."group_key_holders" TO "authenticated";
GRANT ALL ON TABLE "public"."group_key_holders" TO "service_role";

GRANT ALL ON TABLE "public"."group_keys" TO "anon";
GRANT ALL ON TABLE "public"."group_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."group_keys" TO "service_role";

GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";

GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."topic_chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."topic_chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."topic_chat_messages" TO "service_role";

GRANT ALL ON SEQUENCE "public"."topic_chat_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."topic_chat_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."topic_chat_messages_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."topic_key_holders" TO "anon";
GRANT ALL ON TABLE "public"."topic_key_holders" TO "authenticated";
GRANT ALL ON TABLE "public"."topic_key_holders" TO "service_role";

GRANT ALL ON TABLE "public"."topic_keys" TO "anon";
GRANT ALL ON TABLE "public"."topic_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."topic_keys" TO "service_role";

GRANT ALL ON TABLE "public"."tracked_event_blocks" TO "anon";
GRANT ALL ON TABLE "public"."tracked_event_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."tracked_event_blocks" TO "service_role";

GRANT ALL ON TABLE "public"."user_wallets" TO "anon";
GRANT ALL ON TABLE "public"."user_wallets" TO "authenticated";
GRANT ALL ON TABLE "public"."user_wallets" TO "service_role";

GRANT ALL ON TABLE "public"."users_public" TO "anon";
GRANT ALL ON TABLE "public"."users_public" TO "authenticated";
GRANT ALL ON TABLE "public"."users_public" TO "service_role";

GRANT ALL ON TABLE "public"."wallet_linking_nonces" TO "anon";
GRANT ALL ON TABLE "public"."wallet_linking_nonces" TO "authenticated";
GRANT ALL ON TABLE "public"."wallet_linking_nonces" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
