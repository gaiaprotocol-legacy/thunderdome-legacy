
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

CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE OR REPLACE FUNCTION "public"."create_creator"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  if new.wallet_address is not null then
    insert into creators (
      creator_address
    ) values (
      new.wallet_address
    ) on conflict (creator_address) do nothing;
  end if;
  return null;
end;$$;

ALTER FUNCTION "public"."create_creator"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_community_member_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update communities
  set
    member_count = member_count - 1
  where
    id = old.community_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_community_member_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_community_message_reaction_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update community_messages
  set reaction_counts = CASE
      WHEN (reaction_counts ->> old.reaction)::INT = 1 THEN
          reaction_counts - old.reaction
      ELSE
          jsonb_set(
              reaction_counts,
              ARRAY[old.reaction],
              ((reaction_counts ->> old.reaction)::INT - 1)::TEXT::JSONB
          )
      END
  where
    community_id = old.community_id and id = old.message_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_community_message_reaction_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_creator_holder_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update creators
  set
    holder_count = holder_count - 1
  where
    creator_address = old.creator_address;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_creator_holder_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_creator_message_reaction_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update creator_messages
  set reaction_counts = CASE
      WHEN (reaction_counts ->> old.reaction)::INT = 1 THEN
          reaction_counts - old.reaction
      ELSE
          jsonb_set(
              reaction_counts,
              ARRAY[old.reaction],
              ((reaction_counts ->> old.reaction)::INT - 1)::TEXT::JSONB
          )
      END
  where
    creator_address = old.creator_address and id = old.message_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_creator_message_reaction_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_follow_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update users_public
  set
    follower_count = follower_count - 1
  where
    user_id = old.followee_id;
  update users_public
  set
    following_count = following_count - 1
  where
    user_id = old.follower_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_follow_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_follower_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update users_public
  set
    follower_count = follower_count - 1
  where
    user_id = old.followee_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_follower_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_following_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update users_public
  set
    following_count = following_count - 1
  where
    user_id = old.follower_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_following_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_hashtag_holder_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update hashtags
  set
    holder_count = holder_count - 1
  where
    hashtag = old.hashtag;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_hashtag_holder_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_hashtag_message_reaction_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update hashtag_messages
  set reaction_counts = CASE
      WHEN (reaction_counts ->> old.reaction)::INT = 1 THEN
          reaction_counts - old.reaction
      ELSE
          jsonb_set(
              reaction_counts,
              ARRAY[old.reaction],
              ((reaction_counts ->> old.reaction)::INT - 1)::TEXT::JSONB
          )
      END
  where
    hashtag = old.hashtag and id = old.message_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_hashtag_message_reaction_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_post_comment_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  IF old.parent_post_id IS NOT NULL THEN
    update posts
    set
      comment_count = comment_count - 1
    where
      id = old.parent_post_id;
  END IF;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_post_comment_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_post_like_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update posts
  set
    like_count = like_count - 1
  where
    id = old.post_id;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_post_like_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."decrease_repost_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  IF old.quoted_post_id IS NOT NULL THEN
    update posts
    set
      repost_count = repost_count - 1
    where
      id = old.quoted_post_id;
  END IF;
  return null;
end;$$;

ALTER FUNCTION "public"."decrease_repost_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."delete_creator_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  update creators
  set
      last_message_sender = null,
      last_message = null
  where creator_address = old.creator_address and last_message_id = old.id;
  return null;
end;$$;

ALTER FUNCTION "public"."delete_creator_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."delete_hashtag_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  update hashtags
  set
      last_message_sender = null,
      last_message = null
  where hashtag = old.hashtag and last_message_id = old.id;
  return null;
end;$$;

