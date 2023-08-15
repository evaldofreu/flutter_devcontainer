FROM ubuntu:22.04

ENV UID=2000
ENV GID=2000
ENV USER="developer"
ENV JAVA_VERSION="17"
ENV ANDROID_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip"
ENV ANDROID_VERSION="33"
ENV ANDROID_BUILD_TOOLS_VERSION="29.0.3"
ENV ANDROID_ARCHITECTURE="x86_64"
ENV ANDROID_SDK_ROOT="/home/$USER/android"
ENV FLUTTER_CHANNEL="stable"
ENV FLUTTER_VERSION="3.10.6"
ENV FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/linux/flutter_linux_$FLUTTER_VERSION-$FLUTTER_CHANNEL.tar.xz"
ENV FLUTTER_HOME="/home/$USER/flutter"
ENV FLUTTER_WEB_PORT="8090"
ENV FLUTTER_DEBUG_PORT="42000"
ENV FLUTTER_EMULATOR_NAME="flutter_emulator"
ENV PATH="$ANDROID_SDK_ROOT/cmdline-tools/tools:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/cmdline-tools/tools/lib:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/platforms:$FLUTTER_HOME/bin:$PATH"

# install all dependencies
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install --yes --no-install-recommends openjdk-$JAVA_VERSION-jdk curl unzip sed git bash xz-utils libglvnd0 ssh xauth x11-xserver-utils libpulse0 libxcomposite1 libgl1-mesa-glx sudo clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev npm nodejs\
  && rm -rf /var/lib/{apt,dpkg,cache,log}

# create user
RUN groupadd --gid $GID $USER \
  && useradd -s /bin/bash --uid $UID --gid $GID -m $USER \
  && echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
  && chmod 0440 /etc/sudoers.d/$USER

USER $USER
WORKDIR /home/$USER

# android sdk
RUN mkdir -p $ANDROID_SDK_ROOT 
RUN mkdir -p /home/$USER/.android 
RUN touch /home/$USER/.android/repositories.cfg 
RUN curl -o android_tools.zip $ANDROID_TOOLS_URL 
RUN unzip -qq -d "$ANDROID_SDK_ROOT" android_tools.zip 
RUN rm android_tools.zip 
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/tools 
RUN mv $ANDROID_SDK_ROOT/cmdline-tools/bin $ANDROID_SDK_ROOT/cmdline-tools/tools 
RUN mv $ANDROID_SDK_ROOT/cmdline-tools/lib $ANDROID_SDK_ROOT/cmdline-tools/tools 
RUN yes "y" | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION" 
RUN yes "y" | sdkmanager "platforms;android-$ANDROID_VERSION" 
RUN yes "y" | sdkmanager "platform-tools" 
RUN yes "y" | sdkmanager "emulator" 
RUN yes "y" | sdkmanager "system-images;android-$ANDROID_VERSION;google_apis_playstore;$ANDROID_ARCHITECTURE"

# flutter
RUN curl -o flutter.tar.xz $FLUTTER_URL \
  && mkdir -p $FLUTTER_HOME \
  && tar xf flutter.tar.xz -C /home/$USER \
  && rm flutter.tar.xz 
RUN flutter config --no-analytics 
RUN flutter --disable-telemetry 
RUN flutter precache 
RUN sdkmanager --install "cmdline-tools;latest"
# RUN cd $ANDROID_SDK_ROOT/cmdline-tools/tools/bin && yes | ./sdkmanager --licenses
RUN yes "y" | flutter doctor --android-licenses 
RUN flutter doctor
RUN flutter emulators --create 

#
RUN curl -sL firebase.tools | bash

COPY entrypoint.sh /usr/local/bin/
COPY chown.sh /usr/local/bin/
COPY flutter-android-emulator.sh /usr/local/bin/flutter-android-emulator

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]