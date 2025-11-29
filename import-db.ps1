# Import database vào Docker MySQL container
Write-Host "=== Importing database to Docker MySQL ===" -ForegroundColor Green

# Copy SQL files into container for better UTF-8 handling
Write-Host "Copying SQL files to container..." -ForegroundColor Yellow
docker cp db btl3_mysql:/tmp/

# Execute using bash to pipe files (supports DELIMITER)
Write-Host "Executing SQL files..." -ForegroundColor Yellow
docker exec btl3_mysql bash -c "cat /tmp/db/01_create_tables.sql | mysql -u root --default-character-set=utf8mb4"
docker exec btl3_mysql bash -c "cat /tmp/db/02_user_procedures.sql | mysql -u root --default-character-set=utf8mb4 btl2_db"
docker exec btl3_mysql bash -c "cat /tmp/db/03_insert_data.sql | mysql -u root --default-character-set=utf8mb4 btl2_db"
docker exec btl3_mysql bash -c "cat /tmp/db/04_stored_procedures.sql | mysql -u root --default-character-set=utf8mb4 btl2_db"
docker exec btl3_mysql bash -c "cat /tmp/db/05_triggers.sql | mysql -u root --default-character-set=utf8mb4 btl2_db"
docker exec btl3_mysql bash -c "cat /tmp/db/06_functions.sql | mysql -u root --default-character-set=utf8mb4 btl2_db"

Write-Host ""
Write-Host "=== Verifying database ===" -ForegroundColor Green
docker exec btl3_mysql mysql -u root --default-character-set=utf8mb4 btl2_db -e "SELECT COUNT(*) AS 'Total Users' FROM Useraccount;"
docker exec btl3_mysql mysql -u root --default-character-set=utf8mb4 btl2_db -e "SELECT COUNT(*) AS 'Total Products' FROM Product;"

Write-Host ""
Write-Host "=== Restarting app ===" -ForegroundColor Green
docker-compose restart app

Write-Host ""
Write-Host "Done! Access app at http://localhost:3000" -ForegroundColor Green
