<?php


$pdo = require __DIR__ . '/../../database/connection.php';

header('Content-Type: application/json; charset=utf-8');

$slug = $_GET['slug'] ?? null;

if (!$slug) {
    http_response_code(400);

    echo json_encode([
        'status' => 'error',
        'message' => 'Menu item slug is required.'
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
         WHERE menu_items.slug = :slug"
    );

    $stmt->execute([
        'slug' => $slug
    ]);

    $menu_item = $stmt->fetch();

    if (!$menu_item) {
        http_response_code(404);

        echo json_encode([
            'status' => 'error',
            'message' => 'Menu item not found.'
        ]);

        exit;
    }

    $category = null;

    if ($menu_item['cat_id'] !== null) {
        $category = [
            'id' => $menu_item['cat_id'],
            'name' => $menu_item['cat_name'],
            'slug' => $menu_item['cat_slug']
        ];
    }

    unset(
        $menu_item['cat_id'],
        $menu_item['cat_name'],
        $menu_item['cat_slug']
    );

    $menu_item['category'] = $category;

    echo json_encode([
        'status' => 'success',
        'data' => $menu_item
    ]);
} catch (PDOException $e) {
    http_response_code(500);

    echo json_encode([
        'status' => 'error',
        'message' => 'Unable to fetch menu item.'
    ]);
}