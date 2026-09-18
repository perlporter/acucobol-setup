# debian-cobol — AcuCOBOL-GT 5.2 em Docker

Imagem Docker com **AcuCOBOL-GT 5.2** (Runtime + AcuShare + compilador `ccbl`)
rodando sobre **Debian 3.1 "Sarge" (i386)**, capaz de compilar e executar
programas `.cbl` dentro do container.

## Por que Debian Sarge?

Os binários do AcuCOBOL-GT 5.2 (build de 2003, extraídos de
`files/acucobol/archives/linux_22.tar`, alvo Linux glibc 2.2) usam um símbolo
versionado antigo (`errno@GLIBC_2.0`) que o glibc removeu a partir de ~2.32.
Isso quebra esses binários em qualquer Debian >= 11 (Bullseye) ou mais novo.

Debian 3.1 "Sarge" (glibc 2.3.2) é o Debian mais antigo ainda disponível via
Docker Hub (`debian/eol:sarge`) que preserva esse símbolo — e é também a
versão de Debian mais próxima, na linha do tempo, do build original do
AcuCOBOL. Testado e validado: `ccbl`, `runcbl` e `acushare` rodam sem
nenhum patch binário.

## Arquitetura: linux/386 (32-bit)

Os executáveis são ELF 32-bit x86. A imagem é construída para a plataforma
`linux/386`.

- **Em host x86_64 (Intel/AMD, incluindo a maioria dos servidores/VMs Linux
  e Docker Hub cloud runners):** roda **nativo**, sem emulação — o kernel
  x86_64 executa código de 32 bits diretamente. É o ambiente recomendado
  para uso real/produção.
- **Em host ARM (ex.: Mac Apple Silicon):** o Docker Desktop usa QEMU para
  emular `linux/386`. Funciona, mas a comunicação interna do `acushare`
  (IPC via memória compartilhada) fica sensível a timing sob emulação e
  pode ocasionalmente acusar `Timeout waiting for reply from acushare`.
  Isso é uma limitação do ambiente de emulação, não um bug da imagem — em
  x86_64 real essa flutuação desaparece.

## Licenciamento — não incluído na imagem

Este projeto **não** contém nem publica nenhum código/chave de licença da
Acucorp/Micro Focus. São três produtos, três licenças diferentes:

| Produto | Habilita | Arquivo gerado |
|---|---|---|
| Runtime | `runcbl` (executar programas compilados) | `runcbl.alc` |
| Dev System | `ccbl` (compilar `.cbl`) | `ccbl.alc` |
| (mesma licença Runtime, modo rede) | `acushare` precisa estar de pé para o `runcbl`/`ccbl` fazerem checkout de licença | — |

As licenças são ativadas com o utilitário `activator`, a partir de um
"Product Code" + "Product Key" que você recebeu da Acucorp/Micro Focus.
Cada `.alc` fica em `/opt/acucobol/bin/<programa>.alc`, mas na imagem esses
caminhos são **symlinks** para `/opt/acucobol/license/<programa>.alc` — por
isso basta montar uma pasta local como volume em `/opt/acucobol/license`
para a ativação persistir entre execuções, sem nunca gravar a licença
dentro da imagem.

```bash
mkdir -p license

# Ativa o Runtime (gera runcbl.alc)
docker run --rm -it -v "$PWD/license":/opt/acucobol/license debian-cobol:5.2 activate
# -> Enter the product code: <seu código Runtime>
# -> Enter the product key : <sua chave Runtime>

# Ativa o Dev System / compilador (gera ccbl.alc)
docker run --rm -it -v "$PWD/license":/opt/acucobol/license debian-cobol:5.2 activate
# -> Enter the product code: <seu código Dev System>
# -> Enter the product key : <sua chave Dev System>
```

A pasta `license/` (e qualquer `*.alc`/`*.txt` com códigos) está no
`.gitignore` — nunca é versionada nem vai para o Docker Hub.

## Build da imagem

Requer Docker com suporte a `buildx`/QEMU para `linux/386` (Docker Desktop
já vem com isso; em Linux, `docker run --privileged --rm tonistiigi/binfmt --install 386`
se necessário).

```bash
docker buildx build --platform linux/386 -f docker/Dockerfile -t debian-cobol:5.2 --load .
```

## Uso

```bash
# Compilar e rodar um .cbl num só comando
docker run --rm --platform linux/386 \
  -v "$PWD/license":/opt/acucobol/license \
  -v "$PWD/examples":/work \
  debian-cobol:5.2 build-run hello.cbl

# Só compilar
docker run --rm --platform linux/386 \
  -v "$PWD/license":/opt/acucobol/license \
  -v "$PWD/examples":/work \
  debian-cobol:5.2 compile hello.cbl

# Só rodar um programa já compilado (hello.acu/hello.int)
docker run --rm --platform linux/386 \
  -v "$PWD/license":/opt/acucobol/license \
  -v "$PWD/examples":/work \
  debian-cobol:5.2 run hello

# Shell interativo dentro da imagem
docker run --rm -it --platform linux/386 \
  -v "$PWD/license":/opt/acucobol/license \
  -v "$PWD/examples":/work \
  debian-cobol:5.2 shell
```

O `acushare` é iniciado automaticamente pelo entrypoint antes de qualquer
`compile`/`run`/`build-run`/`shell` (idempotente — se já estiver rodando,
não faz nada).

## Compartilhando com outra pessoa (Docker Hub)

Como os binários são software comercial da Acucorp/Micro Focus, publique
num **repositório privado** do Docker Hub e convide a pessoa como
colaboradora — não num repositório público.

```bash
docker login
docker tag debian-cobol:5.2 <seu-usuario-dockerhub>/debian-cobol:5.2
docker push <seu-usuario-dockerhub>/debian-cobol:5.2
```

Imagem publicada em: **`perlporter/debian-cobol`** (tags `5.2` e `latest`),
repositório **privado**. Para outra pessoa usar, ela precisa:

1. Ser convidada como colaboradora no repositório (hub.docker.com →
   `perlporter/debian-cobol` → Settings → Collaborators);
2. Rodar `docker login` com a conta dela;
3. `docker pull perlporter/debian-cobol:5.2`.

Cada pessoa que rodar a imagem (você e seu amigo) ativa sua **própria**
licença localmente com `activate`, do jeito descrito acima — a licença
nunca viaja dentro da imagem.

## Estrutura do repositório

```
.
├── docker/
│   ├── Dockerfile        # build multi-stage: extrai o Runtime+ccbl do
│   │                       linux_22.tar e monta a imagem final
│   └── entrypoint.sh     # activate / compile / run / build-run / shell
├── examples/
│   └── hello.cbl         # programa de exemplo
├── files/                # mídia de instalação original (não versionado)
└── license/              # .alc ativados localmente (não versionado)
```
