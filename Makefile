CFLAGS = -std=gnu99 -fPIC -levent -lpthread
LDFLAGS = -shared 

CURL_VER = 7.24.0
SSL_VER=1.0.1i

all : boot2yo.so

%.so : %.c
	$(CC) -o $@ -std=gnu99 -fPIC -shared -lcurl $^

hooks : .git/hooks/pre-commit

.git/hooks/% : Makefile
	echo "#!/bin/sh" > $@
	echo "make `basename $@`" >> $@
	chmod 755 $@

pre-commit :
	git diff-index --check HEAD

# Remove anything listed in the .gitignore file.
clean :
	find . -path ./.git -prune -o -print0 | \
	git check-ignore -z --stdin | xargs -0 rm -f

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
	cd upstream/curl-${CURL_VER} && ./configure --disable-ares --disable-ftp --disable-file --disable-ldap --disable-ldaps --disable-rtsp --disable-proxy --disable-disc --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-manual --disable-ipv6 --disable-threaded-resolver --disable-sspi --disable-crypto-auth --disable-ntlm-wb --disable-tls-srp --without-libssh2 --without-librtmp --without-libidn --without-nghttp2
	cd upstream/curl-${CURL_VER}/lib && cp Makefile Makefile.orig

.PHONY : all clean hooks
