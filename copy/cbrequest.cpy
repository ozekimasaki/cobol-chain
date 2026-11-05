*> 呼び出しは1ブロックだけ渡す。配置は表示形式で詰め、736 バイト。
*>   0 機能  2 オプション  4 状態  8 ファイル状態  10 詳細
*>  18 パス長  22 パス  278 データ長  282 データ
*> 410 難易度  412 ナンス上限  422 時刻入力
*> 436 件数  444 ブロック番号  452 時刻  466 前ハッシュ
*> 530 データ長  534 データ  662 ナンス  672 ハッシュ
01 CB-REQUEST PIC X(736).
01 CB-VIEW REDEFINES CB-REQUEST.
   05 CB-FUNC         PIC 9(2).
   05 CB-OPTIONS      PIC 9(2).
   05 CB-STATUS       PIC 9(4).
   05 CB-FS           PIC XX.
   05 CB-DETAIL       PIC 9(8).
   05 CB-PATH-LEN     PIC 9(4).
   05 CB-PATH         PIC X(256).
   05 CB-DATA-LEN     PIC 9(4).
   05 CB-DATA         PIC X(128).
   05 CB-DIFFICULTY   PIC 9(2).
   05 CB-MAX-NONCE    PIC 9(10).
   05 CB-TIMESTAMP    PIC X(14).
   05 CB-COUNT        PIC 9(8).
   05 CB-INDEX        PIC 9(8).
   05 CB-TIME         PIC X(14).
   05 CB-PREV         PIC X(64).
   05 CB-BLEN         PIC 9(4).
   05 CB-BDATA        PIC X(128).
   05 CB-NONCE        PIC 9(10).
   05 CB-HASH         PIC X(64).
