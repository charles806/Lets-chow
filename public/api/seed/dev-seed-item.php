<?php

$pdo = require __DIR__ . '/../../../database/connection.php';

header('Content-Type: application/json; charset=utf-8');


$stmt = $pdo->prepare(
    "INSERT INTO menu_items
        (category_id, name, slug, description, price_ngn, is_available)
     VALUES
        (:category_id, :name, :slug, :description, :price_ngn, :is_available)"
);

$stmt->execute([
    'category_id' => 4,
    'name' => 'Classic Burger',
    'slug' => 'classic-burger',
    'description' => 'A classic burger with fresh ingredients.',
    'price_ngn' => '3500.00',
    'is_available' => 1,
]);

echo "Food item seeded successfully.";
