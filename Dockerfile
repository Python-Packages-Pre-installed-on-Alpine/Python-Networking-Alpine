ARG DOCKER_BASE_IMAGE_PREFIX
ARG DOCKER_BASE_IMAGE_NAMESPACE=pythonpackagesonalpine
ARG DOCKER_BASE_IMAGE_NAME=python-networking-alpine
ARG DOCKER_BASE_IMAGE_TAG=cryptography-alpine
FROM ${DOCKER_BASE_IMAGE_PREFIX}${DOCKER_BASE_IMAGE_NAMESPACE}/${DOCKER_BASE_IMAGE_NAME}:${DOCKER_BASE_IMAGE_TAG}

ARG FIX_ALL_GOTCHAS_SCRIPT_LOCATION
ARG ETC_ENVIRONMENT_LOCATION
ARG CLEANUP_SCRIPT_LOCATION

# Depending on the base image used, we might lack wget/curl/etc to fetch ETC_ENVIRONMENT_LOCATION.
ADD $FIX_ALL_GOTCHAS_SCRIPT_LOCATION .
ADD $CLEANUP_SCRIPT_LOCATION .

RUN set -o allexport \
    && . ./fix_all_gotchas.sh \
    && set +o allexport \
    && pip install --no-cache-dir pyspnego decorator \
    && pip install --no-cache-dir wheel \
    && apk add --no-cache --virtual .build-deps gcc musl-dev krb5-dev \
    # need gcc for gssapi
    # gcc -Wno-unused-result -Wsign-compare -DNDEBUG -g -fwrapv -O3 -Wall -fomit-frame-pointer -g -fno-semantic-interposition -fomit-frame-pointer -g -fno-semantic-interposition -fomit-frame-pointer -g -fno-semantic-interposition -DTHREAD_STACK_SIZE=0x100000 -fPIC -I/usr/include/python3.8 -c gssapi/raw/misc.c -o build/temp.linux-x86_64-3.8/gssapi/raw/misc.o -DHAS_GSSAPI_EXT_H
    && pip install --no-cache-dir gssapi \
    && pip install --no-cache-dir git+https://github.com/jborean93/smbprotocol.git#egg=smbprotocol[kerberos] \
    && apk del --no-cache .build-deps \
    && python -c "import smbprotocol" \
    && python -c "import smbclient; smbclient.ClientConfig; smbclient.register_session" \
    && apk add --no-cache krb5 \
    && pip install --no-cache-dir --upgrade certifi \
    # Do we really need YAML capability? No, no we do not.
    # But it's small, and it enables the testing, and it's nice to test on the exact Docker image that is actually used.
    && pip install --no-cache-dir pyyaml \
    && . ./cleanup.sh

