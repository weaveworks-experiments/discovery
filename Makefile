PUBLISH=publish_weavediscovery

.DEFAULT: all
.PHONY: all update tests publish $(PUBLISH) clean prerequisites build travis run-smoketests

# If you can use docker without being root, you can do "make SUDO="
SUDO=sudo

DOCKERHUB_USER=weaveworks
WEAVE_VERSION=git-$(shell git rev-parse --short=12 HEAD)

WEAVEDISCOVERY_EXE=prog/weavediscovery/weavediscovery
EXES=$(WEAVEDISCOVERY_EXE)
WEAVEDISCOVERY_UPTODATE=.weavediscovery.uptodate
IMAGES_UPTODATE=$(WEAVEDISCOVERY_UPTODATE)
WEAVEDISCOVERY_IMAGE=$(DOCKERHUB_USER)/weavediscovery
IMAGES=$(WEAVEDISCOVERY_IMAGE)
WEAVE_EXPORT=weavediscovery.tar

all: $(WEAVE_EXPORT)

travis: $(EXES)

update:
	go get -u -f -v -tags -netgo $(addprefix ./,$(dir $(EXES)))

$(WEAVEDISCOVERY_EXE):
	go get -tags netgo ./$(@D)
	go build -ldflags "-extldflags \"-static\" -X main.version $(WEAVE_VERSION)" -tags netgo -o $@ ./$(@D)
	@strings $@ | grep cgo_stub\\\.go >/dev/null || { \
		rm $@; \
		echo "\nYour go standard library was built without the 'netgo' build tag."; \
		echo "To fix that, run"; \
		echo "    sudo go clean -i net"; \
		echo "    sudo go install -tags netgo std"; \
		false; \
	}

$(WEAVEDISCOVERY_EXE): prog/weavediscovery/*.go

$(WEAVEDISCOVERY_UPTODATE): prog/weavediscovery/Dockerfile $(WEAVEDISCOVERY_EXE)
	$(SUDO) docker build -t $(WEAVEDISCOVERY_IMAGE) prog/weavediscovery
	touch $@

$(WEAVE_EXPORT): $(IMAGES_UPTODATE)
	$(SUDO) docker save $(addsuffix :latest,$(IMAGES)) > $@

$(DOCKER_DISTRIB):
	curl -o $(DOCKER_DISTRIB) $(DOCKER_DISTRIB_URL)

$(PUBLISH): publish_%:
	$(SUDO) docker tag -f $(DOCKERHUB_USER)/$* $(DOCKERHUB_USER)/$*:$(WEAVE_VERSION)
	$(SUDO) docker push   $(DOCKERHUB_USER)/$*:$(WEAVE_VERSION)
	$(SUDO) docker push   $(DOCKERHUB_USER)/$*:latest

publish: $(PUBLISH)

clean:
	-$(SUDO) docker rmi $(IMAGES) 2>/dev/null
	rm -f $(EXES) $(IMAGES_UPTODATE) $(WEAVE_EXPORT) test/tls/*.pem coverage.html profile.cov

build:
	$(SUDO) go clean -i net
	$(SUDO) go install -tags netgo std
	$(MAKE)
