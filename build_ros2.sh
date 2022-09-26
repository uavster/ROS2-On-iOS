# Usage:
#
#      build_ros2.sh [Platform]
#
# where [Platform] should be either [iOS], [iOS_Simulator], [iOS_Simulator_M1], [macCatalyst], [macCatalyst_M1]
# or [macOS] for Mac desktop.

REPO_ROOT=`pwd`
targetPlatform=$1
ros2PythonEnvPath=$REPO_ROOT/ros2PythonEnv
ros2InstallPath=$REPO_ROOT/ros2_$targetPlatform
ros2SystemDependenciesPath=$REPO_ROOT/ros2_deps_$targetPlatform

colconArgs=(--install-base $ros2InstallPath \
            --merge-install --cmake-force-configure \
            --cmake-args -DBUILD_TESTING=NO \
                         -DTHIRDPARTY=FORCE \
                         -DCOMPILE_TOOLS=NO \
                         -DFORCE_BUILD_VENDOR_PKG=ON \
                         -DBUILD_MEMORY_TOOLS=OFF \
                         -DRCL_LOGGING_IMPLEMENTATION=rcl_logging_noop)

prepareVirtualEnv() {
    python3 -m venv $ros2PythonEnvPath
    source $ros2PythonEnvPath/bin/activate
    python3 -m pip install -r requirements.txt
}

printPython() {
    echo "python3        : found " $(which python3)
    echo "python3-config : found " $(which python3-config)
    echo "    --prefix   : " $(python3-config --prefix)
    echo "    --ldflags  : " $(python3-config --ldflags)
    echo "    --libs     : " $(python3-config --libs)
    echo "    --includes : " $(python3-config --includes)
    echo "    --cflags   : " $(python3-config --cflags)
    # echo "Files in /Users/runner/hostedtoolcache/Python/3.10.7/x64/"
    # find /Users/runner/hostedtoolcache/Python/3.10.7/x64/
}

buildRos2Base() {
    echo "Build ros2 base"

    # Download local ASIO
    # git clone https://github.com/chriskohlhoff/asio

    # Get prebuilt dependencies
    if [ $targetPlatform == "macOS" ]; then
        curl -L -o ros2_deps_macOS.tar.xz https://github.com/light-tech/ROS2-On-iOS/releases/download/humble-1.0.1/ros2_deps_macOS.tar.xz
        tar xzf ros2_deps_macOS.tar.xz
    fi

    cd $REPO_ROOT
    mkdir -p ros2_ws/src
    cd ros2_ws

    # wget https://raw.githubusercontent.com/ros2/ros2/humble/ros2.repos
    vcs import src < $REPO_ROOT/ros2_min.repos

    # Ignore rcl_logging_spdlog package
    touch src/ros2/rcl_logging/rcl_logging_spdlog/AMENT_IGNORE

    if [ $targetPlatform == "macOS" ]; then
        # For macOS desktop, we add the CLI tools (ros2 launch) and rclpy as well
        vcs import src < $REPO_ROOT/ros2_cli.repos

        # And also build RVIZ2
        vcs import src < $REPO_ROOT/rviz2.repos

        sed -i.bak "s,CMAKE_ARGS,CMAKE_ARGS\n      -DCMAKE_PREFIX_PATH=$REPO_ROOT/ros2_deps_macOS,g" \
            src/ros2/rviz/rviz_ogre_vendor/CMakeLists.txt \
            src/ros2/orocos_kdl_vendor/orocos_kdl_vendor/CMakeLists.txt

        touch src/ros2/orocos_kdl_vendor/python_orocos_kdl_vendor/AMENT_IGNORE \
              src/ros2/rviz/rviz_visual_testing_framework/AMENT_IGNORE

        colconArgs+=(-DCMAKE_PREFIX_PATH=$ros2SystemDependenciesPath)

    else
        # For iOS platform, set appropriate toolchain file
        colconArgs+=(-DCMAKE_TOOLCHAIN_FILE=$REPO_ROOT/cmake/$targetPlatform.cmake)

        # Replace if_arp.h header with ethernet.h
        sed -i.bak 's/if_arp.h/ethernet.h/g' src/eProsima/Fast-DDS/src/cpp/utils/IPFinder.cpp
    fi

    # VERBOSE=1 --executor sequential --event-handlers console_direct+
    colcon build "${colconArgs[@]}"
}

setupROS2base() {
    echo "Prepare ROS2 base and dependencies"

    # Extract previously built dependencies and ROS2 base to save time while we try to build rviz2
    curl -L -o ros2_deps_macOS.tar.xz https://github.com/light-tech/ROS2-On-iOS/releases/download/humble-1.0.1/ros2_deps_macOS.tar.xz \
         -o ros2_macOS.tar.xz https://github.com/light-tech/ROS2-On-iOS/releases/download/humble-1.0.1/ros2_macOS.tar.xz
    tar xzf ros2_deps_macOS.tar.xz
    tar xzf ros2_macOS.tar.xz

    # Source the prebuilt ROS2 base
    # IMPORTANT: GitHub Action uses bash shell!
    source $REPO_ROOT/ros2_macOS/setup.sh

    # Temporarily rebuild freetype2 without any dependencies
    ./build_deps.sh macOS
}

buildRviz2() {
    echo "Build rviz2"

    cd $REPO_ROOT
    mkdir -p ros2_ws/src
    cd ros2_ws
    vcs import src < $REPO_ROOT/rviz2.repos

    sed -i.bak "s,CMAKE_ARGS,CMAKE_ARGS\n      -DCMAKE_PREFIX_PATH=$REPO_ROOT/ros2_deps_macOS,g" src/ros2/rviz/rviz_ogre_vendor/CMakeLists.txt
    sed -i.bak "s,CMAKE_ARGS,CMAKE_ARGS\n      -DCMAKE_PREFIX_PATH=$REPO_ROOT/ros2_deps_macOS,g" src/ros2/orocos_kdl_vendor/orocos_kdl_vendor/CMakeLists.txt
    touch src/ros2/orocos_kdl_vendor/python_orocos_kdl_vendor/AMENT_IGNORE
    touch src/ros2/rviz/rviz_visual_testing_framework/AMENT_IGNORE

    colconArgs+=(-DCMAKE_PREFIX_PATH=$ros2SystemDependenciesPath)

    VERBOSE=1 colcon build --executor sequential --event-handlers console_direct+ "${colconArgs[@]}"
}

test -d $ros2PythonEnvPath || prepareVirtualEnv
source $ros2PythonEnvPath/bin/activate
printPython
buildRos2Base
# setupROS2base
# buildRviz2
