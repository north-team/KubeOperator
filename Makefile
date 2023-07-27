GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
BASEPATH := $(shell pwd)
BUILDDIR=$(BASEPATH)/dist
GOGINDATA=go-bindata

KO_SERVER_NAME=ko-server
KO_CONFIG_DIR=etc/ko
KO_BIN_DIR=usr/local/bin
KO_DATA_DIR=usr/local/lib/ko

GOPROXY="https://goproxy.cn,direct"

image_name ?= "registry.fit2cloud.com/north/kubeoperator/server"
branch ?= "north"
image = "${image_name}:${branch}"

build_server_linux:
	GOOS=linux $(GOGINDATA) -o ./pkg/i18n/locales.go -pkg i18n ./locales/...
	GOOS=linux $(GOBUILD) -o $(BUILDDIR)/$(KO_BIN_DIR)/$(KO_SERVER_NAME) main.go
	mkdir -p $(BUILDDIR)/$(KO_CONFIG_DIR) && cp -r  $(BASEPATH)/conf/app.yaml $(BUILDDIR)/$(KO_CONFIG_DIR)
	mkdir -p $(BUILDDIR)/$(KO_DATA_DIR)
	cp -r  $(BASEPATH)/migration $(BUILDDIR)/$(KO_DATA_DIR)

docker_ui:
	docker build -t registry.fit2cloud.com/north/kubeoperator/ui:master  ./ui --no-cache

docker_server:
	docker build -t ${image} --build-arg GOPROXY=$(GOPROXY) --build-arg --build-arg XPACK="no" .

dockerx_server:
	docker buildx build -t ${image} --output "type=image,push=false" --platform linux/amd64,linux/arm64 --build-arg GOPROXY=$(GOPROXY) --build-arg XPACK="no" .

docker_save:
	docker pull --platform=linux/amd64 ${image}
	docker save -o ko-${branch}.tar  ${image}
	docker pull --platform=linux/arm64 ${image}
	docker save -o ko-arm-${branch}.tar  ${image}
	docker rmi ${image}

docker_server_xpack:
	docker build -t ${image} --build-arg GOPROXY=$(GOPROXY) --build-arg --build-arg XPACK="yes" .

clean:
	rm -fr ./dist
	go clean
