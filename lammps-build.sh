#!/bin/sh

#make -j8
#make install
export PATH=${PWD}/musl/bin:${PATH}
prefix_dir=${PWD}/musl

gcc_ver=$(awk '/GCC_VER/ {print $3}' config.mak)
zlib_ver=1.3.1
png_ver=1.6.48
termcap_ver=1.3.1
readline_ver=8.2.13
jpeg_ver=3.1.0

# setup toolkit for in place compilation and installation
sed -e "s%@ROOT_DIR@%${PWD}%" -e "s%@GCC_VERSION@%${gcc_ver}%" musl/share/cmake/linux-musl.cmake.in > musl/share/cmake/linux-musl.cmake

# download additional source packages, if needed.
if [ ! -e sources/zlib-${zlib_ver}.tar.gz ]
then \
    curl --location --output sources/zlib-${zlib_ver}.tar.gz https://zlib.net/zlib-${zlib_ver}.tar.gz
fi

if [ ! -e sources/libpng-${png_ver}.tar.gz ]
then \
    curl --location --output sources/libpng-${png_ver}.tar.gz https://download.sourceforge.net/libpng/libpng-${png_ver}.tar.gz
fi

if [ ! -e sources/termcap-${termcap_ver}.tar.gz ]
then \
    curl --location --output sources/termcap-${termcap_ver}.tar.gz https://ftp.gnu.org/gnu/termcap/termcap-${termcap_ver}.tar.gz
fi

if [ ! -e sources/libjpeg-turbo-${jpeg_ver}.tar.gz ]
then \
    curl --location --output sources/libjpeg-turbo-${jpeg_ver}.tar.gz \
       https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${jpeg_ver}/libjpeg-turbo-${jpeg_ver}.tar.gz
fi

# check hashes
sha256sum -c - <<EOF
9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23  sources/zlib-1.3.1.tar.gz
68f3d83a79d81dfcb0a439d62b411aa257bb4973d7c67cd1ff8bdf8d011538cd  sources/libpng-1.6.48.tar.gz
91a0e22e5387ca4467b5bcb18edf1c51b930262fd466d5fda396dd9d26719100  sources/termcap-1.3.1.tar.gz
0e5be4d2937e8bd9b7cd60d46721ce79f88a33415dd68c2d738fb5924638f656  sources/readline-8.2.13.tar.gz
9564c72b1dfd1d6fe6274c5f95a8d989b59854575d4bbee44ade7bc17aa9bc93  sources/libjpeg-turbo-3.1.0.tar.gz
EOF
if [ $? -ne 0 ]
then \
    echo "Checksum failure"
    exit 1
fi

# unpack sources
if [ ! -e zlib-${zlib_ver} ]
then \
    tar -xzvvf sources/zlib-${zlib_ver}.tar.gz
    if [ -e patches/zlib-${zlib_ver}.patch ]
    then \
        patch -p 0 -b < patches/zlib-${zlib_ver}.patch
    fi
fi

if [ ! -e libpng-${png_ver} ]
then \
    tar -xzvvf sources/libpng-${png_ver}.tar.gz
    if [ -e patches/libpng-${png_ver}.patch ]
    then \
        patch -p 0 -b < patches/libpng-${png_ver}.patch
    fi
fi

if [ ! -e termcap-${termcap_ver} ]
then \
    tar -xzvvf sources/termcap-${termcap_ver}.tar.gz
    if [ -e patches/termcap-${termcap_ver}.patch ]
    then \
        patch -p 0 -b < patches/termcap-${termcap_ver}.patch
    fi
fi

if [ ! -e readline-${readline_ver} ]
then \
    tar -xzvvf sources/readline-${readline_ver}.tar.gz
    if [ -e patches/readline-${readline_ver}.patch ]
    then \
        patch -p 0 -b < patches/readline-${readline_ver}.patch
    fi
fi

if [ ! -e libjpeg-turbo-${jpeg_ver} ]
then \
    tar -xzvvf sources/libjpeg-turbo-${jpeg_ver}.tar.gz
    if [ -e patches/libjpeg-turbo-${jpeg_ver}.patch ]
    then \
        patch -p 0 -b < patches/libjpeg-turbo-${jpeg_ver}.patch
    fi
