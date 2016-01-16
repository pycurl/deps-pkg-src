DEST_HOME=/home/travis

wget_once() {
  url="$1"
  if ! test -f `basename "$url"`; then
    wget -O `basename "$url"`.part "$url"
    rv=$?
    if test $rv = 0; then
      mv `basename "$url"`.part `basename "$url"`
    else
      rm -f `basename "$url"`.part
      return $rv
    fi
  fi
}

wget_once_to() {
  url="$1"
  dest="$2"
  if ! test -f "$dest"; then
    wget -O "$dest".part "$url"
    rv=$?
    if test $rv = 0; then
      mv "$dest".part "$dest"
    else
      rm -f "$dest".part
      return $rv
    fi
  fi
}

gnutls_deps() {
  echo libgnutls-dev libkrb5-dev
}

all_deps() {
  echo `gnutls_deps` \
    libssl-dev libnss3-dev libkrb5-dev libssh2-1-dev
}

prep_build_and_cd() {
  rm -rf build
  mkdir build
  cd build
}

fetch_curl() {
  wget_once http://curl.haxx.se/download/curl-$curl_version.tar.gz
}

fetch_old_curl() {
  wget_once http://curl.haxx.se/download/archeology/curl-$curl_version.tar.gz
}

build_curl_7_43_0_or_higher() {
  suffix=$1
  opts="$2"
  
  rm -rf curl-$curl_version
  tar xfz ../curl-$curl_version.tar.gz
  cd curl-$curl_version
  patch -p1 <../../../patches/curl-7.43.0-nss-patch
  ./configure --prefix=$DEST_HOME/opt/curl-$curl_version-$suffix \
    --with-nghttp2=$DEST_HOME/opt/nghttp2-$nghttp2_version $opts
  make
  # building in vagrant, installing to $DEST_HOME
  sudo make install

  cd ../..
  tar cfz curl-$curl_version-$suffix-precise-64.tar.gz \
    -C $DEST_HOME/opt curl-$curl_version-$suffix
  cd build
}

setup_nghttp2_envvars() {
  #export CPPFLAGS="$CPPFLAGS -I$DEST_HOME/local/include"
  #export LDLAGS="$LDLAGS -L$DEST_HOME/local/lib"
  :
}

fetch_nghttp2() {
  wget_once https://github.com/tatsuhiro-t/nghttp2/releases/download/v$nghttp2_version/nghttp2-$nghttp2_version.tar.xz
}

build_nghttp2() {
  if test -e $DEST_HOME/opt/nghttp2-$nghttp2_version; then
    echo Skipping build of nghttp2 $nghttp2_version
    return
  fi
  
  tar xf ../nghttp2-$nghttp2_version.tar.xz
  cd nghttp2-$nghttp2_version
  ./configure --prefix=$DEST_HOME/opt/nghttp2-$nghttp2_version
  make
  sudo make install
  cd ..
}
