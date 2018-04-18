#!/usr/bin/env bash

set -e

# The Docker image and version to use.
#
KIIC_IMAGE="clockworksoul/k8s-in-a-can"
KIIC_VERSION="1.10.1"

# Determines the fully-qualified script source directory. Don't change this
# unless you know what you're doing and why.
readonly SCRIPT_SOURCE_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

###############################################################################
# Environment variables. By default these are imported from the user's 
# environment, but this can be overidden by seting them here.
###############################################################################

# The AWS access key ID and and secret access keys. By default these values 
# are taken from the user's environment, but they can be set here as well.
#
ENV_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV_AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

# The address of the kops state store: an S3 bucket where the cluster
# configuration lives (example: `s3://conductor-testing-kops-state`)
#
ENV_KOPS_STATE_STORE=${KOPS_STATE_STORE}

# The (optional) location of your ansible-vault password file. Only necessary
# if you intend to use ansible vault.
ENV_ABSOLUTE_VAULT_PASSWORD_FILE=${ANSIBLE_VAULT_PASSWORD_FILE}

# The location of the configuration files. You can use ${HOME} to use your own
# settings, or you can store per-environment configs by changing this to a
# directory name (which will be created if it doesn't exist)
#
#CONFIGURATION_HOME="${HOME}/."
CONFIGURATION_HOME=${SCRIPT_SOURCE_DIRECTORY}/config/

# The ssh keys to use. You'll usually want to use yours, but you can create
# new ones per environment if you really want to.
#
#VOLUME_SSH=${CONFIGURATION_HOME}ssh
VOLUME_SSH=${HOME}/.ssh

# A source directory to volume in. If this isn't set the script will assume
# it's part of a git repo and volume the entire repository.
#
VOLUME_SOURCE=

###############################################################################
# Don't change any of the following variables.
###############################################################################

# The files and directories to volume into the container.
#
readonly VOLUME_ANSIBLE=${CONFIGURATION_HOME}ansible
readonly VOLUME_AWS=${CONFIGURATION_HOME}aws
readonly VOLUME_GITCONFIG=${CONFIGURATION_HOME}gitconfig
readonly VOLUME_HELM=${CONFIGURATION_HOME}helm
readonly VOLUME_KUBE=${CONFIGURATION_HOME}kube

# Scans downward from the script's source directory to find a .git directory.
# If it doesn't find it, it uses the script's source directory.
#
guess_source_directory()
{
  (
    cd ${SCRIPT_SOURCE_DIRECTORY}

    while [ "$(pwd)" != "/" ]; do
      if [ -e .git ]; then
        break
      fi

      cd ..
    done

    if [ "$(pwd)" == "/" ]; then
      cd ${SCRIPT_SOURCE_DIRECTORY}
    fi

    echo $(pwd)
  )
}

# If VOLUME_SOURCE isn't specified, we guess the volume to be the one with
# a .git repo.
#
if [ -z "${VOLUME_SOURCE}" ]; then
  VOLUME_SOURCE="$(guess_source_directory)"
  echo "Source directory unspecified. Using: ${VOLUME_SOURCE}"
fi

# Discovers the absolute location of the working code so it can be volumed in.
#
readonly ABSOLUTE_SOURCE_DIR="$(cd "${VOLUME_SOURCE}" && pwd)"

# If ANSIBLE_VAULT_PASSWORD_FILE is unset, this will set it to a standard value
# and create a placeholder password file in that location.
#
if [ -z "$ENV_ABSOLUTE_VAULT_PASSWORD_FILE" ]; then
  ENV_ABSOLUTE_VAULT_PASSWORD_FILE="${CONFIGURATION_HOME}ansible/vault_password.txt"

  if [ ! -f $ENV_ABSOLUTE_VAULT_PASSWORD_FILE ]; then
    mkdir -p $(dirname ${ENV_ABSOLUTE_VAULT_PASSWORD_FILE})
    echo "NO-PLAYBOOKS-FOR-YOU" > $ENV_ABSOLUTE_VAULT_PASSWORD_FILE
    chmod 400 $ENV_ABSOLUTE_VAULT_PASSWORD_FILE
  fi
fi

if [ ! $(ls -l $ENV_ABSOLUTE_VAULT_PASSWORD_FILE | awk '{print $1}' | grep '\-\-\-\-\-\-$') ]; then
  echo "WARNING: Permissions on $ENV_ABSOLUTE_VAULT_PASSWORD_FILE are too open! Execute the following to resolve: chmod 400 $ENV_ABSOLUTE_VAULT_PASSWORD_FILE"
fi

# (Somewhat) safely standardizes the location of the ansible vault file
# location from the $ENV_ABSOLUTE_VAULT_PASSWORD_FILE environment setting. Using a
# tilde will break this. :/
#
readonly ABSOLUTE_VAULT_PASSWORD_FILE="$(cd $(dirname ${ENV_ABSOLUTE_VAULT_PASSWORD_FILE}) && pwd)/$(basename ${ENV_ABSOLUTE_VAULT_PASSWORD_FILE})"

# Ensure that some standard files and directories exist and have the proper
# permissions where appropriate. Docker would actually create these
# automatically, but would do so with root ownership, which makes things annoying.
#
for d in ${VOLUME_ANSIBLE} ${VOLUME_AWS} ${VOLUME_HELM} ${VOLUME_KUBE} ${VOLUME_SSH}; do
  mkdir -vp $d
done

touch ${VOLUME_GITCONFIG} ${VOLUME_KUBE}/config

# Make sure that we have the newest version of the image.
#
docker pull ${KIIC_IMAGE}:${KIIC_VERSION} || true

# Finally, run and attach to the container proper.
#
docker run -it \
  -h can \
  --net=host \
  -v ${VOLUME_ANSIBLE}:/home/k8s/.ansible:rw \
  -v ${VOLUME_GITCONFIG}:/home/k8s/.gitconfig:rw \
  -v ${VOLUME_HELM}:/home/k8s/.helm:rw \
  -v ${VOLUME_AWS}:/home/k8s/.aws:rw \
  -v ${VOLUME_KUBE}:/home/k8s/.kube:rw \
  -v ${VOLUME_SSH}:/home/k8s/.ssh:rw \
  -v ${ABSOLUTE_SOURCE_DIR}:/home/k8s/$(basename ${ABSOLUTE_SOURCE_DIR}):rw \
  -v ${ENV_ABSOLUTE_VAULT_PASSWORD_FILE}:/home/k8s/.avp:ro \
  -e AWS_ACCESS_KEY_ID=${ENV_AWS_ACCESS_KEY_ID} \
  -e AWS_SECRET_ACCESS_KEY=${ENV_AWS_SECRET_ACCESS_KEY} \
  -e KOPS_STATE_STORE=${ENV_KOPS_STATE_STORE} \
  ${KIIC_IMAGE}:${KIIC_VERSION}
