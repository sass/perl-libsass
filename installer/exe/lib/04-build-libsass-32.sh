PERLPATH=`pwd`/../32/perl

echo $PERLPATH

PATH=$PERLPATH/perl/site/bin:$PATH
PATH=$PERLPATH/perl/bin:$PATH
PATH=$PERLPATH/c/bin:$PATH

CURPATH=`pwd`

perl -v

cd ../../../libsass

autoreconf --force --install

./configure \
  --disable-tests \
  --disable-static \
  --enable-shared \
  --prefix=$CURPATH/../32/usr

make -j1 install

echo installed into "$CURPATH/../32/usr"
