ARG BASE_IMAGE=ciwei123321/foam-api-v2:latest

FROM ${BASE_IMAGE} AS original

FROM eclipse-temurin:21-jdk AS patcher
COPY --from=original /app.jar /work/app.jar
COPY patch-classes/ /patch-classes/
RUN jar uf /work/app.jar \
    -C /patch-classes BOOT-INF/classes/com/una/embyhub/config/license/LicenseRuntimeGate.class \
    -C /patch-classes BOOT-INF/classes/com/una/embyhub/service/impl/LicenseServiceImpl.class

FROM ${BASE_IMAGE}
COPY --from=patcher /work/app.jar /app.jar
