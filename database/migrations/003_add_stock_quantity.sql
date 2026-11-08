-- Let's Chow Database Schema - Add Stock Quantity to Menu Items
-- Version: 003
-- Description: Adds stock_quantity column to menu_items for inventory tracking
-- Database: lets_chow (MySQL 8.4, InnoDB, utf8mb4)
-- Timestamps are stored in UTC

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- MENU_ITEMS: Add stock_quantity column
-- ============================================================================
ALTER TABLE `menu_items`
    ADD COLUMN `stock_quantity` INT UNSIGNED NOT NULL DEFAULT 0
        COMMENT 'Current stock quantity. 0 = out of stock, item becomes unavailable automatically'
    AFTER `is_available`,
    ADD KEY `idx_menu_items_stock` (`stock_quantity`);

-- ============================================================================
-- SET INITIAL STOCK FOR EXISTING ITEMS
-- ============================================================================
-- Set a sensible default stock for existing available items
-- Unavailable items (is_available = 0) keep stock at 0
UPDATE `menu_items`
SET `stock_quantity` = 100
WHERE `is_available` = 1;

-- ============================================================================
-- ADD CHECK CONSTRAINT FOR STOCK QUANTITY
-- ============================================================================
ALTER TABLE `menu_items`
    ADD CONSTRAINT `chk_menu_items_stock_nonneg` CHECK (`stock_quantity` >= 0);

-- ============================================================================
-- VERIFICATION QUERIES (run after migration to confirm)
-- ============================================================================
-- SHOW CREATE TABLE menu_items;
-- SELECT id, name, is_available, stock_quantity FROM menu_items;

SET FOREIGN_KEY_CHECKS = 1;