>>SOURCE FORMAT FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. CHAIN.

*> CBCHAIN 部品を呼ぶだけのコマンド。台帳の規則は部品側にある。
ENVIRONMENT DIVISION.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY cbconst.
COPY cbrequest.
01 CMDLINE PIC X(2048).
01 VERB PIC X(16).
01 ARG-BUF PIC X(512).
01 ARG-LEN PIC 9(4) VALUE 0.
01 ARG-AT PIC 9(4).
01 SP PIC 9(4).
01 SCAN-I PIC 9(4).
01 CLI-RC PIC 99 VALUE 0.
01 SAVED-COUNT PIC 9(8).
01 SHOW-INDEX PIC 9(8).
01 COUNT-TEXT PIC Z(7)9.
01 LEDGER-PATH PIC X(9) VALUE "chain.dat".

PROCEDURE DIVISION.
MAIN-LOGIC.
    PERFORM RESET-REQUEST
    MOVE LEDGER-PATH TO CB-PATH
    MOVE 9 TO CB-PATH-LEN
    PERFORM PARSE-COMMAND
    EVALUATE VERB
        WHEN "help"
            PERFORM DO-USAGE
        WHEN "init"
            PERFORM DO-INIT
        WHEN "add"
            PERFORM DO-ADD
        WHEN "list"
            PERFORM DO-LIST
        WHEN "get"
            PERFORM DO-GET
        WHEN "verify"
            PERFORM DO-VERIFY
        WHEN OTHER
            PERFORM DO-USAGE
            MOVE 1 TO CLI-RC
    END-EVALUATE
    IF CLI-RC = 0
        MOVE CB-STATUS TO CLI-RC
    END-IF
    MOVE CLI-RC TO RETURN-CODE
    STOP RUN
    .

RESET-REQUEST.
    MOVE 0 TO CB-FUNC
    MOVE 0 TO CB-OPTIONS
    MOVE 0 TO CB-STATUS
    MOVE 0 TO CB-DETAIL
    MOVE 0 TO CB-PATH-LEN
    MOVE 0 TO CB-DATA-LEN
    MOVE 0 TO CB-DIFFICULTY
    MOVE 0 TO CB-MAX-NONCE
    MOVE 0 TO CB-COUNT
    MOVE 0 TO CB-INDEX
    MOVE 0 TO CB-BLEN
    MOVE 0 TO CB-NONCE
    MOVE "00" TO CB-FS
    MOVE SPACES TO CB-PATH
    MOVE SPACES TO CB-DATA
    MOVE SPACES TO CB-TIMESTAMP
    MOVE SPACES TO CB-TIME
    MOVE SPACES TO CB-PREV
    MOVE SPACES TO CB-BDATA
    MOVE SPACES TO CB-HASH
    .

PARSE-COMMAND.
    MOVE "help" TO VERB
    ACCEPT CMDLINE FROM COMMAND-LINE
    MOVE FUNCTION TRIM(CMDLINE) TO CMDLINE
    IF CMDLINE = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO SP
    INSPECT CMDLINE TALLYING SP FOR CHARACTERS BEFORE INITIAL " "
    IF SP = 0 OR SP > 16
        MOVE "????" TO VERB
        EXIT PARAGRAPH
    END-IF
    MOVE FUNCTION LOWER-CASE(CMDLINE(1:SP)) TO VERB
    MOVE SPACES TO ARG-BUF
    MOVE 0 TO ARG-LEN
    IF SP < 2048
        COMPUTE ARG-AT = SP + 1
        PERFORM UNTIL ARG-AT > 2048
            IF CMDLINE(ARG-AT:1) NOT = SPACE
                EXIT PERFORM
            END-IF
            ADD 1 TO ARG-AT
        END-PERFORM
    END-IF
    IF ARG-AT <= 2048
        IF CMDLINE(ARG-AT:1) NOT = SPACE
            MOVE CMDLINE(ARG-AT:) TO ARG-BUF
            PERFORM MEASURE-ARG
        END-IF
    END-IF
    .

MEASURE-ARG.
    MOVE 0 TO ARG-LEN
    PERFORM VARYING SCAN-I FROM FUNCTION LENGTH(ARG-BUF) BY -1
        UNTIL SCAN-I < 1
        IF ARG-BUF(SCAN-I:1) NOT = SPACE
            MOVE SCAN-I TO ARG-LEN
            EXIT PERFORM
        END-IF
    END-PERFORM
    .

