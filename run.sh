#!/usr/bin/env bash

generate_pki () {
  case `uname -s` in
      Linux*)     sslConfig=/etc/ssl/openssl.cnf;;
      Darwin*)    sslConfig=/System/Library/OpenSSL/openssl.cnf;;
  esac

  openssl genrsa -out rootCA.key 4096 -nodes
  openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.crt -subj "/C=US/ST=CO/O=ORG/OU=ORG_UNIT/CN=SWIMLANE_ROOT"
  openssl genrsa -out server.key 2048 -nodes
  openssl req -new -key server.key -out server.csr -reqexts SAN -extensions SAN -subj /CN=test_proxy -config <(cat $sslConfig <(printf '[SAN]\nsubjectAltName=DNS:test_proxy')) -sha256
  openssl x509 -req -extfile <(printf "subjectAltName=DNS:test_proxy") -days 120 -in server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out server.pem -sha256

}

build_go_proxy_container () {
  cp server.{key,pem} go_proxy/
  cd go_proxy
  docker build -t go_proxy .
  cd ..
}

build_centos7_client_container () {
  cp rootCA.crt centos7_client/
  cd centos7_client
  docker build -t centos7_client .
  cd ..
}

build_tools_client_container () {
  cp rootCA.crt tools_client/
  cd tools_client
  docker build -t tools_client .
  cd ..
}

generate_pki
build_go_proxy_container
build_centos7_client_container
build_tools_client_container

docker network create proxy_test_network
echo -e "\n\n\n\n\n\n\n\n\n"
echo starting http proxy
docker run -d --rm --network proxy_test_network --name test_proxy go_proxy ./proxy --proto http
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo testing HTTP proxy with HTTPS specified in proxy endpoint with curl 7.29.0
docker run -it --rm --network proxy_test_network centos7_client curl -ILv --proxy https://test_proxy:8888 https://www.google.com
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo testing HTTP proxy with HTTP specified in proxy endpoint with curl 7.29.0
docker run -it --rm --network proxy_test_network centos7_client curl -ILv --proxy http://test_proxy:8888 https://www.google.com
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo  testing HTTP proxy with HTTPS specified in proxy endpoint with curl 7.64.0
docker run -it --rm --network proxy_test_network tools_client curl -ILv --proxy https://test_proxy:8888 https://www.google.com
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo testing HTTP proxy with HTTP specified in proxy endpoint with curl 7.64.0
docker run -it --rm --network proxy_test_network tools_client curl -ILv --proxy http://test_proxy:8888 https://www.google.com
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo starting https proxy
docker stop test_proxy
docker run -d --rm --network proxy_test_network --name test_proxy go_proxy ./proxy --proto https --key server.key --pem server.pem
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo testing HTTPS proxy with HTTPS specified in proxy endpoint with curl 7.29.0
docker run -it --rm --network proxy_test_network centos7_client curl -ILv --proxy https://test_proxy:8888 https://www.google.com
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo testing HTTPS proxy with HTTP specified in proxy endpoint with curl 7.29.0
docker run -it --rm --network proxy_test_network centos7_client curl -ILv --proxy http://test_proxy:8888 https://www.google.com
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo testing HTTPS proxy with HTTPS specified in proxy endpoint with curl 7.64.0
docker run -it --rm --network proxy_test_network tools_client curl -ILv --proxy https://test_proxy:8888 https://www.google.com
read -n 1 -s -r -p "Press any key to continue"

echo -e "\n\n\n\n\n\n\n\n\n"
echo testing HTTPS proxy with HTTP specified in proxy endpoint with curl 7.64.0
docker run -it --rm --network proxy_test_network tools_client curl -ILv --proxy http://test_proxy:8888 https://www.google.com

docker stop test_proxy
docker network rm proxy_test_network
