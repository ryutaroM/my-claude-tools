# memory-tools

セッションが終わるたびに会話を読み返し、残すべき訂正・好み・決定を auto memory に反映する Claude Code プラグイン。「前に言った」を減らすためのもので、入れておけば意識せずに動く。Anthropic 公式のプラグインではない。

## 仕組み

`SessionEnd` hook が裏で別の Claude（Sonnet）を起動し、会話を渡して auto memory を更新する。hook 1つとスクリプト1本だけで、コマンドや通知は無い。

- 残すのは1行の要約と、根拠になったユーザーの発言の引用だけ（広い解釈を避けるため）
- 対象は対話セッションだけ（`claude -p` では動かない）
- 読むのはユーザーと Claude の発言の末尾 約60KB
- 裏の Claude に許すのはファイルの読み書きだけで、コマンドは実行しない

## 注意

- セッションが終わるたびに、会話が自動で Claude に渡される
- 記憶は確認なしで書き換わる。気に入らないものは `/memory` から直す
- 古いセッションを再開して終えると、その中の古い発言で記憶が書き換わることがある
- 強制終了したセッションは対象にならない
- `jq` が必要

## インストール

```bash
claude plugin marketplace add ryutaroM/my-claude-tools
claude plugin install memory-tools@ryutaroM-tools
```
