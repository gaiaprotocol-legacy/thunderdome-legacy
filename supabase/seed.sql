
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
            new.block_number, new.log_index, new.tx, new.args[1], 1, new.args[2], new.event_name, new.args
        );

        -- add key info
        insert into group_keys (
            group_id, owner, name, symbol
        ) values (
            new.args[2], new.args[1], new.args[3], new.args[4]
        );

        -- add key holder info
        insert into group_key_holders (
            group_id, wallet_address, last_fetched_balance
        ) values (
            new.args[2], new.args[1], new.args[4]::numeric
        );
        
        -- update wallet's total key balance
        insert into user_wallets (
            wallet_address, total_key_balance
        ) values (
            new.args[1], new.args[4]::numeric
        ) on conflict (wallet_address) do update
            set total_key_balance = user_wallets.total_key_balance + new.args[4]::numeric;

        -- notify
        v_receiver := (SELECT user_id FROM users_public WHERE wallet_address = new.args[1]);
        IF v_receiver IS NOT NULL THEN
            insert into notifications (
                user_id, type, key_type, reference_key
            ) values (
                v_receiver, 0, 1, new.args[2]
            );
        END IF;

    ELSIF new.event_name = 'Trade' AND (
        new.key_type = 0 OR new.key_type = 1 OR new.key_type = 2
    ) THEN

        -- add activity
        insert into activities (
            block_number, log_index, tx, wallet_address, key_type, reference_key, activity_name, args
        ) values (
            new.block_number, new.log_index, new.tx, new.args[1], new.key_type, new.args[2], new.event_name, new.args
        );

        -- notify
        IF new.key_type = 0 THEN
            --TODO:
        ELSIF new.key_type = 1 THEN
            v_receiver := (SELECT user_id FROM users_public WHERE wallet_address = (
                SELECT owner FROM group_keys WHERE group_id = new.args[2]
            ));
        ELSIF new.key_type = 2 THEN
            --TODO:
        END IF;

        v_triggerer := (SELECT user_id FROM users_public WHERE wallet_address = new.args[1]);
        IF v_receiver IS NOT NULL AND v_receiver != v_triggerer THEN
            insert into notifications (
                user_id, triggerer, type, key_type, reference_key, amount
            ) values (
                v_receiver, v_triggerer, CASE WHEN new.args[3] = 'true' THEN 1 ELSE 2 END, new.key_type, new.args[2], new.args[4]::numeric
            );
        END IF;

        -- buy
        IF new.args[3] = 'true' THEN

            IF new.key_type = 0 THEN
                
                -- update key info
                update creator_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now()
                where creator_address = new.args[2];

                -- update key holder info
                insert into creator_key_holders (
                    creator_address, wallet_address, last_fetched_balance
                ) values (
                    new.args[2], new.args[1], new.args[4]::numeric
                ) on conflict (creator_address, wallet_address) do update
                    set last_fetched_balance = creator_key_holders.last_fetched_balance + new.args[4]::numeric;
                
                -- if key holder is new, add to key holder count
                IF NOT FOUND THEN
                    update creator_keys set
                        holder_count = holder_count + 1
                    where creator_address = new.args[2];
                END IF;
                
            ELSIF new.key_type = 1 THEN
                
                -- update key info
                update group_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now()
                where group_id = new.args[2];

                -- update key holder info
                insert into group_key_holders (
                    group_id, wallet_address, last_fetched_balance
                ) values (
                    new.args[2], new.args[1], new.args[4]::numeric
                ) on conflict (group_id, wallet_address) do update
                    set last_fetched_balance = group_key_holders.last_fetched_balance + new.args[4]::numeric;
                
                -- if key holder is new, add to key holder count
                IF NOT FOUND THEN
                    update group_keys set
                        holder_count = holder_count + 1
                    where group_id = new.args[2];
                END IF;
            
            ELSIF new.key_type = 2 THEN
                
                -- update key info
                update topic_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = total_trading_volume + new.args[5]::numeric,
                    is_price_up = true,
                    last_purchased_at = now()
                where topic = new.args[2];

                -- update key holder info
                insert into topic_key_holders (
                    topic, wallet_address, last_fetched_balance
                ) values (
                    new.args[2], new.args[1], new.args[4]::numeric
                ) on conflict (topic, wallet_address) do update
                    set last_fetched_balance = topic_key_holders.last_fetched_balance + new.args[4]::numeric;
                
                -- if key holder is new, add to key holder count
                IF NOT FOUND THEN
                    update topic_keys set
                        holder_count = holder_count + 1
                    where topic = new.args[2];
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
                    total_trading_volume = total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where creator_address = new.args[2];

                -- update key holder info
                WITH updated AS (
                    UPDATE creator_key_holders
                    SET last_fetched_balance = last_fetched_balance - new.args[4]::numeric
                    WHERE creator_address = new.args[2]
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
                    where creator_address = new.args[2];
                END IF;

            ELSIF new.key_type = 1 THEN
                
                -- update key info
                update group_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where group_id = new.args[2];

                -- update key holder info
                WITH updated AS (
                    UPDATE group_key_holders
                    SET last_fetched_balance = last_fetched_balance - new.args[4]::numeric
                    WHERE group_id = new.args[2]
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
                    where group_id = new.args[2];
                END IF;
            
            ELSIF new.key_type = 2 THEN
                
                -- update key info
                update topic_keys set
                    supply = new.args[8]::numeric,
                    last_fetched_price = new.args[5]::numeric,
                    total_trading_volume = total_trading_volume + new.args[5]::numeric,
                    is_price_up = false
                where topic = new.args[2];

                -- update key holder info
                WITH updated AS (
                    UPDATE topic_key_holders
                    SET last_fetched_balance = last_fetched_balance - new.args[4]::numeric
                    WHERE topic = new.args[2]
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
                    where topic = new.args[2];
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
    "event_type" smallint NOT NULL,
    "args" text[] DEFAULT '{}'::text[] NOT NULL,
    "wallet_address" text NOT NULL,
    "key_type" smallint,
    "reference_key" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
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
    "holder_count" integer DEFAULT 1 NOT NULL,
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
    "name" text NOT NULL,
    "image" text,
    "image_thumb" text,
    "image_stored" boolean DEFAULT false NOT NULL,
    "stored_image" text,
    "stored_image_thumb" text,
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
    "holder_count" integer DEFAULT 1 NOT NULL,
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

CREATE POLICY "can view only user" ON "public"."notifications" FOR SELECT TO authenticated USING ((user_id = auth.uid()));

CREATE POLICY "can write only authed" ON "public"."creator_chat_messages" FOR INSERT TO authenticated WITH CHECK (((((message IS NOT NULL) AND (message <> ''::text) AND (length(message) <= 1000)) OR ((message IS NULL) AND (rich IS NOT NULL))) AND (author = auth.uid())));

CREATE POLICY "can write only authed" ON "public"."group_chat_messages" FOR INSERT TO authenticated WITH CHECK (((((message IS NOT NULL) AND (message <> ''::text) AND (length(message) <= 1000)) OR ((message IS NULL) AND (rich IS NOT NULL))) AND (author = auth.uid())));

CREATE POLICY "can write only authed" ON "public"."topic_chat_messages" FOR INSERT TO authenticated WITH CHECK (((((message IS NOT NULL) AND (message <> ''::text) AND (length(message) <= 1000)) OR ((message IS NULL) AND (rich IS NOT NULL))) AND (author = auth.uid())));

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

CREATE POLICY "view everyone" ON "public"."contract_events" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."creator_chat_messages" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."group_chat_messages" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."topic_chat_messages" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."user_wallets" FOR SELECT USING (true);

CREATE POLICY "view everyone" ON "public"."users_public" FOR SELECT USING (true);

ALTER TABLE "public"."wallet_linking_nonces" ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."create_creator_key"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_creator_key"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_creator_key"() TO "service_role";

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
