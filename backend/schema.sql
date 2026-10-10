-- Esquema SQLite para Clearing

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS photos (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    path TEXT NOT NULL,
    lat REAL NOT NULL,
    lon REAL NOT NULL,
    taken_at TIMESTAMP NOT NULL,
    cell_id TEXT NOT NULL,
    phash TEXT,
    gemma_json TEXT,
    status TEXT NOT NULL CHECK(status IN ('verified', 'rejected', 'duplicate', 'pending_review')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS cells (
    user_id TEXT NOT NULL,
    cell_id TEXT NOT NULL,
    cleared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, cell_id),
    FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS challenges (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    visual_criterion TEXT NOT NULL,
    period TEXT NOT NULL CHECK(period IN ('daily', 'weekly')),
    difficulty TEXT NOT NULL CHECK(difficulty IN ('easy', 'medium', 'hard')),
    points INTEGER NOT NULL DEFAULT 15,
    reviewed INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS points_ledger (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    reason TEXT NOT NULL CHECK(reason IN ('photo_verified', 'new_cell', 'daily_challenge', 'weekly_challenge', 'streak_day')),
    amount INTEGER NOT NULL,
    ref_id TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id),
    CONSTRAINT uq_points_ledger UNIQUE (user_id, reason, ref_id)
);

CREATE INDEX IF NOT EXISTS idx_photos_user_status ON photos(user_id, status);
CREATE INDEX IF NOT EXISTS idx_photos_map_viewport ON photos(user_id, status, lat, lon);
CREATE INDEX IF NOT EXISTS idx_photos_phash ON photos(phash);
CREATE INDEX IF NOT EXISTS idx_cells_user ON cells(user_id);
CREATE INDEX IF NOT EXISTS idx_ledger_user ON points_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_ledger_user_reason_created
    ON points_ledger(user_id, reason, created_at);
CREATE UNIQUE INDEX IF NOT EXISTS uq_points_ledger_idempotency
    ON points_ledger(user_id, reason, COALESCE(ref_id, ''));