fi

# compile and install zlib
rm -rvf build/zlib-*
cmake -B build/zlib-${zlib_ver} -S zlib-${zlib_ver} -D CMAKE_INSTALL_PREFIX=$PWD/musl -D CMAKE_BUILD_TYPE=MinSizeRel \
        -D ZLIB_BUILD_EXAMPLES=off --toolchain $PWD/musl/share/cmake/linux-musl.cmake -G Ninja
cmake --build build/zlib-${zlib_ver} || exit 2
cmake --install build/zlib-${zlib_ver} || exit 2
ln -sf libzlib.a musl/lib/libz.a

# compile and install libpng16
rm -rvf build/libpng-*
cmake -B build/libpng-${png_ver} -S libpng-${png_ver} -D CMAKE_INSTALL_PREFIX=$PWD/musl -D CMAKE_BUILD_TYPE=MinSizeRel \
        -D PNG_SHARED=off --toolchain $PWD/musl/share/cmake/linux-musl.cmake -G Ninja
cmake --build build/libpng-${png_ver} || exit 3
cmake --install build/libpng-${png_ver} || exit 3
[ -f musl/lib/liblibpng16_static.a ] && mv musl/lib/liblibpng16_static.a musl/lib/libpng16.a
ln -sf libpng16.a musl/lib/libpng.a

# compile and install termcap
rm -rvf build/termcap-*
mkdir -p build/termcap-${termcap_ver}
pushd build/termcap-${termcap_ver}
CC=x86_64-linux-musl-gcc LD=x86_64-linux-musl-ld CFLAGS="-g0 -Os -Wall -DNDEBUG" LDFLAGS=-static ../../termcap-${termcap_ver}/configure --prefix=${prefix_dir}
make
make install oldincludedir=
popd
sed -e "s%@PREFIX@%${PWD}/musl%" musl/lib/pkgconfig/termcap.pc.in > musl/lib/pkgconfig/termcap.pc

# compile and install readline
mkdir -p build/readline-${readline_ver}
pushd build/readline-${readline_ver}
CC=x86_64-linux-musl-gcc LD=x86_64-linux-musl-ld CFLAGS="-g0 -Os -Wall -DNDEBUG" LDFLAGS=-static ../../readline-${readline_ver}/configure --prefix=${prefix_dir} --disable-shared --without-shared-termcap-library
make
make install oldincludedir=
popd
#sed -e "s%@PREFIX@%${PWD}/musl%" musl/lib/pkgconfig/termcap.pc.in > musl/lib/pkgconfig/termcap.pc

# compile and install jpeg-turbo
rm -rvf build/libjpeg-turbo-*
cmake -B build/libjpeg-turbo-${jpeg_ver} -S libjpeg-turbo-${jpeg_ver} -D CMAKE_INSTALL_PREFIX=$PWD/musl -D CMAKE_BUILD_TYPE=MinSizeRel \
        -D ENABLE_SHARED=off --toolchain $PWD/musl/share/cmake/linux-musl.cmake -G Ninja
cmake --build build/libjpeg-turbo-${jpeg_ver} || exit 3
cmake --install build/libjpeg-turbo-${jpeg_ver} || exit 3

# setup toolkit for use in containers at the /usr/musl toplevel directory
sed -e "s%@ROOT_DIR@%/usr%" -e "s%@GCC_VERSION@%${gcc_ver}%" musl/share/cmake/linux-musl.cmake.in > musl/share/cmake/linux-musl.cmake
# fix up pkgconfig files
for s in musl/share/pkgconfig/*.pc
do \
        sed -i "s%${PWD}%/usr%g" $s
done
# clean up and create archive
touch musl/dummy~
rm -rvf musl/share/info musl/share/doc musl/share/man musl/share/readline musl/info
find musl -type f -name \*~ -print0 | xargs -0 rm -v
#tar -czvvf musl-gcc-f41.tar.gz musl
