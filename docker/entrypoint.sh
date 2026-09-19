#!/bin/sh
# Entrypoint da imagem debian-cobol.
set -e

usage() {
    cat <<'EOF'
debian-cobol - AcuCOBOL-GT 5.2 Runtime/AcuShare/Compiler

Uso:
  <imagem> activate                     Ativa uma licença (roda o activator, interativo)
  <imagem> compile <arquivo.cbl> [opts] Compila um .cbl com o ccbl
  <imagem> run <programa> [args]        Executa um programa já compilado com o runcbl
  <imagem> build-run <arquivo.cbl>      Compila e executa em seguida
  <imagem> acushare [opts]              Inicia o daemon acushare
  <imagem> vutil [opts] arquivo         Utilitário de arquivos Vision (indexados)
  <imagem> shell                        Abre um shell dentro da imagem

Exemplos de vutil (não precisa de licença nem de acushare):
  <imagem> vutil -info cadastro.dat     Estatísticas do arquivo (registros, tamanho, chaves)
  <imagem> vutil -check cadastro.dat    Verifica integridade
  <imagem> vutil -rebuild cadastro.dat  Reconstrói o índice

Licenças (.alc) ficam em /opt/acucobol/license — monte essa pasta como
volume para persistir a ativação entre execuções, ex:

  docker run --rm -it -v "$PWD/license":/opt/acucobol/license debian-cobol:5.2 activate

Compilar e rodar um programa do host:

  docker run --rm -v "$PWD":/work -v "$PWD/license":/opt/acucobol/license \
      debian-cobol:5.2 build-run hello.cbl
EOF
}

ensure_acushare() {
    acushare -start >/tmp/acushare.log 2>&1 || true
    # dá um tempo para o daemon ficar pronto para atender checkouts de licença
    # (generoso de propósito: sob QEMU/binfmt em host ARM o IPC do acushare
    # é sensível a timing; em host x86_64 nativo isso é quase instantâneo)
    sleep 10
}

cmd="${1:-help}"
[ $# -gt 0 ] && shift || true

case "$cmd" in
    activate)
        exec activator
        ;;
    compile)
        [ -n "$1" ] || { usage; exit 1; }
        ensure_acushare
        exec ccbl "$@"
        ;;
    run)
        [ -n "$1" ] || { usage; exit 1; }
        ensure_acushare
        exec runcbl "$@"
        ;;
    build-run)
        [ -n "$1" ] || { usage; exit 1; }
        ensure_acushare
        src="$1"; shift
        base=$(basename "$src" .cbl)
        ccbl "$src" "$@"
        exec runcbl "$base"
        ;;
    acushare)
        exec acushare "$@"
        ;;
    vutil)
        [ -n "$1" ] || { usage; exit 1; }
        exec vutil "$@"
        ;;
    shell|sh|bash)
        ensure_acushare
        exec /bin/sh
        ;;
    help|*)
        usage
        ;;
esac
