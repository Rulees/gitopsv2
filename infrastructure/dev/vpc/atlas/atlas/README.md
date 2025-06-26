# POSTGRES
0) curl -sSf https://atlasgo.sh | sh 
1) docker run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=pass -e POSTGRES_DB=real postgres:17
2) docker exec postgres psql -U postgres -d real -c "SELECT 1;"
3) tg apply
4) docker exec -it postgres psql -uroot -ppass real -e "DESCRIBE users;"

# MYSQL
docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=pass -e MYSQL_DATABASE=myapp mysql:8
docker exec mysql mysql -uroot -ppass -e "SELECT 1"
tg apply
docker exec -it mysql mysql -uroot -ppass myapp -e "DESCRIBE users;"

