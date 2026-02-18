---
name: commit
description: Format code and run compile checks before committing
user-invocable: true
---

1. Run `mix format` to format all Elixir code
2. Run `mix compile --warnings-as-errors` to check for warnings
3. Then proceed with the git commit
