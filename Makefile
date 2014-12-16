CFLAGS = -std=gnu99 -fPIC -levent -lpthread
LDFLAGS = -shared 

CURL_VER = 7.24.0
SSL_VER=1.0.1j

CURL_DIR = upstream/curl-${CURL_VER}

HERE = $(shell pwd)

all : boot2yo.so upstream

upstream : libcurl.so ${CURL_DIR}/include/curl/curl.h

libcurl.so : ${CURL_DIR}/lib/.libs/libcurl.so
	cp $< $@

boot2yo.o : boot2yo.c upstream
	$(CC) -Wall -fPIC -c -I${CURL_DIR}/include -o $@ -std=gnu99 $< 

boot2yo : boot2yo.o
	$(CC) -L${HERE} -o $@ -std=gnu99 -lcurl $< 

boot2yo.so : boot2yo.o
	$(CC) -L. -o $@ -std=gnu99 -fPIC -shared -lcurl $<

hooks : .git/hooks/pre-commit

.git/hooks/% : Makefile
	echo "#!/bin/sh" > $@
	echo "make `basename $@`" >> $@
	chmod 755 $@

openssl-${SSL_VER}.a : upstream/openssl-${SSL_VER}/libssl.a
	cp -v $< $@

pre-commit :
	git diff-index --check HEAD

clean :
	rm -f  *.so *.o
	rm -rf upstream/curl-${CURL_VER}
	rm -rf upstream/openssl-${SSL_VER}

upstream/openssl-${SSL_VER}.tar.gz:
	mkdir -p upstream
	cd upstream && wget -O openssl-${SSL_VER}.tar.gz "http://mirrors.ibiblio.org/openssl/source/openssl-${SSL_VER}.tar.gz"

upstream/openssl-${SSL_VER}: upstream/openssl-${SSL_VER}.tar.gz
	cd upstream && tar xvf openssl-${SSL_VER}.tar.gz
	cd upstream/openssl-${SSL_VER} && ./config && mv Makefile Makefile.orig && sed -e "s/CFLAG= /CFLAG= -fPIC /" Makefile.orig > Makefile

upstream/openssl-${SSL_VER}/libssl.a: upstream/openssl-${SSL_VER}
	cd upstream/openssl-${SSL_VER} && make MAKEFLAGS=

upstream/curl-${CURL_VER}.tar.lzma:
	mkdir -p upstream
	cd upstream && wget http://curl.haxx.se/download/curl-${CURL_VER}.tar.lzma

upstream/curl-${CURL_VER}: upstream/curl-${CURL_VER}.tar.lzma
	cd upstream && tar xvf curl-${CURL_VER}.tar.lzma

upstream/curl-${CURL_VER}/lib/libssl.a: upstream/openssl-${SSL_VER}/libssl.a upstream/curl-${CURL_VER}
	cd upstream && cp openssl-${SSL_VER}/libssl.a curl-${CURL_VER}/lib
upstream/curl-${CURL_VER}/lib/.libs/libcurl.so.4.3.0: upstream/curl-${CURL_VER}  upstream/curl-${CURL_VER}/lib/libssl.a

upstream/curl-${CURL_VER}/include/curl/curl.h : upstream/curl-${CURL_VER}/lib/.libs/libcurl.so

upstream/curl-${CURL_VER}/lib/.libs/libcurl.so : upstream/curl-${CURL_VER}
	cd upstream/curl-${CURL_VER} && ./configure --disable-ares --disable-ftp --disable-file --disable-ldap --disable-ldaps --disable-rtsp --disable-proxy --disable-disc --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-manual --disable-ipv6 --disable-threaded-resolver --disable-sspi --disable-crypto-auth --disable-ntlm-wb --disable-tls-srp --without-libssh2 --without-librtmp --without-libidn --without-nghttp2 --enable-static=no --enable-shared=yes && make 

.PHONY : all clean hooks upstream
