-- Let's Chow Database Schema - Audit Fixes Migration (remaining changes)
-- Version: 002
-- Description: Applies remaining fixes from schema audit (menu visibility, order deletion safety, payment idempotency, actor tracking, indexes)
-- Database: lets_chow (MySQL 8.4, InnoDB, utf8mb4)
-- Timestamps are stored in UTC
-- Note: delivery_fee_status and chk_orders_public_ref_format were applied in a previous partial run

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- 1. MENU ITEMS: Clarify is_available meaning (orderable, not hidden)
-- ============================================================================
ALTER TABLE `menu_items`
    MODIFY COLUMN `is_available` TINYINT(1) NOT NULL DEFAULT 1
    COMMENT '1 = available for ordering, 0 = visible but not orderable (disabled at application layer)';

-- ============================================================================
-- 2. ORDER_ITEMS: Change FK to RESTRICT (prevent order deletion)
-- ============================================================================
ALTER TABLE `order_items`
    DROP FOREIGN KEY `fk_order_items_order`;

ALTER TABLE `order_items`
    ADD CONSTRAINT `fk_order_items_order`
        FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================================
-- 3. PAYMENTS: Add idempotency_key with unique constraint
-- ============================================================================
ALTER TABLE `payments`
    ADD COLUMN `idempotency_key` VARCHAR(100) NULL
    COMMENT 'Application-generated key for idempotent payment creation (e.g., UUID v4)'
    AFTER `provider_response`,
    ADD UNIQUE KEY `uk_payments_idempotency` (`idempotency_key`);

-- Add composite index for payment lookup by order and status
ALTER TABLE `payments`
    ADD KEY `idx_payments_order_status` (`order_id`, `status`);

-- ============================================================================
-- 4. ORDER_STATUS_HISTORY: Support admin, customer, system actors
-- ============================================================================
-- Add actor_type and actor_id columns (actor_admin_id kept for backward compatibility)
ALTER TABLE `order_status_history`
    ADD COLUMN `actor_type` ENUM('admin','customer','system') NOT NULL DEFAULT 'system'
    COMMENT 'Type of actor who made the change'
    AFTER `change_note`,
    ADD COLUMN `actor_id` BIGINT UNSIGNED NULL
    COMMENT 'Reference ID: admins.id for admin, customer phone/email hash for customer, NULL for system'
    AFTER `actor_type`,
    ADD KEY `idx_order_status_history_actor` (`actor_type`, `actor_id`);

-- Note: actor_admin_id is retained for backward compatibility.
-- New code should populate actor_type + actor_id.
-- Application layer should populate both for admin actions.

-- ============================================================================
-- 5. ORDER_STATUS_HISTORY: Change FK to RESTRICT (prevent order deletion)
-- ============================================================================
ALTER TABLE `order_status_history`
    DROP FOREIGN KEY `fk_order_status_history_order`;

ALTER TABLE `order_status_history`
    ADD CONSTRAINT `fk_order_status_history_order`
        FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================================
-- 6. INDEXES: Additional helpful indexes
-- ============================================================================
-- Index for finding latest status per order
ALTER TABLE `order_status_history`
    ADD KEY `idx_order_status_history_order_status` (`order_id`, `new_status`);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run after migration:
-- SHOW CREATE TABLE menu_items;
-- SHOW CREATE TABLE orders;
-- SHOW CREATE TABLE order_items;
-- SHOW CREATE TABLE payments;
-- SHOW CREATE TABLE order_status_history;
-- SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = 'lets_chow';

SET FOREIGN_KEY_CHECKS = 1;