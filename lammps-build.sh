#!/bin/sh

make -j8
make install
export PATH=${PWD}/musl/bin:${PATH}
prefix_dir=${PWD}/musl

gcc_ver=$(awk '/GCC_VER/ {print $3}' config.mak)
zlib_ver=1.3.1
png_ver=1.6.48
termcap_ver=1.3.1
readline_ver=8.2.13
jpeg_ver=3.1.0
openssl_ver=3.5.0
curl_ver=8.14.1
zstd_ver=1.5.7

# setup toolkit for in place compilation and installation
mkdir -p musl/share/cmake
sed -e "s%@ROOT_DIR@%${PWD}%" -e "s%@GCC_VERSION@%${gcc_ver}%" files/linux-musl.cmake.in > musl/share/cmake/linux-musl.cmake

# download additional source packages, if needed.
if [ ! -e sources/zlib-${zlib_ver}.tar.gz ]
then \
    curl --location --output sources/zlib-${zlib_ver}.tar.gz https://zlib.net/zlib-${zlib_ver}.tar.gz
fi

if [ ! -e sources/zstd-${zstd_ver}.tar.gz ]
then \
    curl --location --output sources/zstd-${zstd_ver}.tar.gz https://github.com/facebook/zstd/releases/download/v${zstd_ver}/zstd-${zstd_ver}.tar.gz
fi

if [ ! -e sources/libpng-${png_ver}.tar.gz ]
then \
    curl --location --output sources/libpng-${png_ver}.tar.gz https://download.sourceforge.net/libpng/libpng-${png_ver}.tar.gz
fi

if [ ! -e sources/libjpeg-turbo-${jpeg_ver}.tar.gz ]
then \
    curl --location --output sources/libjpeg-turbo-${jpeg_ver}.tar.gz \
       https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${jpeg_ver}/libjpeg-turbo-${jpeg_ver}.tar.gz
fi

if [ ! -e sources/termcap-${termcap_ver}.tar.gz ]
then \
    curl --location --output sources/termcap-${termcap_ver}.tar.gz https://ftp.gnu.org/gnu/termcap/termcap-${termcap_ver}.tar.gz
fi

if [ ! -e sources/readline-${readline_ver}.tar.gz ]
then \
    curl --location --output sources/readline-${readline_ver}.tar.gz https://ftp.gnu.org/gnu/readline/readline-${readline_ver}.tar.gz
fi

if [ ! -e sources/openssl-${openssl_ver}.tar.gz ]
then \
    curl --location --output sources/openssl-${openssl_ver}.tar.gz https://github.com/openssl/openssl/releases/download/openssl-${openssl_ver}/openssl-${openssl_ver}.tar.gz
fi

if [ ! -e sources/curl-${curl_ver}.tar.gz ]
then \
    curl --location --output sources/curl-${curl_ver}.tar.gz https://curl.se/download/curl-${curl_ver}.tar.gz
fi

# check hashes
sha256sum -c - <<EOF
9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23  sources/zlib-1.3.1.tar.gz
68f3d83a79d81dfcb0a439d62b411aa257bb4973d7c67cd1ff8bdf8d011538cd  sources/libpng-1.6.48.tar.gz
91a0e22e5387ca4467b5bcb18edf1c51b930262fd466d5fda396dd9d26719100  sources/termcap-1.3.1.tar.gz
0e5be4d2937e8bd9b7cd60d46721ce79f88a33415dd68c2d738fb5924638f656  sources/readline-8.2.13.tar.gz
9564c72b1dfd1d6fe6274c5f95a8d989b59854575d4bbee44ade7bc17aa9bc93  sources/libjpeg-turbo-3.1.0.tar.gz
344d0a79f1a9b08029b0744e2cc401a43f9c90acd1044d09a530b4885a8e9fc0  sources/openssl-3.5.0.tar.gz
6766ada7101d292b42b8b15681120acd68effa4a9660935853cf6d61f0d984d4  sources/curl-8.14.1.tar.gz
eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3  sources/zstd-1.5.7.tar.gz
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

if [ ! -e zstd-${zstd_ver} ]
then \
    tar -xzvvf sources/zstd-${zstd_ver}.tar.gz
    if [ -e patches/zstd-${zstd_ver}.patch ]
    then \
        patch -p 0 -b < patches/zstd-${zstd_ver}.patch
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

if [ ! -e openssl-${openssl_ver} ]
then \
    tar -xzvvf sources/openssl-${openssl_ver}.tar.gz
    if [ -e patches/openssl-${openssl_ver}.patch ]
    then \
        patch -p 0 -b < patches/openssl-${openssl_ver}.patch
    fi
fi

if [ ! -e curl-${curl_ver} ]
then \
    tar -xzvvf sources/curl-${curl_ver}.tar.gz
    if [ -e patches/curl-${curl_ver}.patch ]
    then \
        patch -p 0 -b < patches/curl-${curl_ver}.patch
    fi
fi

# compile and install zlib
rm -rvf build/zlib-*
cmake -B build/zlib-${zlib_ver} -S zlib-${zlib_ver} -D CMAKE_INSTALL_PREFIX=${prefix_dir} -D CMAKE_BUILD_TYPE=MinSizeRel \
        -D ZLIB_BUILD_EXAMPLES=off --toolchain ${prefix_dir}/share/cmake/linux-musl.cmake -G Ninja
