FROM nvcr.io/nvidia/l4t-base:r32.2
RUN apt-get update && apt-get install -y vim git wget

ARG git_repo=https://github.com/jerwallace/aws-nvidia-sample-robomaker-dino-detect.git
ARG local_home=~/environment
ARG git_folder=aws-nvidia-sample-robomaker-dino-detect
ARG app_name=dinobot
ARG fs_path=rootfs-nano
ARG bucket=dinobot-robomaker-assets

# Install ROS
RUN apt-add-repository universe \
    && apt-add-repository multiverse \
    && apt-add-repository restricted
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
RUN apt-get update
RUN apt-get install ros-melodic-ros-base -y
RUN sh -c 'echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc'
RUN rosdep init
RUN printf "yaml https://s3-us-west-2.amazonaws.com/rosdep/base.yaml\nyaml https://nvidia-jetbot-sources.s3-us-west-2.amazonaws.com/nvidia.yaml" > /etc/ros/rosdep/sources.list.d/19-aws-sdk.list
RUN rosdep update

# Install Python and colcon
RUN apt-get update && apt-get install -y \
      python \
      python3-apt \
      curl \
    && curl -O https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py \
    && python2 get-pip.py \
    && python3 -m pip install -U colcon-ros-bundle
RUN pip3 install --upgrade numpy 
RUN pip3 install torch-1.0.0a0+18eef1d-cp36-cp36m-linux_aarch64.whl
RUN pip3 install torchvision
RUN git clone $git_repo
RUN cd $git_folder/robot_ws/src/$app_name/
COPY $local_home/$git_folder/robot_ws/src/$app_name/certs/ $git_folder/robot_ws/src/$app_name/

RUN echo $'BUCKET='$bucket'\n\
GIT_FOLDER='$git_folder'\n\
GIT_REPO='$git_repo'\n\
source /opt/ros/melodic/setup.bash\n\
[ -d "$GIT_FOLDER" ] && cd $GIT_FOLDER || (git clone $GIT_REPO && cd $GIT_FOLDER)\n\
git stash\n\
git pull\n\
rosdep update\n\
rosdep fix-permissions\n\
rosdep install --from-paths src --ignore-src -r -y\n\
colcon build\n\
colcon bundle\n\
today=`date +%Y_%m_%d_%H_%M_%S`;\n\
s3key="s3://$BUCKET/robot_app_$today.tar"\n\
aws s3 cp bundle/output.tar $s3key'\
>> build.sh
RUN chmod +x build.sh