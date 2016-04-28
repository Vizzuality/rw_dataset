--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.2
-- Dumped by pg_dump version 9.5.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE datasets (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    dateable_id uuid,
    dateable_type character varying,
    name character varying,
    format integer DEFAULT 0,
    data_path character varying,
    attributes_path character varying,
    row_count integer,
    status integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: json_connectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE json_connectors (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    connector_provider integer DEFAULT 0,
    parent_connector_url character varying,
    parent_connector_id uuid,
    parent_connector_type character varying,
    parent_connector_provider integer,
    parent_connector_data_path character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: rest_connectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rest_connectors (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    connector_provider integer DEFAULT 0,
    connector_url character varying,
    table_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


--
-- Name: json_connectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY json_connectors
    ADD CONSTRAINT json_connectors_pkey PRIMARY KEY (id);


--
-- Name: rest_connectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rest_connectors
    ADD CONSTRAINT rest_connectors_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_datasets_on_connector_and_connector_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_datasets_on_connector_and_connector_type ON datasets USING btree (dateable_id, dateable_type);


--
-- Name: index_json_connectors_on_connector_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_json_connectors_on_connector_provider ON json_connectors USING btree (connector_provider);


--
-- Name: index_rest_connectors_on_connector_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rest_connectors_on_connector_provider ON rest_connectors USING btree (connector_provider);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20160420124502'), ('20160420124523'), ('20160420124632'), ('20160420124652');


