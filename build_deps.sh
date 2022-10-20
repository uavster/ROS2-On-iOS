# Currently we assume that this script is invoked at the repo root where it resides.

# Platform to build [macOS] or [iOS, iOS_Simulator, ...]
targetPlatform=$1

# The location of this script (the repo root) where supporting files can be found
scriptDir=`pwd`

# Prefix where we built Qt for host machine
ros2HostQtPath=$scriptDir/host_deps/

# Where we download the source archives
# We download and extract at different places so that it is easier to clean up
depsDownloadPath=$scriptDir/deps_download/

# Location to extract the source
depsExtractPath=$scriptDir/deps_src/

# Location to install dependencies
depsInstallPath=$scriptDir/ros2_$targetPlatform/deps

# Root for Python 3.10 to build Boost, change the match the platform such as
# pythonRoot=/Library/Frameworks/Python.framework/Versions/3.10/
# if use official Python instead of Homebrew's version on GitHub Action
pythonRoot=/usr/local/opt/python@3.10/Frameworks/Python.framework/Versions/3.10/

export PATH=$depsInstallPath/bin:$PATH
export PKG_CONFIG=$depsInstallPath/bin/pkg-config
export PKG_CONFIG_PATH=$depsInstallPath/lib/pkgconfig

platformExtraCMakeArgs=(-DCMAKE_INSTALL_PREFIX=$depsInstallPath -DCMAKE_PREFIX_PATH=$depsInstallPath)
platformBasicConfigureArgs=(--prefix=$depsInstallPath) # Configure args for regular situation
platformBasicConfigureArgsPixmanCairo=(--prefix=$depsInstallPath) # Special configure args for pixman and cairo

function getSource() {
    mkdir -p $depsDownloadPath
    cd $depsDownloadPath

    curl -s -L -o pkg-config.tar.gz https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
         #-o autoconf.tar.gz http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz \
         #-o automake.tar.gz http://ftpmirror.gnu.org/automake/automake-1.15.tar.gz \
         #-o libtool.tar.gz http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz \
         #-o mm-common.tar.gz https://github.com/GNOME/mm-common/archive/refs/tags/1.0.4.tar.gz

    # Dependencies for rviz
    # Need -L to download github releases according to https://stackoverflow.com/questions/46060010/download-github-release-with-curl
    curl -s -L -o freetype.tar.xz https://download.savannah.gnu.org/releases/freetype/freetype-2.12.1.tar.xz \
         -o libpng.tar.xz https://download.sourceforge.net/libpng/libpng-1.6.37.tar.xz \
         -o zlib.tar.xz https://zlib.net/zlib-1.2.13.tar.xz \
         -o eigen.tar.bz2 https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.bz2 \
         -o tinyxml2.tar.gz https://github.com/leethomason/tinyxml2/archive/refs/tags/9.0.0.tar.gz \
         -o bullet3.tar.gz https://github.com/bulletphysics/bullet3/archive/refs/tags/3.24.tar.gz \
         -o qtbase.tar.gz https://download.qt.io/archive/qt/5.15/5.15.5/submodules/qtbase-everywhere-opensource-src-5.15.5.tar.xz

    # Common heavy dependencies OpenCV, Boost
    curl -s -L -o opencv.tar.gz https://github.com/opencv/opencv/archive/refs/tags/4.6.0.tar.gz \
               -o boost.tar.gz https://boostorg.jfrog.io/artifactory/main/release/1.80.0/source/boost_1_80_0.tar.gz

    # Dependencies for MoveIt2
    curl -s -L -o fcl.tar.gz https://github.com/flexible-collision-library/fcl/archive/refs/tags/0.7.0.tar.gz \
        -o ccd.tar.gz https://github.com/danfis/libccd/archive/refs/tags/v2.1.tar.gz \
        -o octomap.tar.gz https://github.com/OctoMap/octomap/archive/refs/tags/v1.9.6.tar.gz \
        -o qhull.tgz http://www.qhull.org/download/qhull-2020-src-8.0.2.tgz \
        -o assimp.tar.gz https://github.com/assimp/assimp/archive/refs/tags/v5.2.5.tar.gz \
        -o ruckig.tar.gz https://github.com/pantor/ruckig/archive/refs/tags/v0.8.4.tar.gz \
        -o glew.tgz https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.tgz \
        -o freeglut.tar.gz https://github.com/FreeGLUTProject/freeglut/releases/download/v3.4.0/freeglut-3.4.0.tar.gz \
        -o openssl.tar.gz https://github.com/openssl/openssl/archive/refs/tags/openssl-3.0.6.tar.gz \
        -o omplcore.tar.gz https://github.com/ompl/ompl/archive/1.5.2.tar.gz \
        -o openmp.tar.xz https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/openmp-14.0.6.src.tar.xz

    # Dependencies for cartographer
    # For CERES, must checkout `2.0.0` to avoid https://github.com/cartographer-project/cartographer/issues/1879
    if [ $targetPlatform != "macOS" ] && [ $targetPlatform != "macOS_M1" ]; then
    curl -s -L -o abseil-cpp.tar.gz https://github.com/abseil/abseil-cpp/archive/refs/tags/20220623.0.tar.gz \
         -o gflags.tar.gz https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz \
         -o cairo.tar.xz https://www.cairographics.org/releases/cairo-1.16.0.tar.xz \
         -o pixman.tar.gz https://cairographics.org/releases/pixman-0.40.0.tar.gz \
         -o glog.tar.gz https://github.com/google/glog/archive/refs/tags/v0.6.0.tar.gz \
         -o gmp.tar.xz https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz \
         -o protobuf.tar.gz https://github.com/protocolbuffers/protobuf/releases/download/v21.5/protobuf-cpp-3.21.5.tar.gz \
         -o lua.tar.gz https://www.lua.org/ftp/lua-5.4.4.tar.gz \
         -o flann.tar.gz https://github.com/flann-lib/flann/archive/refs/tags/1.9.1.tar.gz \
         -o mpfr.tar.xz https://www.mpfr.org/mpfr-current/mpfr-4.1.0.tar.xz \
         -o pcl.tar.gz https://github.com/PointCloudLibrary/pcl/releases/download/pcl-1.12.1/source.tar.gz \
         -o googletest.tar.gz https://github.com/google/googletest/archive/refs/tags/release-1.12.1.tar.gz \
         -o SuiteSparse.tar.gz https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/refs/tags/v5.12.0.tar.gz \
         -o ceres-solver.tar.gz http://ceres-solver.org/ceres-solver-2.0.0.tar.gz
    fi
}

