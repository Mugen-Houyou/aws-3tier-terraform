#!/bin/bash
dnf update -y
dnf install -y httpd php php-mysqlnd htop tree wget curl

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple PHP info page
cat > /var/www/html/index.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>3-Tier Web Application</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; padding: 15px; background: #e8f4fd; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 3-Tier Web Application</h1>
            <p>Welcome to the Application Tier!</p>
        </div>
        
        <div class="info">
            <h3>Server Information</h3>
            <p><strong>Server:</strong> <?php echo gethostname(); ?></p>
            <p><strong>IP Address:</strong> <?php echo $_SERVER['SERVER_ADDR']; ?></p>
            <p><strong>Timestamp:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
            <p><strong>Environment:</strong> Development</p>
        </div>

        <div class="info">
            <h3>Database Connection</h3>
            <?php
            $db_host = "${db_endpoint}";
            if (!empty($db_host)) {
                echo "<p><strong>Database Host:</strong> " . $db_host . "</p>";
                echo "<p><strong>Status:</strong> Ready for connection</p>";
            } else {
                echo "<p><strong>Status:</strong> Database not configured yet</p>";
            }
            ?>
        </div>

        <div class="info">
            <h3>Architecture</h3>
            <ul>
                <li>Web Tier: Load Balancer (Public Subnets)</li>
                <li>Application Tier: Web Servers (Private Subnets) ← You are here</li>
                <li>Database Tier: RDS MySQL (Database Subnets)</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Create a health check endpoint
cat > /var/www/html/health.php << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'healthy',
    'server' => gethostname(),
    'timestamp' => date('c')
]);
?>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure firewall
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

echo "Web server setup completed" > /var/log/user-data.log
