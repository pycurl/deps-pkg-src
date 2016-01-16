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
