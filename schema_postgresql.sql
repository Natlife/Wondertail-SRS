-- PostgreSQL schema generated from db.puml
-- Note:
-- 1) Table names are normalized to snake_case.
-- 2) `user` is renamed to `app_user` to avoid reserved-word conflicts.
-- 3) Story.id is BIGINT with auto-increment; all FK references updated accordingly.
-- 4) JSON structures in PUML (ActorConfig, OnEnterAction, Transition, ScriptLine)
--    are represented as jsonb fields in parent tables.
-- 5) All tables are created in the 'app' schema.

BEGIN;

CREATE SCHEMA IF NOT EXISTS app;
SET search_path TO app;

-- =========================
-- User Module
-- =========================

CREATE TABLE role (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE
);

CREATE TABLE module (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            TEXT NOT NULL,
    path            TEXT
);

CREATE TABLE action (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            TEXT NOT NULL,
    path            TEXT
);

CREATE TABLE permission (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module_id       BIGINT NOT NULL REFERENCES module(id),
    action_id       BIGINT NOT NULL REFERENCES action(id),
    name            TEXT NOT NULL,
    UNIQUE (module_id, action_id)
);

CREATE TABLE app_user (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id         BIGINT NOT NULL REFERENCES role(id),
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    parent_id       BIGINT REFERENCES app_user(id),
    name            TEXT,
    user_name       TEXT UNIQUE,
    dob             DATE,
    phone           TEXT,
    email           TEXT UNIQUE,
    password        TEXT
);

CREATE TABLE role_permission (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id         BIGINT NOT NULL REFERENCES role(id),
    permission_id   BIGINT NOT NULL REFERENCES permission(id),
    UNIQUE (role_id, permission_id)
);

-- =========================
-- Story Module
-- =========================

CREATE TABLE graphic_asset (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    name            TEXT,
    description     TEXT,
    image_url       TEXT,
    type            TEXT
);

CREATE TABLE audio_asset (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    name            TEXT,
    description     TEXT,
    audio_url       TEXT,
    type            TEXT
);

CREATE TABLE story (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version         TEXT,
    title           TEXT,
    author          TEXT,

    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT REFERENCES app_user(id),
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    approved_by     BIGINT REFERENCES app_user(id),
    approved_at     TIMESTAMP,
    rejected_reason TEXT,
    duration        INT,
    is_premium      BOOLEAN NOT NULL DEFAULT FALSE,

    description     TEXT,
    cover_image     BIGINT REFERENCES graphic_asset(id),
    entry_point     TEXT,
    localization    TEXT[]
);

CREATE TABLE story_state (
    id              TEXT NOT NULL,
    story_id        BIGINT NOT NULL REFERENCES story(id) ON DELETE CASCADE,
    type            TEXT,
    background      TEXT,
    music           TEXT,
    actors          JSONB,
    on_enter        JSONB,
    transitions     JSONB,
    ai_context      TEXT,
    PRIMARY KEY (id, story_id)
);

CREATE TABLE story_script (
    id              TEXT NOT NULL,
    story_id        BIGINT NOT NULL REFERENCES story(id) ON DELETE CASCADE,
    language        TEXT,
    lines           JSONB,
    PRIMARY KEY (id, story_id)
);

CREATE TABLE story_intent (
    id              TEXT NOT NULL,
    story_id        BIGINT NOT NULL REFERENCES story(id) ON DELETE CASCADE,
    keywords        TEXT[],
    PRIMARY KEY (id, story_id)
);

CREATE TABLE story_embedding (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    story_id        BIGINT NOT NULL REFERENCES story(id) ON DELETE CASCADE,
    state_id        TEXT,
    content         TEXT,
    embedding       public.VECTOR(768),
    created_at      TIMESTAMP
);

