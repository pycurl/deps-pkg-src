DEST_HOME=/home/travis
DISTRO=bionic

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
  echo libgnutls28-dev libkrb5-dev
}

all_deps() {
  echo `gnutls_deps` \
    libssl-dev libnss3-dev libkrb5-dev libssh2-1-dev
}

prep_build_and_cd() {
  sudo rm -rf /deps
  sudo mkdir /deps
  cd /deps
  sudo chown -R `id -u`:`id -g` .
}

fetch_curl() {
  wget_once http://curl.haxx.se/download/curl-$curl_version.tar.gz
}

fetch_old_curl() {
  wget_once http://curl.haxx.se/download/archeology/curl-$curl_version.tar.gz
}

validate_dependency_dirs() {
  opts="$1"
  
  cmd=`cat <<'CMD'
    for (split /\s+/, <>) {
      if (m/^(--with-.*)=(.*)/) {
        if (! -e $2) {
          print "Missing path $2 given for $1\n";
          exit(2);
        }
      }
    }
CMD`
  echo "$opts" |perl -e "$cmd"
}

build_curl_7_43_0_or_higher() {
  suffix=$1
  opts="$2"
  if ! validate_dependency_dirs "$opts"; then
    return 1
  fi
  
  if echo "$curl_version" |grep -q dev; then
    sudo apt-get install -y autoconf libtool
    rsync -a ../curl . --exclude .git
    cd curl
  else
    rm -rf curl-$curl_version
    tar xfz $ROOT/curl-$curl_version.tar.gz
    cd curl-$curl_version
  fi
  
  if echo "$curl_version" |grep -q dev; then
    ./buildconf
  fi
  
  patch -p1 <$ROOT/patches/curl-7.43.0-nss-patch
  
  if test -n "$nghttp2_version"; then
    opts="--with-nghttp2=$DEST_HOME/opt/nghttp2-$nghttp2_version $opts"
  fi
  ./configure --prefix=$DEST_HOME/opt/curl-$curl_version-$suffix \
    --enable-ftp \
    $opts
  make
  # building in vagrant, installing to $DEST_HOME
  sudo make install

  cd ..
  
  pack_curl $suffix
}

pack_curl() {
  suffix="$1"
  pack_args=curl-$curl_version-$suffix
  if test -n "$nghttp2_version"; then
    pack_args="$pack_args nghttp2-$nghttp2_version"
  fi
  if false; then
    if echo $suffix |grep -q openssl10; then
      pack_args="$pack_args openssl-$openssl10_version"
    fi
    if echo $suffix |grep -q openssl11; then
      pack_args="$pack_args openssl-$openssl11_version"
    fi
    if echo $suffix |grep -q libressl; then
      pack_args="$pack_args libressl-$libressl_version"
    fi
  fi
  tar cfJ curl-$curl_version-$suffix-$DISTRO-64.tar.xz \
    -C $DEST_HOME/opt $pack_args
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
  
  tar xf $ROOT/nghttp2-$nghttp2_version.tar.xz
  cd nghttp2-$nghttp2_version
  ./configure --prefix=$DEST_HOME/opt/nghttp2-$nghttp2_version
  make
  sudo make install
  cd ..
}
