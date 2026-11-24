# my-claude-tools

ryutaroM の Claude Code プラグイン集（marketplace 名: `ryutaroM-tools`）。

## 使い方

```bash
claude plugin marketplace add ryutaroM/my-claude-tools
claude plugin install <プラグイン名>@ryutaroM-tools
```

## プラグイン

| 名前                     | 内容                                                                |
| ------------------------ | ------------------------------------------------------------------- |
| [memory-tools](plugins/memory-tools) | Skill `yumemi`: 過去セッションを読み返して auto memory を検証・整理する（dreaming） |

## プラグインを追加するとき

1. `plugins/<名前>/` に plugin を置く（`.claude-plugin/plugin.json` の `name` とディレクトリ名を揃える）
2. `.claude-plugin/marketplace.json` の `plugins` に `{"name": "<名前>", "source": "./plugins/<名前>"}` を足す
3. `claude plugin validate .` を通す
