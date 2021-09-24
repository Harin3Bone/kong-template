docker-compose up -d kong-db

docker-compose run --rm kong kong migrations bootstrap --vv

docker-compose up -d kong

docker-compose up -d konga

docker-compose up -d prometheus

docker-compose up -d node_exporter

docker-compose up -d grafana