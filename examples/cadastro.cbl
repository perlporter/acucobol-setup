       IDENTIFICATION DIVISION.
       PROGRAM-ID. CADASTRO.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OPTIONAL ARQ-CADASTRO ASSIGN TO "cadastro.dat"
               ORGANIZATION IS LINE SEQUENTIAL
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
       01  WS-CONTINUA         PIC X(1) VALUE "S".
       01  WS-FILE-STATUS      PIC X(2).

       SCREEN SECTION.
       01  TELA-CADASTRO.
           05  BLANK SCREEN.
           05  LINE 2  COL 10 VALUE "==============================".
           05  LINE 3  COL 10 VALUE "   CADASTRO DE CONTATOS".
           05  LINE 4  COL 10 VALUE "==============================".
           05  LINE 6  COL 10 VALUE "Nome ....: ".
           05  LINE 7  COL 10 VALUE "Telefone : ".
           05  LINE 9  COL 10 VALUE "==============================".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN EXTEND ARQ-CADASTRO.

           PERFORM UNTIL WS-CONTINUA = "N" OR WS-CONTINUA = "n"
               MOVE SPACES TO WS-NOME
               MOVE SPACES TO WS-TELEFONE
               DISPLAY TELA-CADASTRO
               ACCEPT WS-NOME LINE 6 COLUMN 21
               ACCEPT WS-TELEFONE LINE 7 COLUMN 21

               MOVE WS-NOME     TO REG-NOME
               MOVE WS-TELEFONE TO REG-TELEFONE
               WRITE REG-CADASTRO

               DISPLAY "Cadastrar outro? (S/N): " LINE 12 COLUMN 10
               ACCEPT WS-CONTINUA LINE 12 COLUMN 35
           END-PERFORM.

           CLOSE ARQ-CADASTRO.
           DISPLAY " ".
           DISPLAY "Cadastro encerrado.".
           DISPLAY "Registros salvos em cadastro.dat".
           STOP RUN.
