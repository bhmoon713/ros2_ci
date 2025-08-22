# ROS 2 Humble on Jammy (desktop-full = RViz etc.)
FROM osrf/ros:humble-desktop-full
SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

# Tools for ROS 2 builds + Gazebo Classic integration
RUN apt-get update && apt-get install -y \
    python3-rosdep \
    python3-colcon-common-extensions \
    ros-dev-tools \
    ros-humble-gazebo-ros-pkgs ros-humble-gazebo-ros2-control \
    gazebo \
    xvfb x11-apps wget git \
 && rm -rf /var/lib/apt/lists/*

# rosdep (safe to re-run)
RUN rosdep init 2>/dev/null || true
RUN rosdep update

# Workspace
ENV ROS_WS=/ros2_ws
RUN mkdir -p ${ROS_WS}/src
WORKDIR ${ROS_WS}

# Bring in your local fastbot stack from the build context
# (Assumes a 'fastbot/' folder exists next to this Dockerfile build context)
COPY fastbot/ ./src/fastbot/

# Clone your ROS 2 waypoints package
ARG WAYPOINTS_REF=main
RUN git clone --depth 1 --branch "${WAYPOINTS_REF}" \
    https://github.com/bhmoon713/fastbot_waypoints.git ./src/fastbot_waypoints

# Resolve deps & build
RUN source /opt/ros/humble/setup.bash \
 && rosdep install --rosdistro humble --from-paths src --ignore-src -r -y \
 && colcon build --symlink-install

# Headless display defaults (if you need to run Gazebo in CI)
ENV DISPLAY=:99
ENV GAZEBO_MODEL_PATH=${ROS_WS}/src:${GAZEBO_MODEL_PATH}
ENV GAZEBO_RESOURCE_PATH=${ROS_WS}/src:${GAZEBO_RESOURCE_PATH}

CMD ["bash"]
