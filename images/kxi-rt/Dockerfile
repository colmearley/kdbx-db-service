ARG DS_REGISTRY=portal.dl.kx.com/
ARG DS_RT_TAG=1.18.0

FROM ${DS_REGISTRY:-}kxi-rt:${DS_RT_TAG}

ARG KX_BASE_DIR=/opt/kx
ARG KX_APP_DIR=${KX_BASE_DIR}/app
ARG KX_RT_DIR=${KX_APP_DIR}/kxi-rt-common

USER root
RUN yum install -y net-tools lsof file man
COPY files/customdotz.q ${KX_BASE_DIR}/
RUN sed -i '/export KX_LINE=0/s/^/#/' ${KX_BASE_DIR}/startq.sh
RUN sed -i "1i \\\\\\l ${KX_BASE_DIR}/customdotz.q" ${KX_BASE_DIR}/ic.init.q
RUN sed -i '$a .customdotz.applyOverrides[];' ${KX_APP_DIR}/startq.q ${KX_RT_DIR}/run-raft-seq.q ${KX_RT_DIR}/raft-seq-lib/seq.q ${KX_RT_DIR}/archiver.q ${KX_RT_DIR}/rest.q
USER nobody