function extractSource() {
    mkdir -p $depsExtractPath
    cd $depsExtractPath
    local src_files=($(ls $depsDownloadPath))
    for f in "${src_files[@]}"; do
        echo "Extract $f"
        file $depsDownloadPath/$f
        tar xzf $depsDownloadPath/$f
    done
}

function setupPlatform() {
    case $targetPlatform in
        "iOS")
            targetArch=arm64
            boostArch=arm
            targetSysroot=`xcodebuild -version -sdk iphoneos Path`
            platformBasicConfigureArgs+=(--host=aarch64-apple-darwin)
            platformBasicConfigureArgsPixmanCairo+=(--host=arm-apple-darwin) # For pixman and cairo we must use arm-apple thank to  https://gist.github.com/jvcleave/9d78de9bb27434bde2b0c3a1af355d9c
            platformExtraCMakeArgs+=(-DCMAKE_TOOLCHAIN_FILE=$scriptDir/cmake/$targetPlatform.cmake);;

        "iOS_Simulator")
            targetArch=x86_64
            boostArch=ia64
            targetSysroot=`xcodebuild -version -sdk iphonesimulator Path`
            platformExtraCMakeArgs+=(-DCMAKE_TOOLCHAIN_FILE=$scriptDir/cmake/$targetPlatform.cmake);;

        "iOS_Simulator_M1")
            targetArch=arm64
            boostArch=arm
            targetSysroot=`xcodebuild -version -sdk iphonesimulator Path`
            platformExtraCMakeArgs+=(-DCMAKE_TOOLCHAIN_FILE=$scriptDir/cmake/$targetPlatform.cmake);;

        "macCatalyst")
            targetArch=x86_64
            boostArch=ia64
            targetSysroot=`xcodebuild -version -sdk macosx Path`
            platformExtraCMakeArgs+=(-DCMAKE_TOOLCHAIN_FILE=$scriptDir/cmake/$targetPlatform.cmake);;

        "macCatalyst_M1")
            targetArch=arm64
            boostArch=arm
            targetSysroot=`xcodebuild -version -sdk macosx Path`
            platformExtraCMakeArgs+=(-DCMAKE_TOOLCHAIN_FILE=$scriptDir/cmake/$targetPlatform.cmake);;

        "macOS")
            targetArch=x86_64
            boostArch=ia64
            targetSysroot=`xcodebuild -version -sdk macosx Path`
            platformExtraCMakeArgs+=(-DCMAKE_OSX_ARCHITECTURES=$targetArch);;

        "macOS_M1")
            targetArch=arm64
            boostArch=arm
            targetSysroot=`xcodebuild -version -sdk macosx Path`
            platformBasicConfigureArgs+=(--host=aarch64-apple-darwin)
            platformBasicConfigureArgsPixmanCairo+=(--host=arm-apple-darwin)
            platformExtraCMakeArgs+=(-DCMAKE_OSX_ARCHITECTURES=$targetArch);;
    esac
}

