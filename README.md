# HTTP and HTTPS proxy response tests with different curl versions

## How to run

Run the `./run.sh` script which will
 - generate a PKI (CA + issued certificate for the proxy server)
 - build an image with a golang http/https proxy service - thanks to https://medium.com/@mlowicki/http-s-proxy-in-golang-in-less-than-100-lines-of-code-6a51c2f2c38c
 - build a CentOS 7 image with the new CA certificate 
 - build a swimlane-tools image with the new CA certificate
 - run through all test cases with the proxy service running as an HTTP proxy and as an HTTPS proxy
   - all curl commands are run with headers only, no body, argument `-I`
   - the user-agent header shows the curl version used for each call

## Curl version changes

Curl has implemented HTTPS proxy support in 7.52.0 - https://daniel.haxx.se/blog/2016/11/26/https-proxy-with-curl/

swimlane-tools is shipped with curl 7.64.0

CentOS 7 is shipped with curl 7.29.0
