#!/bin/sh

#make -j8
#make install
export PATH=${PWD}/musl/bin:${PATH}

gcc_ver=$(awk '/GCC_VER/ {print $3}' config.mak)
zlib_ver=1.3.1
png_ver=1.6.48

# setup toolkit for in place compilation and installation
sed -e "s%@ROOT_DIR@%${PWD}%" -e "s%@GCC_VERSION@%${gcc_ver}%" musl/share/cmake/linux-musl.cmake.in > musl/share/cmake/linux-musl.cmake

# download additional source packages, if needed.
if [ ! -e sources/zlib-${zlib_ver}.tar.gz ]
then \
    curl --location --output sources/zlib-${zlib_ver}.tar.gz https://zlib.net/zlib-${zlib_ver}.tar.gz
fi
if [ ! -e sources/libpng-${png_ver}.tar.gz ]
then \
    curl --location --output sources/libpng-${png_ver}.tar.gz https://download.sourceforge.net/libpng/libpng-1.6.48.tar.gz
fi
sha256sum -c - <<EOF
9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23  sources/zlib-1.3.1.tar.gz
68f3d83a79d81dfcb0a439d62b411aa257bb4973d7c67cd1ff8bdf8d011538cd  sources/libpng-1.6.48.tar.gz
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

# setup toolkit for use in containers at the /usr/musl toplevel directory
sed -e "s%@ROOT_DIR@%/usr%" -e "s%@GCC_VERSION@%${gcc_ver}%" musl/share/cmake/linux-musl.cmake.in > musl/share/cmake/linux-musl.cmake
# fix up pkgconfig files
for s in musl/share/pkgconfig/*.pc
do \
        sed -i "s%${PWD}%/usr%g" $s
done
# clean up and create archive
touch musl/dummy~
find musl -type f -name \*~ -print0 | xargs -0 rm -v
#tar -czvvf musl-gcc-f41.tar.gz musl
