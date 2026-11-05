# cobol-chain

GnuCOBOL で書いた、ハッシュでつながる台帳です。画面用のコマンドと、他のプログラムから呼ぶ部品に分かれています。

署名、残高、ノード間の合意は入っていません。1つのファイルに対する追記と検証です。

## 必要なもの

- GnuCOBOL 3.1 以降（`cobc`）
- C から呼ぶときは `libcob` のヘッダ

Ubuntu では `sudo apt install gnucobol` です。

## ビルド

```bash
make
make test
```

`make test` は SHA-256 の既知ベクタ、COBOL からの呼び出し、C からの呼び出しを実行します。

## コマンド

台帳ファイルはカレントディレクトリの `chain.dat` です。

```bash
./chain init
./chain add "太郎から花子へ 10"
./chain list
./chain get 1
./chain verify
```

既にある台帳を置き換えるときは `./chain init --replace` です。取引データは 1 から 128 バイトです。初期の難易度は 2 で、ハッシュの先頭 2 桁が `0` になるまでナンスを探します。

## COBOL から使う

`copy/cbconst.cpy` と `copy/cbrequest.cpy` をコピーし、`CBCHAIN` を呼びます。部品は画面に出しません。結果は `CB-STATUS` です。`0` が成功です。

```cobol
COPY cbconst.
COPY cbrequest.

MOVE CB-FN-APPEND TO CB-FUNC
MOVE 9 TO CB-PATH-LEN
MOVE "chain.dat" TO CB-PATH
MOVE "Alice -> Bob 10" TO CB-DATA
MOVE 15 TO CB-DATA-LEN
CALL "CBCHAIN" USING CB-REQUEST
```

機能番号は次のとおりです。

| 番号 | 定数 | 動作 |
| --- | --- | --- |
| 1 | `CB-FN-INIT` | 台帳を作る |
| 2 | `CB-FN-APPEND` | ブロックを追加する |
| 3 | `CB-FN-GET` | 番号で 1 件読む |
| 4 | `CB-FN-VERIFY` | 連結とハッシュを検証する |
| 5 | `CB-FN-COUNT` | 件数と難易度を返す |
| 6 | `CB-FN-LAST` | 末尾を読む |

`CB-OPTIONS` が `CB-OPT-REPLACE`（1）のときだけ、初期化は既存ファイルを置き換えます。難易度 `0` は初期値 2 です。時刻が空白または `00000000000000` のときは現在時刻を使います。形式は `YYYYMMDDHHMMSS` です。

静的に結ぶ例です。

```bash
cobc -x -free -O2 -I copy -o app app.cbl cbchain.cbl sha256.cbl
```

## C から使う

`cbchain.h` の `cb_request` は、COBOL の要求ブロックと同じ 736 バイトです。数値は文字の数字で詰めます。

```c
cb_request request;

cb_request_clear(&request);
cb_set_path(&request, "chain.dat");
cb_put_u(request.func, 2, CB_FN_VERIFY);
cbchain_call(&request);
```

共有モジュールを作ってから、同じディレクトリで実行します。

```bash
make CBCHAIN.so embed
COB_LIBRARY_PATH=. ./embed
```

## 台帳の形式

先頭行は `CBCH|01|DD|` です。`01` は形式の版、`DD` は難易度（01 から 08）です。

続く各行は 297 バイトです。

| 位置 | 内容 |
| --- | --- |
| 1-8 | ブロック番号 |
| 10-23 | 時刻 |
| 25-88 | 前ハッシュ |
| 90-92 | データのバイト数 |
| 94-221 | データ |
| 223-232 | ナンス |
| 234-297 | SHA-256 |

ハッシュの入力は、番号、時刻、前ハッシュ、データ長、データの実バイト、ナンスです。追記の前に、既存のブロックをすべて検証します。

## 構成

| ファイル | 役割 |
| --- | --- |
| `cbchain.cbl` | 台帳部品 |
| `sha256.cbl` | SHA-256 |
| `chain.cbl` | コマンド |
| `cbchain.h` `cbchain_api.c` | C の呼び出し口 |
| `cbtest.cbl` `embed.c` `shatest.cbl` | テスト |
