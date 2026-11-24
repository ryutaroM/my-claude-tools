# memory-tools

Claude Code の過去セッションのトランスクリプトを読み返し、auto memory を検証・整理する dreaming プラグイン。中心となる Skill は `yumemi`（夢見）。

## 背景

Anthropic の記事「[Components of agent memory](https://www.anthropic.com/research/components-of-agent-memory)」で紹介されている dreaming の考え方を、Claude Code のトランスクリプトと auto memory で再現したもの。Anthropic 公式のプラグインではない。

- メモリを原本のトランスクリプトと突き合わせて誤りを直す
- 常に読み込む層（`MEMORY.md`）は小さく保ち、詳細はリンク先のトピックファイルに置く

## 仕組み

| 部品 | タイミング | やること |
| --- | --- | --- |
| `SessionStart` hook | 新規セッション開始時 | 未整理のセッションが閾値（既定5件）以上なら、その旨を Claude に伝える |
| `/memory-tools:yumemi` | 手動、または Claude の判断 | 未整理のセッションを古い順に最大20件読み、メモリを修正・統合する |

未整理のセッションとは、前回の整理より後に更新されたトランスクリプトのこと。どこまで整理したかは `memory/.yumemi-last` の更新時刻で覚える。実行中のセッションと、`/yumemi` で始まったセッションは数えない。初回は残っているトランスクリプトすべてが対象になる。

hook は通知だけ。Skill は自動起動が有効なので、`/memory-tools:yumemi` を打ったときに加えて、「メモリを見直して」と頼んだときや、hook から未整理がたまったと知らされたときにも Claude が自分の判断で実行する。手動に限りたい場合は SKILL.md の frontmatter に `disable-model-invocation: true` を足す。

## データの扱い

hook は手元のトランスクリプトの更新時刻とスキルの起動履歴を調べるだけで、外部には送信しない。`/memory-tools:yumemi` を実行すると、トランスクリプトの内容は通常の会話と同じように Claude に渡される。

## インストール

```bash
claude plugin marketplace add ryutaroM/my-claude-tools
claude plugin install memory-tools@ryutaroM-tools
```

## 設定

- `threshold`: 通知する未整理セッション数（`/config` から変更可）
- トランスクリプトは既定で30日で消えるので、遡りたい場合は `settings.json` の `cleanupPeriodDays` を伸ばす
