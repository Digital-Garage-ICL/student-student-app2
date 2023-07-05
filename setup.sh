#!/bin/bash
# Setup Github actions variables and secrets

## Usage:
## Run this script from the root of the repo

## Pre-requisites:
## - jq (json parser)
## - wf cli (with a profile pointing at the correct server)
## - gh (github cli) -- run `gh auth login` first

# Download wf cli for Mac Intel processor (set WAYFINDER_VERSION to the version of Wayfinder currently deployed)
# curl -fsSLo ./wf.tgz https://storage.googleapis.com/wayfinder-dev-releases/${WAYFINDER_VERSION}/wf-cli-darwin-amd64.tar.gz && tar -xzf ./wf.tgz -C .
# sudo mv ./wf-cli-darwin-amd64 /usr/local/bin/wf

# Download wf cli for Mac Apple Silicon processor (M1/M2) (set WAYFINDER_VERSION to the version of Wayfinder currently deployed)
# curl -fsSLo ./wf.tgz https://storage.googleapis.com/wayfinder-dev-releases/${WAYFINDER_VERSION}/wf-cli-darwin-arm64.tar.gz && tar -xzf ./wf.tgz -C .
# sudo mv ./wf-cli-darwin-arm64 /usr/local/bin/wf

# Download wf cli for Linux (set WAYFINDER_VERSION to the version of Wayfinder currently deployed)
# curl -fsSLo ./wf.tgz https://storage.googleapis.com/wayfinder-dev-releases/${WAYFINDER_VERSION}/wf-cli-linux-amd64.tar.gz && tar -xzf ./wf.tgz -C .
# sudo mv ./wf-cli-linux-amd64 /usr/local/bin/wf

# Download wf cli for Windows (set WAYFINDER_VERSION to the version of Wayfinder currently deployed)
# $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://storage.googleapis.com/wayfinder-dev-releases/${env:WAYFINDER_VERSION}/wf-cli-windows-amd64.exe.tar.gz -OutFile $env:TEMP/wf.tgz; tar -C $env:TEMP -xzf $env:TEMP/wf.tgz
# mv $env:TEMP/wf-cli-windows-amd64.exe ./wf.exe

# jq download: https://jqlang.github.io/jq/download/

# gh cli download: https://cli.github.com/

# Wayfinder version and endpoint have already been set up as Github actions variables
# FYI, they can be obtained with
# wf serverinfo -o json | jq -r .version.release
# wf profiles show -o json | jq -r .endpoint

## Secrets
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 repo_name workspace_name personal_gh_token"
    echo "where workspace_name is the name of the WayFinder workspace to set up (e.g. sabc12)"
    echo "      personal_gh_token is a personal access token (classic) with read:pacakges scope"
    exit 1
fi

SHORT_REPO_NAME=$(basename "$PWD")
WORKSPACE_NAME=$1
PERSONAL_GH_TOKEN=$2
FULL_REPO_NAME="Digital-Garage-ICL/${SHORT_REPO_NAME}"
# TODO - if you rename the app, you'll need to change this and re-run the script to make sure that the Workspace Access Token (WAT) has the correct permissions
APP_NAME=example-app
# TODO - if you rename the environment, you'll need to change this and re-run the script to make sure that the Workspace Access Token (WAT) has the correct permissions
ENVIRONMENT=dev

APPLICATION_DIRECTORY='infra'
APPLICATION_FILENAME='application.yaml'
APP_ENVIRONMENT_FILENAME='appenv.yaml'

echo Repo name: ${SHORT_REPO_NAME}

token=$(wf create wat ${SHORT_REPO_NAME} -w ${WORKSPACE_NAME} --reset-token --show-token)
gh secret set WAYFINDER_TOKEN --repo ${FULL_REPO_NAME} --body $token

wf use workspace ${WORKSPACE_NAME}

# now we have to create the app and app environment so that there is an application namespace we can give the Worksapce Access Token (WAT) access to
# otherwise the wf asssign accessrole commands below will fail
wf apply -f "${APPLICATION_DIRECTORY}/${APPLICATION_FILENAME}"
wf apply -f "${APPLICATION_DIRECTORY}/${APP_ENVIRONMENT_FILENAME}" --wait-for-ready '1m'

# allow the Workspace Access Token (WAT) to manage apps, DNS, etc
wf assign wayfinderrole --workspace ${WORKSPACE_NAME} --workspace-access-token ${SHORT_REPO_NAME} --role workspace.appmanager
wf assign wayfinderrole --workspace ${WORKSPACE_NAME} --workspace-access-token ${SHORT_REPO_NAME} --role workspace.dnsmanager
wf assign wayfinderrole --workspace ${WORKSPACE_NAME} --workspace-access-token ${SHORT_REPO_NAME} --role workspace.accessmanager
wf assign wayfinderrole --workspace ${WORKSPACE_NAME} --workspace-access-token ${SHORT_REPO_NAME} --role workspace.appdeployer

wf assign accessrole --workspace ${WORKSPACE_NAME} --workspace-access-token ${SHORT_REPO_NAME} --role cluster.deployment --cluster aks-stdnt1
wf assign accessrole --workspace ${WORKSPACE_NAME} --workspace-access-token ${SHORT_REPO_NAME} --role namespace.deployment --cluster aks-stdnt1 --namespace ${WORKSPACE_NAME}-${APP_NAME}-${ENVIRONMENT}

# get access to our kuberenetes namespace so that we can create a secret allowing kubernetes' kubelet to pull our container image
wf access cluster to1.aks-stdnt1 --role namespace.admin --namespace ${WORKSPACE_NAME}-${APP_NAME}-${ENVIRONMENT}

export GITHUB_TOKEN=$PERSONAL_GH_TOKEN
username=$(gh api user | jq -r '.login')

# create a k8s secret so that kubelet can pull our container image
# but delete the secret first in case it already exists
kubectl delete secret ghcr-login-secret --namespace ${WORKSPACE_NAME}-${APP_NAME}-${ENVIRONMENT} > /dev/null 2>&1 || true
kubectl create secret docker-registry ghcr-login-secret --namespace ${WORKSPACE_NAME}-${APP_NAME}-${ENVIRONMENT} --docker-username=$username --docker-password=$PERSONAL_GH_TOKEN --docker-server=ghcr.io
