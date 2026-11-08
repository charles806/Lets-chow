<?php

require_once __DIR__ . '/connection.php';

try {
    $pdo = require __DIR__ . '/connection.php';

    $stmt = $pdo->query('SELECT DATABASE() AS current_db');
    $result = $stmt->fetch();

    echo "Connected to database: " . $result['current_db'] . "\n";
} catch (Throwable $e) {
    echo "Database connection failed. Please check your configuration.\n";
    error_log("Test connection error: " . $e->getMessage());
}