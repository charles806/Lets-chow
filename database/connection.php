<?php

use Dotenv\Dotenv;

require_once __DIR__ . '/../vendor/autoload.php';

$projectRoot = dirname(__DIR__);

$dotenv = Dotenv::createImmutable($projectRoot);
$dotenv->load();

$db_host = $_ENV["DB_HOST"];
$db_port = $_ENV["DB_PORT"];
$db_database = $_ENV["DB_DATABASE"];
$db_username = $_ENV["DB_USERNAME"];
$db_password = $_ENV["DB_PASSWORD"];

$dsn = "mysql:host={$db_host};port={$db_port};dbname={$db_database};charset=utf8mb4";

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,       
    PDO::ATTR_EMULATE_PREPARES   => false,        
];

try {
   $pdo = new PDO($dsn, $db_username, $db_password, $options);
   // Ensure UTC timezone for consistent timestamp handling
   $pdo->exec("SET time_zone = '+00:00'");
   return $pdo;
} catch (PDOException $e) {
    error_log("DB connection failed: " . $e->getMessage());
    throw new RuntimeException("Database connection failed");
}

?>