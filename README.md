# A primitive set of scripts to deploy tt-rss via docker-compose (Docker Hub variant)

The idea is to provide tt-rss working (and updating) out of the box with minimal fuss.

This setup is still WIP. Some features may be unimplemented or broken. Check the following
before deploying:

- [TODO](https://git.tt-rss.org/fox/ttrss-docker-compose/wiki/TODO)
- [FAQ](https://git.tt-rss.org/fox/ttrss-docker-compose/wiki#faq)

**EXPERIMENTAL, DON'T USE IN PRODUCTION**

General outline of the configuration is as follows:

 - separate containers (frontend: caddy, database: pgsql, app and updater: php/fpm)
 - tt-rss latest git master source baked into container on build
 - images are pulled from Docker Hub (automatically published on tt-rss master source update)
 - working copy is stored on (and rsynced over on restart) a persistent volume so plugins, etc. could be easily added
 - ``config.php`` is generated if it is missing
 - database schema is installed automatically if it is missing
 - Caddy has its http port exposed to the outside
 - optional SSL support via Caddy w/ automatic letsencrypt certificates
 - feed updates are handled via update daemon started in a separate container (updater)

### Installation

#### Get ``docker-compose.yml`` and ``.env-dist``

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

* You will likely have to change ``SELF_URL_PATH`` which should equal fully qualified tt-rss
URL as seen when opening it in your web browser. If this field is set incorrectly, you will
likely see the correct value in the tt-rss fatal error message.

Note: ``SELF_URL_PATH`` is updated in generated tt-rss ``config.php`` automatically on container
restart. You don't need to modify ``config.php`` manually for this.

* By default, container binds to **localhost** port **8280**. If you want the container to be
accessible on the net, without using a reverse proxy sharing same host, you will need to
remove ``127.0.0.1:`` from ``HTTP_PORT`` variable in ``.env``.

#### Pull and start the container

```sh
docker-compose pull && docker-compose up
```

See ``docker-compose`` documentation for more information and available options.

### Updating

You will need to pull a fresh image from Docker Hub to update tt-rss source code. Working copy
will be synchronized on startup.

If database needs to be updated, tt-rss will prompt you to do so on next page refresh.

#### Updating container scripts

1. Stop the containers: ``docker-compose down && docker-compose rm``
2. Update scripts from git: ``git pull origin master`` and apply any necessary modifications to ``.env``, etc.
3. Pull fresh images and start the containers: ``docker-compose pull && docker-compose up``

### Using SSL with Letsencrypt

 - ``HTTP_HOST`` in ``.env`` should be set to a valid hostname (i.e. no localhost or IP address)
 - comment out ``web`` container, uncomment ``web-ssl`` in ``docker-compose.yml``
 - ``SELF_URL_PATH`` in ``.env`` should not include a port as the container is going to use default https port
 - ports 80 and 443 should be externally accessible i.e. not blocked by firewall and/or conflicting with host services

### How do I add plugins and themes?

By default, tt-rss code is stored on a persistent docker volume (``app``). You can find
its location like this:

```sh
docker volume inspect ttrss-docker_app | grep Mountpoint
```

Alternatively, you can mount any host directory as ``/var/www/html`` by updating ``docker-compose.yml``, i.e.:

```yml
volumes:
      - app:/var/www/html
```

Replace with:

```yml
volumes:
      - /opt/tt-rss:/var/www/html
```

Copy and/or git clone any third party plugins into ``plugins.local`` as usual.

### How do I put this container behind a reverse proxy?

A common pattern is shared nginx doing SSL termination, etc.

```nginx
   location /tt-rss/ {
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $remote_addr;
      proxy_set_header X-Forwarded-Proto $scheme;

      proxy_pass http://127.0.0.1:8280/tt-rss/;
      break;
   }
```

You will need to set ``SELF_URL_PATH`` to a correct (i.e. visible from the outside) value in the ``.env`` file.

### Suggestions / bug reports

- [Forum thread](https://community.tt-rss.org/t/docker-compose-tt-rss/2894)