DO-USAGE.
    DISPLAY "COBOL ブロックチェーン"
    DISPLAY "台帳の作成、追記、参照、検証は部品 CBCHAIN が行う。"
    DISPLAY "使い方:"
    DISPLAY "  chain init [--replace]   台帳 chain.dat を作る"
    DISPLAY "  chain add <取引>         ブロックを追加する"
    DISPLAY "  chain list               台帳を表示する"
    DISPLAY "  chain get <番号>         1件を表示する"
    DISPLAY "  chain verify             連結とハッシュを検証する"
    DISPLAY "取引は 1 から 128 バイト。初期の難易度は 2。"
    DISPLAY "既存の台帳は init --replace で置き換える。"
    .

DO-INIT.
    IF ARG-LEN = 0
        MOVE CB-OPT-NONE TO CB-OPTIONS
    ELSE
        IF ARG-LEN = 9
            AND FUNCTION LOWER-CASE(ARG-BUF(1:9)) = "--replace"
            MOVE CB-OPT-REPLACE TO CB-OPTIONS
        ELSE
            PERFORM DO-USAGE
            MOVE 1 TO CLI-RC
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE CB-FN-INIT TO CB-FUNC
    MOVE CB-DEFAULT-DIFF TO CB-DIFFICULTY
    MOVE SPACES TO CB-DATA
    MOVE "GENESIS / COBOL CHAIN" TO CB-DATA
    PERFORM VARYING SCAN-I FROM FUNCTION LENGTH(CB-DATA) BY -1
        UNTIL SCAN-I = 0
        IF CB-DATA(SCAN-I:1) NOT = SPACE
            MOVE SCAN-I TO CB-DATA-LEN
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE SPACES TO CB-TIMESTAMP
    DISPLAY "ジェネシスブロックを採掘します"
    CALL "CBCHAIN" USING CB-REQUEST
    IF CB-STATUS = CB-OK
        DISPLAY "ジェネシスブロックを書きました"
        PERFORM SHOW-BLOCK
    ELSE
        PERFORM SHOW-ERROR
    END-IF
    .

DO-ADD.
    MOVE CB-FN-APPEND TO CB-FUNC
    MOVE CB-OPT-NONE TO CB-OPTIONS
    MOVE 0 TO CB-DIFFICULTY
    MOVE SPACES TO CB-TIMESTAMP
    MOVE SPACES TO CB-DATA
    IF ARG-LEN > 0
        IF ARG-LEN > CB-DATA-MAX
            MOVE ARG-BUF(1:CB-DATA-MAX) TO CB-DATA
        ELSE
            MOVE ARG-BUF(1:ARG-LEN) TO CB-DATA
        END-IF
    END-IF
    MOVE ARG-LEN TO CB-DATA-LEN
    IF ARG-LEN > 0 AND ARG-LEN <= CB-DATA-MAX
        DISPLAY "ブロックを採掘します"
    END-IF
    CALL "CBCHAIN" USING CB-REQUEST
    IF CB-STATUS = CB-OK
        DISPLAY "ブロックを追加しました"
        PERFORM SHOW-BLOCK
    ELSE
        PERFORM SHOW-ERROR
    END-IF
    .

DO-LIST.
    MOVE CB-FN-COUNT TO CB-FUNC
    CALL "CBCHAIN" USING CB-REQUEST
    IF CB-STATUS NOT = CB-OK
        PERFORM SHOW-ERROR
        EXIT PARAGRAPH
    END-IF
    MOVE CB-COUNT TO SAVED-COUNT
    MOVE CB-COUNT TO COUNT-TEXT
    DISPLAY "難易度 " CB-DIFFICULTY
        " / " FUNCTION TRIM(COUNT-TEXT) " ブロック"
    PERFORM VARYING SHOW-INDEX FROM 0 BY 1
        UNTIL SHOW-INDEX >= SAVED-COUNT OR CB-STATUS NOT = CB-OK
        MOVE CB-FN-GET TO CB-FUNC
        MOVE SHOW-INDEX TO CB-INDEX
        CALL "CBCHAIN" USING CB-REQUEST
        IF CB-STATUS = CB-OK
            PERFORM SHOW-BLOCK
        ELSE
            PERFORM SHOW-ERROR
        END-IF
    END-PERFORM
    .

