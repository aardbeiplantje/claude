
build:
```
docker buildx build --load --tag claude:latest .
```

alias:
```
alias claude="docker run --rm -it -e TERM -e ANTHROPIC_AUTH_TOKEN -e ANTHROPIC_BASE_URL -e ANTHROPIC_MODEL -e ANTHROPIC_SMALL_FAST_MODEL -e UID=\$(id -u ) -v claude:/workspace -v \$(pwd):/workspace/workdir claude:latest"
```

Usage:
```
export ANTHROPIC_BASE_URL=https://api.anthropic.com
export ANTHROPIC_AUTH_TOKEN=your_token_here
export ANTHROPIC_MODEL=claude-2
export ANTHROPIC_SMALL_FAST_MODEL=claude-instant-100k
claude
```

Or
```
claude --resume
```
