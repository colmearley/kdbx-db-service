ARG DS_REGISTRY=portal.dl.kx.com/
ARG DS_TAG=0.1.0-beta.1

FROM ${DS_REGISTRY}kxi-sg-agg:${DS_TAG}

ARG KX_BASE_DIR=/opt/kx
ARG KX_APP_DIR=${KX_BASE_DIR}/app

USER root
RUN yum install -y net-tools lsof file man
COPY files/customdotz.q ${KX_BASE_DIR}/
RUN sed -i '/export KX_LINE=0/s/^/#/' ${KX_BASE_DIR}/startq.sh
RUN sed -i "1i \\\\\\l ${KX_BASE_DIR}/customdotz.q" ${KX_BASE_DIR}/ic.init.q
RUN sed -i '$a .customdotz.applyOverrides[];' ${KX_APP_DIR}/startq.q
USER nobody