DO-GET.
    IF ARG-LEN = 0 OR ARG-LEN > 8
        DISPLAY "ブロック番号を指定してください"
        MOVE 1 TO CLI-RC
        EXIT PARAGRAPH
    END-IF
    IF ARG-BUF(1:ARG-LEN) IS NOT NUMERIC
        DISPLAY "ブロック番号を指定してください"
        MOVE 1 TO CLI-RC
        EXIT PARAGRAPH
    END-IF
    MOVE CB-FN-GET TO CB-FUNC
    MOVE ARG-BUF(1:ARG-LEN) TO CB-INDEX
    CALL "CBCHAIN" USING CB-REQUEST
    IF CB-STATUS = CB-OK
        PERFORM SHOW-BLOCK
    ELSE
        PERFORM SHOW-ERROR
    END-IF
    .

DO-VERIFY.
    MOVE CB-FN-VERIFY TO CB-FUNC
    CALL "CBCHAIN" USING CB-REQUEST
    IF CB-STATUS = CB-OK
        MOVE CB-COUNT TO COUNT-TEXT
        DISPLAY "検証しました: " FUNCTION TRIM(COUNT-TEXT)
            " ブロック。連結とハッシュは一致しています"
    ELSE
        PERFORM SHOW-ERROR
    END-IF
    .

SHOW-BLOCK.
    DISPLAY "---- ブロック " CB-INDEX " ----"
    DISPLAY "時刻     " CB-TIME(1:4) "-" CB-TIME(5:2) "-"
        CB-TIME(7:2) " " CB-TIME(9:2) ":" CB-TIME(11:2) ":"
        CB-TIME(13:2)
    IF CB-BLEN > 0
        DISPLAY "データ   " CB-BDATA(1:CB-BLEN)
    END-IF
    DISPLAY "前ハッシュ " CB-PREV
    DISPLAY "ナンス   " CB-NONCE
    DISPLAY "ハッシュ " CB-HASH
    .

SHOW-ERROR.
    MOVE CB-DETAIL TO COUNT-TEXT
    EVALUATE CB-STATUS
        WHEN CB-ERR-NOT-FOUND
            DISPLAY "台帳がありません。先に chain init を実行してください"
        WHEN CB-ERR-EXISTS
            DISPLAY "台帳が既にあります。置き換えるときは chain init --replace"
        WHEN CB-ERR-IO
            DISPLAY "入出力に失敗しました file status=" CB-FS
        WHEN CB-ERR-FORMAT
            DISPLAY "台帳の形式が違います"
        WHEN CB-ERR-ARGUMENT
            EVALUATE CB-DETAIL
                WHEN CB-WHY-DATA
                    DISPLAY "取引データは 1 から 128 バイトです"
                WHEN CB-WHY-TIMESTAMP
                    DISPLAY "時刻は YYYYMMDDHHMMSS で指定します"
                WHEN OTHER
                    DISPLAY "引数が不正です"
            END-EVALUATE
        WHEN CB-ERR-POW
            DISPLAY "採掘に失敗しました"
        WHEN CB-ERR-INDEX
            DISPLAY "検証失敗 ブロック " CB-DETAIL
                ": 番号が連続していません"
        WHEN CB-ERR-LINK
            DISPLAY "検証失敗 ブロック " CB-DETAIL
                ": 前ハッシュとつながっていません"
        WHEN CB-ERR-HASH
            DISPLAY "検証失敗 ブロック " CB-DETAIL
                ": 再計算したハッシュが記録と違います"
        WHEN CB-ERR-DIFFICULTY
            DISPLAY "検証失敗 ブロック " CB-DETAIL
                ": ハッシュが難易度を満たしていません"
        WHEN CB-ERR-EMPTY
            DISPLAY "台帳にブロックがありません"
        WHEN CB-ERR-RANGE
            DISPLAY "その番号のブロックはありません（件数 "
                FUNCTION TRIM(COUNT-TEXT) "）"
        WHEN OTHER
            DISPLAY "失敗しました status=" CB-STATUS
    END-EVALUATE
    .

END PROGRAM CHAIN.
