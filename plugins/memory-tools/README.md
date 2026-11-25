# memory-tools

セッションが終わるたびに会話を読み返し、残すべき訂正・好み・決定を auto memory に反映して整理する Claude Code プラグイン。「前に言った」を減らすためのもので、入れておけば意識せずに動く。規則は Skill `yumemi`（夢見）にある。

## 背景

Anthropic の記事「[Components of agent memory](https://www.anthropic.com/research/components-of-agent-memory)」で紹介されている dreaming の考え方を、Claude Code のトランスクリプトと auto memory で小さく再現したもの。Cookbook の「[Dreaming with a dynamic workflow](https://platform.claude.com/cookbook/managed-agents-cma-dreaming-with-a-dynamic-workflow)」も参考にしている。Anthropic 公式のプラグインではない。

- Cookbook と同じ: 終わった会話を裏で読む、会話はデータとして扱い指示に従わない、ツールを絞る、重複・矛盾・索引を整理する
- 違う: セッションが終わるたびに1件ずつ処理する。残すのはユーザー自身の発言だけで、作業で分かった事実の保存や、既存の記憶の検証はしない。許可や、その場限りの指示は残さない

## 仕組み

| 部品 | 役割 |
| --- | --- |
| `skills/yumemi/SKILL.md` | 何を残し、何を残さず、どう整理するかの規則。変えたいときはここを直す |
| `scripts/remember.sh` | `SessionEnd` hook。会話から発言を取り出し、裏の Claude（Sonnet）に規則と一緒に渡す |
| `scripts/check-deps.sh` | 必要なコマンドの確認 |

- 残すのは1行の要約と、根拠になったユーザーの発言の引用だけ（広い解釈を避けるため）
- 許可や確認の省略、その場限りの指示は残さない。迷うものも残さない（許可は設定で与える）
- 対象は対話セッションだけ（`claude -p` では動かない）
- 読むのはユーザーと Claude の発言の末尾 約60KB
- 裏の Claude に許すのはファイルの検索と読み書きだけで、コマンドは実行しない
- 今すぐ反映・整理したいときは `/memory-tools:yumemi` を打つ。Claude が自分の判断で起動することはない

## 必要なもの

macOS か Linux で、`jq` と `perl` が使えること（`perl` は macOS に標準で入っている）。足りないときは、セッション終了時と `/memory-tools:yumemi` の実行時に、無いものと入れ方を表示する。

## 注意

- セッションが終わるたびに、会話が自動で Claude に渡される
- 記憶は確認なしで書き換わる。気に入らないものは `/memory` から直す
- 古いセッションを再開して終えると、その中の古い発言で記憶が書き換わることがある
- 強制終了したセッションは対象にならない
- 裏の処理は10分で打ち切る（その回の記憶は残らないか、途中までになる）

## 控え

裏の Claude が書き換える前に、全プロジェクトの記憶を `~/.claude/plugins/data/memory-tools-ryutaroM-tools/backup/<日時>/<プロジェクト>/` に写す。前回と同じなら取らず、直近20回分を残す。Claude Code が読み込むのは元の場所だけなので、控えが会話に入ることはない。

- 戻すときは、必要なプロジェクトのフォルダの中身を `~/.claude/projects/<プロジェクト>/memory/` に書き戻す
- 記憶を消しても、控えに最大20回分残る。消したいときは `backup/` ごと削除する
- アンインストールすると控えも消える（残すなら `claude plugin uninstall --keep-data`）

## インストール

```bash
claude plugin marketplace add ryutaroM/my-claude-tools
claude plugin install memory-tools@ryutaroM-tools
```
