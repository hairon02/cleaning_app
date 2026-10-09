import sqlite3

import pytest

from app.cells import cell_to_bounds, get_cleared_cells, latlon_to_cell, mark_cleared


@pytest.fixture
def cells_db() -> sqlite3.Connection:
    conn = sqlite3.connect(':memory:')
    conn.row_factory = sqlite3.Row
    conn.executescript(
        '''
        CREATE TABLE users (id TEXT PRIMARY KEY, display_name TEXT NOT NULL);
        CREATE TABLE cells (
            user_id TEXT NOT NULL,
            cell_id TEXT NOT NULL,
            cleared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, cell_id),
            FOREIGN KEY(user_id) REFERENCES users(id)
        );
        INSERT INTO users VALUES ('user-1', 'Guest');
        '''
    )
    return conn


def test_same_point_has_same_cell():
    assert latlon_to_cell(19.4326, -99.1332) == latlon_to_cell(19.4326, -99.1332)


def test_cell_bounds_contain_point():
    cell_id = latlon_to_cell(19.4326, -99.1332)
    lat_min, lon_min, lat_max, lon_max = cell_to_bounds(cell_id)
    assert lat_min <= 19.4326 < lat_max
    assert lon_min <= -99.1332 < lon_max


def test_mark_cleared_is_idempotent(cells_db: sqlite3.Connection):
    cell_id = latlon_to_cell(19.4326, -99.1332)
    assert mark_cleared('user-1', cell_id, cells_db) is True
    assert mark_cleared('user-1', cell_id, cells_db) is False


def test_get_cleared_cells_filters_bbox(cells_db: sqlite3.Connection):
    cell_id = latlon_to_cell(19.4326, -99.1332)
    mark_cleared('user-1', cell_id, cells_db)
    assert cell_id in get_cleared_cells('user-1', (19.4, -99.2, 19.5, -99.1), cells_db)
    assert get_cleared_cells('user-1', (20.0, -99.2, 20.1, -99.1), cells_db) == []
