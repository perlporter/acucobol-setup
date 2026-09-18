       IDENTIFICATION DIVISION.
       PROGRAM-ID. SOMA.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-NUM1        PIC 9(4) VALUE 15.
       01  WS-NUM2        PIC 9(4) VALUE 27.
       01  WS-RESULTADO   PIC 9(5).
       01  WS-CONTADOR    PIC 9(2).
       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== Teste debian-cobol ===".
           ADD WS-NUM1 TO WS-NUM2 GIVING WS-RESULTADO.
           DISPLAY WS-NUM1 " + " WS-NUM2 " = " WS-RESULTADO.

           DISPLAY "Contando ate 5:".
           PERFORM VARYING WS-CONTADOR FROM 1 BY 1
                   UNTIL WS-CONTADOR > 5
               DISPLAY "  -> " WS-CONTADOR
           END-PERFORM.

           DISPLAY "=== Fim ===".
           STOP RUN.
