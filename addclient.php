<?php
// Enable CORS (Cross-Origin Resource Sharing)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Database connection
$host = 'localhost';  // Change if necessary
$dbname = 'ftth'; // Replace with your database name
$username = 'root';   // Replace with your database username
$password = '';   // Replace with your database password

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed: " . $e->getMessage()]);
    exit;
}

// Read the JSON input from the request body
$data = json_decode(file_get_contents("php://input"), true);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($data)) {
    $id = $data['id'] ?? ''; // Firestore ID
    $name = $data['name'] ?? '';
    $phoneNumber = $data['phoneNumber'] ?? '';
    $accountNumber = $data['accountNumber'] ?? '';
    $address = $data['address'] ?? '';
    $installation = $data['installation'] ?? 'Incomplete';

    // Validate input
    if (empty($id) || empty($name) || empty($phoneNumber) || empty($accountNumber) || empty($address)) {
        http_response_code(400);
        echo json_encode(["error" => "All fields are required."]);
        exit;
    }

    try {
        // Insert data into the 'clients' table
        $stmt = $pdo->prepare("
            INSERT INTO clients (id, name, phone_number, account_number, address, installation, timestamp)
            VALUES (:id, :name, :phoneNumber, :accountNumber, :address, :installation, NOW())
        ");

        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':phoneNumber', $phoneNumber);
        $stmt->bindParam(':accountNumber', $accountNumber);
        $stmt->bindParam(':address', $address);
        $stmt->bindParam(':installation', $installation);

        if ($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["message" => "Client added successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => "Failed to add client."]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["error" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "Invalid request or missing data."]);
}
?>
