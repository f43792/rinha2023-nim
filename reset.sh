docker-compose down
docker rm $(docker ps -q)
docker rmi $(docker images -q)
docker volume rm $(docker volume ls -q)