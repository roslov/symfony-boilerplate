################################
### Microservice boilerplate ###
################################

# Build argument: Image tag
ARG IMAGE_TAG=8.5.5

# Build argument: Composer version
ARG COMPOSER_VERSION=2.9.7

###############################
### Stage: Composer version ###
###############################

# Base image
FROM composer:$COMPOSER_VERSION AS versioned-composer

#############################
### Stage: Base PHP image ###
#############################

# Base image
FROM php:$IMAGE_TAG

# Installs libraries
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
    git \
    jq \
    libicu-dev \
    libpng-dev \
    libzip-dev \
    openssh-client \
    unzip \
    zlib1g-dev \
    --no-install-recommends && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Installs PHP extensions
RUN docker-php-ext-configure gd \
    && docker-php-ext-install \
    bcmath \
    gd \
    intl \
    pcntl \
    sockets \
    zip

# Sets paths
ENV PATH=/app:/app/vendor/bin:$PATH

# Sets common environment variables
ENV PHP_USER_ID=33 \
    TERM=linux

# Sets the working directory
WORKDIR /app

# Copies scripts and configs
COPY image-files/ /

# Sets permissions for scripts
RUN chmod +x /usr/local/bin/*

# Starts the app
CMD ["app-bootstrap"]

# Fixes git dubious ownership
RUN git config --global --add safe.directory /app

# Prepares for loading private Composer dependencies
RUN mkdir -p ~/.ssh \
    && ssh-keyscan -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts

# Installs Composer
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=versioned-composer /usr/bin/composer /usr/bin/composer
