# debian-cobol — AcuCOBOL-GT 5.2 em Docker

Imagem Docker com **AcuCOBOL-GT 5.2** (Runtime + AcuShare + compilador `ccbl`)
rodando sobre **Debian 3.1 "Sarge" (i386)**, capaz de compilar e executar
programas `.cbl` dentro do container.

Código-fonte deste repositório: https://github.com/perlporter/acucobol-setup
(público — sem segredos versionados, ver seção de Licenciamento abaixo).

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

## Exemplos incluídos (`examples/`)

| Arquivo | O que mostra |
|---|---|
| `hello.cbl` | Programa mínimo, só `DISPLAY` |
| `soma.cbl` | `WORKING-STORAGE`, `ADD`, `PERFORM VARYING` |
| `cadastro.cbl` | Arquivo **sequencial** (`LINE SEQUENTIAL`) com telinha (`SCREEN SECTION`): cadastra nome+telefone em `cadastro.dat`, acrescentando a cada execução |
| `cadastro_isam.cbl` | Mesmo cadastro, mas em arquivo **indexado** (Vision/ISAM, `ORGANIZATION IS INDEXED`), com menu: cadastrar, consultar por nome, sair. Gera `cadastro.dat` (dados) + `cadastro.vix` (índice) |

Detalhes técnicos que valeram a pena guardar ao escrever esses exemplos com
esse compilador de 2003:

- **Linhas de código-fonte não podem passar de 72 colunas** (formato fixo
  do COBOL). Passar disso faz o compilador "perder" a aspa de fechamento
  de string literal e o erro reportado aponta pro fim do arquivo, não pra
  linha real do problema — se aparecer `Missing closing quote` apontando
  pro finalzinho do programa, o culpado quase sempre é uma linha comprida
  demais mais acima.
- **`SELECT OPTIONAL` é obrigatório** para abrir (`OPEN EXTEND`/`OPEN I-O`)
  um arquivo que ainda não existe sem cair na tela de erro fatal do
  runtime — mesmo declarando `FILE STATUS`. Sem `OPTIONAL`, arquivo
  ausente é sempre erro fatal.
- **Não aceita `NOT INVALID KEY`** (só `INVALID KEY`) nem os terminadores
  de escopo `END-WRITE`/`END-READ` (COBOL-85) — usa-se o estilo COBOL-74,
  terminando a cláusula com ponto e checando sucesso via `FILE STATUS`.
- **`ACCEPT` de um grupo de tela inteiro** (`ACCEPT TELA-X`) deixa o Enter
  fechar o formulário inteiro em vez de avançar de campo em campo — usar
  `ACCEPT campo LINE n COLUMN n` individual por campo é mais previsível.
- **Telas com `ACCEPT`/`SCREEN SECTION` exigem terminal interativo real**
  (`-it`, digitado à mão). Não dá para simular via `stdin` em pipe — o
  programa entra num loop redesenhando a tela sem nunca consumir a
  entrada.

## `vutil` — utilitário de arquivos Vision (indexados)

Não precisa de licença nem do `acushare` — funciona direto:

```bash
docker run --rm -v "$PWD/examples":/work debian-cobol:5.2 vutil -info cadastro.dat
docker run --rm -v "$PWD/examples":/work debian-cobol:5.2 vutil -check cadastro.dat
docker run --rm -v "$PWD/examples":/work debian-cobol:5.2 vutil -rebuild cadastro.dat
```

`-info` mostra número de registros, tamanho de cada arquivo físico
(`.dat` e `.vix`) e número de chaves. Rode `vutil` sem argumentos pra ver
todas as opções (`-check`, `-rebuild`, `-size`, `-tree`, `-load`/`-unload`
para exportar/importar registros, etc.).

## Rodando no Windows (Docker Desktop)

Testado de verdade num PC Windows/x86_64 — roda **nativo, sem QEMU**
(diferente do Mac Apple Silicon). Duas pegadinhas específicas do Windows:

1. **Quebra de linha (CRLF).** O Git no Windows costuma converter LF em
   CRLF ao clonar (`core.autocrlf`), e esse compilador não tolera `\r` no
   meio da linha (erro tipo `PROCEDURE expected, ?? found` logo nas
   primeiras linhas). O `.gitattributes` deste repositório já força
   `eol=lf` nos `.cbl`/`.sh`/Dockerfile — se ainda assim der esse erro,
   clone o repositório de novo do zero (o `.gitattributes` só vale para
   checkouts feitos depois dele existir).

2. **Arquivo indexado (Vision/ISAM) não funciona em pasta comum do
   Windows.** Programas com `ORGANIZATION IS INDEXED` (como o
   `cadastro_isam.cbl`) usam travamento de arquivo (file locking) mesmo
   rodando sozinho, e o compartilhamento de pasta do Docker Desktop pro
   Windows (bind mount tipo `-v "${PWD}/examples:/work"`) não sustenta
   esse locking direito — dá erro `File error 93` (recurso indisponível).
   Solução: rodar de dentro do **WSL2** (Debian ou Ubuntu), clonando o
   repositório na pasta home do próprio Linux (`~/acucobol-setup`, **não**
   em `/mnt/c/...`). Arquivos **sequenciais** (`LINE SEQUENTIAL`, como
   `cadastro.cbl`) funcionam numa boa em pasta comum do Windows — só o
   indexado que precisa do WSL2.

   Um problema parecido (`stat(): Value too large for defined data type`)
   também aparece ao **ativar a licença** (`activate`) apontando pra uma
   pasta comum do Windows — mesma causa raiz (bind mount). Resolvido
   usando um **volume nomeado do Docker** em vez de pasta do host:

   ```powershell
   docker volume create acucobol-license
   docker run --rm -it -v acucobol-license:/opt/acucobol/license debian-cobol:5.2 activate
   ```

   E depois usar esse mesmo volume nomeado (em vez de `-v "$PWD/license":...`)
   em todos os comandos.

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
│   └── entrypoint.sh     # activate / compile / run / build-run / vutil / shell
├── examples/
│   ├── hello.cbl         # programa mínimo
│   ├── soma.cbl          # WORKING-STORAGE, ADD, PERFORM VARYING
│   ├── cadastro.cbl      # telinha + arquivo sequencial
│   └── cadastro_isam.cbl # telinha + arquivo indexado (Vision/ISAM)
├── files/                # mídia de instalação original (não versionado)
└── license/              # .alc ativados localmente (não versionado)
```
