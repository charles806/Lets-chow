-- Let's Chow Database Schema - Initial Migration
-- Version: 001
-- Description: Creates all tables for the MVP restaurant ordering platform
-- Database: lets_chow (MySQL 8.4, InnoDB, utf8mb4)
-- Timestamps are stored in UTC

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- ADMINS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS `admins` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(255) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL COMMENT 'bcrypt/argon2 hash, never plaintext',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_admins_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CATEGORIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS `categories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `slug` VARCHAR(120) NOT NULL COMMENT 'URL-friendly unique identifier',
    `description` TEXT NULL,
    `display_order` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'For menu ordering',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = active, 0 = inactive',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_categories_slug` (`slug`),
    KEY `idx_categories_active_order` (`is_active`, `display_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MENU_ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS `menu_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id` BIGINT UNSIGNED NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(160) NOT NULL COMMENT 'URL-friendly unique identifier',
    `description` TEXT NULL,
    `price_ngn` DECIMAL(10,2) UNSIGNED NOT NULL COMMENT 'Price in NGN, stored as exact decimal',
    `image_path` VARCHAR(500) NULL COMMENT 'Relative path to image file',
    `is_available` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = available, 0 = unavailable (hidden from menu)',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_menu_items_slug` (`slug`),
    KEY `idx_menu_items_category_available` (`category_id`, `is_available`),
    CONSTRAINT `fk_menu_items_category`
        FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_menu_items_price_positive` CHECK (`price_ngn` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ORDERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS `orders` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `public_ref` CHAR(12) NOT NULL COMMENT 'Non-guessable public reference (e.g., base36 encoded)',
    `customer_name` VARCHAR(150) NOT NULL,
    `customer_phone` VARCHAR(30) NOT NULL,
    `customer_email` VARCHAR(255) NULL,
    `fulfilment_type` ENUM('delivery','pickup') NOT NULL,
    `delivery_address` TEXT NULL COMMENT 'Required for delivery, NULL for pickup',
    `delivery_instructions` TEXT NULL,
    `delivery_fee_ngn` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT 'Quoted delivery fee in NGN',
    `subtotal_ngn` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT 'Sum of order_items line totals',
    `total_ngn` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT 'subtotal + delivery_fee',
    `order_status` ENUM(
        'awaiting_review',
        'awaiting_customer',
        'confirmed',
        'preparing',
        'ready',
        'out_for_delivery',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'awaiting_review',
    `payment_status` ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
    `delivery_fee_accepted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Customer accepted quoted delivery fee',
    `delivery_fee_accepted_at` TIMESTAMP NULL COMMENT 'When customer accepted delivery fee',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_orders_public_ref` (`public_ref`),
    KEY `idx_orders_status_created` (`order_status`, `created_at`),
    KEY `idx_orders_payment_status` (`payment_status`),
    KEY `idx_orders_customer_phone` (`customer_phone`),
    CONSTRAINT `chk_orders_delivery_fee_nonneg` CHECK (`delivery_fee_ngn` >= 0),
    CONSTRAINT `chk_orders_subtotal_nonneg` CHECK (`subtotal_ngn` >= 0),
    CONSTRAINT `chk_orders_total_nonneg` CHECK (`total_ngn` >= 0),
    CONSTRAINT `chk_orders_delivery_address_required` CHECK (
        (`fulfilment_type` = 'delivery' AND `delivery_address` IS NOT NULL AND `delivery_address` <> '')
        OR (`fulfilment_type` = 'pickup' AND `delivery_address` IS NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ORDER_ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS `order_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `menu_item_id` BIGINT UNSIGNED NULL COMMENT 'NULL if item was removed from menu',
    `item_name` VARCHAR(150) NOT NULL COMMENT 'Snapshot of name at purchase time',
    `unit_price_ngn` DECIMAL(10,2) UNSIGNED NOT NULL COMMENT 'Snapshot of price at purchase time',
    `quantity` INT UNSIGNED NOT NULL,
    `line_total_ngn` DECIMAL(10,2) UNSIGNED NOT NULL COMMENT 'unit_price * quantity',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_order_items_order` (`order_id`),
    KEY `idx_order_items_menu_item` (`menu_item_id`),
    CONSTRAINT `fk_order_items_order`
        FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_order_items_menu_item`
        FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `chk_order_items_quantity_positive` CHECK (`quantity` > 0),
    CONSTRAINT `chk_order_items_unit_price_nonneg` CHECK (`unit_price_ngn` >= 0),
    CONSTRAINT `chk_order_items_line_total_nonneg` CHECK (`line_total_ngn` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS `payments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `provider` VARCHAR(50) NOT NULL COMMENT 'e.g., bachs, cash_on_delivery, cash_on_pickup',
    `method` VARCHAR(50) NOT NULL COMMENT 'e.g., card, bank_transfer, cash',
    `amount_ngn` DECIMAL(10,2) UNSIGNED NOT NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'NGN',
    `status` ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
    `provider_reference` VARCHAR(255) NULL COMMENT 'Provider transaction ID / reference',
    `provider_response` JSON NULL COMMENT 'Raw provider response for audit',
    `paid_at` TIMESTAMP NULL COMMENT 'When payment was confirmed paid',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_payments_order` (`order_id`),
    KEY `idx_payments_provider_ref` (`provider_reference`),
    KEY `idx_payments_status` (`status`),
    CONSTRAINT `fk_payments_order`
        FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `chk_payments_amount_positive` CHECK (`amount_ngn` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ORDER_STATUS_HISTORY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS `order_status_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `previous_status` ENUM(
        'awaiting_review',
        'awaiting_customer',
        'confirmed',
        'preparing',
        'ready',
        'out_for_delivery',
        'completed',
        'cancelled'
    ) NULL COMMENT 'NULL for initial status',
    `new_status` ENUM(
        'awaiting_review',
        'awaiting_customer',
        'confirmed',
        'preparing',
        'ready',
        'out_for_delivery',
        'completed',
        'cancelled'
    ) NOT NULL,
    `change_note` VARCHAR(500) NULL COMMENT 'Reason for status change',
    `actor_admin_id` BIGINT UNSIGNED NULL COMMENT 'Admin who made the change, if applicable',
    `changed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_order_status_history_order` (`order_id`, `changed_at`),
    CONSTRAINT `fk_order_status_history_order`
        FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_order_status_history_admin`
        FOREIGN KEY (`actor_admin_id`) REFERENCES `admins` (`id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- VERIFICATION QUERIES (run after migration to confirm)
-- ============================================================================
-- SHOW TABLES;
-- SHOW CREATE TABLE admins;
-- SHOW CREATE TABLE categories;
-- SHOW CREATE TABLE menu_items;
-- SHOW CREATE TABLE orders;
-- SHOW CREATE TABLE order_items;
-- SHOW CREATE TABLE payments;
-- SHOW CREATE TABLE order_status_history;