CREATE TABLE story_feedback (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT NOT NULL REFERENCES app_user(id),
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    story_id        BIGINT NOT NULL REFERENCES story(id),
    rate            BIGINT,
    content         TEXT,
    UNIQUE (created_user, story_id)
);

-- =========================
-- Assignment Module
-- =========================

CREATE TABLE topic (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    name            TEXT,
    description     TEXT
);

CREATE TABLE assignment (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    topic_id        BIGINT REFERENCES topic(id),
    name            TEXT,
    description     TEXT,
    total           BIGINT,
    is_shuffle      BOOLEAN NOT NULL DEFAULT FALSE,
    is_premium      BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE question_bank (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    assignment_id   BIGINT NOT NULL REFERENCES assignment(id) ON DELETE CASCADE,
    question_list   JSONB,
    UNIQUE (assignment_id)
);

-- =========================
-- Logs & Payments Module
-- =========================

CREATE TABLE user_feedback (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT REFERENCES app_user(id),
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    rate            BIGINT,
    content         TEXT
);

CREATE TABLE children_story_log (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    story_id        BIGINT NOT NULL REFERENCES story(id),
    content         JSONB,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    completed_at    TIMESTAMP
);

CREATE TABLE assignment_log (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    assignment_id   BIGINT NOT NULL REFERENCES assignment(id),
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    question_list   JSONB,
    finished_at     TIMESTAMP,
    version         INT
);

CREATE TABLE preorder_story (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    story_id        BIGINT NOT NULL REFERENCES story(id),
    order_date      DATE
);

CREATE TABLE blacklist_story (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    story_id        BIGINT NOT NULL REFERENCES story(id),
    UNIQUE (user_id, story_id)
);

CREATE TABLE time_limit (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    limit_date      DATE,
    limit_time      DOUBLE PRECISION
);

CREATE TABLE payment_type (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE
);

CREATE TABLE parent_payment (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    total           BIGINT,
    payment_type_id BIGINT REFERENCES payment_type(id),
    start_date      TIMESTAMP,
    end_date        TIMESTAMP
);

-- =========================
-- Game Module
-- =========================

CREATE TABLE game_type (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    name            TEXT
);

CREATE TABLE game_bank (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    game_type_id    BIGINT REFERENCES game_type(id),
    image_url       TEXT,
    name            TEXT,
    description     TEXT,
    view            BIGINT,
    age_group       TEXT,
    topic_id        BIGINT REFERENCES topic(id),
    is_premium      BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE game_log (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    game_bank_id    BIGINT NOT NULL REFERENCES game_bank(id),
    score           INT,
    finished_at     TIMESTAMP
);

-- =========================
-- Notification Module
-- =========================

CREATE TABLE notification (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status          INT NOT NULL,
    created_at      TIMESTAMP,
    created_user    BIGINT,
    updated_at      TIMESTAMP,
    updated_user    BIGINT,
    title           TEXT,
    content         TEXT,
    type            TEXT,
    is_broadcast    BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE notification_target (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    notification_id BIGINT NOT NULL REFERENCES notification(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    UNIQUE (notification_id, user_id)
);

CREATE TABLE notification_log (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    notification_id BIGINT NOT NULL REFERENCES notification(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES app_user(id),
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    read_at         TIMESTAMP,
    UNIQUE (notification_id, user_id)
);

-- Helpful indexes
CREATE INDEX idx_story_feedback_story_id ON story_feedback(story_id);
CREATE INDEX idx_story_state_story_id ON story_state(story_id);
CREATE INDEX idx_story_script_story_id ON story_script(story_id);
CREATE INDEX idx_story_intent_story_id ON story_intent(story_id);
CREATE INDEX idx_story_embedding_story_id ON story_embedding(story_id);
CREATE INDEX idx_assignment_log_user_id ON assignment_log(user_id);
CREATE INDEX idx_children_story_log_user_id ON children_story_log(user_id);
CREATE INDEX idx_game_log_user_id ON game_log(user_id);

COMMIT;
