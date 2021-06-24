# Buildah Introduction
[![Build](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

---

## Description

Buildah is a tool for building OCI-compatible images through a lower-level Coreutils interface. Similar to Podman, Buildah doesn't depend on a daemon, such as Docker or CRI-O, and it doesn't require root privileges. Buildah provides a command-line tool that replicates all the commands found in a Dockerfile

----
## Feature

- It allows for finer control of creating image layers. This is a feature that many container users have been asking for for a long time. Committing many changes to a single layer is desirable.
- Buildah’s run command is not the same as Podman’s run command.  Because Buildah is for building images, the run command is essentially the same as the Dockerfile RUN command. I remember the week this was made explicit. I was foolishly complaining that some port or mount that I was trying wasn’t working as I expected it to.  Dan (@rhatdan) weighed in and said that Buildah should not be supporting running containers in that way. No port mapping. No volume mounting. Those flags were removed.  Instead buildah run is for running specific commands to help build a container image, for example, buildah run dnf -y install nginx.
- Buildah can build images from scratch, that is, images with nothing in them at all. Nothing. Looking at the container storage created as a result of a buildah from scratch command yields an empty directory. This is useful for creating very lightweight images that contain only the packages needed to run your application.

-----

## Pre-Requests

- Need to install docker daemon

-----

## How to install Docker and Buildah

- [Docker installtion](https://docs.docker.com/engine/install/ubuntu/) 
- [Buildah installation](https://github.com/containers/buildah/blob/main/install.md)

---
# How to install these tools
_Steps: (Ubuntu 20.4)_
```sh
sudo apt install docker -y
sudo apt install git -y
. /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${ID^}_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/x${ID^}_${VERSION_ID}/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo apt-get update -qq
sudo apt-get -qq -y install buildah
```
```sh
buildah --version
```

----

## How to Build a buildah image from a Dockerfile (Explanation)
> This dockerfile which I used multistage Dockerfile with a sample template of go language. So, we can reduce the size of that image that was the main advantage of the multistage docker file

### Pull two image from the docker library using buildah
```sh
~$ sudo buildah pull golang:latest
✔ docker.io/library/golang:latest                             <---------------- Image from docker library 
Trying to pull docker.io/library/golang:latest...
Getting image source signatures
Copying blob a8fd09c11b02 done
Copying blob 83d3c0fa203a done
Copying blob a110e5871660 done
Copying blob 0bc3020d05f1 done
Copying blob f37c08d9a1e1 [======================================] 123.1MiB / 123.1MiB
Copying blob 78287c648ba2 done
Copying blob 1f10b5e5b99b done
Copying config ee23292e28 done
Writing manifest to image destination
Storing signatures
ee23292e282684136ded9a63f7f96b3aea50e19e9a5cec684aa7d107d6e1cc30
```

```sh
~$ sudo buildah pull alpine:3.8
Resolved "alpine" as an alias (/etc/containers/registries.conf.d/000-shortnames.conf)
Trying to pull docker.io/library/alpine:3.8...                      <---------------- Image from docker library 
Getting image source signatures
Copying blob 486039affc0a done
Copying config c8bccc0af9 done
Writing manifest to image destination
Storing signatures
c8bccc0af9571ec0d006a43acb5a8d08c4ce42b6cc7194dd6eb167976f501ef1
```

### Images listing command in buildah
```sh
~$ sudo buildah images    
REPOSITORY                 TAG      IMAGE ID       CREATED         SIZE
docker.io/library/golang   latest   ee23292e2826   3 hours ago     883 MB
docker.io/library/alpine   3.8      c8bccc0af957   17 months ago   4.67 MB
```
### Dockerfile and Golanguage Template
_vim Dockerfile_
```sh
FROM golang:latest AS base                   <----------- Temp Image for go compilation
RUN mkdir /var/go
WORKDIR /var/go
COPY ./app.go .
RUN go build app.go

FROM alpine:3.8                           <------------ Container image with less size and execute the go output
COPY --from=base /var/go/app /var/app
RUN chmod +x /var/app
CMD ["/var/app"]
```
_vim app.go_
```sh
package main
import "fmt"
func main() {
    fmt.Println("hello world")
}
```
----
### Buildah Image Creation
```sh
~$ sudo buildah bud -t go:1 .
STEP 1: FROM golang:latest AS base
STEP 2: RUN mkdir /var/go
STEP 3: WORKDIR /var/go
STEP 4: COPY ./app.go .
STEP 5: RUN go build app.go
STEP 6: FROM alpine:3.8
STEP 7: COPY --from=base /var/go/app /var/app
STEP 8: RUN chmod +x /var/app
STEP 9: CMD ["/var/app"]
STEP 10: COMMIT go:1
Getting image source signatures
Copying blob 7444ea29e45e skipped: already exists
Copying blob 7e3a36034b7b done
Copying config d0f1876010 done
Writing manifest to image destination
Storing signatures
--> d0f1876010c
Successfully tagged localhost/go:1
d0f1876010cf8aaa8e42c37f735e097eaeb1e1405f86ebd1bf5ff7f5cb247969


~$ sudo buildah images
REPOSITORY                 TAG      IMAGE ID       CREATED          SIZE
localhost/go               1        d0f1876010cf   15 seconds ago   6.62 MB               <-------------- multistage image created (only 7MB)
docker.io/library/golang   latest   ee23292e2826   3 hours ago      883 MB
docker.io/library/alpine   3.8      c8bccc0af957   17 months ago    4.67 MB
```
### Buildah Image push to local Docker Daemon for creating Creating a Docker container
```sh
~$ sudo buildah push localhost/go:1 docker-daemon:go:1              <-------- push the image from buildah to docker on the same system
Getting image source signatures
Copying blob 7444ea29e45e done
Copying blob 7e3a36034b7b done
Copying config d0f1876010 done
Writing manifest to image destination
Storing signatures
```

```sh
~$ sudo docker image ls                                                  <---------- Image migrated successfully 
REPOSITORY            TAG       IMAGE ID       CREATED             SIZE
go                    1         d0f1876010cf   About an hour ago   6.35MB
```

### Finally create a docker container with the buildah image.
```sh
~$ sudo docker container run --rm go:1
hello world                           <------------- output
```

## Conclusion

Just introduce a RedHat-based tool for docker image creation. Also, you guys can see how to reduce the image size using a multi staging docker file.

<p align="center">
<a href="mailto:yousaf.k.hamza@gmail.com"><img src="https://img.shields.io/badge/-yousaf.k.hamza@gmail.com-D14836?style=flat&logo=Gmail&logoColor=white"/></a>
<a href="https://www.linkedin.com/in/yousafkhamza"><img src="https://img.shields.io/badge/-Linkedin-blue"/></a>
<a href="https://techbit-new.blogspot.com/"><img src="https://img.shields.io/badge/-Blogger-orange"/></a>


