# Dockerized tt-rss using docker-compose

The idea is to provide tt-rss working (and updating) out of the box with minimal fuss.

**This setup uses official prebuilt images from Docker Hub. Note that images are only available for Linux/amd64.**

- [TODO](https://git.tt-rss.org/fox/ttrss-docker-compose/wiki/TODO)
- [FAQ](https://git.tt-rss.org/fox/ttrss-docker-compose/wiki#faq)

General outline of the configuration is as follows:

 - separate containers (frontend: nginx, database: pgsql, app and updater: php/fpm)
 - tt-rss latest git master source baked into container on build
 - images are pulled from [Docker Hub](https://hub.docker.com/u/cthulhoo) (automatically built and published on tt-rss master source update)
 - working copy is stored on (and rsynced over on restart) a persistent volume so plugins, etc. could be easily added
 - database schema is installed automatically if it is missing
 - nginx has its http port exposed to the outside
 - optional SSL support via Caddy w/ automatic letsencrypt certificates (deprecated)
 - feed updates are handled via update daemon started in a separate container (updater)
 - optional backups container which performs tt-rss database backup once a week

### Installation

#### Get [docker-compose.yml](https://git.tt-rss.org/fox/ttrss-docker-compose/src/static-dockerhub/docker-compose.yml) and [.env-dist](https://git.tt-rss.org/fox/ttrss-docker-compose/src/static-dockerhub/.env-dist)

```sh
git clone https://git.tt-rss.org/fox/ttrss-docker-compose.git ttrss-docker
cd ttrss-docker
git checkout static-dockerhub
```

You're interested in ``docker-compose.yml`` stored in root directory, as opposed to ``src``.

Latter directory is used to build images for publishing on Docker Hub. Use it if you
want to build your own containers.

#### Edit configuration files:

Copy ``.env-dist`` to ``.env`` and edit any relevant variables you need changed.

You will likely have to change ``SELF_URL_PATH`` which should equal fully qualified tt-rss
URL as seen when opening it in your web browser. If this field is set incorrectly, you will
likely see the correct value in the tt-rss fatal error message.

By default, `web` container binds to **localhost** port **8280**. If you want the container to be
accessible on the net, without using a reverse proxy sharing same host, you will need to
remove ``127.0.0.1:`` from ``HTTP_PORT`` variable in ``.env``.

Please don't rename the services inside `docker-compose.yml` unless you know what you're doing. Web container expects application container to be named `app`, if you rename it and it's not accessible via Docker DNS as `http://app` you will run into 502 errors on startup.

Main configuration file (`config.php`) is rewritten on startup, don't edit it manually. Use environment variables
(see `app/Dockerfile` for complete list) or `config.d` snippets to customize it.

#### Pull and start the container

```sh
docker-compose pull && docker-compose up -d
```

See ``docker-compose`` documentation for more information and available options.

### Updating

You will need to pull a fresh image from Docker Hub to update tt-rss source code. Working copy
will be synchronized on startup.

If database needs to be updated, tt-rss will prompt you to do so on next page refresh.

#### Updating container scripts

1. Stop the containers: ``docker-compose down && docker-compose rm``
2. Update scripts from git: ``git pull origin static-dockerhub`` and apply any necessary modifications to ``.env``, etc.
3. Pull fresh images and start the containers: ``docker-compose pull && docker-compose up``

### Suggestions / bug reports

- [Forum thread](https://community.tt-rss.org/t/docker-compose-tt-rss/2894)
