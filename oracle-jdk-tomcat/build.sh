#!/bin/bash

NAMESPACE=sourcegarden
NAME=tomcat
FULLNAME=registry.cn-hangzhou.aliyuncs.com/${NAMESPACE}/${NAME}
#FULLNAME=$(NAMESPACE)/$(NAME)
DOCKERFILE=$2
VERSION=$3


all(){
	usage
	build
}

clean(){

	CID=$( docker ps -a | awk '{ print $1 " " $2 }' | grep ${FULLNAME} | awk '{ print $1 }' )
	if [ ! -z "$CID" ];then
		echo "Removing container which reference $(FULLNAME)"
		for container in ${CID};do 
			docker rm -f $container
		done
	fi

	echo "Removing image $(FULLNAME)"

	if docker images ${FULLNAME} | awk '{ print $2 }' | grep -q -F ${VERSION}; then 
		docker rmi -f ${FULLNAME}:${VERSION}
	
	fi

	if docker images ${FULLNAME} | awk '{ print $2 }' | grep -q -F latest; then 
		docker rmi -f ${FULLNAME}:latest
	fi
}

build(){
	clean ${FULLNAME} ${VERSION}
	docker build -t ${FULLNAME}:${VERSION} --rm -f ./${DOCKERFILE} .
}

tag_latest(){
	docker tag ${FULLNAME}:${VERSION} ${FULLNAME}:latest
}

release(){
	build 
	tag_latest
	docker push ${FULLNAME}
#	@echo "Create a tag v-${VERSION}"
#	@git tag v-${VERSION}
#	@git push origin v-${VERSION}
}

debug(){
	docker run -t -i ${FULLNAME}:${VERSION} /bin/bash
}

save(){
	OUTPUT_FILE =  ${NAME}_${VERSION}_`date +%Y%m%d%H%M%S`.tgz
	docker save ${FULLNAME}:${VERSION} | gzip --best --stdout  > ${OUTPUT_FILE}
	echo "Image ${FULLNAME}:${VERSION} exported to ${OUTPUT_FILE}"
}

# run(){
# 	echo "IPAddress =" $$(docker inspect --format '{{.NetworkSettings.IPAddress}}' $$(docker run -d $(FULLNAME):$(VERSION)))
# }

usage(){
	echo "List of target"
	echo "all: print usage and build"
	echo "clean:         remove containers and image"
	echo "build:         build docker image"
	echo "tag_latest:    build and tag image with 'latest'"
	echo "debug:         launch a shell with this image"
	echo "save:          export this image"
	echo "run:           launch this image with inner command"
	echo "usage:         this help"
}

#release

$1