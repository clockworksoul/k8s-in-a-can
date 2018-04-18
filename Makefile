.DEFAULT_GOAL := help

############################
## Project Info
############################
PROJECT = k8s-in-a-can

############################
## Tool versions
############################
ANSIBLE_VERSION = 2.1.1.0-1~ubuntu16.04.1
AWSCLI_VERSION = 1.12.1
HELM_VERSION = 2.8.2
ISTIO_VERSION = 0.6.0
KOPS_VERSION = 1.9.0
KUBECTL_VERSION = 1.10.1
TERRAFORM_VERSION = 0.11.0

############################
## Docker Registry Info
############################
REGISTRY_URL = clockworksoul
IMAGE_NAME = $(REGISTRY_URL)/$(PROJECT)
IMAGE_TAG = $(KUBECTL_VERSION)

help:
	# Commands:
	# make help           - Show this message
	#
	# Dev commands:
	# make clean          - Remove generated files
	# make install        - Install requirements
	#
	# Docker commands:
	# make build          - Build Docker image with current version tag
	# make run            - Run Docker image with current version tag
	#
	# Deployment commands:
	# make push           - Push current version tag to registry

clean:
	echo

install: clean
	echo

build:
	@docker build -t $(IMAGE_NAME):$(IMAGE_TAG) \
		--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
		--build-arg AWSCLI_VERSION=$(AWSCLI_VERSION) \
		--build-arg HELM_VERSION=$(HELM_VERSION) \
		--build-arg KOPS_VERSION=$(KOPS_VERSION) \
		--build-arg KUBECTL_VERSION=$(KUBECTL_VERSION) \
		--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
		.

	@echo "\033[36mDoes the k8s-in-a-can.sh script need to be updated with the new label?\033[0m"
push:
	@docker push $(IMAGE_NAME):$(IMAGE_TAG)