ALTER FUNCTION "public"."delete_hashtag_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_all_referees"() RETURNS TABLE("user_id" "uuid", "wallet_address" "text", "wallet_type" "text", "display_name" "text", "avatar" "text", "avatar_thumb" "text", "avatar_stored" boolean, "stored_avatar" "text", "stored_avatar_thumb" "text", "x_username" "text", "metadata" "jsonb", "points" integer, "deleted" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "last_sign_in_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.user_id,
        u.wallet_address,
        u.wallet_type,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.avatar_stored,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,
        u.metadata,
        u.points,
        u.deleted,
        u.created_at,
        u.updated_at,
        u.last_sign_in_at
    FROM 
        public.users_public u
    JOIN 
        public.referral_used ru ON ru.referrer_user_id = auth.uid() AND ru.user_id = u.user_id;
END;
$$;

ALTER FUNCTION "public"."get_all_referees"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_asset_contract_events"("p_chain" "text", "p_contract_type" "text", "p_asset_id" "text", "last_created_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "max_count" integer DEFAULT 100) RETURNS TABLE("chain" "text", "contract_type" "text", "block_number" bigint, "log_index" bigint, "tx" "text", "event_name" "text", "args" "text"[], "wallet_address" "text", "asset_id" "text", "created_at" timestamp with time zone, "user_id" "uuid", "user_wallet_address" "text", "user_display_name" "text", "user_avatar" "text", "user_avatar_thumb" "text", "user_stored_avatar" "text", "user_stored_avatar_thumb" "text", "user_x_username" "text", "asset_name" "text", "asset_image_thumb" "text", "asset_stored_image_thumb" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.chain,
        e.contract_type,
        e.block_number,
        e.log_index,
        e.tx,
        e.event_name,
        e.args,
        e.wallet_address,
        e.asset_id,
        e.created_at,

        u.user_id,
        u.wallet_address as user_wallet_address,
        u.display_name as user_display_name,
        u.avatar as user_avatar,
        u.avatar_thumb as user_avatar_thumb,
        u.stored_avatar as user_stored_avatar,
        u.stored_avatar_thumb as user_stored_avatar_thumb,
        u.x_username as user_x_username,

        a.asset_name,
        a.asset_image_thumb,
        a.asset_stored_image_thumb
    FROM 
        "public"."contract_events" e
    LEFT JOIN 
        "public"."users_public" u ON e.wallet_address = u.wallet_address
    INNER JOIN 
        LATERAL (
            SELECT
                users_public.wallet_address as asset_id,
                display_name as asset_name,
                avatar_thumb as asset_image_thumb,
                stored_avatar_thumb as asset_stored_image_thumb
            FROM public.users_public WHERE e.contract_type = 'creator-trade' AND users_public.wallet_address = e.asset_id

            UNION ALL

            SELECT
                hashtag as asset_id,
                hashtag as asset_name,
                image_thumb as asset_image_thumb,
                null as asset_stored_image_thumb
            FROM public.hashtags WHERE e.contract_type = 'hashtag-trade' AND hashtag = e.asset_id
        ) a ON e.asset_id = a.asset_id
    WHERE
        e.chain = p_chain AND
        e.contract_type = p_contract_type AND
        e.asset_id = p_asset_id AND
        (last_created_at IS NULL OR e.created_at < last_created_at)
    ORDER BY 
        e.created_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_asset_contract_events"("p_chain" "text", "p_contract_type" "text", "p_asset_id" "text", "last_created_at" timestamp with time zone, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_communities"("last_member_count" integer DEFAULT 2147483647, "max_count" integer DEFAULT 100, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("id" bigint, "slug" "text", "name" "text", "image" "text", "image_thumb" "text", "metadata" "jsonb", "tokens" "jsonb", "member_count" integer, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "is_member" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.slug,
        c.name,
        c.image,
        c.image_thumb,
        c.metadata,
        c.tokens,
        c.member_count,
        c.created_at,
        c.updated_at,
        CASE
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (
                    SELECT 1
                    FROM public.community_members cm
                    WHERE cm.community_id = c.id AND cm.user = signed_user_id
                )
            ELSE FALSE 
        END AS is_member
    FROM 
        public.communities c
    WHERE 
        c.member_count < last_member_count
    ORDER BY
        c.member_count DESC;
END;
$$;

ALTER FUNCTION "public"."get_communities"("last_member_count" integer, "max_count" integer, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_community"("p_community_id" bigint, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("id" bigint, "slug" "text", "name" "text", "image" "text", "image_thumb" "text", "metadata" "jsonb", "tokens" "jsonb", "member_count" integer, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "is_member" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.slug,
        c.name,
        c.image,
        c.image_thumb,
        c.metadata,
        c.tokens,
        c.member_count,
        c.created_at,
        c.updated_at,
        CASE
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (
                    SELECT 1
                    FROM public.community_members cm
                    WHERE cm.community_id = c.id AND cm.user = signed_user_id
                )
            ELSE FALSE 
        END AS is_member
    FROM 
        public.communities c
    WHERE 
        c.id = p_community_id;
END;
$$;

ALTER FUNCTION "public"."get_community"("p_community_id" bigint, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_community_by_slug"("p_slug" "text", "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("id" bigint, "slug" "text", "name" "text", "image" "text", "image_thumb" "text", "metadata" "jsonb", "tokens" "jsonb", "member_count" integer, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "is_member" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.slug,
        c.name,
        c.image,
        c.image_thumb,
        c.metadata,
        c.tokens,
        c.member_count,
        c.created_at,
        c.updated_at,
        CASE
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (
                    SELECT 1
                    FROM public.community_members cm
                    WHERE cm.community_id = c.id AND cm.user = signed_user_id
                )
            ELSE FALSE 
        END AS is_member
    FROM 
        public.communities c
    WHERE 
        c.slug = p_slug;
END;
$$;

ALTER FUNCTION "public"."get_community_by_slug"("p_slug" "text", "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_community_message"("p_community_id" bigint, "p_message_id" bigint, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("community_id" bigint, "id" bigint, "parent_message_id" bigint, "parent_message_author_display_name" "text", "parent_message_external_author_name" "text", "parent_message_message" "text", "parent_message_translated" "jsonb", "parent_message_rich" "jsonb", "source" "text", "author" "uuid", "external_author_id" "text", "external_author_name" "text", "external_author_avatar" "text", "message" "text", "external_message_id" "text", "translated" "jsonb", "rich" "jsonb", "reaction_counts" "jsonb", "signed_user_reactions" "text"[], "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "author_user_id" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.community_id,
        m.id,

        m.parent_message_id,
        p_u.display_name AS parent_message_author_display_name,
        p.external_author_name AS parent_message_external_author_name,
        p.message AS parent_message_message,
        p.translated AS parent_message_translated,
        p.rich AS parent_message_rich,

        m.source,
        m.author,
        m.external_author_id,
        m.external_author_name,
        m.external_author_avatar,
        m.message,
        m.external_message_id,
        m.translated,
        m.rich,

        m.reaction_counts,
        CASE
            WHEN signed_user_id IS NOT NULL THEN
                ARRAY(
                    SELECT
                        r.reaction
                    FROM
                        public.community_message_reactions r
                    WHERE
                        r.community_id = m.community_id AND r.message_id = m.id AND r.reactor = signed_user_id
                )
            ELSE
                null::text[]
        END AS signed_user_reactions,

        m.created_at,
        m.updated_at,

        u.user_id AS author_user_id,
        u.wallet_address AS author_wallet_address,
        u.display_name AS author_display_name,
        u.avatar AS author_avatar,
        u.avatar_thumb AS author_avatar_thumb,
        u.stored_avatar AS author_stored_avatar,
        u.stored_avatar_thumb AS author_stored_avatar_thumb,
        u.x_username AS author_x_username
    FROM 
        public.community_messages m
    LEFT JOIN 
        public.users_public u ON m.author = u.user_id
    LEFT JOIN 
        public.community_messages p ON m.community_id = p.community_id AND m.parent_message_id = p.id
    LEFT JOIN 
        public.users_public p_u ON p.author = p_u.user_id
    WHERE 
        m.community_id = p_community_id AND m.id = p_message_id;
END;
$$;

ALTER FUNCTION "public"."get_community_message"("p_community_id" bigint, "p_message_id" bigint, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_community_messages"("p_community_id" bigint, "last_message_id" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 100, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("community_id" bigint, "id" bigint, "parent_message_id" bigint, "parent_message_author_display_name" "text", "parent_message_external_author_name" "text", "parent_message_message" "text", "parent_message_translated" "jsonb", "parent_message_rich" "jsonb", "source" "text", "author" "uuid", "external_author_id" "text", "external_author_name" "text", "external_author_avatar" "text", "message" "text", "external_message_id" "text", "translated" "jsonb", "rich" "jsonb", "reaction_counts" "jsonb", "signed_user_reactions" "text"[], "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "author_user_id" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.community_id,
        m.id,

        m.parent_message_id,
        p_u.display_name AS parent_message_author_display_name,
        p.external_author_name AS parent_message_external_author_name,
        p.message AS parent_message_message,
        p.translated AS parent_message_translated,
        p.rich AS parent_message_rich,

        m.source,
        m.author,
        m.external_author_id,
        m.external_author_name,
        m.external_author_avatar,
        m.message,
        m.external_message_id,
        m.translated,
        m.rich,

        m.reaction_counts,
        CASE
            WHEN signed_user_id IS NOT NULL THEN
                ARRAY(
                    SELECT
                        r.reaction
                    FROM
                        public.community_message_reactions r
                    WHERE
                        r.community_id = m.community_id AND r.message_id = m.id AND r.reactor = signed_user_id
                )
            ELSE
                null::text[]
        END AS signed_user_reactions,

        m.created_at,
        m.updated_at,

        u.user_id AS author_user_id,
        u.wallet_address AS author_wallet_address,
        u.display_name AS author_display_name,
        u.avatar AS author_avatar,
        u.avatar_thumb AS author_avatar_thumb,
        u.stored_avatar AS author_stored_avatar,
        u.stored_avatar_thumb AS author_stored_avatar_thumb,
        u.x_username AS author_x_username
    FROM 
        public.community_messages m
    LEFT JOIN 
        public.users_public u ON m.author = u.user_id
    LEFT JOIN 
        public.community_messages p ON m.community_id = p.community_id AND m.parent_message_id = p.id
    LEFT JOIN 
        public.users_public p_u ON p.author = p_u.user_id
    WHERE 
        m.community_id = p_community_id AND
        (last_message_id IS NULL OR m.id < last_message_id)
    ORDER BY
        m.id DESC;
END;
$$;

ALTER FUNCTION "public"."get_community_messages"("p_community_id" bigint, "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_contract_event"("p_chain" "text", "p_contract_type" "text", "p_block_number" bigint, "p_log_index" bigint) RETURNS TABLE("chain" "text", "contract_type" "text", "block_number" bigint, "log_index" bigint, "tx" "text", "event_name" "text", "args" "text"[], "wallet_address" "text", "asset_id" "text", "created_at" timestamp with time zone, "user_id" "uuid", "user_wallet_address" "text", "user_display_name" "text", "user_avatar" "text", "user_avatar_thumb" "text", "user_stored_avatar" "text", "user_stored_avatar_thumb" "text", "user_x_username" "text", "asset_name" "text", "asset_image_thumb" "text", "asset_stored_image_thumb" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.chain,
        e.contract_type,
        e.block_number,
        e.log_index,
        e.tx,
        e.event_name,
        e.args,
        e.wallet_address,
        e.asset_id,
        e.created_at,

        u.user_id,
        u.wallet_address as user_wallet_address,
        u.display_name as user_display_name,
        u.avatar as user_avatar,
        u.avatar_thumb as user_avatar_thumb,
        u.stored_avatar as user_stored_avatar,
        u.stored_avatar_thumb as user_stored_avatar_thumb,
        u.x_username as user_x_username,

        a.asset_name,
        a.asset_image_thumb,
        a.asset_stored_image_thumb
    FROM 
        "public"."contract_events" e
    LEFT JOIN 
        "public"."users_public" u ON e.wallet_address = u.wallet_address
    LEFT JOIN 
        LATERAL (
            SELECT
                users_public.wallet_address as asset_id,
                display_name as asset_name,
                avatar_thumb as asset_image_thumb,
                stored_avatar_thumb as asset_stored_image_thumb
            FROM public.users_public WHERE e.contract_type = 'creator-trade' AND users_public.wallet_address = e.asset_id

            UNION ALL

            SELECT
                hashtag as asset_id,
                hashtag as asset_name,
                image_thumb as asset_image_thumb,
                null as asset_stored_image_thumb
            FROM public.hashtags WHERE e.contract_type = 'hashtag-trade' AND hashtag = e.asset_id
        ) a ON e.asset_id = a.asset_id
    WHERE
        e.chain = p_chain AND
        e.contract_type = p_contract_type AND
        e.block_number = p_block_number AND
        e.log_index = p_log_index;
END;
$$;

ALTER FUNCTION "public"."get_contract_event"("p_chain" "text", "p_contract_type" "text", "p_block_number" bigint, "p_log_index" bigint) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_contract_events_recently"("last_created_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "max_count" integer DEFAULT 100) RETURNS TABLE("chain" "text", "contract_type" "text", "block_number" bigint, "log_index" bigint, "tx" "text", "event_name" "text", "args" "text"[], "wallet_address" "text", "asset_id" "text", "created_at" timestamp with time zone, "user_id" "uuid", "user_wallet_address" "text", "user_display_name" "text", "user_avatar" "text", "user_avatar_thumb" "text", "user_stored_avatar" "text", "user_stored_avatar_thumb" "text", "user_x_username" "text", "asset_name" "text", "asset_image_thumb" "text", "asset_stored_image_thumb" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.chain,
        e.contract_type,
        e.block_number,
        e.log_index,
        e.tx,
        e.event_name,
        e.args,
        e.wallet_address,
        e.asset_id,
        e.created_at,

        u.user_id,
        u.wallet_address as user_wallet_address,
        u.display_name as user_display_name,
        u.avatar as user_avatar,
        u.avatar_thumb as user_avatar_thumb,
        u.stored_avatar as user_stored_avatar,
        u.stored_avatar_thumb as user_stored_avatar_thumb,
        u.x_username as user_x_username,

        a.asset_name,
        a.asset_image_thumb,
        a.asset_stored_image_thumb
    FROM 
        "public"."contract_events" e
    LEFT JOIN 
        "public"."users_public" u ON e.wallet_address = u.wallet_address
    LEFT JOIN 
        LATERAL (
            SELECT
                users_public.wallet_address as asset_id,
                display_name as asset_name,
                avatar_thumb as asset_image_thumb,
                stored_avatar_thumb as asset_stored_image_thumb
            FROM public.users_public WHERE e.contract_type = 'creator-trade' AND users_public.wallet_address = e.asset_id

            UNION ALL

            SELECT
                hashtag as asset_id,
                hashtag as asset_name,
                image_thumb as asset_image_thumb,
                null as asset_stored_image_thumb
            FROM public.hashtags WHERE e.contract_type = 'hashtag-trade' AND hashtag = e.asset_id
        ) a ON e.asset_id = a.asset_id
    WHERE
        (last_created_at IS NULL OR e.created_at < last_created_at)
        AND e.event_name IN ('TicketCreated', 'TicketDeleted', 'Trade')
    ORDER BY 
        e.created_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_contract_events_recently"("last_created_at" timestamp with time zone, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_creator"("p_creator_address" "text") RETURNS TABLE("creator_address" "text", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "creator_user_id" "uuid", "creator_wallet_address" "text", "creator_display_name" "text", "creator_avatar" "text", "creator_avatar_thumb" "text", "creator_stored_avatar" "text", "creator_stored_avatar_thumb" "text", "creator_x_username" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.creator_address,
        c.supply,
        c.total_trading_volume::text,
        c.is_price_up,
        c.last_message_id,
        c.last_message_sender,
        c.last_message,
        c.last_message_sent_at,
        c.holder_count,
        c.last_purchased_at,
        c.created_at,
        c.updated_at,

        u.user_id AS creator_user_id,
        u.wallet_address AS creator_wallet_address,
        u.display_name AS creator_display_name,
        u.avatar AS creator_avatar,
        u.avatar_thumb AS creator_avatar_thumb,
        u.stored_avatar AS creator_stored_avatar,
        u.stored_avatar_thumb AS creator_stored_avatar_thumb,
        u.x_username AS creator_x_username
    FROM 
        public.creators c
    LEFT JOIN 
        public.users_public u ON c.creator_address = u.wallet_address
    WHERE 
        c.creator_address = p_creator_address;
END;
$$;

ALTER FUNCTION "public"."get_creator"("p_creator_address" "text") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_creator_holders"("p_creator_address" "text", "last_balance" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 100) RETURNS TABLE("user_id" "uuid", "wallet_address" "text", "wallet_type" "text", "display_name" "text", "avatar" "text", "avatar_thumb" "text", "avatar_stored" boolean, "stored_avatar" "text", "stored_avatar_thumb" "text", "x_username" "text", "metadata" "jsonb", "points" integer, "deleted" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "last_sign_in_at" timestamp with time zone, "balance" bigint)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.user_id,
        u.wallet_address,
        u.wallet_type,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.avatar_stored,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,
        u.metadata,
        u.points,
        u.deleted,
        u.created_at,
        u.updated_at,
        u.last_sign_in_at,
        ch.last_fetched_balance
    FROM 
        public.users_public u
    JOIN 
        public.creator_holders ch ON ch.creator_address = p_creator_address AND ch.wallet_address = u.wallet_address
    WHERE 
        last_balance IS NULL OR ch.last_fetched_balance > last_balance
    ORDER BY 
        ch.last_fetched_balance DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_creator_holders"("p_creator_address" "text", "last_balance" bigint, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_creator_message"("p_creator_address" "text", "p_message_id" bigint, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("creator_address" "text", "id" bigint, "parent_message_id" bigint, "parent_message_author_display_name" "text", "parent_message_external_author_name" "text", "parent_message_message" "text", "parent_message_translated" "jsonb", "parent_message_rich" "jsonb", "source" "text", "author" "uuid", "external_author_id" "text", "external_author_name" "text", "external_author_avatar" "text", "message" "text", "external_message_id" "text", "translated" "jsonb", "rich" "jsonb", "reaction_counts" "jsonb", "signed_user_reactions" "text"[], "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "author_user_id" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.creator_address,
        m.id,

        m.parent_message_id,
        p_u.display_name AS parent_message_author_display_name,
        p.external_author_name AS parent_message_external_author_name,
        p.message AS parent_message_message,
        p.translated AS parent_message_translated,
        p.rich AS parent_message_rich,

        m.source,
        m.author,
        m.external_author_id,
        m.external_author_name,
        m.external_author_avatar,
        m.message,
        m.external_message_id,
        m.translated,
        m.rich,

        m.reaction_counts,
        CASE
            WHEN signed_user_id IS NOT NULL THEN
                ARRAY(
                    SELECT
                        r.reaction
                    FROM
                        public.creator_message_reactions r
                    WHERE
                        r.creator_address = m.creator_address AND r.message_id = m.id AND r.reactor = signed_user_id
                )
            ELSE
                null::text[]
        END AS signed_user_reactions,

        m.created_at,
        m.updated_at,

        u.user_id AS author_user_id,
        u.wallet_address AS author_wallet_address,
        u.display_name AS author_display_name,
        u.avatar AS author_avatar,
        u.avatar_thumb AS author_avatar_thumb,
        u.stored_avatar AS author_stored_avatar,
        u.stored_avatar_thumb AS author_stored_avatar_thumb,
        u.x_username AS author_x_username
    FROM 
        public.creator_messages m
    LEFT JOIN 
        public.users_public u ON m.author = u.user_id
    LEFT JOIN 
        public.creator_messages p ON m.creator_address = p.creator_address AND m.parent_message_id = p.id
    LEFT JOIN 
        public.users_public p_u ON p.author = p_u.user_id
    WHERE 
        m.creator_address = p_creator_address AND m.id = p_message_id;
END;
$$;

ALTER FUNCTION "public"."get_creator_message"("p_creator_address" "text", "p_message_id" bigint, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_creator_messages"("p_creator_address" "text", "last_message_id" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 100, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("creator_address" "text", "id" bigint, "parent_message_id" bigint, "parent_message_author_display_name" "text", "parent_message_external_author_name" "text", "parent_message_message" "text", "parent_message_translated" "jsonb", "parent_message_rich" "jsonb", "source" "text", "author" "uuid", "external_author_id" "text", "external_author_name" "text", "external_author_avatar" "text", "message" "text", "external_message_id" "text", "translated" "jsonb", "rich" "jsonb", "reaction_counts" "jsonb", "signed_user_reactions" "text"[], "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "author_user_id" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.creator_address,
        m.id,

        m.parent_message_id,
        p_u.display_name AS parent_message_author_display_name,
        p.external_author_name AS parent_message_external_author_name,
        p.message AS parent_message_message,
        p.translated AS parent_message_translated,
        p.rich AS parent_message_rich,

        m.source,
        m.author,
        m.external_author_id,
        m.external_author_name,
        m.external_author_avatar,
        m.message,
        m.external_message_id,
        m.translated,
        m.rich,

        m.reaction_counts,
        CASE
            WHEN signed_user_id IS NOT NULL THEN
                ARRAY(
                    SELECT
                        r.reaction
                    FROM
                        public.creator_message_reactions r
                    WHERE
                        r.creator_address = m.creator_address AND r.message_id = m.id AND r.reactor = signed_user_id
                )
            ELSE
                null::text[]
        END AS signed_user_reactions,

        m.created_at,
        m.updated_at,

        u.user_id AS author_user_id,
        u.wallet_address AS author_wallet_address,
        u.display_name AS author_display_name,
        u.avatar AS author_avatar,
        u.avatar_thumb AS author_avatar_thumb,
        u.stored_avatar AS author_stored_avatar,
        u.stored_avatar_thumb AS author_stored_avatar_thumb,
        u.x_username AS author_x_username
    FROM 
        public.creator_messages m
    LEFT JOIN 
        public.users_public u ON m.author = u.user_id
    LEFT JOIN 
        public.creator_messages p ON m.creator_address = p.creator_address AND m.parent_message_id = p.id
    LEFT JOIN 
        public.users_public p_u ON p.author = p_u.user_id
    WHERE 
        m.creator_address = p_creator_address AND
        (last_message_id IS NULL OR m.id < last_message_id)
    ORDER BY
        m.id DESC;
END;
$$;

ALTER FUNCTION "public"."get_creator_messages"("p_creator_address" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_followers"("p_user_id" "uuid", "last_followed_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "max_count" integer DEFAULT 50) RETURNS TABLE("user_id" "uuid", "wallet_address" "text", "wallet_type" "text", "display_name" "text", "avatar" "text", "avatar_thumb" "text", "avatar_stored" boolean, "stored_avatar" "text", "stored_avatar_thumb" "text", "x_username" "text", "metadata" "jsonb", "points" integer, "deleted" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "last_sign_in_at" timestamp with time zone, "followed_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.user_id,
        u.wallet_address,
        u.wallet_type,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.avatar_stored,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,
        u.metadata,
        u.points,
        u.deleted,
        u.created_at,
        u.updated_at,
        u.last_sign_in_at,
        f.followed_at
    FROM 
        users_public u
    INNER JOIN 
        follows f ON u.user_id = f.follower_id
    WHERE 
        f.followee_id = p_user_id
        AND (last_followed_at IS NULL OR f.followed_at < last_followed_at)
    ORDER BY 
        f.followed_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_followers"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_following_users"("p_user_id" "uuid", "last_followed_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "max_count" integer DEFAULT 50) RETURNS TABLE("user_id" "uuid", "wallet_address" "text", "wallet_type" "text", "display_name" "text", "avatar" "text", "avatar_thumb" "text", "avatar_stored" boolean, "stored_avatar" "text", "stored_avatar_thumb" "text", "x_username" "text", "metadata" "jsonb", "points" integer, "deleted" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "last_sign_in_at" timestamp with time zone, "followed_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.user_id,
        u.wallet_address,
        u.wallet_type,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.avatar_stored,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,
        u.metadata,
        u.points,
        u.deleted,
        u.created_at,
        u.updated_at,
        u.last_sign_in_at,
        f.followed_at
    FROM 
        users_public u
    INNER JOIN 
        follows f ON u.user_id = f.followee_id
    WHERE 
        f.follower_id = p_user_id
        AND (last_followed_at IS NULL OR f.followed_at < last_followed_at)
    ORDER BY 
        f.followed_at DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_following_users"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_global_activities"("last_created_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "max_count" integer DEFAULT 100) RETURNS TABLE("block_number" bigint, "log_index" bigint, "tx" "text", "wallet_address" "text", "key_type" smallint, "reference_key" "text", "activity_name" "text", "args" "text"[], "created_at" timestamp with time zone, "user_id" "uuid", "user_wallet_address" "text", "user_display_name" "text", "user_avatar" "text", "user_avatar_thumb" "text", "user_stored_avatar" "text", "user_stored_avatar_thumb" "text", "user_x_username" "text", "key_name" "text", "key_image_thumb" "text", "key_stored_image_thumb" "text")
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

ALTER FUNCTION "public"."get_global_activities"("last_created_at" timestamp with time zone, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_hashtag_holders"("p_hashtag" "text", "last_balance" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 100) RETURNS TABLE("user_id" "uuid", "wallet_address" "text", "wallet_type" "text", "display_name" "text", "avatar" "text", "avatar_thumb" "text", "avatar_stored" boolean, "stored_avatar" "text", "stored_avatar_thumb" "text", "x_username" "text", "metadata" "jsonb", "points" integer, "deleted" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "last_sign_in_at" timestamp with time zone, "balance" bigint)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.user_id,
        u.wallet_address,
        u.wallet_type,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.avatar_stored,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,
        u.metadata,
        u.points,
        u.deleted,
        u.created_at,
        u.updated_at,
        u.last_sign_in_at,
        hh.last_fetched_balance
    FROM 
        public.users_public u
    JOIN 
        public.hashtag_holders hh ON hh.hashtag = p_hashtag AND hh.wallet_address = u.wallet_address
    WHERE 
        last_balance IS NULL OR hh.last_fetched_balance > last_balance
    ORDER BY 
        hh.last_fetched_balance DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_hashtag_holders"("p_hashtag" "text", "last_balance" bigint, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_hashtag_leaderboard"("last_rank" integer DEFAULT NULL::integer, "max_count" integer DEFAULT 100) RETURNS TABLE("rank" integer, "hashtag" "text", "image" "text", "image_thumb" "text", "metadata" "jsonb", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    row_rank integer;
BEGIN
    row_rank := COALESCE(last_rank, 0);
    RETURN QUERY
    SELECT
        (row_number() OVER (ORDER BY h.supply DESC) + row_rank)::integer AS rank,
        h.hashtag,
        h.image,
        h.image_thumb,
        h.metadata,
        h.supply,
        h.total_trading_volume::text,
        h.is_price_up,
        h.last_message_id,
        h.last_message_sender,
        h.last_message,
        h.last_message_sent_at,
        h.holder_count,
        h.last_purchased_at,
        h.created_at,
        h.updated_at
    FROM 
        public.hashtags h
    ORDER BY 
        row_rank DESC
    OFFSET 
        row_rank
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_hashtag_leaderboard"("last_rank" integer, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_hashtag_message"("p_hashtag" "text", "p_message_id" bigint, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("hashtag" "text", "id" bigint, "parent_message_id" bigint, "parent_message_author_display_name" "text", "parent_message_external_author_name" "text", "parent_message_message" "text", "parent_message_translated" "jsonb", "parent_message_rich" "jsonb", "source" "text", "author" "uuid", "external_author_id" "text", "external_author_name" "text", "external_author_avatar" "text", "message" "text", "external_message_id" "text", "translated" "jsonb", "rich" "jsonb", "reaction_counts" "jsonb", "signed_user_reactions" "text"[], "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "author_user_id" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.hashtag,
        m.id,

        m.parent_message_id,
        p_u.display_name AS parent_message_author_display_name,
        p.external_author_name AS parent_message_external_author_name,
        p.message AS parent_message_message,
        p.translated AS parent_message_translated,
        p.rich AS parent_message_rich,

        m.source,
        m.author,
        m.external_author_id,
        m.external_author_name,
        m.external_author_avatar,
        m.message,
        m.external_message_id,
        m.translated,
        m.rich,

        m.reaction_counts,
        CASE
            WHEN signed_user_id IS NOT NULL THEN
                ARRAY(
                    SELECT
                        r.reaction
                    FROM
                        public.hashtag_message_reactions r
                    WHERE
                        r.hashtag = m.hashtag AND r.message_id = m.id AND r.reactor = signed_user_id
                )
            ELSE
                null::text[]
        END AS signed_user_reactions,

        m.created_at,
        m.updated_at,

        u.user_id AS author_user_id,
        u.wallet_address AS author_wallet_address,
        u.display_name AS author_display_name,
        u.avatar AS author_avatar,
        u.avatar_thumb AS author_avatar_thumb,
        u.stored_avatar AS author_stored_avatar,
        u.stored_avatar_thumb AS author_stored_avatar_thumb,
        u.x_username AS author_x_username
    FROM 
        public.hashtag_messages m
    LEFT JOIN 
        public.users_public u ON m.author = u.user_id
    LEFT JOIN 
        public.hashtag_messages p ON m.hashtag = p.hashtag AND m.parent_message_id = p.id
    LEFT JOIN 
        public.users_public p_u ON p.author = p_u.user_id
    WHERE 
        m.hashtag = p_hashtag AND m.id = p_message_id;
END;
$$;

ALTER FUNCTION "public"."get_hashtag_message"("p_hashtag" "text", "p_message_id" bigint, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_hashtag_messages"("p_hashtag" "text", "last_message_id" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 100, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("hashtag" "text", "id" bigint, "parent_message_id" bigint, "parent_message_author_display_name" "text", "parent_message_external_author_name" "text", "parent_message_message" "text", "parent_message_translated" "jsonb", "parent_message_rich" "jsonb", "source" "text", "author" "uuid", "external_author_id" "text", "external_author_name" "text", "external_author_avatar" "text", "message" "text", "external_message_id" "text", "translated" "jsonb", "rich" "jsonb", "reaction_counts" "jsonb", "signed_user_reactions" "text"[], "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "author_user_id" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.hashtag,
        m.id,

        m.parent_message_id,
        p_u.display_name AS parent_message_author_display_name,
        p.external_author_name AS parent_message_external_author_name,
        p.message AS parent_message_message,
        p.translated AS parent_message_translated,
        p.rich AS parent_message_rich,

        m.source,
        m.author,
        m.external_author_id,
        m.external_author_name,
        m.external_author_avatar,
        m.message,
        m.external_message_id,
        m.translated,
        m.rich,

        m.reaction_counts,
        CASE
            WHEN signed_user_id IS NOT NULL THEN
                ARRAY(
                    SELECT
                        r.reaction
                    FROM
                        public.hashtag_message_reactions r
                    WHERE
                        r.hashtag = m.hashtag AND r.message_id = m.id AND r.reactor = signed_user_id
                )
            ELSE
                null::text[]
        END AS signed_user_reactions,

        m.created_at,
        m.updated_at,

        u.user_id AS author_user_id,
        u.wallet_address AS author_wallet_address,
        u.display_name AS author_display_name,
        u.avatar AS author_avatar,
        u.avatar_thumb AS author_avatar_thumb,
        u.stored_avatar AS author_stored_avatar,
        u.stored_avatar_thumb AS author_stored_avatar_thumb,
        u.x_username AS author_x_username
    FROM 
        public.hashtag_messages m
    LEFT JOIN 
        public.users_public u ON m.author = u.user_id
    LEFT JOIN 
        public.hashtag_messages p ON m.hashtag = p.hashtag AND m.parent_message_id = p.id
    LEFT JOIN 
        public.users_public p_u ON p.author = p_u.user_id
    WHERE 
        m.hashtag = p_hashtag AND
        (last_message_id IS NULL OR m.id < last_message_id)
    ORDER BY
        m.id DESC;
END;
$$;

ALTER FUNCTION "public"."get_hashtag_messages"("p_hashtag" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_holding_assets"("p_wallet_address" "text") RETURNS TABLE("chain" "text", "contract_type" "text", "asset_id" "text", "asset_name" "text", "asset_image_thumb" "text", "asset_stored_image_thumb" "text", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "balance" bigint)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.chain,
        a.contract_type,
        a.asset_id,
        a.asset_name,
        a.asset_image_thumb,
        a.asset_stored_image_thumb,
        a.supply,
        a.total_trading_volume,
        a.is_price_up,
        a.last_message_id,
        a.last_message_sender,
        a.last_message,
        a.last_message_sent_at,
        a.holder_count,
        a.last_purchased_at,
        a.created_at,
        a.updated_at,
        a.balance
    FROM
        (
            SELECT
                null AS chain,
                'creator-trade' AS contract_type,
                c.creator_address AS asset_id,
                u.display_name AS asset_name,
                u.avatar_thumb AS asset_image_thumb,
                u.stored_avatar_thumb AS asset_stored_image_thumb,
                c.supply,
                c.total_trading_volume::text AS total_trading_volume,
                c.is_price_up,
                c.last_message_id,
                c.last_message_sender,
                c.last_message,
                c.last_message_sent_at,
                c.holder_count,
                c.last_purchased_at,
                c.created_at,
                c.updated_at,
                COALESCE(ch.last_fetched_balance, 0) AS balance
            FROM
                public.creators c
            LEFT JOIN 
                public.users_public u ON c.creator_address = u.wallet_address
            LEFT JOIN
                public.creator_holders ch ON c.creator_address = ch.creator_address AND ch.wallet_address = p_wallet_address
            WHERE
                c.creator_address = p_wallet_address OR ch.wallet_address = p_wallet_address

            UNION ALL

            SELECT
                null AS chain,
                'hashtag-trade' AS contract_type,
                h.hashtag AS asset_id,
                h.hashtag AS asset_name,
                h.image_thumb AS asset_image_thumb,
                h.image_thumb AS asset_stored_image_thumb,
                h.supply,
                h.total_trading_volume::text AS total_trading_volume,
                h.is_price_up,
                h.last_message_id,
                h.last_message_sender,
                h.last_message,
                h.last_message_sent_at,
                h.holder_count,
                h.last_purchased_at,
                h.created_at,
                h.updated_at,
                hh.last_fetched_balance AS balance
            FROM
                public.hashtags h
            JOIN
                public.hashtag_holders hh ON h.hashtag = hh.hashtag AND hh.wallet_address = p_wallet_address
            WHERE
                hh.wallet_address = p_wallet_address
        ) AS a
    ORDER BY
        a.balance DESC;
END;
$$;

ALTER FUNCTION "public"."get_holding_assets"("p_wallet_address" "text") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_holding_creators"("p_wallet_address" "text") RETURNS TABLE("creator_address" "text", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "creator_user_id" "uuid", "creator_wallet_address" "text", "creator_display_name" "text", "creator_avatar" "text", "creator_avatar_thumb" "text", "creator_stored_avatar" "text", "creator_stored_avatar_thumb" "text", "creator_x_username" "text", "balance" bigint)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.creator_address,
        c.supply,
        c.total_trading_volume::text,
        c.is_price_up,
        c.last_message_id,
        c.last_message_sender,
        c.last_message,
        c.last_message_sent_at,
        c.holder_count,
        c.last_purchased_at,
        c.created_at,
        c.updated_at,

        u.user_id AS creator_user_id,
        u.wallet_address AS creator_wallet_address,
        u.display_name AS creator_display_name,
        u.avatar AS creator_avatar,
        u.avatar_thumb AS creator_avatar_thumb,
        u.stored_avatar AS creator_stored_avatar,
        u.stored_avatar_thumb AS creator_stored_avatar_thumb,
        u.x_username AS creator_x_username,

        COALESCE(ch.last_fetched_balance, 0) AS balance
    FROM 
        public.creators c
    LEFT JOIN 
        public.users_public u ON c.creator_address = u.wallet_address
    LEFT JOIN 
        public.creator_holders ch ON c.creator_address = ch.creator_address AND ch.wallet_address = p_wallet_address
    WHERE 
        c.creator_address = p_wallet_address OR ch.wallet_address = p_wallet_address
    ORDER BY 
        ch.last_fetched_balance DESC;
END;
$$;

ALTER FUNCTION "public"."get_holding_creators"("p_wallet_address" "text") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_holding_hashtags"("p_wallet_address" "text") RETURNS TABLE("hashtag" "text", "image" "text", "image_thumb" "text", "metadata" "jsonb", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "balance" bigint)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.hashtag,
        h.image,
        h.image_thumb,
        h.metadata,
        h.supply,
        h.total_trading_volume::text,
        h.is_price_up,
        h.last_message_id,
        h.last_message_sender,
        h.last_message,
        h.last_message_sent_at,
        h.holder_count,
        h.last_purchased_at,
        h.created_at,
        h.updated_at,
        hh.last_fetched_balance
    FROM 
        public.hashtags h
    JOIN 
        public.hashtag_holders hh ON h.hashtag = hh.hashtag AND hh.wallet_address = p_wallet_address
    WHERE 
        hh.wallet_address = p_wallet_address
    ORDER BY 
        hh.last_fetched_balance DESC;
END;
$$;

ALTER FUNCTION "public"."get_holding_hashtags"("p_wallet_address" "text") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_key_holders"("p_key_type" smallint, "p_reference_key" "text", "last_balance" numeric DEFAULT NULL::numeric, "max_count" integer DEFAULT 50) RETURNS TABLE("user_id" "uuid", "wallet_address" "text", "total_earned_trading_fees" numeric, "display_name" "text", "avatar" "text", "avatar_thumb" "text", "avatar_stored" boolean, "stored_avatar" "text", "stored_avatar_thumb" "text", "x_username" "text", "metadata" "jsonb", "points" integer, "blocked" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "balance" "text")
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

ALTER FUNCTION "public"."get_key_holders"("p_key_type" smallint, "p_reference_key" "text", "last_balance" numeric, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_new_assets"() RETURNS TABLE("chain" "text", "contract_type" "text", "asset_id" "text", "asset_name" "text", "asset_image_thumb" "text", "asset_stored_image_thumb" "text", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.chain,
        a.contract_type,
        a.asset_id,
        a.asset_name,
        a.asset_image_thumb,
        a.asset_stored_image_thumb,
        a.supply,
        a.total_trading_volume,
        a.is_price_up,
        a.last_message_id,
        a.last_message_sender,
        a.last_message,
        a.last_message_sent_at,
        a.holder_count,
        a.last_purchased_at,
        a.created_at,
        a.updated_at
    FROM
        (
            SELECT
                null AS chain,
                'creator-trade' AS contract_type,
                c.creator_address AS asset_id,
                u.display_name AS asset_name,
                u.avatar_thumb AS asset_image_thumb,
                u.stored_avatar_thumb AS asset_stored_image_thumb,
                c.supply,
                c.total_trading_volume::text AS total_trading_volume,
                c.is_price_up,
                c.last_message_id,
                c.last_message_sender,
                c.last_message,
                c.last_message_sent_at,
                c.holder_count,
                c.last_purchased_at,
                c.created_at,
                c.updated_at
            FROM
                public.creators c
            LEFT JOIN 
                public.users_public u ON c.creator_address = u.wallet_address

            UNION ALL

            SELECT
                null AS chain,
                'hashtag-trade' AS contract_type,
                h.hashtag AS asset_id,
                h.hashtag AS asset_name,
                h.image_thumb AS asset_image_thumb,
                h.image_thumb AS asset_stored_image_thumb,
                h.supply,
                h.total_trading_volume::text AS total_trading_volume,
                h.is_price_up,
                h.last_message_id,
                h.last_message_sender,
                h.last_message,
                h.last_message_sent_at,
                h.holder_count,
                h.last_purchased_at,
                h.created_at,
                h.updated_at
            FROM
                public.hashtags h
        ) AS a
    ORDER BY
        a.created_at DESC
    LIMIT 
        50;
END;
$$;

ALTER FUNCTION "public"."get_new_assets"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_point_rank"("p_user_id" "uuid") RETURNS integer
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

ALTER FUNCTION "public"."get_point_rank"("p_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_post_thread"("p_post_id" bigint, "max_comment_count" integer DEFAULT 50, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("id" bigint, "parent_post_id" bigint, "quoted_post_id" bigint, "q_parent_post_id" bigint, "q_quoted_post_id" bigint, "q2_parent_post_id" bigint, "q2_quoted_post_id" bigint, "q2_author" "uuid", "q2_author_wallet_address" "text", "q2_author_display_name" "text", "q2_author_avatar" "text", "q2_author_avatar_thumb" "text", "q2_author_stored_avatar" "text", "q2_author_stored_avatar_thumb" "text", "q2_author_x_username" "text", "q2_message" "text", "q2_translated" "jsonb", "q2_rich" "jsonb", "q2_comment_count" integer, "q2_repost_count" integer, "q2_like_count" integer, "q2_created_at" timestamp with time zone, "q2_updated_at" timestamp with time zone, "q_author" "uuid", "q_author_wallet_address" "text", "q_author_display_name" "text", "q_author_avatar" "text", "q_author_avatar_thumb" "text", "q_author_stored_avatar" "text", "q_author_stored_avatar_thumb" "text", "q_author_x_username" "text", "q_message" "text", "q_translated" "jsonb", "q_rich" "jsonb", "q_comment_count" integer, "q_repost_count" integer, "q_like_count" integer, "q_created_at" timestamp with time zone, "q_updated_at" timestamp with time zone, "q_liked" boolean, "q_reposted" boolean, "author" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text", "message" "text", "translated" "jsonb", "rich" "jsonb", "comment_count" integer, "repost_count" integer, "like_count" integer, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "liked" boolean, "reposted" boolean, "depth" integer)
    LANGUAGE "sql"
    AS $$
WITH RECURSIVE ancestors AS (
    SELECT 
        p.id,
        p.parent_post_id as parent_post_id,
        p.quoted_post_id,

            pq.parent_post_id as q_parent_post_id,
            pq.quoted_post_id,

                pq2.parent_post_id as q2_parent_post_id,
                pq2.quoted_post_id,

                pq2.author,
                uq2.wallet_address,
                uq2.display_name,
                uq2.avatar,
                uq2.avatar_thumb,
                uq2.stored_avatar,
                uq2.stored_avatar_thumb,
                uq2.x_username,

                pq2.message,
                pq2.translated,
                pq2.rich,
                pq2.comment_count,
                pq2.repost_count,
                pq2.like_count,
                pq2.created_at,
                pq2.updated_at,

            pq.author,
            uq.wallet_address,
            uq.display_name,
            uq.avatar,
            uq.avatar_thumb,
            uq.stored_avatar,
            uq.stored_avatar_thumb,
            uq.x_username,

            pq.message,
            pq.translated,
            pq.rich,
            pq.comment_count,
            pq.repost_count,
            pq.like_count,
            pq.created_at,
            pq.updated_at,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = pq.id AND pl.user_id = signed_user_id)
                ELSE FALSE 
            END AS liked,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = pq.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
                ELSE FALSE 
            END AS reposted,

        p.author,
        u.wallet_address,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,

        p.message,
        p.translated,
        p.rich,
        p.comment_count,
        p.repost_count,
        p.like_count,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = signed_user_id)
            ELSE FALSE 
        END AS liked,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = p.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
            ELSE FALSE 
        END AS reposted,
        0 AS depth
    FROM 
        posts p
    INNER JOIN users_public u ON p.author = u.user_id
    LEFT JOIN posts pq ON pq.id = p.quoted_post_id
    LEFT JOIN users_public uq ON pq.author = uq.user_id
    LEFT JOIN posts pq2 ON pq2.id = pq.quoted_post_id
    LEFT JOIN users_public uq2 ON pq2.author = uq2.user_id
    WHERE 
        p.id = p_post_id
    UNION
    SELECT 
        p.id,
        p.parent_post_id as parent_post_id,
        p.quoted_post_id,

            pq.parent_post_id as q_parent_post_id,
            pq.quoted_post_id,

                pq2.parent_post_id as q2_parent_post_id,
                pq2.quoted_post_id,

                pq2.author,
                uq2.wallet_address,
                uq2.display_name,
                uq2.avatar,
                uq2.avatar_thumb,
                uq2.stored_avatar,
                uq2.stored_avatar_thumb,
                uq2.x_username,

                pq2.message,
                pq2.translated,
                pq2.rich,
                pq2.comment_count,
                pq2.repost_count,
                pq2.like_count,
                pq2.created_at,
                pq2.updated_at,

            pq.author,
            uq.wallet_address,
            uq.display_name,
            uq.avatar,
            uq.avatar_thumb,
            uq.stored_avatar,
            uq.stored_avatar_thumb,
            uq.x_username,

            pq.message,
            pq.translated,
            pq.rich,
            pq.comment_count,
            pq.repost_count,
            pq.like_count,
            pq.created_at,
            pq.updated_at,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = pq.id AND pl.user_id = signed_user_id)
                ELSE FALSE 
            END AS liked,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = pq.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
                ELSE FALSE 
            END AS reposted,

        p.author,
        u.wallet_address,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,

        p.message,
        p.translated,
        p.rich,
        p.comment_count,
        p.repost_count,
        p.like_count,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = signed_user_id)
            ELSE FALSE 
        END AS liked,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = p.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
            ELSE FALSE 
        END AS reposted,
        a.depth - 1 AS depth
    FROM 
        posts p
    INNER JOIN users_public u ON p.author = u.user_id
    LEFT JOIN posts pq ON pq.id = p.quoted_post_id
    LEFT JOIN users_public uq ON pq.author = uq.user_id
    LEFT JOIN posts pq2 ON pq2.id = pq.quoted_post_id
    LEFT JOIN users_public uq2 ON pq2.author = uq2.user_id
    JOIN 
        ancestors a ON p.id = a.parent_post_id
),
comments AS (
    SELECT
        p.id,
        p.parent_post_id,
        p.quoted_post_id,

            pq.parent_post_id,
            pq.quoted_post_id,

                pq2.parent_post_id,
                pq2.quoted_post_id,

                pq2.author,
                uq2.wallet_address,
                uq2.display_name,
                uq2.avatar,
                uq2.avatar_thumb,
                uq2.stored_avatar,
                uq2.stored_avatar_thumb,
                uq2.x_username,

                pq2.message,
                pq2.translated,
                pq2.rich,
                pq2.comment_count,
                pq2.repost_count,
                pq2.like_count,
                pq2.created_at,
                pq2.updated_at,

            pq.author,
            uq.wallet_address,
            uq.display_name,
            uq.avatar,
            uq.avatar_thumb,
            uq.stored_avatar,
            uq.stored_avatar_thumb,
            uq.x_username,

            pq.message,
            pq.translated,
            pq.rich,
            pq.comment_count,
            pq.repost_count,
            pq.like_count,
            pq.created_at,
            pq.updated_at,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = pq.id AND pl.user_id = signed_user_id)
                ELSE FALSE 
            END AS liked,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = pq.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
                ELSE FALSE 
            END AS reposted,

        p.author,
        u.wallet_address,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,

        p.message,
        p.translated,
        p.rich,
        p.comment_count,
        p.repost_count,
        p.like_count,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = signed_user_id)
            ELSE FALSE 
        END AS liked,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = p.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
            ELSE FALSE 
        END AS reposted,
        1 AS depth
    FROM 
        posts p
    INNER JOIN users_public u ON p.author = u.user_id
    LEFT JOIN posts pq ON pq.id = p.quoted_post_id
    LEFT JOIN users_public uq ON pq.author = uq.user_id
    LEFT JOIN posts pq2 ON pq2.id = pq.quoted_post_id
    LEFT JOIN users_public uq2 ON pq2.author = uq2.user_id
    WHERE 
        p.parent_post_id = p_post_id
    ORDER BY p.id
    LIMIT max_comment_count
)
SELECT * FROM ancestors
UNION ALL
SELECT * FROM comments
ORDER BY depth, id;
$$;

ALTER FUNCTION "public"."get_post_thread"("p_post_id" bigint, "max_comment_count" integer, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_posts_following"("signed_user_id" "uuid", "last_post_id" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 50) RETURNS TABLE("id" bigint, "parent_post_id" bigint, "quoted_post_id" bigint, "q_parent_post_id" bigint, "q_quoted_post_id" bigint, "q2_parent_post_id" bigint, "q2_quoted_post_id" bigint, "q2_author" "uuid", "q2_author_wallet_address" "text", "q2_author_display_name" "text", "q2_author_avatar" "text", "q2_author_avatar_thumb" "text", "q2_author_stored_avatar" "text", "q2_author_stored_avatar_thumb" "text", "q2_author_x_username" "text", "q2_message" "text", "q2_translated" "jsonb", "q2_rich" "jsonb", "q2_comment_count" integer, "q2_repost_count" integer, "q2_like_count" integer, "q2_created_at" timestamp with time zone, "q2_updated_at" timestamp with time zone, "q_author" "uuid", "q_author_wallet_address" "text", "q_author_display_name" "text", "q_author_avatar" "text", "q_author_avatar_thumb" "text", "q_author_stored_avatar" "text", "q_author_stored_avatar_thumb" "text", "q_author_x_username" "text", "q_message" "text", "q_translated" "jsonb", "q_rich" "jsonb", "q_comment_count" integer, "q_repost_count" integer, "q_like_count" integer, "q_created_at" timestamp with time zone, "q_updated_at" timestamp with time zone, "q_liked" boolean, "q_reposted" boolean, "author" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text", "message" "text", "translated" "jsonb", "rich" "jsonb", "comment_count" integer, "repost_count" integer, "like_count" integer, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "liked" boolean, "reposted" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.parent_post_id,
        p.quoted_post_id,

            pq.parent_post_id,
            pq.quoted_post_id,

                pq2.parent_post_id,
                pq2.quoted_post_id,

                pq2.author,
                uq2.wallet_address,
                uq2.display_name,
                uq2.avatar,
                uq2.avatar_thumb,
                uq2.stored_avatar,
                uq2.stored_avatar_thumb,
                uq2.x_username,

                pq2.message,
                pq2.translated,
                pq2.rich,
                pq2.comment_count,
                pq2.repost_count,
                pq2.like_count,
                pq2.created_at,
                pq2.updated_at,

            pq.author,
            uq.wallet_address,
            uq.display_name,
            uq.avatar,
            uq.avatar_thumb,
            uq.stored_avatar,
            uq.stored_avatar_thumb,
            uq.x_username,

            pq.message,
            pq.translated,
            pq.rich,
            pq.comment_count,
            pq.repost_count,
            pq.like_count,
            pq.created_at,
            pq.updated_at,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = pq.id AND pl.user_id = signed_user_id)
                ELSE FALSE 
            END AS liked,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = pq.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
                ELSE FALSE 
            END AS reposted,

        p.author,
        u.wallet_address,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,

        p.message,
        p.translated,
        p.rich,
        p.comment_count,
        p.repost_count,
        p.like_count,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = signed_user_id)
            ELSE FALSE 
        END AS liked,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = p.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
            ELSE FALSE 
        END AS reposted
    FROM 
        posts p
    INNER JOIN users_public u ON p.author = u.user_id
    LEFT JOIN posts pq ON pq.id = p.quoted_post_id
    LEFT JOIN users_public uq ON pq.author = uq.user_id
    LEFT JOIN posts pq2 ON pq2.id = pq.quoted_post_id
    LEFT JOIN users_public uq2 ON pq2.author = uq2.user_id
    INNER JOIN 
        follows f ON p.author = f.followee_id
    WHERE 
        f.follower_id = signed_user_id
        AND p.parent_post_id IS NULL
        AND (last_post_id IS NULL OR p.id < last_post_id)
    ORDER BY 
        p.id DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_posts_following"("signed_user_id" "uuid", "last_post_id" bigint, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_posts_for_you"("last_post_id" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 50, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("id" bigint, "parent_post_id" bigint, "quoted_post_id" bigint, "q_parent_post_id" bigint, "q_quoted_post_id" bigint, "q2_parent_post_id" bigint, "q2_quoted_post_id" bigint, "q2_author" "uuid", "q2_author_wallet_address" "text", "q2_author_display_name" "text", "q2_author_avatar" "text", "q2_author_avatar_thumb" "text", "q2_author_stored_avatar" "text", "q2_author_stored_avatar_thumb" "text", "q2_author_x_username" "text", "q2_message" "text", "q2_translated" "jsonb", "q2_rich" "jsonb", "q2_comment_count" integer, "q2_repost_count" integer, "q2_like_count" integer, "q2_created_at" timestamp with time zone, "q2_updated_at" timestamp with time zone, "q_author" "uuid", "q_author_wallet_address" "text", "q_author_display_name" "text", "q_author_avatar" "text", "q_author_avatar_thumb" "text", "q_author_stored_avatar" "text", "q_author_stored_avatar_thumb" "text", "q_author_x_username" "text", "q_message" "text", "q_translated" "jsonb", "q_rich" "jsonb", "q_comment_count" integer, "q_repost_count" integer, "q_like_count" integer, "q_created_at" timestamp with time zone, "q_updated_at" timestamp with time zone, "q_liked" boolean, "q_reposted" boolean, "author" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text", "message" "text", "translated" "jsonb", "rich" "jsonb", "comment_count" integer, "repost_count" integer, "like_count" integer, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "liked" boolean, "reposted" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.parent_post_id,
        p.quoted_post_id,

            pq.parent_post_id,
            pq.quoted_post_id,

                pq2.parent_post_id,
                pq2.quoted_post_id,

                pq2.author,
                uq2.wallet_address,
                uq2.display_name,
                uq2.avatar,
                uq2.avatar_thumb,
                uq2.stored_avatar,
                uq2.stored_avatar_thumb,
                uq2.x_username,

                pq2.message,
                pq2.translated,
                pq2.rich,
                pq2.comment_count,
                pq2.repost_count,
                pq2.like_count,
                pq2.created_at,
                pq2.updated_at,

            pq.author,
            uq.wallet_address,
            uq.display_name,
            uq.avatar,
            uq.avatar_thumb,
            uq.stored_avatar,
            uq.stored_avatar_thumb,
            uq.x_username,

            pq.message,
            pq.translated,
            pq.rich,
            pq.comment_count,
            pq.repost_count,
            pq.like_count,
            pq.created_at,
            pq.updated_at,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = pq.id AND pl.user_id = signed_user_id)
                ELSE FALSE 
            END AS liked,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = pq.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
                ELSE FALSE 
            END AS reposted,

        p.author,
        u.wallet_address,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,

        p.message,
        p.translated,
        p.rich,
        p.comment_count,
        p.repost_count,
        p.like_count,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = signed_user_id)
            ELSE FALSE 
        END AS liked,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = p.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
            ELSE FALSE 
        END AS reposted
    FROM 
        posts p
    INNER JOIN users_public u ON p.author = u.user_id
    LEFT JOIN posts pq ON pq.id = p.quoted_post_id
    LEFT JOIN users_public uq ON pq.author = uq.user_id
    LEFT JOIN posts pq2 ON pq2.id = pq.quoted_post_id
    LEFT JOIN users_public uq2 ON pq2.author = uq2.user_id
    WHERE 
        p.parent_post_id IS NULL
        AND (last_post_id IS NULL OR p.id < last_post_id)
        AND (p.quoted_post_id IS NULL OR p.message IS NOT NULL OR p.rich IS NOT NULL)

        -- algorithm
        --AND p.comment_count + p.repost_count + p.like_count + FLOOR(random() * 3 + 1)::int >= 4
    ORDER BY 
        p.id DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_posts_for_you"("last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_signed_user_notifications"("signed_user_id" "uuid", "last_notification_id" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 50) RETURNS TABLE("id" bigint, "user_id" "uuid", "type" "text", "target_chain" "text", "target_id" "text", "senders" "uuid"[], "sender_wallet_addresses" "text"[], "sender_display_names" "text"[], "sender_avatars" "text"[], "sender_avatar_thumbs" "text"[], "sender_stored_avatars" "text"[], "sender_stored_avatar_thumbs" "text"[], "sender_x_usernames" "text"[], "data" "jsonb", "created_at" timestamp with time zone, "notified_at" timestamp with time zone, "p_id" bigint, "p_parent_post_id" bigint, "p_quoted_post_id" bigint, "q_parent_post_id" bigint, "q_quoted_post_id" bigint, "q2_parent_post_id" bigint, "q2_quoted_post_id" bigint, "q2_author" "uuid", "q2_author_wallet_address" "text", "q2_author_display_name" "text", "q2_author_avatar" "text", "q2_author_avatar_thumb" "text", "q2_author_stored_avatar" "text", "q2_author_stored_avatar_thumb" "text", "q2_author_x_username" "text", "q2_message" "text", "q2_translated" "jsonb", "q2_rich" "jsonb", "q2_comment_count" integer, "q2_repost_count" integer, "q2_like_count" integer, "q2_created_at" timestamp with time zone, "q2_updated_at" timestamp with time zone, "q_author" "uuid", "q_author_wallet_address" "text", "q_author_display_name" "text", "q_author_avatar" "text", "q_author_avatar_thumb" "text", "q_author_stored_avatar" "text", "q_author_stored_avatar_thumb" "text", "q_author_x_username" "text", "q_message" "text", "q_translated" "jsonb", "q_rich" "jsonb", "q_comment_count" integer, "q_repost_count" integer, "q_like_count" integer, "q_created_at" timestamp with time zone, "q_updated_at" timestamp with time zone, "q_liked" boolean, "q_reposted" boolean, "p_author" "uuid", "p_author_wallet_address" "text", "p_author_display_name" "text", "p_author_avatar" "text", "p_author_avatar_thumb" "text", "p_author_stored_avatar" "text", "p_author_stored_avatar_thumb" "text", "p_author_x_username" "text", "p_message" "text", "p_translated" "jsonb", "p_rich" "jsonb", "p_comment_count" integer, "p_repost_count" integer, "p_like_count" integer, "p_created_at" timestamp with time zone, "p_updated_at" timestamp with time zone, "p_liked" boolean, "p_reposted" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    WITH notifications_data AS (
        SELECT
            n.*,
            array_agg(senders.wallet_address) AS sender_wallet_addresses,
            array_agg(senders.display_name) AS sender_display_names,
            array_agg(senders.avatar) AS sender_avatars,
            array_agg(senders.avatar_thumb) AS sender_avatar_thumbs,
            array_agg(senders.stored_avatar) AS sender_stored_avatars,
            array_agg(senders.stored_avatar_thumb) AS sender_stored_avatar_thumbs,
            array_agg(senders.x_username) AS sender_x_usernames
        FROM
            notifications n
        LEFT JOIN LATERAL (
            SELECT
                u.wallet_address,
                u.display_name,
                u.avatar,
                u.avatar_thumb,
                u.stored_avatar,
                u.stored_avatar_thumb,
                u.x_username
            FROM
                unnest(n.senders) AS sender_id
            JOIN
                users_public u ON u.user_id = sender_id
        ) AS senders ON TRUE
        WHERE
            n.user_id = signed_user_id
            AND (last_notification_id IS NULL OR n.id < last_notification_id)
        GROUP BY
            n.id
        ORDER BY
            n.id DESC
        LIMIT
            max_count
    )
    SELECT
        nd.id,
        nd.user_id,
        nd.type,
        nd.target_chain,
        nd.target_id,

        nd.senders,
        nd.sender_wallet_addresses,
        nd.sender_display_names,
        nd.sender_avatars,
        nd.sender_avatar_thumbs,
        nd.sender_stored_avatars,
        nd.sender_stored_avatar_thumbs,
        nd.sender_x_usernames,

        nd.data,
        nd.created_at,
        nd.notified_at,

        p.id,
        p.parent_post_id,
        p.quoted_post_id,

            pq.parent_post_id,
            pq.quoted_post_id,

                pq2.parent_post_id,
                pq2.quoted_post_id,

                pq2.author,
                uq2.wallet_address,
                uq2.display_name,
                uq2.avatar,
                uq2.avatar_thumb,
                uq2.stored_avatar,
                uq2.stored_avatar_thumb,
                uq2.x_username,

                pq2.message,
                pq2.translated,
                pq2.rich,
                pq2.comment_count,
                pq2.repost_count,
                pq2.like_count,
                pq2.created_at,
                pq2.updated_at,

            pq.author,
            uq.wallet_address,
            uq.display_name,
            uq.avatar,
            uq.avatar_thumb,
            uq.stored_avatar,
            uq.stored_avatar_thumb,
            uq.x_username,

            pq.message,
            pq.translated,
            pq.rich,
            pq.comment_count,
            pq.repost_count,
            pq.like_count,
            pq.created_at,
            pq.updated_at,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = pq.id AND pl.user_id = signed_user_id)
                ELSE FALSE 
            END AS liked,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = pq.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
                ELSE FALSE 
            END AS reposted,

        p.author,
        u.wallet_address,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,

        p.message,
        p.translated,
        p.rich,
        p.comment_count,
        p.repost_count,
        p.like_count,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = signed_user_id)
            ELSE FALSE 
        END AS liked,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = p.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
            ELSE FALSE 
        END AS reposted
    FROM
        notifications_data nd
    LEFT JOIN posts p ON nd.target_id::bigint = p.id
        AND nd.type IN ('post_comment', 'post_like', 'repost', 'post_quote')
    LEFT JOIN users_public u ON p.author = u.user_id
    LEFT JOIN posts pq ON pq.id = p.quoted_post_id
    LEFT JOIN users_public uq ON pq.author = uq.user_id
    LEFT JOIN posts pq2 ON pq2.id = pq.quoted_post_id
    LEFT JOIN users_public uq2 ON pq2.author = uq2.user_id
    ORDER BY
        nd.notified_at DESC;
END;
$$;

ALTER FUNCTION "public"."get_signed_user_notifications"("signed_user_id" "uuid", "last_notification_id" bigint, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_target_activities"("p_key_type" smallint, "p_reference_key" "text", "last_created_at" timestamp with time zone DEFAULT NULL::timestamp with time zone, "max_count" integer DEFAULT 100) RETURNS TABLE("block_number" bigint, "log_index" bigint, "tx" "text", "wallet_address" "text", "key_type" smallint, "reference_key" "text", "activity_name" "text", "args" "text"[], "created_at" timestamp with time zone, "user_id" "uuid", "user_wallet_address" "text", "user_display_name" "text", "user_avatar" "text", "user_avatar_thumb" "text", "user_stored_avatar" "text", "user_stored_avatar_thumb" "text", "user_x_username" "text", "key_name" "text", "key_image_thumb" "text", "key_stored_image_thumb" "text")
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

ALTER FUNCTION "public"."get_target_activities"("p_key_type" smallint, "p_reference_key" "text", "last_created_at" timestamp with time zone, "max_count" integer) OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_top_assets"() RETURNS TABLE("chain" "text", "contract_type" "text", "asset_id" "text", "asset_name" "text", "asset_image_thumb" "text", "asset_stored_image_thumb" "text", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.chain,
        a.contract_type,
        a.asset_id,
        a.asset_name,
        a.asset_image_thumb,
        a.asset_stored_image_thumb,
        a.supply,
        a.total_trading_volume,
        a.is_price_up,
        a.last_message_id,
        a.last_message_sender,
        a.last_message,
        a.last_message_sent_at,
        a.holder_count,
        a.last_purchased_at,
        a.created_at,
        a.updated_at
    FROM
        (
            SELECT
                null AS chain,
                'creator-trade' AS contract_type,
                c.creator_address AS asset_id,
                u.display_name AS asset_name,
                u.avatar_thumb AS asset_image_thumb,
                u.stored_avatar_thumb AS asset_stored_image_thumb,
                c.supply,
                c.total_trading_volume::text AS total_trading_volume,
                c.is_price_up,
                c.last_message_id,
                c.last_message_sender,
                c.last_message,
                c.last_message_sent_at,
                c.holder_count,
                c.last_purchased_at,
                c.created_at,
                c.updated_at
            FROM
                public.creators c
            LEFT JOIN 
                public.users_public u ON c.creator_address = u.wallet_address

            UNION ALL

            SELECT
                null AS chain,
                'hashtag-trade' AS contract_type,
                h.hashtag AS asset_id,
                h.hashtag AS asset_name,
                h.image_thumb AS asset_image_thumb,
                h.image_thumb AS asset_stored_image_thumb,
                h.supply,
                h.total_trading_volume::text AS total_trading_volume,
                h.is_price_up,
                h.last_message_id,
                h.last_message_sender,
                h.last_message,
                h.last_message_sent_at,
                h.holder_count,
                h.last_purchased_at,
                h.created_at,
                h.updated_at
            FROM
                public.hashtags h
        ) AS a
    ORDER BY
        a.supply DESC
    LIMIT 
        50;
END;
$$;

ALTER FUNCTION "public"."get_top_assets"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_trending_assets"() RETURNS TABLE("chain" "text", "contract_type" "text", "asset_id" "text", "asset_name" "text", "asset_image_thumb" "text", "asset_stored_image_thumb" "text", "supply" bigint, "total_trading_volume" "text", "is_price_up" boolean, "last_message_id" bigint, "last_message_sender" "text", "last_message" "text", "last_message_sent_at" timestamp with time zone, "holder_count" integer, "last_purchased_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "creator_user_id" "uuid")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.chain,
        a.contract_type,
        a.asset_id,
        a.asset_name,
        a.asset_image_thumb,
        a.asset_stored_image_thumb,
        a.supply,
        a.total_trading_volume,
        a.is_price_up,
        a.last_message_id,
        a.last_message_sender,
        a.last_message,
        a.last_message_sent_at,
        a.holder_count,
        a.last_purchased_at,
        a.created_at,
        a.updated_at,

        a.creator_user_id
    FROM
        (
            SELECT
                null AS chain,
                'creator-trade' AS contract_type,
                c.creator_address AS asset_id,
                u.display_name AS asset_name,
                u.avatar_thumb AS asset_image_thumb,
                u.stored_avatar_thumb AS asset_stored_image_thumb,
                c.supply,
                c.total_trading_volume::text AS total_trading_volume,
                c.is_price_up,
                c.last_message_id,
                c.last_message_sender,
                c.last_message,
                c.last_message_sent_at,
                c.holder_count,
                c.last_purchased_at,
                c.created_at,
                c.updated_at,

                u.user_id AS creator_user_id
            FROM
                public.creators c
            LEFT JOIN 
                public.users_public u ON c.creator_address = u.wallet_address
            WHERE
                c.is_price_up = true

            UNION ALL

            SELECT
                null AS chain,
                'hashtag-trade' AS contract_type,
                h.hashtag AS asset_id,
                h.hashtag AS asset_name,
                h.image_thumb AS asset_image_thumb,
                h.image_thumb AS asset_stored_image_thumb,
                h.supply,
                h.total_trading_volume::text AS total_trading_volume,
                h.is_price_up,
                h.last_message_id,
                h.last_message_sender,
                h.last_message,
                h.last_message_sent_at,
                h.holder_count,
                h.last_purchased_at,
                h.created_at,
                h.updated_at,

                null AS creator_user_id
            FROM
                public.hashtags h
            WHERE
                h.is_price_up = true
        ) AS a
    ORDER BY
        a.last_purchased_at DESC
    LIMIT 
        20;
END;
$$;

ALTER FUNCTION "public"."get_trending_assets"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_user_posts"("p_user_id" "uuid", "last_post_id" bigint DEFAULT NULL::bigint, "max_count" integer DEFAULT 50, "signed_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("id" bigint, "parent_post_id" bigint, "quoted_post_id" bigint, "q_parent_post_id" bigint, "q_quoted_post_id" bigint, "q2_parent_post_id" bigint, "q2_quoted_post_id" bigint, "q2_author" "uuid", "q2_author_wallet_address" "text", "q2_author_display_name" "text", "q2_author_avatar" "text", "q2_author_avatar_thumb" "text", "q2_author_stored_avatar" "text", "q2_author_stored_avatar_thumb" "text", "q2_author_x_username" "text", "q2_message" "text", "q2_translated" "jsonb", "q2_rich" "jsonb", "q2_comment_count" integer, "q2_repost_count" integer, "q2_like_count" integer, "q2_created_at" timestamp with time zone, "q2_updated_at" timestamp with time zone, "q_author" "uuid", "q_author_wallet_address" "text", "q_author_display_name" "text", "q_author_avatar" "text", "q_author_avatar_thumb" "text", "q_author_stored_avatar" "text", "q_author_stored_avatar_thumb" "text", "q_author_x_username" "text", "q_message" "text", "q_translated" "jsonb", "q_rich" "jsonb", "q_comment_count" integer, "q_repost_count" integer, "q_like_count" integer, "q_created_at" timestamp with time zone, "q_updated_at" timestamp with time zone, "q_liked" boolean, "q_reposted" boolean, "author" "uuid", "author_wallet_address" "text", "author_display_name" "text", "author_avatar" "text", "author_avatar_thumb" "text", "author_stored_avatar" "text", "author_stored_avatar_thumb" "text", "author_x_username" "text", "message" "text", "translated" "jsonb", "rich" "jsonb", "comment_count" integer, "repost_count" integer, "like_count" integer, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "liked" boolean, "reposted" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.parent_post_id,
        p.quoted_post_id,

            pq.parent_post_id,
            pq.quoted_post_id,

                pq2.parent_post_id,
                pq2.quoted_post_id,

                pq2.author,
                uq2.wallet_address,
                uq2.display_name,
                uq2.avatar,
                uq2.avatar_thumb,
                uq2.stored_avatar,
                uq2.stored_avatar_thumb,
                uq2.x_username,

                pq2.message,
                pq2.translated,
                pq2.rich,
                pq2.comment_count,
                pq2.repost_count,
                pq2.like_count,
                pq2.created_at,
                pq2.updated_at,

            pq.author,
            uq.wallet_address,
            uq.display_name,
            uq.avatar,
            uq.avatar_thumb,
            uq.stored_avatar,
            uq.stored_avatar_thumb,
            uq.x_username,

            pq.message,
            pq.translated,
            pq.rich,
            pq.comment_count,
            pq.repost_count,
            pq.like_count,
            pq.created_at,
            pq.updated_at,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = pq.id AND pl.user_id = signed_user_id)
                ELSE FALSE 
            END AS liked,
            CASE 
                WHEN signed_user_id IS NOT NULL THEN 
                    EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = pq.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
                ELSE FALSE 
            END AS reposted,

        p.author,
        u.wallet_address,
        u.display_name,
        u.avatar,
        u.avatar_thumb,
        u.stored_avatar,
        u.stored_avatar_thumb,
        u.x_username,

        p.message,
        p.translated,
        p.rich,
        p.comment_count,
        p.repost_count,
        p.like_count,
        p.created_at,
        p.updated_at,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = signed_user_id)
            ELSE FALSE 
        END AS liked,
        CASE 
            WHEN signed_user_id IS NOT NULL THEN 
                EXISTS (SELECT 1 FROM posts qp WHERE qp.quoted_post_id = p.id AND qp.author = signed_user_id AND qp.message IS NULL AND qp.rich IS NULL)
            ELSE FALSE 
        END AS reposted
    FROM 
        posts p
    INNER JOIN users_public u ON p.author = u.user_id
    LEFT JOIN posts pq ON pq.id = p.quoted_post_id
    LEFT JOIN users_public uq ON pq.author = uq.user_id
    LEFT JOIN posts pq2 ON pq2.id = pq.quoted_post_id
    LEFT JOIN users_public uq2 ON pq2.author = uq2.user_id
    WHERE 
        p.author = p_user_id
        AND p.parent_post_id IS NULL
        AND (last_post_id IS NULL OR p.id < last_post_id)
    ORDER BY 
        p.id DESC
    LIMIT 
        max_count;
END;
$$;

ALTER FUNCTION "public"."get_user_posts"("p_user_id" "uuid", "last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_community_member_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update communities
  set
    member_count = member_count + 1
  where
    id = new.community_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_community_member_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_community_message_reaction_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update community_messages
  set reaction_counts = jsonb_set(
        CASE
            WHEN reaction_counts IS NULL THEN '{}'::JSONB
            ELSE reaction_counts
        END,
        ARRAY[new.reaction],
        COALESCE(
            (reaction_counts ->> new.reaction)::INT + 1,
            1
        )::TEXT::JSONB
    )
  where
    community_id = new.community_id and id = new.message_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_community_message_reaction_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_creator_holder_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update creators
  set
    holder_count = holder_count + 1
  where
    creator_address = new.creator_address;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_creator_holder_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_creator_message_reaction_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update creator_messages
  set reaction_counts = jsonb_set(
        CASE
            WHEN reaction_counts IS NULL THEN '{}'::JSONB
            ELSE reaction_counts
        END,
        ARRAY[new.reaction],
        COALESCE(
            (reaction_counts ->> new.reaction)::INT + 1,
            1
        )::TEXT::JSONB
    )
  where
    creator_address = new.creator_address and id = new.message_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_creator_message_reaction_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_follow_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update users_public
  set
    follower_count = follower_count + 1
  where
    user_id = new.followee_id;
  update users_public
  set
    following_count = following_count + 1
  where
    user_id = new.follower_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_follow_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_follower_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update users_public
  set
    follower_count = follower_count + 1
  where
    user_id = new.followee_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_follower_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_following_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update users_public
  set
    following_count = following_count + 1
  where
    user_id = new.follower_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_following_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_hashtag_holder_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update hashtags
  set
    holder_count = holder_count + 1
  where
    hashtag = new.hashtag;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_hashtag_holder_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_hashtag_message_reaction_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update hashtag_messages
  set reaction_counts = jsonb_set(
        CASE
            WHEN reaction_counts IS NULL THEN '{}'::JSONB
            ELSE reaction_counts
        END,
        ARRAY[new.reaction],
        COALESCE(
            (reaction_counts ->> new.reaction)::INT + 1,
            1
        )::TEXT::JSONB
    )
  where
    hashtag = new.hashtag and id = new.message_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_hashtag_message_reaction_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_post_comment_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  IF new.parent_post_id IS NOT NULL THEN
    update posts
    set
      comment_count = comment_count + 1
    where
      id = new.parent_post_id;
  END IF;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_post_comment_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_post_like_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update posts
  set
    like_count = like_count + 1
  where
    id = new.post_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_post_like_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_referral_points"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update users_public
  set
    points = points + 10
  where
    user_id = new.referrer_user_id;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_referral_points"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."increase_repost_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  IF new.quoted_post_id IS NOT NULL THEN
    update posts
    set
      repost_count = repost_count + 1
    where
      id = new.quoted_post_id;
  END IF;
  return null;
end;$$;

ALTER FUNCTION "public"."increase_repost_count"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_follow"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_notification_id bigint;
    v_senders uuid[];
    v_created_at timestamp;
    v_notification_interval interval := '1 hour';
begin
    SELECT id, senders, created_at INTO v_notification_id, v_senders, v_created_at
    FROM notifications
    WHERE user_id = NEW.followee_id AND type = 'follow'
    ORDER BY id DESC LIMIT 1;

    IF v_notification_id IS NOT NULL THEN
        IF v_created_at > NOW() - v_notification_interval THEN
            IF array_position(v_senders, NEW.follower_id) IS NULL THEN
                UPDATE notifications
                SET senders = array_append(v_senders, NEW.follower_id),
                    notified_at = NOW()
                WHERE id = v_notification_id;
            END IF;
        ELSE
            INSERT INTO notifications (
                user_id, type, senders
            ) VALUES (
                NEW.followee_id, 'follow', ARRAY[NEW.follower_id]
            );
        END IF;
    ELSE
        INSERT INTO notifications (
            user_id, type, senders
        ) VALUES (
            NEW.followee_id, 'follow', ARRAY[NEW.follower_id]
        );
    END IF;

    RETURN NULL;
END;$$;

ALTER FUNCTION "public"."notify_follow"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_post_comment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_parent_post_author uuid;
begin
    select author into v_parent_post_author from posts where id = new.parent_post_id;
    IF v_parent_post_author is not null THEN
        insert into notifications (
            user_id, type, target_id, senders
        ) values (
            v_parent_post_author, 'post_comment', new.id::text, ARRAY[new.author]
        );
    END IF;
    return null;
end;$$;

ALTER FUNCTION "public"."notify_post_comment"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_post_like"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_post_author uuid;
    v_notification_id bigint;
    v_senders uuid[];
    v_created_at timestamp;
    v_notification_interval interval := '1 hour';
begin
    SELECT author INTO v_post_author FROM posts WHERE id = NEW.post_id;

    IF v_post_author IS NOT NULL THEN
        SELECT id, senders, created_at INTO v_notification_id, v_senders, v_created_at
        FROM notifications
        WHERE user_id = v_post_author AND target_id = NEW.post_id::text AND type = 'post_like'
        ORDER BY id DESC LIMIT 1;

        IF v_notification_id IS NOT NULL THEN
            IF v_created_at > NOW() - v_notification_interval THEN
                IF array_position(v_senders, NEW.user_id) IS NULL THEN
                    UPDATE notifications
                    SET senders = array_append(v_senders, NEW.user_id),
                        notified_at = NOW()
                    WHERE id = v_notification_id;
                END IF;
            ELSE
                INSERT INTO notifications (
                    user_id, type, target_id, senders
                ) VALUES (
                    v_post_author, 'post_like', NEW.post_id, ARRAY[NEW.user_id]
                );
            END IF;
        ELSE
            INSERT INTO notifications (
                user_id, type, target_id, senders
            ) VALUES (
                v_post_author, 'post_like', NEW.post_id, ARRAY[NEW.user_id]
            );
        END IF;
    END IF;
    RETURN NULL;
END;$$;

ALTER FUNCTION "public"."notify_post_like"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."notify_repost"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_parent_post_author uuid;
    v_notification_id bigint;
    v_senders uuid[];
    v_notification_type text;
    v_target_id text;
    v_created_at timestamp;
    v_notification_interval interval := '1 hour';
begin
    SELECT author INTO v_parent_post_author FROM posts WHERE id = NEW.quoted_post_id;

    IF v_parent_post_author IS NOT NULL THEN
        v_notification_type := CASE WHEN NEW.message IS NULL AND NEW.rich IS NULL THEN 'repost' ELSE 'post_quote' END;
        v_target_id := CASE WHEN NEW.message IS NULL AND NEW.rich IS NULL THEN NEW.quoted_post_id ELSE NEW.id END;

        IF v_notification_type = 'repost' THEN
            SELECT id, senders, created_at INTO v_notification_id, v_senders, v_created_at
            FROM notifications
            WHERE user_id = v_parent_post_author AND target_id = v_target_id AND type = v_notification_type
            ORDER BY id DESC LIMIT 1;

            IF v_notification_id IS NOT NULL THEN
                IF v_created_at > NOW() - v_notification_interval THEN
                    IF array_position(v_senders, NEW.author) IS NULL THEN
                        UPDATE notifications
                        SET senders = array_append(v_senders, NEW.author),
                            notified_at = NOW()
                        WHERE id = v_notification_id;
                    END IF;
                ELSE
                    INSERT INTO notifications (
                        user_id, type, target_id, senders
                    ) VALUES (
                        v_parent_post_author,
                        v_notification_type,
                        v_target_id,
                        ARRAY[NEW.author]
                    );
                END IF;
            ELSE
                INSERT INTO notifications (
                    user_id, type, target_id, senders
                ) VALUES (
                    v_parent_post_author,
                    v_notification_type,
                    v_target_id,
                    ARRAY[NEW.author]
                );
            END IF;
        ELSE
            INSERT INTO notifications (
                user_id, type, target_id, senders
            ) VALUES (
                v_parent_post_author,
                v_notification_type,
                v_target_id,
                ARRAY[NEW.author]
            );
        END IF;
    END IF;
    RETURN NULL;
END;$$;

ALTER FUNCTION "public"."notify_repost"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."parse_contract_event"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_noti_receiver UUID;
    v_noti_sender UUID;
BEGIN
    IF new.contract_type = 'creator-trade' THEN
        IF new.event_name = 'Trade' THEN

            -- buy
            IF new.args[3] = 'true' THEN

                insert into creators (
                    creator_address, supply, total_trading_volume, is_price_up, last_purchased_at
                ) values (
                    new.asset_id, new.args[9]::bigint, new.args[5]::numeric, true, now()
                ) on conflict (creator_address) do update
                    set supply = new.args[9]::bigint,
                    total_trading_volume = creators.total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now();
                
                insert into creator_holders (
                    creator_address, wallet_address, last_fetched_balance
                ) values (
                    new.asset_id, new.args[1], new.args[4]::bigint
                ) on conflict (creator_address, wallet_address) do update
                    set last_fetched_balance = creator_holders.last_fetched_balance + new.args[4]::bigint;

                insert into user_wallets (
                    wallet_address, total_asset_balance, total_earned_revenue
                ) values (
                    new.args[1], new.args[4]::bigint, ('{"' || new.chain || '": "-' || new.args[5] || '"}')::JSONB
                ) on conflict (wallet_address) do update
                    set
                        total_asset_balance = user_wallets.total_asset_balance + new.args[4]::bigint,
                        total_earned_revenue = user_wallets.total_earned_revenue || jsonb_build_object(
                            new.chain, 
                            (COALESCE(user_wallets.total_earned_revenue->>new.chain, '0')::numeric - new.args[5]::numeric)::text
                        );
                
                insert into user_wallets (
                    wallet_address, total_earned_trading_fees, total_earned_revenue
                ) values (
                    new.asset_id, ('{"' || new.chain || '": "' || new.args[7] || '"}')::JSONB, ('{"' || new.chain || '": "' || new.args[7] || '"}')::JSONB
                ) on conflict (wallet_address) do update
                    set
                        total_earned_trading_fees = user_wallets.total_earned_trading_fees || jsonb_build_object(
                            new.chain, 
                            (COALESCE(user_wallets.total_earned_trading_fees->>new.chain, '0')::numeric + new.args[7]::numeric)::text
                        ),
                        total_earned_revenue = user_wallets.total_earned_revenue || jsonb_build_object(
                            new.chain, 
                            (COALESCE(user_wallets.total_earned_revenue->>new.chain, '0')::numeric + new.args[7]::numeric)::text
                        );

                -- increment points
                update users_public set
                    points = users_public.points + new.args[5]::numeric / 1000000000000000000 * 4
                where wallet_address = new.args[1];

                -- notify
                select user_id into v_noti_receiver from users_public where wallet_address = new.asset_id;
                IF v_noti_receiver is not null THEN
                    select user_id into v_noti_sender from users_public where wallet_address = new.args[1];
                    IF v_noti_sender is not null AND v_noti_sender != v_noti_receiver THEN
                        insert into notifications (
                            user_id, type, target_chain, target_id, senders, data
                        ) values (
                            v_noti_receiver, 'buy_creator', new.chain, new.asset_id, ARRAY[v_noti_sender], ('{"amount": "' || new.args[4] || '", "price": "' || new.args[5] || '"}')::JSONB
                        );
                    END IF;
                END IF;

            -- sell
            ELSE

                update creators set
                    supply = new.args[9]::bigint,
                    total_trading_volume = creators.total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where creator_address = new.asset_id;

                UPDATE creator_holders
                SET last_fetched_balance = creator_holders.last_fetched_balance - new.args[4]::bigint
                WHERE creator_address = new.asset_id
                AND wallet_address = new.args[1];

                DELETE FROM creator_holders WHERE last_fetched_balance = 0;

                update user_wallets set
                    total_asset_balance = user_wallets.total_asset_balance - new.args[4]::bigint,
                    total_earned_revenue = user_wallets.total_earned_revenue || jsonb_build_object(
                        new.chain, 
                        (COALESCE(user_wallets.total_earned_revenue->>new.chain, '0')::numeric + new.args[5]::numeric)::text
                    )
                where wallet_address = new.args[1];
                
                insert into user_wallets (
                    wallet_address, total_earned_trading_fees, total_earned_revenue
                ) values (
                    new.asset_id, ('{"' || new.chain || '": "' || new.args[7] || '"}')::JSONB, ('{"' || new.chain || '": "' || new.args[7] || '"}')::JSONB
                ) on conflict (wallet_address) do update
                    set
                        total_earned_trading_fees = user_wallets.total_earned_trading_fees || jsonb_build_object(
                            new.chain, 
                            (COALESCE(user_wallets.total_earned_trading_fees->>new.chain, '0')::numeric + new.args[7]::numeric)::text
                        ),
                        total_earned_revenue = user_wallets.total_earned_revenue || jsonb_build_object(
                            new.chain, 
                            (COALESCE(user_wallets.total_earned_revenue->>new.chain, '0')::numeric + new.args[7]::numeric)::text
                        );

                -- notify
                select user_id into v_noti_receiver from users_public where wallet_address = new.asset_id;
                IF v_noti_receiver is not null THEN
                    select user_id into v_noti_sender from users_public where wallet_address = new.args[1];
                    IF v_noti_sender is not null AND v_noti_sender != v_noti_receiver THEN
                        insert into notifications (
                            user_id, type, target_chain, target_id, senders, data
                        ) values (
                            v_noti_receiver, 'sell_creator', new.chain, new.asset_id, ARRAY[v_noti_sender], ('{"amount": "' || new.args[4] || '", "price": "' || new.args[5] || '"}')::JSONB
                        );
                    END IF;
                END IF;

            END IF;

        END IF;
    
    ELSIF new.contract_type = 'hashtag-trade' THEN
        IF new.event_name = 'Trade' THEN

            -- buy
            IF new.args[3] = 'true' THEN

                insert into hashtags (
                    hashtag, supply, total_trading_volume, is_price_up, last_purchased_at
                ) values (
                    new.asset_id, new.args[9]::bigint, new.args[5]::numeric, true, now()
                ) on conflict (hashtag) do update
                    set supply = new.args[9]::bigint,
                    total_trading_volume = hashtags.total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now();
                
                insert into hashtag_holders (
                    hashtag, wallet_address, last_fetched_balance
                ) values (
                    new.asset_id, new.args[1], new.args[4]::bigint
                ) on conflict (hashtag, wallet_address) do update
                    set last_fetched_balance = hashtag_holders.last_fetched_balance + new.args[4]::bigint;

                insert into user_wallets (
                    wallet_address, total_asset_balance, total_earned_revenue
                ) values (
                    new.args[1], new.args[4]::bigint, ('{"' || new.chain || '": "-' || new.args[5] || '"}')::JSONB
                ) on conflict (wallet_address) do update
                    set
                        total_asset_balance = user_wallets.total_asset_balance + new.args[4]::bigint,
                        total_earned_revenue = user_wallets.total_earned_revenue || jsonb_build_object(
                            new.chain, 
                            (COALESCE(user_wallets.total_earned_revenue->>new.chain, '0')::numeric - new.args[5]::numeric)::text
                        );

                -- increment points
                update users_public set
                    points = users_public.points + new.args[5]::numeric / 1000000000000000000 * 4
                where wallet_address = new.args[1];

            -- sell
            ELSE

                update hashtags set
                    supply = new.args[9]::bigint,
                    total_trading_volume = hashtags.total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where hashtag = new.asset_id;

                UPDATE hashtag_holders
                SET last_fetched_balance = hashtag_holders.last_fetched_balance - new.args[4]::bigint
                WHERE hashtag = new.asset_id
                AND wallet_address = new.args[1];

                DELETE FROM hashtag_holders WHERE last_fetched_balance = 0;

                update user_wallets set
                    total_asset_balance = user_wallets.total_asset_balance - new.args[4]::bigint,
                    total_earned_revenue = user_wallets.total_earned_revenue || jsonb_build_object(
                        new.chain, 
                        (COALESCE(user_wallets.total_earned_revenue->>new.chain, '0')::numeric + new.args[5]::numeric)::text
                    )
                where wallet_address = new.args[1];

            END IF;

        ELSIF new.event_name = 'ClaimHolderFee' THEN

            insert into user_wallets (
                wallet_address,
                total_earned_trading_fees,
                total_earned_revenue
            ) values (
                new.args[1],
                ('{"' || new.chain || '": "' || new.args[3] || '"}')::JSONB,
                ('{"' || new.chain || '": "' || new.args[3] || '"}')::JSONB
            ) on conflict (wallet_address) do update
                set
                    total_earned_trading_fees = user_wallets.total_earned_trading_fees || jsonb_build_object(
                        new.chain, 
                        (COALESCE(user_wallets.total_earned_trading_fees->>new.chain, '0')::numeric + new.args[3]::numeric)::text
                    ),
                    total_earned_revenue = user_wallets.total_earned_revenue || jsonb_build_object(
                        new.chain, 
                        (COALESCE(user_wallets.total_earned_revenue->>new.chain, '0')::numeric + new.args[3]::numeric)::text
                    );

        END IF;
    END IF;
    RETURN NULL;
end;$$;

ALTER FUNCTION "public"."parse_contract_event"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_community_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_new_id INT;
begin
  update communities set
    last_message_id = CASE WHEN communities.last_message_id is null THEN 0 ELSE communities.last_message_id + 1 END,
    last_message_sent_at = now()
  where id = new.community_id
  RETURNING last_message_id INTO v_new_id;

  new.id = v_new_id;
  return new;
end;$$;

ALTER FUNCTION "public"."set_community_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_creator_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_new_id INT;
begin
  insert into creators (
    creator_address,
    last_message_id,
    last_message_sender,
    last_message,
    last_message_sent_at
  ) values (
    new.creator_address,
    0,
    (SELECT display_name FROM public.users_public WHERE user_id = new.author),
    new.message,
    now()
  ) on conflict (creator_address) do update
    set
        last_message_id = CASE WHEN creators.last_message_id is null THEN 0 ELSE creators.last_message_id + 1 END,
        last_message_sender = (SELECT display_name FROM public.users_public WHERE user_id = new.author),
        last_message = CASE WHEN new.message is null and new.rich is not null then 'File uploaded' ELSE new.message END,
        last_message_sent_at = now()
  RETURNING last_message_id INTO v_new_id;

  new.id = v_new_id;
  return new;
end;$$;

ALTER FUNCTION "public"."set_creator_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_creator_message_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  IF new.message != old.message OR new.rich != old.rich THEN
    new.updated_at := now();
  END IF;
  RETURN new;
END;$$;

ALTER FUNCTION "public"."set_creator_message_updated_at"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_hashtag_key_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  insert into hashtag_keys (
    hashtag,
    last_message,
    last_message_sent_at
  ) values (
    new.hashtag,
    (SELECT display_name FROM public.users_public WHERE user_id = new.author) || ': ' || new.message,
    now()
  ) on conflict (hashtag) do update
    set
        last_message = (SELECT display_name FROM public.users_public WHERE user_id = new.author) || ': ' || new.message,
        last_message_sent_at = now();
  return null;
end;$$;

ALTER FUNCTION "public"."set_hashtag_key_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_hashtag_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_new_id INT;
begin
  insert into hashtags (
    hashtag,
    last_message_id,
    last_message_sender,
    last_message,
    last_message_sent_at
  ) values (
    new.hashtag,
    0,
    (SELECT display_name FROM public.users_public WHERE user_id = new.author),
    new.message,
    now()
  ) on conflict (hashtag) do update
    set
        last_message_id = CASE WHEN hashtags.last_message_id is null THEN 0 ELSE hashtags.last_message_id + 1 END,
        last_message_sender = (SELECT display_name FROM public.users_public WHERE user_id = new.author),
        last_message = CASE WHEN new.message is null and new.rich is not null then 'File uploaded' ELSE new.message END,
        last_message_sent_at = now()
  RETURNING last_message_id INTO v_new_id;

  new.id = v_new_id;
  return new;
end;$$;

ALTER FUNCTION "public"."set_hashtag_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_hashtag_message_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  IF new.message != old.message OR new.rich != old.rich THEN
    new.updated_at := now();
  END IF;
  RETURN new;
END;$$;

ALTER FUNCTION "public"."set_hashtag_message_updated_at"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_message_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  IF new.message != old.message OR new.rich != old.rich THEN
    new.updated_at := now();
  END IF;
  RETURN new;
END;$$;

ALTER FUNCTION "public"."set_message_updated_at"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  new.updated_at := now();
  RETURN new;
END;$$;

ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."set_user_metadata_to_public"() RETURNS "trigger"
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

CREATE OR REPLACE FUNCTION "public"."update_community_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  update communities
  set
      last_message_sent_at = now()
  where id = old.community_id and last_message_id = old.id;
  return null;
end;$$;

ALTER FUNCTION "public"."update_community_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."update_creator_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  update creators
  set
      last_message_sender = (SELECT display_name FROM public.users_public WHERE user_id = new.author),
      last_message = CASE WHEN new.message is null and new.rich is not null then 'File uploaded' ELSE new.message END,
      last_message_sent_at = now()
  where creator_address = old.creator_address and last_message_id = old.id;
  return null;
end;$$;

ALTER FUNCTION "public"."update_creator_last_message"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."update_hashtag_last_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  update hashtags
  set
      last_message_sender = (SELECT display_name FROM public.users_public WHERE user_id = new.author),
      last_message = CASE WHEN new.message is null and new.rich is not null then 'File uploaded' ELSE new.message END,
      last_message_sent_at = now()
  where hashtag = old.hashtag and last_message_id = old.id;
  return null;
end;$$;

ALTER FUNCTION "public"."update_hashtag_last_message"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."admins" (
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."admins" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."banned_users" (
    "user_id" "uuid" NOT NULL,
    "ban_reason" "text",
    "ban_duration" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."banned_users" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."communities" (
    "id" bigint NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "image" "text" NOT NULL,
    "image_thumb" "text" NOT NULL,
    "metadata" "jsonb" NOT NULL,
    "tokens" "jsonb" NOT NULL,
    "member_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "last_message_sent_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "last_message_id" bigint
);

ALTER TABLE "public"."communities" OWNER TO "postgres";

ALTER TABLE "public"."communities" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."communities_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."community_applications" (
    "id" bigint NOT NULL,
    "applicant" "uuid" DEFAULT "auth"."uid"(),
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "metadata" "jsonb" NOT NULL,
    "tokens" "jsonb" NOT NULL,
    "contact_info" "text" NOT NULL,
    "message" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."community_applications" OWNER TO "postgres";

ALTER TABLE "public"."community_applications" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."community_applications_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."community_chat_users" (
    "community_id" bigint NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "last_seen_message_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."community_chat_users" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."community_members" (
    "community_id" bigint NOT NULL,
    "user" "uuid" NOT NULL,
    "holding_tokens" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "holding_points" integer DEFAULT 0 NOT NULL
);

ALTER TABLE "public"."community_members" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."community_message_reactions" (
    "community_id" bigint NOT NULL,
    "message_id" bigint NOT NULL,
    "reactor" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "reaction" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."community_message_reactions" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."community_messages" (
    "community_id" bigint NOT NULL,
    "id" bigint NOT NULL,
    "parent_message_id" bigint,
    "source" "text" NOT NULL,
    "author" "uuid" DEFAULT "auth"."uid"(),
    "external_author_id" "text",
    "external_author_name" "text",
    "external_author_avatar" "text",
    "message" "text",
    "external_message_id" "text",
    "translated" "jsonb",
    "rich" "jsonb",
    "reaction_counts" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."community_messages" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."contract_events" (
    "chain" "text" NOT NULL,
    "contract_type" "text" NOT NULL,
    "block_number" bigint NOT NULL,
    "log_index" bigint NOT NULL,
    "tx" "text" NOT NULL,
    "event_name" "text" NOT NULL,
    "args" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "wallet_address" "text",
    "asset_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."contract_events" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."creator_chat_users" (
    "creator_address" "text" NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "last_seen_message_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."creator_chat_users" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."creator_holders" (
    "creator_address" "text" NOT NULL,
    "wallet_address" "text" NOT NULL,
    "last_fetched_balance" bigint DEFAULT '0'::bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."creator_holders" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."creator_message_reactions" (
    "creator_address" "text" NOT NULL,
    "message_id" bigint NOT NULL,
    "reactor" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "reaction" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."creator_message_reactions" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."creator_messages" (
    "creator_address" "text" NOT NULL,
    "id" bigint NOT NULL,
    "source" "text" NOT NULL,
    "author" "uuid" DEFAULT "auth"."uid"(),
    "external_author_id" "text",
    "external_author_name" "text",
    "external_author_avatar" "text",
    "message" "text",
    "external_message_id" "text",
    "translated" "jsonb",
    "rich" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "parent_message_id" bigint,
    "reaction_counts" "jsonb",
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."creator_messages" OWNER TO "postgres";

ALTER TABLE "public"."creator_messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."creator_messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."creators" (
    "creator_address" "text" NOT NULL,
    "supply" bigint DEFAULT '0'::bigint NOT NULL,
    "total_trading_volume" numeric DEFAULT '0'::numeric NOT NULL,
    "is_price_up" boolean,
    "last_message_id" bigint,
    "last_message_sender" "text",
    "last_message" "text",
    "last_message_sent_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "holder_count" integer DEFAULT 0 NOT NULL,
    "last_purchased_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."creators" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."fcm_subscribed_topics" (
    "user_id" "uuid" NOT NULL,
    "topic" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."fcm_subscribed_topics" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."fcm_tokens" (
    "user_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "subscribed_topics" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."fcm_tokens" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."feedbacks" (
    "id" bigint NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"(),
    "feedback" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."feedbacks" OWNER TO "postgres";

ALTER TABLE "public"."feedbacks" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."feedbacks_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."follows" (
    "follower_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "followee_id" "uuid" NOT NULL,
    "followed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."follows" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."hashtag_chat_users" (
    "hashtag" "text" NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "last_seen_message_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."hashtag_chat_users" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."hashtag_holders" (
    "hashtag" "text" NOT NULL,
    "wallet_address" "text" NOT NULL,
    "last_fetched_balance" bigint DEFAULT '0'::bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."hashtag_holders" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."hashtag_message_reactions" (
    "hashtag" "text" NOT NULL,
    "message_id" bigint NOT NULL,
    "reactor" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "reaction" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."hashtag_message_reactions" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."hashtag_messages" (
    "hashtag" "text" NOT NULL,
    "id" bigint NOT NULL,
    "source" "text" NOT NULL,
    "author" "uuid" DEFAULT "auth"."uid"(),
    "external_author_id" "text",
    "external_author_name" "text",
    "external_author_avatar" "text",
    "message" "text",
    "external_message_id" "text",
    "translated" "jsonb",
    "rich" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "parent_message_id" bigint,
    "reaction_counts" "jsonb",
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."hashtag_messages" OWNER TO "postgres";

ALTER TABLE "public"."hashtag_messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."hashtag_messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."hashtags" (
    "hashtag" "text" NOT NULL,
    "image" "text",
    "image_thumb" "text",
    "metadata" "jsonb",
    "supply" bigint DEFAULT '0'::bigint NOT NULL,
    "total_trading_volume" numeric DEFAULT '0'::numeric NOT NULL,
    "is_price_up" boolean,
    "last_message_id" bigint,
    "last_message_sender" "text",
    "last_message" "text",
    "last_message_sent_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "holder_count" integer DEFAULT 0 NOT NULL,
    "last_purchased_at" timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."hashtags" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "target_chain" "text",
    "target_id" "text",
    "senders" "uuid"[],
    "data" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notified_at" timestamp with time zone DEFAULT "now"() NOT NULL
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

CREATE TABLE IF NOT EXISTS "public"."points_marketplace_products" (
    "product_id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text" NOT NULL,
    "image" "text" NOT NULL,
    "asset_type" smallint NOT NULL,
    "asset_address" "text" NOT NULL,
    "token_id" "text",
    "price_points_per_unit" double precision NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "symbol" "text" NOT NULL
);

ALTER TABLE "public"."points_marketplace_products" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."points_marketplace_purchase_pending" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "wallet_address" "text" NOT NULL,
    "chain" "text" NOT NULL,
    "product_id" bigint NOT NULL,
    "amount" bigint NOT NULL,
    "points" double precision NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."points_marketplace_purchase_pending" OWNER TO "postgres";

ALTER TABLE "public"."points_marketplace_purchase_pending" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."points_marketplace_purchase_pending_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."post_likes" (
    "post_id" bigint NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."post_likes" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" bigint NOT NULL,
    "parent_post_id" bigint,
    "quoted_post_id" bigint,
    "author" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "message" "text",
    "translated" "jsonb",
    "rich" "jsonb",
    "comment_count" integer DEFAULT 0 NOT NULL,
    "repost_count" integer DEFAULT 0 NOT NULL,
    "like_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."posts" OWNER TO "postgres";

ALTER TABLE "public"."posts" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."posts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."referral_used" (
    "user_id" "uuid" NOT NULL,
    "referrer_user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."referral_used" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."subscribed_hashtags" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "hashtag" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."subscribed_hashtags" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."tracked_event_blocks" (
    "chain" "text" NOT NULL,
    "contract_type" "text" NOT NULL,
    "block_number" bigint NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."tracked_event_blocks" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."unsubscribed_communities" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "community_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."unsubscribed_communities" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."unsubscribed_creators" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "creator_address" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."unsubscribed_creators" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."user_wallets" (
    "wallet_address" "text" NOT NULL,
    "total_asset_balance" bigint DEFAULT '0'::bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "total_earned_trading_fees" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "total_earned_revenue" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);

ALTER TABLE "public"."user_wallets" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."users_public" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "wallet_address" "text",
    "total_earned_trading_fees" numeric DEFAULT '0'::numeric NOT NULL,
    "display_name" "text",
    "avatar" "text",
    "avatar_thumb" "text",
    "avatar_stored" boolean DEFAULT false NOT NULL,
    "stored_avatar" "text",
    "stored_avatar_thumb" "text",
    "x_username" "text",
    "metadata" "jsonb",
    "points" integer DEFAULT 0 NOT NULL,
    "blocked" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "wallet_type" "text",
    "deleted" boolean DEFAULT false NOT NULL,
    "last_sign_in_at" timestamp with time zone,
    "follower_count" integer DEFAULT 0 NOT NULL,
    "following_count" integer DEFAULT 0 NOT NULL
);

ALTER TABLE "public"."users_public" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."wallet_linking_nonces" (
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "wallet_address" "text" NOT NULL,
    "nonce" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."wallet_linking_nonces" OWNER TO "postgres";

ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."banned_users"
    ADD CONSTRAINT "banned_users_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."communities"
    ADD CONSTRAINT "communities_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."community_applications"
    ADD CONSTRAINT "community_applications_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."community_chat_users"
    ADD CONSTRAINT "community_chat_users_pkey" PRIMARY KEY ("community_id", "user_id");

ALTER TABLE ONLY "public"."community_members"
    ADD CONSTRAINT "community_members_pkey" PRIMARY KEY ("community_id", "user");

ALTER TABLE ONLY "public"."community_message_reactions"
    ADD CONSTRAINT "community_message_reactions_pkey" PRIMARY KEY ("community_id", "message_id", "reactor", "reaction");

ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_pkey" PRIMARY KEY ("community_id", "id");

ALTER TABLE ONLY "public"."contract_events"
    ADD CONSTRAINT "contract_events_pkey" PRIMARY KEY ("chain", "contract_type", "block_number", "log_index");

ALTER TABLE ONLY "public"."creator_chat_users"
    ADD CONSTRAINT "creator_chat_users_pkey" PRIMARY KEY ("creator_address", "user_id");

ALTER TABLE ONLY "public"."creator_holders"
    ADD CONSTRAINT "creator_holders_pkey" PRIMARY KEY ("creator_address", "wallet_address");

ALTER TABLE ONLY "public"."creator_message_reactions"
    ADD CONSTRAINT "creator_message_reactions_pkey" PRIMARY KEY ("creator_address", "message_id", "reactor", "reaction");

ALTER TABLE ONLY "public"."creator_messages"
    ADD CONSTRAINT "creator_messages_pkey" PRIMARY KEY ("creator_address", "id");

ALTER TABLE ONLY "public"."creators"
    ADD CONSTRAINT "creators_pkey" PRIMARY KEY ("creator_address");

ALTER TABLE ONLY "public"."fcm_subscribed_topics"
    ADD CONSTRAINT "fcm_subscribed_topics_pkey" PRIMARY KEY ("user_id", "topic");

ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_pkey" PRIMARY KEY ("user_id", "token");

ALTER TABLE ONLY "public"."feedbacks"
    ADD CONSTRAINT "feedbacks_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_pkey" PRIMARY KEY ("follower_id", "followee_id");

ALTER TABLE ONLY "public"."hashtag_chat_users"
    ADD CONSTRAINT "hashtag_chat_users_pkey" PRIMARY KEY ("hashtag", "user_id");

ALTER TABLE ONLY "public"."hashtag_holders"
    ADD CONSTRAINT "hashtag_holders_pkey" PRIMARY KEY ("hashtag", "wallet_address");

ALTER TABLE ONLY "public"."hashtag_message_reactions"
    ADD CONSTRAINT "hashtag_message_reactions_pkey" PRIMARY KEY ("hashtag", "message_id", "reactor", "reaction");

ALTER TABLE ONLY "public"."hashtag_messages"
    ADD CONSTRAINT "hashtag_messages_pkey" PRIMARY KEY ("hashtag", "id");

ALTER TABLE ONLY "public"."hashtags"
    ADD CONSTRAINT "hashtags_pkey" PRIMARY KEY ("hashtag");

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."points_marketplace_products"
    ADD CONSTRAINT "points_marketplace_products_pkey" PRIMARY KEY ("product_id");

ALTER TABLE ONLY "public"."points_marketplace_purchase_pending"
    ADD CONSTRAINT "points_marketplace_purchase_pending_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_pkey" PRIMARY KEY ("post_id", "user_id");

ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."referral_used"
    ADD CONSTRAINT "referral_used_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."subscribed_hashtags"
    ADD CONSTRAINT "subscribed_hashtags_pkey" PRIMARY KEY ("user_id", "hashtag");

ALTER TABLE ONLY "public"."tracked_event_blocks"
    ADD CONSTRAINT "tracked_event_blocks_pkey" PRIMARY KEY ("chain", "contract_type");

ALTER TABLE ONLY "public"."unsubscribed_communities"
    ADD CONSTRAINT "unsubscribed_communities_pkey" PRIMARY KEY ("user_id", "community_id");

ALTER TABLE ONLY "public"."unsubscribed_creators"
    ADD CONSTRAINT "unsubscribed_creators_pkey" PRIMARY KEY ("user_id", "creator_address");

ALTER TABLE ONLY "public"."user_wallets"
    ADD CONSTRAINT "user_wallets_pkey" PRIMARY KEY ("wallet_address");

ALTER TABLE ONLY "public"."users_public"
    ADD CONSTRAINT "users_public_pkey" PRIMARY KEY ("user_id");

ALTER TABLE ONLY "public"."users_public"
    ADD CONSTRAINT "users_public_wallet_address_key" UNIQUE ("wallet_address");

ALTER TABLE ONLY "public"."wallet_linking_nonces"
    ADD CONSTRAINT "wallet_linking_nonces_pkey" PRIMARY KEY ("user_id");

CREATE INDEX "posts_parent_post_id_idx" ON "public"."posts" USING "btree" ("parent_post_id");

CREATE INDEX "posts_quoted_post_id_idx" ON "public"."posts" USING "btree" ("quoted_post_id");

CREATE OR REPLACE TRIGGER "create_creator" AFTER UPDATE ON "public"."users_public" FOR EACH ROW EXECUTE FUNCTION "public"."create_creator"();

CREATE OR REPLACE TRIGGER "decrease_community_member_count" AFTER DELETE ON "public"."community_members" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_community_member_count"();

CREATE OR REPLACE TRIGGER "decrease_creator_holder_count" AFTER DELETE ON "public"."creator_holders" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_creator_holder_count"();

CREATE OR REPLACE TRIGGER "decrease_follow_count" AFTER DELETE ON "public"."follows" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_follow_count"();

CREATE OR REPLACE TRIGGER "decrease_hashtag_holder_count" AFTER DELETE ON "public"."hashtag_holders" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_hashtag_holder_count"();

CREATE OR REPLACE TRIGGER "decrease_post_comment_count" AFTER DELETE ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_post_comment_count"();

CREATE OR REPLACE TRIGGER "decrease_post_like_count" AFTER DELETE ON "public"."post_likes" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_post_like_count"();

CREATE OR REPLACE TRIGGER "decrease_repost_count" AFTER DELETE ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_repost_count"();

CREATE OR REPLACE TRIGGER "delete_creator_last_message" AFTER DELETE ON "public"."creator_messages" FOR EACH ROW EXECUTE FUNCTION "public"."delete_creator_last_message"();

CREATE OR REPLACE TRIGGER "delete_hashtag_last_message" AFTER DELETE ON "public"."hashtag_messages" FOR EACH ROW EXECUTE FUNCTION "public"."delete_hashtag_last_message"();

CREATE OR REPLACE TRIGGER "increase_community_member_count" AFTER INSERT ON "public"."community_members" FOR EACH ROW EXECUTE FUNCTION "public"."increase_community_member_count"();

CREATE OR REPLACE TRIGGER "increase_creator_holder_count" AFTER INSERT ON "public"."creator_holders" FOR EACH ROW EXECUTE FUNCTION "public"."increase_creator_holder_count"();

CREATE OR REPLACE TRIGGER "increase_follow_count" AFTER INSERT ON "public"."follows" FOR EACH ROW EXECUTE FUNCTION "public"."increase_follow_count"();

CREATE OR REPLACE TRIGGER "increase_hashtag_holder_count" AFTER INSERT ON "public"."hashtag_holders" FOR EACH ROW EXECUTE FUNCTION "public"."increase_hashtag_holder_count"();

CREATE OR REPLACE TRIGGER "increase_post_comment_count" AFTER INSERT ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."increase_post_comment_count"();

CREATE OR REPLACE TRIGGER "increase_post_like_count" AFTER INSERT ON "public"."post_likes" FOR EACH ROW EXECUTE FUNCTION "public"."increase_post_like_count"();

CREATE OR REPLACE TRIGGER "increase_referral_points" AFTER INSERT ON "public"."referral_used" FOR EACH ROW EXECUTE FUNCTION "public"."increase_referral_points"();

CREATE OR REPLACE TRIGGER "increase_repost_count" AFTER INSERT ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."increase_repost_count"();

CREATE OR REPLACE TRIGGER "insert_community_application_webhook" AFTER INSERT ON "public"."community_applications" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/insert-data-webhook', 'POST', '{"Content-type":"application/json"}', '{"secret":"f4d19080-75f5-450b-ae9b-86c5577864f8"}', '1000');

CREATE OR REPLACE TRIGGER "insert_contract_event_webhook" AFTER INSERT ON "public"."contract_events" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/insert-data-webhook', 'POST', '{"Content-type":"application/json"}', '{"secret":"f4d19080-75f5-450b-ae9b-86c5577864f8"}', '1000');

CREATE OR REPLACE TRIGGER "insert_creator_message_webhook" AFTER INSERT ON "public"."creator_messages" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/insert-data-webhook', 'POST', '{"Content-type":"application/json"}', '{"secret":"f4d19080-75f5-450b-ae9b-86c5577864f8"}', '1000');

CREATE OR REPLACE TRIGGER "insert_feedback_webhook" AFTER INSERT ON "public"."feedbacks" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/insert-data-webhook', 'POST', '{"Content-type":"application/json"}', '{"secret":"f4d19080-75f5-450b-ae9b-86c5577864f8"}', '1000');

CREATE OR REPLACE TRIGGER "insert_hashtag_message_webhook" AFTER INSERT ON "public"."hashtag_messages" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/insert-data-webhook', 'POST', '{"Content-type":"application/json"}', '{"secret":"f4d19080-75f5-450b-ae9b-86c5577864f8"}', '1000');

CREATE OR REPLACE TRIGGER "insert_post_like_webhook" AFTER INSERT ON "public"."post_likes" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/insert-data-webhook', 'POST', '{"Content-type":"application/json"}', '{"secret":"f4d19080-75f5-450b-ae9b-86c5577864f8"}', '1000');

CREATE OR REPLACE TRIGGER "insert_post_webhook" AFTER INSERT ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://dwzrduviqvesskxhtcbu.supabase.co/functions/v1/insert-data-webhook', 'POST', '{"Content-type":"application/json"}', '{"secret":"f4d19080-75f5-450b-ae9b-86c5577864f8"}', '1000');

CREATE OR REPLACE TRIGGER "notify_follow" AFTER INSERT ON "public"."follows" FOR EACH ROW EXECUTE FUNCTION "public"."notify_follow"();

CREATE OR REPLACE TRIGGER "notify_post_comment" AFTER INSERT ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."notify_post_comment"();

CREATE OR REPLACE TRIGGER "notify_post_like" AFTER INSERT ON "public"."post_likes" FOR EACH ROW EXECUTE FUNCTION "public"."notify_post_like"();

CREATE OR REPLACE TRIGGER "notify_repost" AFTER INSERT ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."notify_repost"();

CREATE OR REPLACE TRIGGER "parse_contract_event" AFTER INSERT ON "public"."contract_events" FOR EACH ROW EXECUTE FUNCTION "public"."parse_contract_event"();

CREATE OR REPLACE TRIGGER "set_communities_updated_at" BEFORE UPDATE ON "public"."communities" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_community_last_message" BEFORE INSERT ON "public"."community_messages" FOR EACH ROW EXECUTE FUNCTION "public"."set_community_last_message"();

CREATE OR REPLACE TRIGGER "set_community_members_updated_at" BEFORE UPDATE ON "public"."community_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_creator_holders_updated_at" BEFORE UPDATE ON "public"."creator_holders" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_creator_last_message" BEFORE INSERT ON "public"."creator_messages" FOR EACH ROW EXECUTE FUNCTION "public"."set_creator_last_message"();

CREATE OR REPLACE TRIGGER "set_creator_message_updated_at" BEFORE UPDATE ON "public"."creator_messages" FOR EACH ROW EXECUTE FUNCTION "public"."set_creator_message_updated_at"();

CREATE OR REPLACE TRIGGER "set_creators_updated_at" BEFORE UPDATE ON "public"."creators" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_hashtag_holders_updated_at" BEFORE UPDATE ON "public"."hashtag_holders" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_hashtag_last_message" BEFORE INSERT ON "public"."hashtag_messages" FOR EACH ROW EXECUTE FUNCTION "public"."set_hashtag_last_message"();

CREATE OR REPLACE TRIGGER "set_hashtag_message_updated_at" BEFORE UPDATE ON "public"."hashtag_messages" FOR EACH ROW EXECUTE FUNCTION "public"."set_hashtag_message_updated_at"();

CREATE OR REPLACE TRIGGER "set_hashtags_updated_at" BEFORE UPDATE ON "public"."hashtags" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_message_updated_at" BEFORE UPDATE ON "public"."community_messages" FOR EACH ROW EXECUTE FUNCTION "public"."set_message_updated_at"();

CREATE OR REPLACE TRIGGER "set_posts_updated_at" BEFORE UPDATE ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_tracked_event_blocks_updated_at" BEFORE UPDATE ON "public"."tracked_event_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_user_wallets_updated_at" BEFORE UPDATE ON "public"."user_wallets" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "set_users_public_updated_at" BEFORE UPDATE ON "public"."users_public" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

CREATE OR REPLACE TRIGGER "trigger_decrease_community_message_reaction_count" AFTER DELETE ON "public"."community_message_reactions" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_community_message_reaction_count"();

CREATE OR REPLACE TRIGGER "trigger_decrease_creator_message_reaction_count" AFTER DELETE ON "public"."creator_message_reactions" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_creator_message_reaction_count"();

CREATE OR REPLACE TRIGGER "trigger_decrease_hashtag_message_reaction_count" AFTER DELETE ON "public"."hashtag_message_reactions" FOR EACH ROW EXECUTE FUNCTION "public"."decrease_hashtag_message_reaction_count"();

CREATE OR REPLACE TRIGGER "trigger_increase_community_message_reaction_count" AFTER INSERT ON "public"."community_message_reactions" FOR EACH ROW EXECUTE FUNCTION "public"."increase_community_message_reaction_count"();

CREATE OR REPLACE TRIGGER "trigger_increase_creator_message_reaction_count" AFTER INSERT ON "public"."creator_message_reactions" FOR EACH ROW EXECUTE FUNCTION "public"."increase_creator_message_reaction_count"();

CREATE OR REPLACE TRIGGER "trigger_increase_hashtag_message_reaction_count" AFTER INSERT ON "public"."hashtag_message_reactions" FOR EACH ROW EXECUTE FUNCTION "public"."increase_hashtag_message_reaction_count"();

CREATE OR REPLACE TRIGGER "update_community_last_message" AFTER UPDATE ON "public"."community_messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_community_last_message"();

CREATE OR REPLACE TRIGGER "update_creator_last_message" AFTER UPDATE ON "public"."creator_messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_creator_last_message"();

CREATE OR REPLACE TRIGGER "update_hashtag_last_message" AFTER UPDATE ON "public"."hashtag_messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_hashtag_last_message"();

ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."banned_users"
    ADD CONSTRAINT "banned_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."community_applications"
    ADD CONSTRAINT "community_applications_applicant_fkey" FOREIGN KEY ("applicant") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."community_members"
    ADD CONSTRAINT "community_members_user_id_fkey" FOREIGN KEY ("user") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."community_message_reactions"
    ADD CONSTRAINT "community_message_reactions_reactor_fkey" FOREIGN KEY ("reactor") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_author_fkey" FOREIGN KEY ("author") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."creator_message_reactions"
    ADD CONSTRAINT "creator_message_reactions_reactor_fkey" FOREIGN KEY ("reactor") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."creator_messages"
    ADD CONSTRAINT "creator_messages_author_fkey" FOREIGN KEY ("author") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."fcm_subscribed_topics"
    ADD CONSTRAINT "fcm_subscribed_topics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."feedbacks"
    ADD CONSTRAINT "feedbacks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_followee_id_fkey" FOREIGN KEY ("followee_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."follows"
    ADD CONSTRAINT "follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."hashtag_message_reactions"
    ADD CONSTRAINT "hashtag_message_reactions_reactor_fkey" FOREIGN KEY ("reactor") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."hashtag_messages"
    ADD CONSTRAINT "hashtag_messages_author_fkey" FOREIGN KEY ("author") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."points_marketplace_purchase_pending"
    ADD CONSTRAINT "points_marketplace_purchase_pending_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."points_marketplace_products"("product_id");

ALTER TABLE ONLY "public"."points_marketplace_purchase_pending"
    ADD CONSTRAINT "points_marketplace_purchase_pending_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_author_fkey" FOREIGN KEY ("author") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."subscribed_hashtags"
    ADD CONSTRAINT "subscribed_hashtags_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."unsubscribed_communities"
    ADD CONSTRAINT "unsubscribed_communities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."unsubscribed_creators"
    ADD CONSTRAINT "unsubscribed_creators_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE ONLY "public"."users_public"
    ADD CONSTRAINT "users_public_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."wallet_linking_nonces"
    ADD CONSTRAINT "wallet_linking_nonces_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users_public"("user_id");

ALTER TABLE "public"."admins" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."banned_users" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "can add reaction only authed" ON "public"."community_message_reactions" FOR INSERT TO "authenticated" WITH CHECK (("reactor" = "auth"."uid"()));

CREATE POLICY "can add reaction only authed" ON "public"."creator_message_reactions" FOR INSERT TO "authenticated" WITH CHECK (("reactor" = "auth"."uid"()));

CREATE POLICY "can add reaction only authed" ON "public"."hashtag_message_reactions" FOR INSERT TO "authenticated" WITH CHECK (("reactor" = "auth"."uid"()));

CREATE POLICY "can delete only authed" ON "public"."community_messages" FOR DELETE TO "authenticated" USING (("author" = "auth"."uid"()));

CREATE POLICY "can delete only authed" ON "public"."creator_messages" FOR DELETE TO "authenticated" USING (("author" = "auth"."uid"()));

CREATE POLICY "can delete only authed" ON "public"."hashtag_messages" FOR DELETE TO "authenticated" USING (("author" = "auth"."uid"()));

CREATE POLICY "can delete only authed" ON "public"."posts" FOR DELETE TO "authenticated" USING (("author" = "auth"."uid"()));

CREATE POLICY "can delete only authed" ON "public"."subscribed_hashtags" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can delete only authed" ON "public"."unsubscribed_communities" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can delete only authed" ON "public"."unsubscribed_creators" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can follow only follower" ON "public"."follows" FOR INSERT TO "authenticated" WITH CHECK ((("follower_id" = "auth"."uid"()) AND ("follower_id" <> "followee_id")));

CREATE POLICY "can like only authed" ON "public"."post_likes" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "can remove reaction only authed" ON "public"."community_message_reactions" FOR DELETE TO "authenticated" USING (("reactor" = "auth"."uid"()));

CREATE POLICY "can remove reaction only authed" ON "public"."creator_message_reactions" FOR DELETE TO "authenticated" USING (("reactor" = "auth"."uid"()));

CREATE POLICY "can remove reaction only authed" ON "public"."hashtag_message_reactions" FOR DELETE TO "authenticated" USING (("reactor" = "auth"."uid"()));

CREATE POLICY "can unfollow only follower" ON "public"."follows" FOR DELETE TO "authenticated" USING (("follower_id" = "auth"."uid"()));

CREATE POLICY "can unlike only authed" ON "public"."post_likes" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can update only authed" ON "public"."community_messages" FOR UPDATE TO "authenticated" USING ((((("message" IS NOT NULL) AND ("message" <> ''::"text") AND ("length"("message") <= 1000)) OR (("message" IS NULL) AND ("rich" IS NOT NULL))) AND ("author" = "auth"."uid"())));

CREATE POLICY "can update only authed" ON "public"."creator_messages" FOR UPDATE TO "authenticated" USING (("author" = "auth"."uid"()));

CREATE POLICY "can update only authed" ON "public"."hashtag_messages" FOR UPDATE TO "authenticated" USING (("author" = "auth"."uid"()));

CREATE POLICY "can update only authed" ON "public"."posts" FOR UPDATE TO "authenticated" USING ((((("message" IS NOT NULL) AND ("message" <> ''::"text") AND ("length"("message") <= 2000)) OR (("message" IS NULL) AND ("rich" IS NOT NULL))) AND ("author" = "auth"."uid"())));

CREATE POLICY "can view only admin" ON "public"."community_applications" FOR SELECT TO "authenticated" USING ((( SELECT "admins"."user_id"
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"())) IS NOT NULL));

CREATE POLICY "can view only admin" ON "public"."feedbacks" FOR SELECT TO "authenticated" USING ((( SELECT "admins"."user_id"
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"())) IS NOT NULL));

CREATE POLICY "can view only referrer" ON "public"."referral_used" FOR SELECT USING (("referrer_user_id" = "auth"."uid"()));

CREATE POLICY "can view only user" ON "public"."fcm_subscribed_topics" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can view only user" ON "public"."fcm_tokens" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can view only user" ON "public"."notifications" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can view only user" ON "public"."subscribed_hashtags" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can view only user" ON "public"."unsubscribed_communities" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can view only user" ON "public"."unsubscribed_creators" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));

CREATE POLICY "can write everyone" ON "public"."community_applications" FOR INSERT WITH CHECK (true);

CREATE POLICY "can write everyone" ON "public"."feedbacks" FOR INSERT WITH CHECK (true);

CREATE POLICY "can write only authed" ON "public"."hashtag_messages" FOR INSERT TO "authenticated" WITH CHECK ((("length"("hashtag") < 32) AND ((("message" IS NOT NULL) AND ("message" <> ''::"text") AND ("length"("message") <= 1000)) OR (("message" IS NULL) AND ("rich" IS NOT NULL))) AND ("author" = "auth"."uid"()) AND (( SELECT "banned_users"."user_id"
   FROM "public"."banned_users"
  WHERE ("banned_users"."user_id" = "auth"."uid"())) IS NULL)));

CREATE POLICY "can write only authed" ON "public"."posts" FOR INSERT TO "authenticated" WITH CHECK ((((("message" IS NOT NULL) AND ("message" <> ''::"text") AND ("length"("message") <= 2000)) OR (("message" IS NULL) AND ("rich" IS NOT NULL)) OR (("message" IS NULL) AND ("quoted_post_id" IS NOT NULL))) AND ("author" = "auth"."uid"()) AND (( SELECT "banned_users"."user_id"
   FROM "public"."banned_users"
  WHERE ("banned_users"."user_id" = "auth"."uid"())) IS NULL)));

CREATE POLICY "can write only authed" ON "public"."subscribed_hashtags" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "can write only authed" ON "public"."unsubscribed_communities" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "can write only authed" ON "public"."unsubscribed_creators" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "check hashtag length" ON "public"."hashtag_holders" FOR INSERT WITH CHECK (("length"("hashtag") < 32));

CREATE POLICY "check hashtag length" ON "public"."hashtags" FOR INSERT WITH CHECK (("length"("hashtag") < 32));

ALTER TABLE "public"."communities" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."community_applications" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."community_chat_users" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."community_members" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."community_message_reactions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."community_messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."contract_events" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creator_chat_users" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creator_holders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creator_message_reactions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creator_messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."creators" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."fcm_subscribed_topics" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."fcm_tokens" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."feedbacks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."follows" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."hashtag_chat_users" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."hashtag_holders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."hashtag_message_reactions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."hashtag_messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."hashtags" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "only authed" ON "public"."community_chat_users" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "only authed" ON "public"."creator_chat_users" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "only authed" ON "public"."hashtag_chat_users" FOR INSERT TO "authenticated" WITH CHECK ((("length"("hashtag") < 32) AND ("user_id" = "auth"."uid"())));

CREATE POLICY "only user" ON "public"."community_chat_users" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "only user" ON "public"."creator_chat_users" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "only user" ON "public"."hashtag_chat_users" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));

ALTER TABLE "public"."points_marketplace_products" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."points_marketplace_purchase_pending" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."post_likes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."posts" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."referral_used" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."subscribed_hashtags" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tracked_event_blocks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."unsubscribed_communities" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."unsubscribed_creators" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."user_wallets" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."users_public" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "view everyone" ON "public"."communities" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."community_chat_users" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."community_members" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."community_message_reactions" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."contract_events" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."creator_chat_users" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."creator_holders" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."creator_message_reactions" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."creators" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."follows" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."hashtag_chat_users" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."hashtag_holders" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."hashtag_message_reactions" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."hashtag_messages" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."hashtags" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."points_marketplace_products" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."post_likes" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."posts" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."user_wallets" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."users_public" FOR SELECT USING (true);

CREATE POLICY "view only holder or owner" ON "public"."community_messages" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."user" = "auth"."uid"())))));

CREATE POLICY "view only holder or owner" ON "public"."creator_messages" FOR SELECT TO "authenticated" USING ((("creator_address" = ( SELECT "users_public"."wallet_address"
   FROM "public"."users_public"
  WHERE ("users_public"."user_id" = "auth"."uid"()))) OR ((1)::numeric <= (( SELECT "creator_holders"."last_fetched_balance"
   FROM "public"."creator_holders"
  WHERE (("creator_holders"."creator_address" = "creator_messages"."creator_address") AND ("creator_holders"."wallet_address" = ( SELECT "users_public"."wallet_address"
           FROM "public"."users_public"
          WHERE ("users_public"."user_id" = "auth"."uid"()))))))::numeric)));

ALTER TABLE "public"."wallet_linking_nonces" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "write only holder or owner" ON "public"."community_messages" FOR INSERT TO "authenticated" WITH CHECK ((((("message" IS NOT NULL) AND ("message" <> ''::"text") AND ("length"("message") <= 1000)) OR (("message" IS NULL) AND ("rich" IS NOT NULL))) AND ("author" = "auth"."uid"()) AND (( SELECT "banned_users"."user_id"
   FROM "public"."banned_users"
  WHERE ("banned_users"."user_id" = "auth"."uid"())) IS NULL) AND (EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."user" = "auth"."uid"()))))));

CREATE POLICY "write only holder or owner" ON "public"."creator_messages" FOR INSERT TO "authenticated" WITH CHECK ((((("message" IS NOT NULL) AND ("message" <> ''::"text") AND ("length"("message") <= 1000)) OR (("message" IS NULL) AND ("rich" IS NOT NULL))) AND ("author" = "auth"."uid"()) AND (( SELECT "banned_users"."user_id"
   FROM "public"."banned_users"
  WHERE ("banned_users"."user_id" = "auth"."uid"())) IS NULL) AND (("creator_address" = ( SELECT "users_public"."wallet_address"
   FROM "public"."users_public"
  WHERE ("users_public"."user_id" = "auth"."uid"()))) OR ((1)::numeric <= (( SELECT "creator_holders"."last_fetched_balance"
   FROM "public"."creator_holders"
  WHERE (("creator_holders"."creator_address" = "creator_messages"."creator_address") AND ("creator_holders"."wallet_address" = ( SELECT "users_public"."wallet_address"
           FROM "public"."users_public"
          WHERE ("users_public"."user_id" = "auth"."uid"()))))))::numeric))));

ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."community_messages";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."contract_events";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."creator_messages";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."hashtag_messages";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."notifications";

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."create_creator"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_creator"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_creator"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_community_member_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_community_member_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_community_member_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_community_message_reaction_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_community_message_reaction_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_community_message_reaction_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_creator_holder_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_creator_holder_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_creator_holder_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_creator_message_reaction_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_creator_message_reaction_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_creator_message_reaction_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_follow_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_follow_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_follow_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_follower_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_follower_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_follower_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_following_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_following_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_following_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_hashtag_holder_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_hashtag_holder_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_hashtag_holder_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_hashtag_message_reaction_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_hashtag_message_reaction_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_hashtag_message_reaction_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_post_comment_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_post_comment_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_post_comment_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_post_like_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_post_like_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_post_like_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."decrease_repost_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_repost_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_repost_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."delete_creator_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_creator_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_creator_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."delete_hashtag_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_hashtag_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_hashtag_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_all_referees"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_all_referees"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_all_referees"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_asset_contract_events"("p_chain" "text", "p_contract_type" "text", "p_asset_id" "text", "last_created_at" timestamp with time zone, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_asset_contract_events"("p_chain" "text", "p_contract_type" "text", "p_asset_id" "text", "last_created_at" timestamp with time zone, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_asset_contract_events"("p_chain" "text", "p_contract_type" "text", "p_asset_id" "text", "last_created_at" timestamp with time zone, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_communities"("last_member_count" integer, "max_count" integer, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_communities"("last_member_count" integer, "max_count" integer, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_communities"("last_member_count" integer, "max_count" integer, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_community"("p_community_id" bigint, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_community"("p_community_id" bigint, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_community"("p_community_id" bigint, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_community_by_slug"("p_slug" "text", "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_community_by_slug"("p_slug" "text", "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_community_by_slug"("p_slug" "text", "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_community_message"("p_community_id" bigint, "p_message_id" bigint, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_community_message"("p_community_id" bigint, "p_message_id" bigint, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_community_message"("p_community_id" bigint, "p_message_id" bigint, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_community_messages"("p_community_id" bigint, "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_community_messages"("p_community_id" bigint, "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_community_messages"("p_community_id" bigint, "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_contract_event"("p_chain" "text", "p_contract_type" "text", "p_block_number" bigint, "p_log_index" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_contract_event"("p_chain" "text", "p_contract_type" "text", "p_block_number" bigint, "p_log_index" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_contract_event"("p_chain" "text", "p_contract_type" "text", "p_block_number" bigint, "p_log_index" bigint) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_contract_events_recently"("last_created_at" timestamp with time zone, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_contract_events_recently"("last_created_at" timestamp with time zone, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_contract_events_recently"("last_created_at" timestamp with time zone, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_creator"("p_creator_address" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_creator"("p_creator_address" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_creator"("p_creator_address" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_creator_holders"("p_creator_address" "text", "last_balance" bigint, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_creator_holders"("p_creator_address" "text", "last_balance" bigint, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_creator_holders"("p_creator_address" "text", "last_balance" bigint, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_creator_message"("p_creator_address" "text", "p_message_id" bigint, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_creator_message"("p_creator_address" "text", "p_message_id" bigint, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_creator_message"("p_creator_address" "text", "p_message_id" bigint, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_creator_messages"("p_creator_address" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_creator_messages"("p_creator_address" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_creator_messages"("p_creator_address" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_followers"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_followers"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_followers"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_following_users"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_following_users"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_following_users"("p_user_id" "uuid", "last_followed_at" timestamp with time zone, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_global_activities"("last_created_at" timestamp with time zone, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_global_activities"("last_created_at" timestamp with time zone, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_global_activities"("last_created_at" timestamp with time zone, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_hashtag_holders"("p_hashtag" "text", "last_balance" bigint, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_hashtag_holders"("p_hashtag" "text", "last_balance" bigint, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_hashtag_holders"("p_hashtag" "text", "last_balance" bigint, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_hashtag_leaderboard"("last_rank" integer, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_hashtag_leaderboard"("last_rank" integer, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_hashtag_leaderboard"("last_rank" integer, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_hashtag_message"("p_hashtag" "text", "p_message_id" bigint, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_hashtag_message"("p_hashtag" "text", "p_message_id" bigint, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_hashtag_message"("p_hashtag" "text", "p_message_id" bigint, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_hashtag_messages"("p_hashtag" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_hashtag_messages"("p_hashtag" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_hashtag_messages"("p_hashtag" "text", "last_message_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_holding_assets"("p_wallet_address" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_holding_assets"("p_wallet_address" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_holding_assets"("p_wallet_address" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_holding_creators"("p_wallet_address" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_holding_creators"("p_wallet_address" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_holding_creators"("p_wallet_address" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_holding_hashtags"("p_wallet_address" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_holding_hashtags"("p_wallet_address" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_holding_hashtags"("p_wallet_address" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_key_holders"("p_key_type" smallint, "p_reference_key" "text", "last_balance" numeric, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_key_holders"("p_key_type" smallint, "p_reference_key" "text", "last_balance" numeric, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_key_holders"("p_key_type" smallint, "p_reference_key" "text", "last_balance" numeric, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_new_assets"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_new_assets"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_new_assets"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_point_rank"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_point_rank"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_point_rank"("p_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_post_thread"("p_post_id" bigint, "max_comment_count" integer, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_post_thread"("p_post_id" bigint, "max_comment_count" integer, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_post_thread"("p_post_id" bigint, "max_comment_count" integer, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_posts_following"("signed_user_id" "uuid", "last_post_id" bigint, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_posts_following"("signed_user_id" "uuid", "last_post_id" bigint, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_posts_following"("signed_user_id" "uuid", "last_post_id" bigint, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_posts_for_you"("last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_posts_for_you"("last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_posts_for_you"("last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."get_signed_user_notifications"("signed_user_id" "uuid", "last_notification_id" bigint, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_signed_user_notifications"("signed_user_id" "uuid", "last_notification_id" bigint, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_signed_user_notifications"("signed_user_id" "uuid", "last_notification_id" bigint, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_target_activities"("p_key_type" smallint, "p_reference_key" "text", "last_created_at" timestamp with time zone, "max_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_target_activities"("p_key_type" smallint, "p_reference_key" "text", "last_created_at" timestamp with time zone, "max_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_target_activities"("p_key_type" smallint, "p_reference_key" "text", "last_created_at" timestamp with time zone, "max_count" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."get_top_assets"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_top_assets"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_top_assets"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_trending_assets"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_trending_assets"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_trending_assets"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_user_posts"("p_user_id" "uuid", "last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_posts"("p_user_id" "uuid", "last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_posts"("p_user_id" "uuid", "last_post_id" bigint, "max_count" integer, "signed_user_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_community_member_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_community_member_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_community_member_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_community_message_reaction_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_community_message_reaction_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_community_message_reaction_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_creator_holder_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_creator_holder_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_creator_holder_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_creator_message_reaction_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_creator_message_reaction_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_creator_message_reaction_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_follow_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_follow_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_follow_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_follower_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_follower_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_follower_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_following_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_following_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_following_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_hashtag_holder_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_hashtag_holder_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_hashtag_holder_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_hashtag_message_reaction_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_hashtag_message_reaction_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_hashtag_message_reaction_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_post_comment_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_post_comment_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_post_comment_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_post_like_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_post_like_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_post_like_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_referral_points"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_referral_points"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_referral_points"() TO "service_role";

GRANT ALL ON FUNCTION "public"."increase_repost_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increase_repost_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_repost_count"() TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_follow"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_follow"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_follow"() TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_post_comment"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_post_comment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_post_comment"() TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_post_like"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_post_like"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_post_like"() TO "service_role";

GRANT ALL ON FUNCTION "public"."notify_repost"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_repost"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_repost"() TO "service_role";

GRANT ALL ON FUNCTION "public"."parse_contract_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."parse_contract_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."parse_contract_event"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_community_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_community_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_community_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_creator_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_creator_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_creator_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_creator_message_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_creator_message_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_creator_message_updated_at"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_hashtag_key_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_hashtag_key_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_hashtag_key_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_hashtag_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_hashtag_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_hashtag_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_hashtag_message_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_hashtag_message_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_hashtag_message_updated_at"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_message_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_message_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_message_updated_at"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";

GRANT ALL ON FUNCTION "public"."set_user_metadata_to_public"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_user_metadata_to_public"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_user_metadata_to_public"() TO "service_role";

GRANT ALL ON FUNCTION "public"."update_community_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_community_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_community_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."update_creator_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_creator_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_creator_last_message"() TO "service_role";

GRANT ALL ON FUNCTION "public"."update_hashtag_last_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_hashtag_last_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_hashtag_last_message"() TO "service_role";

GRANT ALL ON TABLE "public"."admins" TO "anon";
GRANT ALL ON TABLE "public"."admins" TO "authenticated";
GRANT ALL ON TABLE "public"."admins" TO "service_role";

GRANT ALL ON TABLE "public"."banned_users" TO "anon";
GRANT ALL ON TABLE "public"."banned_users" TO "authenticated";
GRANT ALL ON TABLE "public"."banned_users" TO "service_role";

GRANT ALL ON TABLE "public"."communities" TO "anon";
GRANT ALL ON TABLE "public"."communities" TO "authenticated";
GRANT ALL ON TABLE "public"."communities" TO "service_role";

GRANT ALL ON SEQUENCE "public"."communities_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."communities_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."communities_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."community_applications" TO "anon";
GRANT ALL ON TABLE "public"."community_applications" TO "authenticated";
GRANT ALL ON TABLE "public"."community_applications" TO "service_role";

GRANT ALL ON SEQUENCE "public"."community_applications_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."community_applications_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."community_applications_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."community_chat_users" TO "anon";
GRANT ALL ON TABLE "public"."community_chat_users" TO "authenticated";
GRANT ALL ON TABLE "public"."community_chat_users" TO "service_role";

GRANT ALL ON TABLE "public"."community_members" TO "anon";
GRANT ALL ON TABLE "public"."community_members" TO "authenticated";
GRANT ALL ON TABLE "public"."community_members" TO "service_role";

GRANT ALL ON TABLE "public"."community_message_reactions" TO "anon";
GRANT ALL ON TABLE "public"."community_message_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."community_message_reactions" TO "service_role";

GRANT ALL ON TABLE "public"."community_messages" TO "anon";
GRANT ALL ON TABLE "public"."community_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."community_messages" TO "service_role";

GRANT ALL ON TABLE "public"."contract_events" TO "anon";
GRANT ALL ON TABLE "public"."contract_events" TO "authenticated";
GRANT ALL ON TABLE "public"."contract_events" TO "service_role";

GRANT ALL ON TABLE "public"."creator_chat_users" TO "anon";
GRANT ALL ON TABLE "public"."creator_chat_users" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_chat_users" TO "service_role";

GRANT ALL ON TABLE "public"."creator_holders" TO "anon";
GRANT ALL ON TABLE "public"."creator_holders" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_holders" TO "service_role";

GRANT ALL ON TABLE "public"."creator_message_reactions" TO "anon";
GRANT ALL ON TABLE "public"."creator_message_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_message_reactions" TO "service_role";

GRANT ALL ON TABLE "public"."creator_messages" TO "anon";
GRANT ALL ON TABLE "public"."creator_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."creator_messages" TO "service_role";

GRANT ALL ON SEQUENCE "public"."creator_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."creator_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."creator_messages_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."creators" TO "anon";
GRANT ALL ON TABLE "public"."creators" TO "authenticated";
GRANT ALL ON TABLE "public"."creators" TO "service_role";

GRANT ALL ON TABLE "public"."fcm_subscribed_topics" TO "anon";
GRANT ALL ON TABLE "public"."fcm_subscribed_topics" TO "authenticated";
GRANT ALL ON TABLE "public"."fcm_subscribed_topics" TO "service_role";

GRANT ALL ON TABLE "public"."fcm_tokens" TO "anon";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "service_role";

GRANT ALL ON TABLE "public"."feedbacks" TO "anon";
GRANT ALL ON TABLE "public"."feedbacks" TO "authenticated";
GRANT ALL ON TABLE "public"."feedbacks" TO "service_role";

GRANT ALL ON SEQUENCE "public"."feedbacks_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."feedbacks_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."feedbacks_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."follows" TO "anon";
GRANT ALL ON TABLE "public"."follows" TO "authenticated";
GRANT ALL ON TABLE "public"."follows" TO "service_role";

GRANT ALL ON TABLE "public"."hashtag_chat_users" TO "anon";
GRANT ALL ON TABLE "public"."hashtag_chat_users" TO "authenticated";
GRANT ALL ON TABLE "public"."hashtag_chat_users" TO "service_role";

GRANT ALL ON TABLE "public"."hashtag_holders" TO "anon";
GRANT ALL ON TABLE "public"."hashtag_holders" TO "authenticated";
GRANT ALL ON TABLE "public"."hashtag_holders" TO "service_role";

GRANT ALL ON TABLE "public"."hashtag_message_reactions" TO "anon";
GRANT ALL ON TABLE "public"."hashtag_message_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."hashtag_message_reactions" TO "service_role";

GRANT ALL ON TABLE "public"."hashtag_messages" TO "anon";
GRANT ALL ON TABLE "public"."hashtag_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."hashtag_messages" TO "service_role";

GRANT ALL ON SEQUENCE "public"."hashtag_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."hashtag_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."hashtag_messages_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."hashtags" TO "anon";
GRANT ALL ON TABLE "public"."hashtags" TO "authenticated";
GRANT ALL ON TABLE "public"."hashtags" TO "service_role";

GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";

GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."points_marketplace_products" TO "anon";
GRANT ALL ON TABLE "public"."points_marketplace_products" TO "authenticated";
GRANT ALL ON TABLE "public"."points_marketplace_products" TO "service_role";

GRANT ALL ON TABLE "public"."points_marketplace_purchase_pending" TO "anon";
GRANT ALL ON TABLE "public"."points_marketplace_purchase_pending" TO "authenticated";
GRANT ALL ON TABLE "public"."points_marketplace_purchase_pending" TO "service_role";

GRANT ALL ON SEQUENCE "public"."points_marketplace_purchase_pending_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."points_marketplace_purchase_pending_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."points_marketplace_purchase_pending_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."post_likes" TO "anon";
GRANT ALL ON TABLE "public"."post_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."post_likes" TO "service_role";

GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";
GRANT ALL ON TABLE "public"."posts" TO "service_role";

GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."referral_used" TO "anon";
GRANT ALL ON TABLE "public"."referral_used" TO "authenticated";
GRANT ALL ON TABLE "public"."referral_used" TO "service_role";

GRANT ALL ON TABLE "public"."subscribed_hashtags" TO "anon";
GRANT ALL ON TABLE "public"."subscribed_hashtags" TO "authenticated";
GRANT ALL ON TABLE "public"."subscribed_hashtags" TO "service_role";

GRANT ALL ON TABLE "public"."tracked_event_blocks" TO "anon";
GRANT ALL ON TABLE "public"."tracked_event_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."tracked_event_blocks" TO "service_role";

GRANT ALL ON TABLE "public"."unsubscribed_communities" TO "anon";
GRANT ALL ON TABLE "public"."unsubscribed_communities" TO "authenticated";
GRANT ALL ON TABLE "public"."unsubscribed_communities" TO "service_role";

GRANT ALL ON TABLE "public"."unsubscribed_creators" TO "anon";
GRANT ALL ON TABLE "public"."unsubscribed_creators" TO "authenticated";
GRANT ALL ON TABLE "public"."unsubscribed_creators" TO "service_role";

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