function setCompilerFlags() {
    case $targetPlatform in
        "macCatalyst")
            export CFLAGS="-isysroot $targetSysroot -target x86_64-apple-ios14.1-macabi -I$depsInstallPath/include/";;

        "macCatalyst_M1")
            export CFLAGS="-isysroot $targetSysroot -target arm64-apple-ios14.1-macabi -I$depsInstallPath/include/";;

        *)
            export CFLAGS="-isysroot $targetSysroot -arch $targetArch -I$depsInstallPath/include/";;
    esac
    export CXXFLAGS=$CFLAGS
    export CPPFLAGS=$CFLAGS # Without this, encounter error ZLIB_VERNUM != PNG_ZLIB_VERNUM when building libpng
}

function buildCMake() {
    rm -rf _build && mkdir _build && cd _build
    cmake "${platformExtraCMakeArgs[@]}" "$@" .. # >/dev/null 2>&1
    cmake --build . --target install # >/dev/null 2>&1 --parallel 1
}

function configureThenMake() {
    setCompilerFlags
    ./configure "${platformBasicConfigureArgs[@]}" "$@" # >/dev/null 2>&1
    make && make install #>/dev/null 2>&1
}

function configureThenMakeArm() {
    setCompilerFlags
    ./configure "${platformBasicConfigureArgsPixmanCairo[@]}" "$@" # >/dev/null 2>&1
    make && make install # >/dev/null 2>&1
}

function buildHostTools() {
    cd $depsExtractPath/pkg-config-0.29.2
    ./configure --prefix=$depsInstallPath --with-internal-glib >/dev/null 2>&1
    make && make install >/dev/null 2>&1

    #cd $depsExtractPath/autoconf-2.69
    #./configure --prefix=$depsInstallPath
    #make && make install

    #cd $depsExtractPath/automake-1.15
    #./configure --prefix=$depsInstallPath
    #make && make install

    #cd $depsExtractPath/libtool-2.4.6
    #./configure --prefix=$depsInstallPath
    #make && make install

    #cd $depsExtractPath/mm-common-1.0.4
    #./autogen.sh
    #./configure --prefix=$depsInstallPath
    #make USE_NETWORK=yes && make install
}

function buildZlib() {
    echo "Build zlib"
    cd $depsExtractPath/zlib-1.2.13

    # Note that zlib's configure does not set --host but relies on compiler flags environment variables
    setCompilerFlags
    ./configure --prefix=$depsInstallPath "$@" # >/dev/null 2>&1
    make && make install #>/dev/null 2>&1
}

function buildTinyXML2() {
    echo "Build TinyXML2"
    cd $depsExtractPath/tinyxml2-9.0.0
    buildCMake
}

# Needs: zlib
function buildLibPng() {
    echo "Build libpng"
    cd $depsExtractPath/libpng-1.6.37
    configureThenMake
}

# Needs: libpng
function buildPixman() {
    echo "Build pixman"
    cd $depsExtractPath/pixman-0.40.0
    configureThenMakeArm
}

function buildFreeType2() {
    echo "Build freetype"
    cd $depsExtractPath/freetype-2.12.1
    buildCMake -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_ZLIB==ON -DFT_DISABLE_PNG=ON -DFT_DISABLE_BROTLI=ON
}

# Needs: FreeType, pixman
function buildCairo() {
    echo "Build cairo"
    cd $depsExtractPath/cairo-1.16.0
    sed -i.bak 's/#define HAS_DAEMON 1/#define HAS_DAEMON 0/' boilerplate/cairo-boilerplate.c
    configureThenMakeArm --disable-xlib --enable-svg=no --enable-pdf=no --enable-full-testing=no HAS_DAEMON=0
}

function buildBullet3() {
    echo "Build Bullet3"
    cd $depsExtractPath/bullet3-3.24
    buildCMake -DBUILD_BULLET2_DEMOS=OFF -DBUILD_OPENGL3_DEMOS=OFF -DBUILD_UNIT_TESTS=OFF
}

function buildGFlags() {
    echo "Build gflags"
    cd $depsExtractPath/gflags-2.2.2
    buildCMake
}

# Needs: gflags
function buildGlog() {
    echo "Build glog"
    cd $depsExtractPath/glog-0.6.0
    buildCMake -DWITH_GTEST=OFF -DBUILD_TESTING=OFF
}

