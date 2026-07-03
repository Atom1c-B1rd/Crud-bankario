       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKING.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 WS-DB-PATH.
          05 WS-DB-PATH-TEXT   PIC X(50) VALUE "db/bank.db".
       01 WS-DB-PATH-LEN       BINARY-LONG VALUE 50.

       01 WS-ACC-ID            PIC X(10).
       01 WS-ACC-ID-LEN        BINARY-LONG VALUE 10.

       01 WS-NAME               PIC X(30).
       01 WS-NAME-LEN            BINARY-LONG VALUE 30.

       01 WS-BALANCE            COMP-2 VALUE 0.
       01 WS-AMOUNT              COMP-2 VALUE 0.
       01 WS-STATUS               BINARY-LONG VALUE 0.

       01 WS-OPTION                 PIC 9 VALUE 0.
       01 WS-SEGUIR                  PIC X VALUE 'S'.

       01 WS-BALANCE-DISPLAY          PIC ---,---,--9.99.
       01 WS-AMOUNT-DISPLAY            PIC ---,---,--9.99.

       PROCEDURE DIVISION.

       MAIN-LOGIC.
           CALL "db_open" USING BY REFERENCE WS-DB-PATH
                                 BY REFERENCE WS-DB-PATH-LEN
                                 BY REFERENCE WS-STATUS
           END-CALL

           IF WS-STATUS NOT = 0
              DISPLAY "ERROR: no se pudo abrir la base de datos."
              GOBACK
           END-IF

           PERFORM UNTIL WS-SEGUIR = 'N'
              PERFORM MOSTRAR-MENU
              PERFORM PROCESAR-OPCION
           END-PERFORM

           CALL "db_close" END-CALL
           DISPLAY "Hasta luego."
           GOBACK.

       MOSTRAR-MENU.
           DISPLAY " "
           DISPLAY "==================SISTEMA BANCARIO================="
           DISPLAY "1. Crear cuenta"
           DISPLAY "2. Depositar"
           DISPLAY "3. Retirar"
           DISPLAY "4. Consultar saldo"
           DISPLAY "5. Listar cuentas"
           DISPLAY "6. Salir"
           DISPLAY "==================================================="
           DISPLAY "Opcion: " WITH NO ADVANCING
           ACCEPT WS-OPTION.

       PROCESAR-OPCION.
           EVALUATE WS-OPTION
              WHEN 1 PERFORM CREAR-CUENTA
              WHEN 2 PERFORM DEPOSITAR
              WHEN 3 PERFORM RETIRAR
              WHEN 4 PERFORM CONSULTAR-SALDO
              WHEN 5 PERFORM LISTAR-CUENTAS
              WHEN 6 MOVE 'N' TO WS-SEGUIR
              WHEN OTHER DISPLAY "Opcion invalida."
           END-EVALUATE.

       CREAR-CUENTA.
           DISPLAY "Numero de cuenta (max 10 car.): " WITH NO ADVANCING
           ACCEPT WS-ACC-ID
           DISPLAY "Nombre del titular: " WITH NO ADVANCING
           ACCEPT WS-NAME
           DISPLAY "Saldo inicial: " WITH NO ADVANCING
           ACCEPT WS-BALANCE

           CALL "db_create_account" USING BY REFERENCE WS-ACC-ID
                                           BY REFERENCE WS-ACC-ID-LEN
                                           BY REFERENCE WS-NAME
                                           BY REFERENCE WS-NAME-LEN
                                           BY REFERENCE WS-BALANCE
                                           BY REFERENCE WS-STATUS
           END-CALL

           EVALUATE WS-STATUS
              WHEN 0 DISPLAY "Cuenta creada correctamente."
              WHEN 3 DISPLAY "ERROR: esa cuenta ya existe."
              WHEN OTHER DISPLAY "ERROR al crear la cuenta."
           END-EVALUATE.

       DEPOSITAR.
           DISPLAY "Numero de cuenta: " WITH NO ADVANCING
           ACCEPT WS-ACC-ID
           DISPLAY "Monto a depositar: " WITH NO ADVANCING
           ACCEPT WS-AMOUNT

           CALL "db_update_balance" USING BY REFERENCE WS-ACC-ID
                                           BY REFERENCE WS-ACC-ID-LEN
                                           BY REFERENCE WS-AMOUNT
                                           BY REFERENCE WS-STATUS
           END-CALL

           EVALUATE WS-STATUS
              WHEN 0 DISPLAY "Deposito realizado."
              WHEN 1 DISPLAY "ERROR: cuenta no encontrada."
              WHEN OTHER DISPLAY "ERROR al depositar."
           END-EVALUATE.

       RETIRAR.
           DISPLAY "Numero de cuenta: " WITH NO ADVANCING
           ACCEPT WS-ACC-ID
           DISPLAY "Monto a retirar: " WITH NO ADVANCING
           ACCEPT WS-AMOUNT

           COMPUTE WS-AMOUNT = WS-AMOUNT * -1

           CALL "db_update_balance" USING BY REFERENCE WS-ACC-ID
                                           BY REFERENCE WS-ACC-ID-LEN
                                           BY REFERENCE WS-AMOUNT
                                           BY REFERENCE WS-STATUS
           END-CALL

           EVALUATE WS-STATUS
              WHEN 0 DISPLAY "Retiro realizado."
              WHEN 1 DISPLAY "ERROR: cuenta no encontrada."
              WHEN 2 DISPLAY "ERROR: fondos insuficientes."
              WHEN OTHER DISPLAY "ERROR al retirar."
           END-EVALUATE.

       CONSULTAR-SALDO.
           DISPLAY "Numero de cuenta: " WITH NO ADVANCING
           ACCEPT WS-ACC-ID

           CALL "db_get_balance" USING BY REFERENCE WS-ACC-ID
                                        BY REFERENCE WS-ACC-ID-LEN
                                        BY REFERENCE WS-BALANCE
                                        BY REFERENCE WS-STATUS
           END-CALL

           IF WS-STATUS = 0
              MOVE WS-BALANCE TO WS-BALANCE-DISPLAY
              DISPLAY "Saldo actual: " WS-BALANCE-DISPLAY
           ELSE
              DISPLAY "ERROR: cuenta no encontrada."
           END-IF.

       LISTAR-CUENTAS.
           CALL "db_list_accounts" END-CALL.