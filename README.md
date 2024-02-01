# rhda-pipelines-examples
Bring some examples of how to use RHDA Jenkins plugin


## Prerequisites
1. Download Jenkins LTS and Run it on your machine
```shell
curl -X GET https://get.jenkins.io/war-stable/2.426.3/jenkins.war -o /tmp/jenkins.war
java -jar /tmp/jenkins.war --enable-future-java
```

2. Podman CLI Or Docker Daemon, if you don't have docker, can spin up a docker daemon inside a podman container( DIND -Docker in Docker)
   , And Map your user $HOME/.jenkins directory as volume to the container  
```shell
podman volume create some-docker-certs-ca
podman volume create some-docker-certs-client
podman network create docker-network
podman run --privileged --user=root --name docker -d --network docker-network -e DOCKER_TLS_CERTDIR=/certs -v some-docker-certs-ca:/certs/ca -v some-docker-certs-client:/certs/client -v $HOME/.jenkins/:$HOME/.jenkins -p 2376:2376 docker:dind
```

## Demos

### Python Pip

#### Docker

#### Podman

### Java Maven

 - Using maven wrapper or maven tool

### NPM
 - Using node tool

### GO

- Using OCI/Docker image that contains go or go tool if exists.

