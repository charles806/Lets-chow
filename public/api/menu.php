<?php

$pdo = require __DIR__ . '/../../database/connection.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $stmt = $pdo->query(
        "SELECT id, name, slug, description
         FROM categories
         WHERE is_active = 1
         ORDER BY display_order ASC"
    );

    $categories = $stmt->fetchAll();

    $groupedData = [];

    foreach ($categories as $key => $value) {
        $items = $value["id"];

        if (!isset($groupedData[$items])) {
            $groupedData[$items] = [
                "category_id" => $value["id"],
                "items" => []
            ];
        }

        $select_menu_items = $pdo->prepare(
            "SELECT id, name, slug, description, price_ngn, image_path
            FROM menu_items
            WHERE is_available = 1
            AND category_id = :category_id"
        );

        $select_menu_items->execute([
            'category_id' => $value["id"]
        ]);

        $menu_items = $select_menu_items->fetchAll();
        $categories[$key]['items'] = $menu_items;

    }
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
