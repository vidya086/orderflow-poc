-- Runs once, on first container start of the local Postgres instance.
-- Mirrors the "one database + one least-privilege user per service" pattern
-- you'll replicate with separate Cloud SQL databases/users in later stages.

CREATE USER order_user WITH PASSWORD 'order_pass';
CREATE DATABASE orderdb OWNER order_user;

CREATE USER inventory_user WITH PASSWORD 'inventory_pass';
CREATE DATABASE inventorydb OWNER inventory_user;

\connect inventorydb
CREATE TABLE IF NOT EXISTS inventory_items (
    sku VARCHAR(64) PRIMARY KEY,
    quantity_available INT NOT NULL DEFAULT 0
);
INSERT INTO inventory_items (sku, quantity_available) VALUES
    ('SKU-001', 100),
    ('SKU-002', 50),
    ('SKU-003', 25)
ON CONFLICT DO NOTHING;
GRANT ALL PRIVILEGES ON TABLE inventory_items TO inventory_user;