function buildGtest() {
    echo "Build GoogleTest"
    cd $depsExtractPath/googletest-release-1.12.1
    buildCMake
}

function buildAbsl() {
    echo "Build ABSL"
    cd $depsExtractPath/abseil-cpp-20220623.0
    buildCMake -DCMAKE_CXX_STANDARD=14
}

function buildGmp() {
    echo "Build GMP"
    cd $depsExtractPath/gmp-6.2.1
    configureThenMake
}

# Needs: GMP
function buildMpfr() {
    echo "Build MPFR"
    cd $depsExtractPath/mpfr-4.1.0
    configureThenMake --with-gmp=$depsInstallPath
}

function buildProtoBuf() {
    echo "Build ProtoBuf"
    cd $depsExtractPath/protobuf-3.21.5
    buildCMake -Dprotobuf_BUILD_TESTS=OFF
}

function buildLua() {
    echo "Build Lua"
    cd $depsExtractPath/lua-5.4.4
    make macosx
    make install INSTALL_TOP=$depsInstallPath
}

function buildBoost() {
    echo "Build Boost"
    cd $depsExtractPath/boost_1_80_0

    # Note: We must pass the full path to the python3 executable in --with-python-root=$pythonRoot/bin/python3
    # otherwise, will run into the issue https://github.com/boostorg/boost/issues/693.
    # Searching the entire Boost source code for the string `python-cfg` reveals a single file
    #     tools/build/src/tools/python.jam
    # and in that file, the function-like `local rule configure`'s parameter `$cmd-or-prefix` appears to be initialized
    # with whatever passed to `--with-python-root` as it tried to find Python. Since it only tries `bin/python`,
    # it will never succeed on Mac because bin/python does not exist.
    ./bootstrap.sh --prefix=$depsInstallPath \
                   --with-python=$pythonRoot/bin/python3 \
                   --with-python-version=3.10 \
                   --with-python-root=$pythonRoot/bin/python3

    ./b2 install architecture=$boostArch # --debug-configuration --debug-building --debug-generator -d+2
}

function buildQt5Host() {
    echo "Build Qt5 for Build machine"
    cd $depsExtractPath/qtbase-everywhere-src-5.15.5
    ./configure -prefix $ros2HostQtPath -opensource -confirm-license -nomake examples -nomake tests -no-framework
    make && make install
}

function buildQt5() {
    echo "Build Qt5 for Host target"
    cd $depsExtractPath/qtbase-everywhere-src-5.15.5

    # Patch the source https://codereview.qt-project.org/c/qt/qtbase/+/378706
    sed -i.bak "s,QT_BEGIN_NAMESPACE,#include <CoreGraphics/CGColorSpace.h>\n#include <IOSurface/IOSurface.h>\nQT_BEGIN_NAMESPACE," src/plugins/platforms/cocoa/qiosurfacegraphicsbuffer.h

    ./configure -prefix $depsInstallPath -opensource -confirm-license -nomake examples -nomake tests -no-framework -device-option QMAKE_APPLE_DEVICE_ARCHS=$targetArch
    make && make install
}

function buildQt6Host() {
    ./configure -prefix $ros2HostQtPath -opensource -confirm-license -release
    make && make install
}

# Build Qt https://doc.qt.io/qt-6/ios-building-from-source.html
function buildQt6() {
    ./configure -prefix $depsInstallPath -opensource -confirm-license -platform macx-ios-clang -release -qt-host-path $ros2HostQtPath # -sysroot $depsInstallPath -system-zlib -system-libpng -system-freetype -pkg-config
    make && make install
}

function buildSuiteSparse() {
    echo "Build SuiteSparse"
    cd $depsExtractPath/SuiteSparse-5.12.0
    setCompilerFlags

    # By default, SuiteParse uses 64-bit integer for its `idx_t` (`long long`).
    # This unfortunately clashes with Eigen3's usage of `int`.
    # So change this in the included `SuiteParse/metis-5.1.0/include/metis.h`.
    sed -i.bak 's/#define IDXTYPEWIDTH 64/#define IDXTYPEWIDTH 32/' metis-5.1.0/include/metis.h

    #export CMAKE_OPTIONS="-DCMAKE_INSTALL_PREFIX=$depsInstallPath -DCMAKE_TOOLCHAIN_FILE=$scriptDir/cmake/$targetPlatform.cmake"
    #sed -i.bak 's;^CONFIG_FLAGS = ;CONFIG_FLAGS = -DCMAKE_TOOLCHAIN_FILE=\\$(prefix)/../../cmake/$targetPlatform.cmake;' metis-5.1.0/Makefile
    #sed -i.bak 's/^return system.*$/return 1;/' metis-5.1.0/GKlib/fs.c

    make static
    make install INSTALL=$depsInstallPath
}

