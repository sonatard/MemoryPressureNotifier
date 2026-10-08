# MemoryPressureNotifier

[English](README.md) | 日本語

macOS のメモリプレッシャーを監視し、警告になったら通知する常駐アプリです。

- 5 秒ごとに `kern.memorystatus_vm_pressure_level` を読み、正常（1）から警告（2）以上に上がったら通知します。危険（4）へ直接上がった場合も通知します。
- 通知をクリックするとアクティビティモニタを開きます。
- Dock にもメニューバーにも出ません。
- 初回起動時にログイン項目へ登録し、以降はログイン時に自動で起動します。

## 必要なもの

- macOS 13 以降
- Swift コンパイラ（Xcode または Command Line Tools）

## インストール

```sh
make install
```

`build/MemoryPressureNotifier.app` をビルドし、`~/Applications` にコピーして起動します。

初回起動時に、MemoryPressureNotifier に通知を許可するかを聞かれるので、**許可** を押してください。見逃したり閉じたりした場合は、**システム設定 > 通知** で MemoryPressureNotifier の通知をオンにしてください。

## アンインストール

```sh
make uninstall
```

ログイン項目から外し、アプリを止めて `~/Applications` から削除します。

## ログの確認

通知やログイン項目への登録に失敗したときは、ログにエラーが出ます。

```sh
log stream --predicate 'subsystem == "com.github.sonatard.MemoryPressureNotifier"'
```

## Make のターゲット

| ターゲット | 内容 |
| --- | --- |
| `build` | `build/MemoryPressureNotifier.app` を作り、Apple Development 証明書で署名する（なければ ad-hoc 署名） |
| `install` | ビルドして `~/Applications` に置き、起動する |
| `uninstall` | ログイン項目から外し、止めて、削除する |
| `test-notification` | インストール済みのアプリを起動し直し、テスト用の通知を出す |
| `clean` | `build/` を削除する |

## ライセンス

[MIT](LICENSE)
