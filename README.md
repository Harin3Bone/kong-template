# Docker for Kong

![Kong](https://img.shields.io/badge/Kong-1AA687?style=flat&logo=Kongregate&logoColor=FFFFFF)&nbsp;
![Postgresql](https://img.shields.io/badge/Postgresql-FFFFFF?style=flat&logo=postgresql&logoColor=316192)&nbsp;
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=Prometheus&logoColor=FFFFFF)&nbsp;
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=Grafana&logoColor=FFFFFF)&nbsp;
![Docker](https://img.shields.io/badge/Docker-2496ED?&style=flat&logo=docker&logoColor=ffffff)&nbsp;

## Description

This repository made for build simple of Kong with docker.

## Prerequisite

* [Docker](https://docs.docker.com/engine/install/ubuntu/)
* [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

You must run as `sudo` for run command or login as `root`

```sh
sudo time ./quick-start.sh
```

## Postgresql Default Value

Create `.env` file to define your own value

| Variable name | Default value | Datatype | Description |
|:--------------|:--------------|:--------:|------------:|
|PSQL_DB|kong|String|Postgresql database name|
|PSQL_USER|kong|String|Postgresql default user|
|PSQL_PSWD|kong|String|Postgresql default user|
|PSQL_PORT|5432|number|Postgresql default port|
|PSQL_VERSION|13-alpine|String|Postgresql version|
|TIMEZONE|"Asia/Bangkok"|String|System timezone|

## Kong Default Value

| Variable name | Default value | Datatype | Description |
|:--------------|:--------------|:--------:|------------:|
|KONG_VERSION|latest|String|Kong image version|
|KONG_HTTP|80|number|Kong HTTP port|
|KONG_HTTPS|443|number|Kong HTTPS port|
|KONG_ADMIN|8001|number|Kong Admin HTTP port|
|KONG_MANAGE|8444|number|Kong Admin HTTPS port|
|KONG_PROXY_LISTEN|"0.0.0.0:8000, <br> 0.0.0.0:8443 ssl http2"|String|Kong Proxy Listen port|
|KONG_ADMIN_LISTEN|"0.0.0.0:8001, <br> 0.0.0.0:8444 ssl http2"|String|Kong Admin listen port|
|KONG_PREFIX|/var/run/kong|String|Kong prefix|
|TIMEZONE|"Asia/Bangkok"|String|System timezone|

## Konga Default Value

| Variable name | Default value | Datatype | Description |
|:--------------|:--------------|:--------:|------------:|
|KONGA_VERSION|latest|String|Konga image version|
|KONGA_PORT|1337|number|Konga port|
|KONGA_LOG_LEVEL|debug|String|Kong logging level <br> `silly`,`debug`,`info`,`warn`,`error`|
|NODE|development|String|Konga environemnt <br> `production`,`development`|
|TIMEZONE|"Asia/Bangkok"|String|System timezone|

## Setup

**Step 1:** Add `Postgresql` node into `docker-compose.yml`

```yaml
version: '3.8'

services: 
  kong-db:
    image: postgres:${PSQL_VERSION:-13-alpine}
    container_name: kong-db
    ports:
      - "${PSQL_PORT:-5432}:5432"
    environment:
      POSTGRES_DB: ${PSQL_DB:-kong}
      POSTGRES_USER: ${PSQL_USER:-kong}
      POSTGRES_PASSWORD: ${PSQL_PSWD:-kong}
      TZ: ${TIMEZONE:-"Asia/Bangkok"}
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "kong"]
      interval: 5s
      timeout: 30s
      retries: 3
    restart: on-failure
    networks:
      - kong_net
    volumes:
      - kong_data:/var/lib/postgresql/data
```

> **Important !**
>
> You must have `healthcheck` because of postgresql must already start before all of other node.

**Step 2:** Add `Migration` node into `docker-compose.yml`

```yaml
  kong-migrations:
    image: kong
    container_name: kong-migration
    command: kong migrations bootstrap
    depends_on:
      - kong-db
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-db
      KONG_PG_DATABASE: ${PSQL_DB:-kong}
      KONG_PG_USER: ${PSQL_USER:-kong}
      KONG_PG_PASSWORD: ${PSQL_PSWD:-kong}
    networks:
      - kong_net
    restart: on-failure

  kong-migrations-up:
    image: kong
    container_name: kong-migration-up
    command: kong migrations up && kong migrations finish
    depends_on:
      - kong-db
    environment:
      KONG_DATABASE: postgres
      KONG_PG_DATABASE: kong
      KONG_PG_HOST: kong-db
      KONG_PG_USER: kong
      KONG_PG_PASSWORD: kong
    networks:
      - kong_net
    restart: on-failure
```

> **Note**
> From `docker-compose.yml` on above it's not `Kong` server node. But it's **Kong migration** command. Because it's following from install instruction.

**Step 3:** Add `Kong` server node into `docker-compose.yml`

```yaml
  kong:
    image: kong
    container_name: kong
    user: kong
    depends_on:
      - kong-db
    environment:
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_PROXY_LISTEN: ${KONG_PROXY_LISTEN:-"0.0.0.0:8000, 0.0.0.0:8443 ssl http2"}
      KONG_ADMIN_LISTEN: ${KONG_ADMIN_LISTEN:-"0.0.0.0:8001, 0.0.0.0:8444 ssl http2"}
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-db
      KONG_PG_DATABASE: ${PSQL_DB:-kong}
      KONG_PG_USER: ${PSQL_USER:-kong}
      KONG_PG_PASSWORD: ${PSQL_PSWD:-kong}
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_PREFIX: ${KONG_PREFIX:-/var/run/kong}
      TZ: ${TIMEZONE:-"Asia/Bangkok"}
    networks:
      - kong_net
    ports:
      - "${KONG_HTTP:-80}:8000"
      - "${KONG_HTTPS:-443}:8443"
      - "${KONG_ADMIN:-8001}:8001"
      - "${KONG_MANAGE:-8444}:8444"
    healthcheck:
      test: ["CMD", "kong", "health"]
      interval: 10s
      timeout: 10s
      retries: 10
    restart: on-failure:5
    read_only: true
    volumes:
      - kong_prefix_vol:${KONG_PREFIX:-/var/run/kong}
      - kong_tmp_vol:/tmp
```

> **Note**
>
> From `docker-compose.yml` on above you may see a lot of environment. But for starter i think you should care only `KONG_PG`
>
> if you config without `.env` you must make sure that value is same as `Postgresql`  node

> **Important !**
>
> `KONG_ADMIN` and `KONG_MANAGE` of this it's use 8001 , 8444. But in production for security you should use 127.0.0.1:8001 , 127.0.0.1:8444.
>
> Because if it 8001 it's mean 0.0.0.0:8001, That's mean everyone can access `Kong-Admin API` without login to VM

**Step 4:** Add `Konga` into `docker-compose.yml`

```yaml
  konga:
    image: pantsel/konga
    container_name: konga
    volumes:
      - konga_data:/app/kongadata
    networks:
      - kong_net
    ports:
      - "${KONGA_PORT:-1337}:1337"
    environment:
      TZ: ${TIMEZONE:-"Asia/Bangkok"}
      KONGA_LOG_LEVEL: ${KONGA_LOG_LEVEL:-debug}
      NODE_ENV: ${NODE:-development}
    links:
      - kong:kong
    restart: always
```

> **Note**
>
> If on production. Value of `NODE_ENV` should use **production** instead

**Step 5:** Add volume into `docker-compose.yml`

```yaml
volumes: 
  kong_data: {}
  konga_data: {}
  kong_prefix_vol:
    driver_opts:
     type: tmpfs
     device: tmpfs
  kong_tmp_vol:
    driver_opts:
     type: tmpfs
     device: tmpfs
```

**Step 6:** Add network into `docker-compose.yml`

```yaml
networks: 
  kong_net:
    external: false
    driver: bridge
```

Then `docker-compose.yml` will look like [this](https://github.com/Harin3Bone/kong-template/blob/main/example/sample-kong.yml)

**Step 7:** Start server

```bash
docker-compose up -d
```

By the way you can run a lot of more command like this

```bash
docker-compose up -d kong-db

docker-compose run --rm kong kong migrations bootstrap --vv

docker-compose up -d kong

docker-compose up -d konga
```

> ### **Note**
>
> After all of this start finish. you can remove container `kong-migrations` and `kong-migrations-up` later. Because it just create for run migration command only

## Implement monitoring system

We will use `Prometheus` , `Node Exporter` and `Grafana` to monitoring.

### Monitoring Default Value

| Variable name | Default value | Datatype | Description |
|:--------------|:--------------|:--------:|------------:|
|PROMETHEUS_VERSION|latest|String|Prometheus image version|
|PROMETHEUS_PORT|9090|number|Prometheus running port|
|NODEEXP_VERSION|latest|String|Node Exporter running port|
|NODEEXP_PORT|9100|number|Node Exporter running port|
|GRAFANA_VERSION|8.2.6-ubuntu|String|Grafana image version|
|GRAFANA_PORT|3000|number|Grafana running port|
|TIMEZONE|"Asia/Bangkok"|String|System timezone|

**Step 1:** create `prometheus.yml`

```yaml
global:
  external_labels:
    monitor: devops_monitor
  scrape_interval: 5s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - "localhost:9090"

  - job_name: node_exporter
    static_configs:
      - targets:
          - "node_exporter:9100"

  - job_name: kong
    static_configs:
      - targets:
          - "kong:8001"
```

> **Note**
>
> `prometheus.yml` is a configuration file of prometheus service

**Step 2:** add `Prometheus` service to `docker-compose.yml`

```yaml
  prometheus:
    image: prom/prometheus:${PROMETHEUS_VERSION:-latest}
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/promtheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
    ports:
      - "${PROMETHEUS_PORT:-9090}:9090"
    restart: always
    networks:
      - kong_net
    environment:
      TZ: ${TIMEZONE:-"Asia/Bangkok"}
```

**Step 3:** add `Node Exporter` service to `docker-compose.yml`

```yaml
  node_exporter:
    image: prom/node-exporter:${NODEEXP_VERSION:-latest}
    container_name: node_exporter
    ports:
      - "${NODEEXP_PORT:-9100}:9100"
    networks:
      - kong_net
    restart: always
```

**Step 3:** add `Grafana` service to `docker-compose.yml`

```yaml
  grafana:
    image: grafana/grafana:${GRAFANA_VERSION:-8.2.6-ubuntu}
    container_name: grafana
    ports:
      - ${GRAFANA_PORT:-3000}:3000
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - kong_net
    environment:
      TZ: ${TIMEZONE:-"Asia/Bangkok"}
    restart: always
```

**Step 4:** Create volume for `Prometheus` service

```yaml
volumes:
  prometheus_data: {}
  grafana_data: {}
```

Then `docker-compose.yml` will look like [this](https://github.com/Harin3Bone/kong-template/blob/main/example/sample-monitor.yml)

**Step 5:** Start server

```bash
docker-compose up -d
```

## Reference

* [Docker hub (Kong)](https://hub.docker.com/_/kong)
* [Docker hub (Postgresql)](https://hub.docker.com/_/postgres)
* [Docker hub (Konga)](https://hub.docker.com/r/pantsel/konga)
* [Kong](https://konghq.com/)
* [Kong Docker](https://github.com/Kong/docker-kong)
* [Konga](https://github.com/pantsel/konga)
* [Prometheus](https://prometheus.io/docs/prometheus/latest/installation/#using-docker)
* [Node Exporter](https://github.com/prometheus/node_exporter)
* [Grafana](https://grafana.com/docs/grafana/latest/installation/docker/)
* [Kong Dashboard](https://grafana.com/grafana/dashboards/7424)
* [Node Exporter Dashboard](https://grafana.com/grafana/dashboards/1860)

## Contributor

<a href="https://github.com/Harin3Bone">
<img src="https://img.shields.io/badge/Harin3Bone-181717?style=flat&logo=github&logoColor=ffffff">
</a>
