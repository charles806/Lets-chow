<?php

$pdo = require __DIR__ . '/../../database/connection.php';

header('Content-Type: application/json; charset=utf-8');

try{
    $stmt = $pdo->query(
        "INSERT INTO categories (name, slug)
        VALUES ('Burgers', 'burgers');"
    );

     $categories = $stmt->fetchAll();

         echo json_encode([
        'status' => 'success',
        'data' => $categories
    ]);
} catch (PDOException $e) {
    http_response_code(500);

    echo json_encode([
        'status' => 'error',
        'message' => 'Unable to fetch menu categories.'
    ]);
}
