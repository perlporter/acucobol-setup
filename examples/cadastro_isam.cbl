       IDENTIFICATION DIVISION.
       PROGRAM-ID. CADASTRO-ISAM.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OPTIONAL ARQ-CADASTRO ASSIGN TO "cadastro.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS REG-NOME
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-CADASTRO.
       01  REG-CADASTRO.
           05  REG-NOME        PIC X(30).
           05  REG-TELEFONE    PIC X(15).

       WORKING-STORAGE SECTION.
       01  WS-NOME             PIC X(30).
       01  WS-TELEFONE         PIC X(15).
       01  WS-OPCAO            PIC X(1).
       01  WS-PAUSA            PIC X(1).
       01  WS-FILE-STATUS      PIC X(2).

       SCREEN SECTION.
       01  TELA-MENU.
           05  BLANK SCREEN.
           05  LINE 2  COL 10 VALUE "==============================".
           05  LINE 3  COL 10 VALUE "  CADASTRO DE CONTATOS (ISAM)".
           05  LINE 4  COL 10 VALUE "==============================".
           05  LINE 6  COL 10 VALUE "1 - Cadastrar novo contato".
           05  LINE 7  COL 10 VALUE "2 - Consultar contato por nome".
           05  LINE 8  COL 10 VALUE "3 - Sair".
           05  LINE 10 COL 10 VALUE "==============================".
           05  LINE 11 COL 10 VALUE "Opcao: ".

       01  TELA-CADASTRO.
           05  BLANK SCREEN.
           05  LINE 2  COL 10 VALUE "==============================".
           05  LINE 3  COL 10 VALUE "        NOVO CONTATO".
           05  LINE 4  COL 10 VALUE "==============================".
           05  LINE 6  COL 10 VALUE "Nome ....: ".
           05  LINE 7  COL 10 VALUE "Telefone : ".

       01  TELA-CONSULTA.
           05  BLANK SCREEN.
           05  LINE 2  COL 10 VALUE "==============================".
           05  LINE 3  COL 10 VALUE "      CONSULTAR CONTATO".
           05  LINE 4  COL 10 VALUE "==============================".
           05  LINE 6  COL 10 VALUE "Nome a buscar: ".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN I-O ARQ-CADASTRO.

           MOVE SPACES TO WS-OPCAO
           PERFORM UNTIL WS-OPCAO = "3"
               DISPLAY TELA-MENU
               ACCEPT WS-OPCAO LINE 11 COLUMN 18
               EVALUATE WS-OPCAO
                   WHEN "1"
                       PERFORM CADASTRAR
                   WHEN "2"
                       PERFORM CONSULTAR
                   WHEN "3"
                       CONTINUE
                   WHEN OTHER
                       CONTINUE
               END-EVALUATE
           END-PERFORM.

           CLOSE ARQ-CADASTRO.
           DISPLAY " ".
           DISPLAY "Ate mais!".
           STOP RUN.

       CADASTRAR.
           MOVE SPACES TO WS-NOME
           MOVE SPACES TO WS-TELEFONE
           DISPLAY TELA-CADASTRO
           ACCEPT WS-NOME LINE 6 COLUMN 21
           ACCEPT WS-TELEFONE LINE 7 COLUMN 21

           MOVE WS-NOME     TO REG-NOME
           MOVE WS-TELEFONE TO REG-TELEFONE

           WRITE REG-CADASTRO
               INVALID KEY
                   DISPLAY "Nome ja cadastrado!" LINE 9 COLUMN 10.
           IF WS-FILE-STATUS = "00"
               DISPLAY "Contato gravado." LINE 9 COLUMN 10
           END-IF.

           DISPLAY "Pressione ENTER para continuar" LINE 11 COLUMN 10.
           ACCEPT WS-PAUSA LINE 11 COLUMN 42.

       CONSULTAR.
           MOVE SPACES TO WS-NOME
           DISPLAY TELA-CONSULTA
           ACCEPT WS-NOME LINE 6 COLUMN 26

           MOVE WS-NOME TO REG-NOME
           READ ARQ-CADASTRO
               INVALID KEY
                   DISPLAY "Contato nao encontrado." LINE 8 COLUMN 10.
           IF WS-FILE-STATUS = "00"
               DISPLAY "Telefone: " REG-TELEFONE LINE 8 COLUMN 10
           END-IF.

           DISPLAY "Pressione ENTER para continuar" LINE 11 COLUMN 10.
           ACCEPT WS-PAUSA LINE 11 COLUMN 42.
