<?php

require_once __DIR__ . '/connection.php';

echo "Running migration 003_add_stock_quantity.sql...\n";

try {
    // Execute each statement individually
    $statements = [
        "SET FOREIGN_KEY_CHECKS = 0",
        "ALTER TABLE `menu_items` ADD COLUMN `stock_quantity` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current stock quantity. 0 = out of stock, item becomes unavailable automatically' AFTER `is_available`",
        "ALTER TABLE `menu_items` ADD KEY `idx_menu_items_stock` (`stock_quantity`)",
        "UPDATE `menu_items` SET `stock_quantity` = 100 WHERE `is_available` = 1",
        "ALTER TABLE `menu_items` ADD CONSTRAINT `chk_menu_items_stock_nonneg` CHECK (`stock_quantity` >= 0)",
        "SET FOREIGN_KEY_CHECKS = 1",
    ];

    foreach ($statements as $statement) {
        try {
            $pdo->exec($statement);
            echo "Executed: " . substr($statement, 0, 80) . "...\n";
        } catch (PDOException $e) {
            // Check if it's a "already exists" type error which we can ignore
            $errorCode = $e->getCode();
            if (str_contains($e->getMessage(), 'Duplicate column') ||
                str_contains($e->getMessage(), 'already exists') ||
                str_contains($e->getMessage(), 'Duplicate key') ||
                str_contains($e->getMessage(), 'Duplicate entry')) {
                echo "Already exists (ignored): " . substr($statement, 0, 80) . "...\n";
            } else {
                echo "Error: " . $e->getMessage() . "\n";
            }
        }
    }

    // Verify the migration
    $stmt = $pdo->query("SHOW COLUMNS FROM menu_items LIKE 'stock_quantity'");
    $column = $stmt->fetch();

    if ($column) {
        echo "\nMigration successful! stock_quantity column exists:\n";
        print_r($column);
    } else {
        echo "\nMigration may have failed - stock_quantity column not found\n";
    }

    // Check existing data
    $stmt = $pdo->query("SELECT id, name, is_available, stock_quantity FROM menu_items");
    $items = $stmt->fetchAll();

    echo "\nCurrent menu items:\n";
    foreach ($items as $item) {
        echo "  ID: {$item['id']}, Name: {$item['name']}, Available: {$item['is_available']}, Stock: {$item['stock_quantity']}\n";
    }

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\nDone!\n";