# Needs: SuiteSparse even though it is optional
function buildEigen3() {
    echo "Build Eigen3"
    cd $depsExtractPath/eigen-3.4.0
    buildCMake
}

# Needs: gflags, glog, SuiteSparse
function buildCERES() {
    echo "Build CERES"
    cd $depsExtractPath/ceres-solver-2.0.0
    buildCMake
}

function buildFLANN() {
    echo "Build FLANN"
    cd $depsExtractPath/flann-1.9.1
    buildCMake -DBUILD_PYTHON_BINDINGS=OFF -DBUILD_MATLAB_BINDINGS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF
}

# Needs: Boost, FLANN, Eigen3
function buildPCL() {
    echo "Build PCL"
    cd $depsExtractPath/pcl
    buildCMake
}

function buildOpenCV() {
    echo "Build OpenCV"
    cd $depsExtractPath/opencv-4.6.0
    # https://docs.opencv.org/4.x/db/d05/tutorial_config_reference.html
    buildCMake -DCMAKE_BUILD_TYPE=Release -DBUILD_opencv_python2=OFF -DBUILD_JAVA=OFF -DBUILD_OBJC=OFF -DBUILD_ZLIB=NO -DBUILD_OPENEXR=YES
}

function buildAll() {
    buildZlib
    buildTinyXML2
    buildLibPng
    buildPixman
    buildFreeType2
    buildCairo
    buildBullet3
    buildGFlags
    buildGlog
    buildGtest
    buildAbsl
    buildGmp
    buildMpfr
    buildProtoBuf

    # Build Lua, Boost and Qt5 (macOS only)
    #case $targetPlatform in
    #    "macOS")
    #        buildLua
    #        buildBoost
    #        buildQt5;;
    #esac

    buildSuiteSparse
    buildEigen3
    buildCERES
    buildFLANN
    buildPCL
}

buildMoveItDeps() {
    cd $depsExtractPath/libccd-2.1 && buildCMake
    cd $depsExtractPath/octomap-1.9.6 && buildCMake

    # For octomap, we need to manually add
    #   IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libocto(map|math).1.9.6.dylib"
    # appropriately to the two commands
    #   set_target_properties(octomath PROPERTIES ...)
    #   set_target_properties(octomap PROPERTIES ...)
    # in the generated share/octomap/octomap-targets.cmake. Without this, building fcl will fail with
    #
    # CMake Error in CMakeLists.txt:
    #   IMPORTED_LOCATION not set for imported target "octomap" configuration
    #   "Release".

    sed -i.bak -E 's,set_target_properties\(octo(math|map) PROPERTIES,set_target_properties(octo\1 PROPERTIES\n  IMPORTED_LOCATION "\${_IMPORT_PREFIX}/lib/libocto\1.1.9.6.dylib",' $depsInstallPath/share/octomap/octomap-targets.cmake

    # FCL depends on octomap and libccd
    cd $depsExtractPath/fcl-0.7.0 && buildCMake -DBUILD_TESTING=NO
    cd $depsExtractPath/qhull-2020.2 && buildCMake
    cd $depsExtractPath/assimp-5.2.5 && buildCMake
    cd $depsExtractPath/ruckig-0.8.4 && buildCMake
    cd $depsExtractPath/glew-2.2.0/build/cmake && buildCMake

    # FreeGLUT needs X11 (provided by XQuartz for macOS)
    # For some reason the X11 include path is not added so we force add it
    cd $depsExtractPath/freeglut-3.4.0 && buildCMake -DFREEGLUT_BUILD_DEMOS=NO -DCMAKE_C_FLAGS="-isystem /usr/X11R6/include"

    cd $depsExtractPath/openssl-openssl-3.0.6 && ./Configure --prefix=$depsInstallPath && make && make install
    cd $depsExtractPath/ompl-1.5.2 && buildCMake
    cd $depsExtractPath/openmp-14.0.6.src && buildCMake
}

getSource
extractSource
setupPlatform

buildHostTools

case $targetPlatform in
    "macOS"|"macOS_M1") # Build dependencies for RVIZ and OpenCV
        buildZlib
        buildLibPng
        buildFreeType2
        buildEigen3
        buildTinyXML2
        buildBullet3
        buildQt5
        buildBoost
        buildOpenCV
        buildMoveItDeps;;

    *) # Build useful dependencies for iOS
        buildTinyXML2;;
esac
