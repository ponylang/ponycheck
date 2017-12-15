#! /bin/bash

set -o errexit
set -o nounset

download_llvm(){
  echo "Downloading and installing LLVM ${LLVM_VERSION}"

  wget "http://llvm.org/releases/${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-debian8.tar.xz"
  tar -xvf clang+llvm*
  pushd clang+llvm* && sudo mkdir /tmp/llvm && sudo cp -r ./* /tmp/llvm/
  sudo ln -s "/tmp/llvm/bin/llvm-config" "/usr/local/bin/${LLVM_CONFIG}"
  popd
}

download_pcre(){
  echo "Downloading and building PCRE2..."

  wget "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.21.tar.bz2"
  tar -xjvf pcre2-10.21.tar.bz2
  pushd pcre2-10.21 && ./configure --prefix=/usr && make && sudo make install
  popd
}

install-ponyc-master(){
  echo "Installing ponyc master..."
  git clone https://github.com/ponylang/ponyc.git
  pushd ponyc
  echo "Building ponyc..."
  sudo make CC="$CC1" CXX="$CXX1" install
  popd
}

echo "Installing ponyc build dependencies..."
if [ "${TRAVIS_EVENT_TYPE}" = "cron" ]
then
  echo -e "\033[0;32mInstalling ponyc master\033[0m"
  pushd /tmp
  download_llvm
  download_pcre
  install-ponyc-master
  popd
else
  echo "Installing ponyc runtime dependencies..."
  download_pcre
  echo -e "\033[0;32mInstalling latest ponyc release\033[0m"
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "D401AB61 DBE1D0A2"
  echo "deb https://dl.bintray.com/pony-language/ponyc-debian pony-language main" | sudo tee -a /etc/apt/sources.list
  sudo apt-get update
  sudo apt-get -V install ponyc
fi
