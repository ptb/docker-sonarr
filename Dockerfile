FROM debian:jessie
# MAINTAINER Peter T Bosse II <ptb@ioutime.com>

RUN useradd --comment Sonarr --create-home --gid users --no-user-group --shell /usr/sbin/nologin --uid 1026 sonarr \

  && REQUIRED_PACKAGES="gpac nzbdrone python" \
  && BUILD_PACKAGES="build-essential libffi-dev libssl-dev python-dev wget xz-utils" \

  && echo "debconf debconf/frontend select noninteractive" | debconf-set-selections \

  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D3D831EF \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC \
  && printf "%s\n" \
    "deb http://download.mono-project.com/repo/debian wheezy main" \
    "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" \
    >> /etc/apt/sources.list.d/mono-xamarin.list \
  && printf "%s\n" \
    "deb http://apt.sonarr.tv/ master main" \
    >> /etc/apt/sources.list.d/sonarr.list \
  && sed \
    -e "s/httpredir.debian.org/debian.mirror.constant.com/" \
    -i /etc/apt/sources.list \

  && apt-get update -qq \
  && apt-get install -qqy \
    $REQUIRED_PACKAGES \
    $BUILD_PACKAGES \

  && wget \
    --no-check-certificate \
    --output-document - \
    --quiet \
    https://api.github.com/repos/just-containers/s6-overlay/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*s6-overlay-amd64.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --no-check-certificate \
      --output-document - \
      --quiet \
    | tar -xz -C / \

  && mkdir -p /etc/services.d/sonarr/ \
  && printf "%s\n" \
    "#!/usr/bin/env sh" \
    "set -ex" \
    "exec s6-applyuidgid -g 100 -u 1026 mono /opt/NzbDrone/NzbDrone.exe --no-browser -data=/home/sonarr" \
    > /etc/services.d/sonarr/run \
  && chmod +x /etc/services.d/sonarr/run \

  && mkdir -p /home/ffmpeg/ \
  && wget \
    --output-document - \
    --quiet \
    http://cdn.ptb2.me/ffmpeg-2.8.2.tar.gz \
    | tar -xz -C /home/ffmpeg/ \

  && wget \
    --no-check-certificate \
    --output-document - \
    --quiet \
    https://bootstrap.pypa.io/ez_setup.py \
    | python \
  && wget \
    --no-check-certificate \
    --output-document - \
    --quiet \
    https://raw.github.com/pypa/pip/master/contrib/get-pip.py \
    | python \
  && pip install \
    babelfish \
    'guessit<2' \
    qtfaststart \
    requests \
    subliminal \
  && pip install \
    requests[security] \

  && mkdir -p /home/mkv-to-m4v/ \
  && wget \
    --no-check-certificate \
    --output-document - \
    --quiet \
    https://api.github.com/repos/mdhiggins/sickbeard_mp4_automator/tarball/master \
    | tar -xz -C /home/mkv-to-m4v/ \
  && mv /home/mkv-to-m4v/*/* /home/mkv-to-m4v/ \
  && sed -e '/if self.original/,+3 d' -i /home/mkv-to-m4v/tmdb_mp4.py \
  && sed -e '/if self.original/,+3 d' -i /home/mkv-to-m4v/tvdb_mp4.py \
  && chown -R sonarr:users /home/mkv-to-m4v/ \
  && chmod +x /home/mkv-to-m4v/*.py \

  && apt-get purge -qqy --auto-remove \
    $BUILD_PACKAGES \
  && apt-get clean -qqy \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ENTRYPOINT ["/init"]
EXPOSE 8989

# docker build --rm --tag ptb2/sonarr .
# docker run --detach --name sonarr --net host \
#   --publish 8989:8989/tcp \
#   --volume /volume1/@appstore/Sonarr:/home/sonarr \
#   --volume /volume1/@appstore/mkv-to-m4v/autoProcess.ini:/home/mkv-to-m4v/autoProcess.ini \
#   --volume /volume1/Incoming:/home/media \
#   ptb2/sonarr
