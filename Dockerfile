FROM adoptopenjdk/openjdk8-openj9:jdk8u252-b09_openj9-0.20.0-debian

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    libapr1 \
    telnet \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

ARG user=rocketmq
ARG group=rocketmq
ARG uid=3000
ARG gid=3000

# RocketMQ is run with user `rocketmq`, uid = 3000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN groupadd -g ${gid} ${group} \
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user}

ARG version

# Rocketmq version
ENV ROCKETMQ_VERSION 4.6.1
# Rocketmq home
ENV ROCKETMQ_HOME  /home/rocketmq/rocketmq-${ROCKETMQ_VERSION}

WORKDIR  ${ROCKETMQ_HOME}

RUN set -eux \
    && curl https://archive.apache.org/dist/rocketmq/${ROCKETMQ_VERSION}/rocketmq-all-${ROCKETMQ_VERSION}-bin-release.zip -o rocketmq.zip \
    # && curl https://archive.apache.org/dist/rocketmq/${ROCKETMQ_VERSION}/rocketmq-all-${ROCKETMQ_VERSION}-bin-release.zip.asc -o rocketmq.zip.asc \
    # && curl -L https://www.apache.org/dist/rocketmq/KEYS -o KEYS \
    # && gpg --import KEYS \
    # && gpg --batch --verify rocketmq.zip.asc rocketmq.zip \
    && unzip rocketmq.zip \
    && mv rocketmq-all*/* . \
    && rmdir rocketmq-all*  \
    # && rm rocketmq.zip rocketmq.zip.asc KEYS
    && rm rocketmq.zip

# add scripts
COPY scripts/ ${ROCKETMQ_HOME}/bin/

RUN chown -R ${uid}:${gid} ${ROCKETMQ_HOME}

# expose namesrv port
EXPOSE 9876

# add customized scripts for namesrv
RUN mv ${ROCKETMQ_HOME}/bin/runserver-customize.sh ${ROCKETMQ_HOME}/bin/runserver.sh \
    && chmod a+x ${ROCKETMQ_HOME}/bin/runserver.sh \
    && chmod a+x ${ROCKETMQ_HOME}/bin/mqnamesrv

# expose broker ports
EXPOSE 10909 10911 10912

# add customized scripts for broker
RUN mv ${ROCKETMQ_HOME}/bin/runbroker-customize.sh ${ROCKETMQ_HOME}/bin/runbroker.sh \
    && chmod a+x ${ROCKETMQ_HOME}/bin/runbroker.sh \
    && chmod a+x ${ROCKETMQ_HOME}/bin/mqbroker

# export Java options
RUN export JAVA_OPT=" -Duser.home=/opt"

# Add ${JAVA_HOME}/lib/ext as java.ext.dirs
RUN sed -i 's/${JAVA_HOME}\/jre\/lib\/ext/${JAVA_HOME}\/jre\/lib\/ext:${JAVA_HOME}\/lib\/ext/' ${ROCKETMQ_HOME}/bin/tools.sh

USER ${user}

WORKDIR ${ROCKETMQ_HOME}/bin
