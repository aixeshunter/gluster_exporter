GO           ?= go
GOPATH       := $(firstword $(subst :, ,$(shell $(GO) env GOPATH)))
pkgs         = $(shell $(GO) list ./... | grep -v /vendor/)
PROMU        ?= $(GOPATH)/bin/promu
GODEP        ?= $(GOPATH)/bin/dep
GOLINTER     ?= $(GOPATH)/bin/gometalinter
BIN_DIR      ?= $(shell pwd):x
TARGET       ?= gluster_exporter

DOCKERFILE	      ?= Dockerfile
DOCKER_REPO       ?= aixeshunter
DOCKER_IMAGE_NAME ?= glusterfs-exporter
DOCKER_IMAGE_TAG  ?= v1.0

info:
	@echo "build: Go build"
	@echo "docker: build and run in docker container"
	@echo "gometalinter: run some linting checks"
	@echo "gotest: run go tests and reformats"

build: depcheck $(PROMU) gotest
	@echo ">> building binaries"
	@$(PROMU) build

docker: gotest build
	@echo ">> building docker image from $(DOCKERFILE)"
	@docker build -t "$(DOCKER_REPO)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)" .

gotest: vet format
	@echo ">> running tests"
	@$(GO) test -short $(pkgs)

format:
	@echo ">> formatting code"
	@$(GO) fmt $(pkgs)

vet:
	@echo ">> vetting code"
	@$(GO) vet $(pkgs)

$(GOPATH)/bin/promu promu:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
		GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
		$(GO) get -u github.com/prometheus/promu

promu-build: gotest promu
	$(PROMU) build

tarball: build promu
	@$(PROMU) tarball $(BIN_DIR)

clean:
	@echo ">> cleaning up"
	@find . -type f -name '*~' -exec rm -fv {} \;
	@$(RM) $(TARGET)

depcheck: $(GODEP)
	@echo ">> ensure vendoring"
	@$(GODEP) ensure

gometalinter: $(GOLINTER)
	@echo ">> linting code"
	@$(GOLINTER) --install > /dev/null
	@$(GOLINTER) --config=./.gometalinter.json ./...

$(GOPATH)/bin/dep dep:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
		GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
		$(GO) get -u github.com/golang/dep/cmd/dep

$(GOPATH)/bin/gometalinter lint:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
		GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
		$(GO) get -u github.com/alecthomas/gometalinter

.PHONY: all format vet build gotest promu promu-build clean $(GOPATH)/bin/promu $(GOPATH)/bin/dep dep depcheck $(GOPATH)/bin/gometalinter lint