cmake --build build/zlib-${zlib_ver} || exit 2
cmake --install build/zlib-${zlib_ver} || exit 2
ln -sf libzlib.a musl/lib/libz.a

# compile and install zstd
rm -rvf build/zstd-*
cmake -B build/zstd-${zstd_ver} -S zstd-${zstd_ver}/build/cmake -D CMAKE_INSTALL_PREFIX=${prefix_dir} \
      -D CMAKE_BUILD_TYPE=MinSizeRel -D ZSTD_BUILD_CONTRIB=off -D ZSTD_BUILD_PROGRAMS=off \
      -D ZSTD_MULTITHREAD_SUPPORT_DEFAULT=off -D ZSTD_BUILD_STATIC=on -D ZSTD_BUILD_SHARED=off \
      --toolchain ${prefix_dir}/share/cmake/linux-musl.cmake -G Ninja
cmake --build build/zstd-${zstd_ver} || exit 2
cmake --install build/zstd-${zstd_ver} || exit 2

# compile and install libpng16
rm -rvf build/libpng-*
cmake -B build/libpng-${png_ver} -S libpng-${png_ver} -D CMAKE_INSTALL_PREFIX=${prefix_dir} -D CMAKE_BUILD_TYPE=MinSizeRel \
        -D PNG_SHARED=off --toolchain ${prefix_dir}/share/cmake/linux-musl.cmake -G Ninja
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
sed -e "s%@PREFIX@%${PWD}/musl%" files/termcap.pc.in > musl/lib/pkgconfig/termcap.pc

# compile and install readline
mkdir -p build/readline-${readline_ver}
pushd build/readline-${readline_ver}
CC=x86_64-linux-musl-gcc LD=x86_64-linux-musl-ld CFLAGS="-g0 -Os -Wall -DNDEBUG" LDFLAGS=-static ../../readline-${readline_ver}/configure --prefix=${prefix_dir} --disable-shared --without-shared-termcap-library
make
make install oldincludedir=
popd

# compile and install jpeg-turbo
rm -rvf build/libjpeg-turbo-*
cmake -B build/libjpeg-turbo-${jpeg_ver} -S libjpeg-turbo-${jpeg_ver} -D CMAKE_INSTALL_PREFIX=${prefix_dir} -D CMAKE_BUILD_TYPE=MinSizeRel \
        -D ENABLE_SHARED=off --toolchain ${prefix_dir}/share/cmake/linux-musl.cmake -G Ninja
cmake --build build/libjpeg-turbo-${jpeg_ver} || exit 3
cmake --install build/libjpeg-turbo-${jpeg_ver} || exit 3

# compile and install OpenSSL
rm -rvf build/openssl-*
mkdir -p build/openssl-${openssl_ver}
pushd  build/openssl-${openssl_ver}
CC=x86_64-linux-musl-gcc CXX=x86_64-linux-musl-g++ LD=x86_64-linux-musl-ld \
    CFLAGS="-g0 -Os -Wall -DNDEBUG" CXXFLAGS="-g0 -Os -Wall -DNDEBUG"  \
    perl ../../openssl-${openssl_ver}/Configure --prefix=${prefix_dir} no-shared -static --libdir=lib
make -j8
make install -j8
popd

# compile and install libcurl
rm -rvf build/curl-*
cmake -B build/curl-${curl_ver} -S curl-${curl_ver} -D CMAKE_INSTALL_PREFIX=${prefix_dir} \
      -D BUILD_CURL_EXE=off -D BUILD_SHARED_LIBS=off -D BUILD_STATIC_LIBS=on \
      -D USE_OPENSSL=on -D OPENSSL_ROOT_DIR=${prefix_dir} -D OPENSSL_USE_STATIC_LIBS=on \
      -D CURL_DISABLE_LDAP=on -D USE_LIBIDN2=off -D CURL_USE_LIBPSL=off \
      -D CURL_USE_LIBSSH2=off -D CURL_USE_LIBSSH=off \
      -D CMAKE_BUILD_TYPE=MinSizeRel --toolchain ${prefix_dir}/share/cmake/linux-musl.cmake -G Ninja
cmake --build build/curl-${curl_ver} || exit 4
cmake --install build/curl-${curl_ver} || exit 4

# setup toolkit for use in containers at the /usr/musl toplevel directory
sed -e "s%@ROOT_DIR@%/usr%" -e "s%@GCC_VERSION@%${gcc_ver}%" files/linux-musl.cmake.in > musl/share/cmake/linux-musl.cmake
# fix up pkgconfig files
for s in musl/share/pkgconfig/*.pc
do \
        sed -i "s%${PWD}%/usr%g" $s
done

# remove undesired (shared) library files

rm -f musl/x86_64-linux-musl/lib/ld-musl-x86_64.so.1
rm -f musl/x86_64-linux-musl/lib/libc.so
for f in atomic gfortran gomp itm quadmath ssp stdc++
do \
    rm -f lib${f}.so lib${f}.so.* lib${f}.la
done

# clean up and create archive
touch musl/dummy~
rm -rf musl/share/info musl/share/doc musl/share/man musl/share/readline musl/info
rm -f musl/lib/readline.old
rm -f musl/lib/history.old
find musl -type f -name \*~ -print0 | xargs -0 rm
tar -czvvf musl-gcc-f41.tar.gz musl
