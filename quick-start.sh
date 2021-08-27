docker-compose up -d kong-db

docker-compose run --rm kong kong migrations bootstrap --vv

docker-compose up -d kong

docker-compose up -d konga