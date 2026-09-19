# AcuCOBOL-GT 5.2 Runtime + AcuShare + Compiler (ccbl) sobre Debian 3.1 "Sarge" (i386).
#
# Debian Sarge foi escolhido porque os binários do AcuCOBOL-GT 5.2 (build de 2003,
# glibc 2.2) dependem de um símbolo versionado (errno@GLIBC_2.0) removido do glibc
# a partir de ~2.32. Debian >= Bullseye quebra esses binários; Sarge (glibc 2.3.2)
# ainda oferece esse símbolo e roda os executáveis originais sem patches.
#
# Build (emulado via QEMU, plataforma alvo é i386/32-bit):
#   docker buildx build --platform linux/386 -f docker/Dockerfile -t debian-cobol:5.2 --load .
#
# syntax=docker/dockerfile:1.7

FROM --platform=linux/386 debian/eol:sarge AS extract

COPY files/acucobol/archives/linux_22.tar /tmp/acu.tar
COPY files/acucobol/instinfo/linux_22/runlist /tmp/runlist

RUN set -e; \
    mkdir -p /opt/acucobol; \
    cd /tmp && tar xf acu.tar; \
    while read -r f; do \
        [ -z "$f" ] && continue; \
        mkdir -p "/opt/acucobol/$(dirname "$f")"; \
        cp -a "/tmp/$f" "/opt/acucobol/$f"; \
    done < /tmp/runlist; \
    cp -a /tmp/bin/ccbl /opt/acucobol/bin/ccbl; \
    mkdir -p /opt/acucobol/license; \
    for p in runcbl ccbl acushare; do \
        ln -sf /opt/acucobol/license/$p.alc /opt/acucobol/bin/$p.alc; \
    done

FROM --platform=linux/386 debian/eol:sarge

LABEL maintainer="perlporter@gmail.com" \
      description="AcuCOBOL-GT 5.2 Runtime/AcuShare/Compiler em Debian Sarge i386"

ENV COBDIR=/opt/acucobol \
    PATH=/opt/acucobol/bin:$PATH \
    TERM=vt100 \
    A_TERMCAP=/opt/acucobol/etc/a_termcap

COPY --from=extract /opt/acucobol /opt/acucobol
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    printf '\n# aumenta a tolerancia de espera pelo acushare (util sob emulacao QEMU)\nACUSHARE_TIMEOUT\t60\n' >> /opt/acucobol/etc/cblconfig

WORKDIR /work
VOLUME ["/opt/acucobol/license"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["help"]
