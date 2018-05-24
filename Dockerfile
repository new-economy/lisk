FROM node:6 AS builder

RUN groupadd --gid 1100 lisk && \
    useradd --create-home --home-dir /home/lisk --shell /bin/bash --uid 1100 --gid 1100 lisk
COPY . /home/lisk/lisk/
RUN chown lisk:lisk --recursive /home/lisk/lisk

USER lisk
WORKDIR /home/lisk/lisk

RUN npm install
RUN ./node_modules/.bin/grunt release


FROM node:6

ENV CONFD_VERSION 0.16.0
ENV CONFD_SHA256 255d2559f3824dd64df059bdc533fd6b697c070db603c76aaf8d1d5e6b0cc334

RUN groupadd --gid 1100 lisk && \
    useradd --create-home --home-dir /home/lisk --shell /bin/bash --uid 1100 --gid 1100 lisk
COPY --from=builder /home/lisk/lisk/ /home/lisk/lisk/
COPY docker_files/ /
# git repository needed for build; cannot added to .dockerignore
RUN rm -rf /home/lisk/lisk/.git && \
    mkdir /home/lisk/lisk/logs && \
    chown lisk:lisk --recursive /home/lisk/lisk

RUN curl --location --output /tmp/confd \
         https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 && \
    if [ x"$( sha256sum /tmp/confd |awk '{ print $1 }' )" = x"${CONFD_SHA256}" ]; then \
        mv /tmp/confd /usr/local/bin/; \
	chmod +x /usr/local/bin/confd; \
    else \
        rm -f /tmp/confd; \
	exit 1; \
    fi

ARG LISK_VERSION
ARG LISK_MIN_VERSION=${LISK_VERSION}
ENV LISK_VERSION ${LISK_VERSION}
ENV LISK_MIN_VERSION ${LISK_MIN_VERSION}

USER lisk
WORKDIR /home/lisk/lisk
CMD ["/home/lisk/run.sh"]
