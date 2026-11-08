<?php

$pdo = require __DIR__ . '/../../database/connection.php';

header('Content-Type: application/json; charset=utf-8');


$search = $_GET['q'] ?? '';

$search = trim($search);

if (strlen($search) < 1) {
    http_response_code(400);

    echo json_encode([
        'status' => 'error',
        'message' => 'Search query is required.'
    ]);

    exit;
}

try {

    $stmt = $pdo->prepare(
        "SELECT
    menu_items.id,
    menu_items.category_id,
    menu_items.name,
    menu_items.slug,
    menu_items.description,
    menu_items.price_ngn,
    menu_items.image_path,
    menu_items.is_available,
    categories.id AS cat_id,
    categories.name AS cat_name,
    categories.slug AS cat_slug
FROM menu_items
LEFT JOIN categories
    ON menu_items.category_id = categories.id
WHERE menu_items.is_available = 1
AND (
    menu_items.name LIKE :food_name
    OR categories.name LIKE :category_name
)"
    );

    $searchTerm = "%$search%";

    $stmt->execute([
        'food_name' => $searchTerm,
        'category_name' => $searchTerm
    ]);

    $results = $stmt->fetchAll();

    if (!$results) {
        http_response_code(404);

        echo json_encode([
            'status' => 'error',
            'message' => 'Menu item not found.'
        ]);

        exit;
    }


    foreach ($results as $key => $item) {
        $results[$key]['category'] = $item['cat_id'] !== null ? [
            'id' => $item['cat_id'],
            'name' => $item['cat_name'],
            'slug' => $item['cat_slug']
        ] : null;

        unset(
            $results[$key]['cat_id'],
            $results[$key]['cat_name'],
            $results[$key]['cat_slug']
        );
    }

    echo json_encode([
        'status' => "success",
        'data' => $results
    ]);
} catch (PDOException $e) {
    http_response_code(500);

    echo json_encode([
        'status' => 'error',
        'message' => 'Unable to fetch menu item.'
    ]);
}
