#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

echo " === install-tools.sh === "

# brew
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"



# age
brew install age

# Carvel
wget -O- https://carvel.dev/install.sh | sudo bash

# direnv
sudo apt-get install direnv
direnv hook bash >> ~/.bashrc
eval "$(direnv hook bash)"

# git
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt-get update
sudo apt-get install git -y

# GitHub
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

# Java 17
sudo apt install -y wget apt-transport-https
sudo mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update
sudo apt install temurin-17-jdk -y

# jq
sudo apt-get --assume-yes install jq

# k9s
brew install k9s

# kubectl
brew install kubectl

# mozilla sops (https://docs.technotim.live/posts/install-mozilla-sops/)
SOPS_LATEST_VERSION=$(curl -s "https://api.github.com/repositories/40684033/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo sops.deb "https://github.com/mozilla/sops/releases/latest/download/sops_${SOPS_LATEST_VERSION}_amd64.deb"
sudo apt --fix-broken install ./sops.deb
rm -rf sops.deb

# pivnet
wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1
sudo install pivnet-linux-amd64-3.0.1 /usr/local/bin/pivnet
rm pivnet-linux-amd64-3.0.1

# tilt
curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash

# tree
sudo apt install tree

# yq
brew install yq
