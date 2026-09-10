# live-command-help

`live-command-help` displays short, practical command examples beside the active
Zsh command line while you type. Suggestions automatically become more specific
as the command grows.

```text
% git  examples: git status | git log --oneline --graph --decorate | git switch {{branch}}
% git commit  examples: git commit -m "{{message}}" | git commit --amend | git commit --fixup {{commit}}
```

The suggestions are informational only: the plugin does not insert, modify, or
execute commands.

## Features

- Shows examples automatically—no lookup command or key binding is required.
- Defers to useful history suggestions from `zsh-autosuggestions` instead of
  displaying two competing hints.
- Narrows suggestions for subcommands such as `git commit` and partial input
  such as `git com`.
- Understands common command prefixes, including `sudo`, `command`, `env`, and
  environment-variable assignments.
- Resolves simple aliases, including Oh My Zsh aliases such as `gst` for
  `git status`.
- Includes an offline starter catalog covering 83 commands across macOS,
  Linux, Windows, and cross-platform tools.
- Can download the full English [tldr-pages](https://github.com/tldr-pages/tldr)
  catalog for thousands of additional command examples.
- Performs no network requests while you type.

## Requirements

- Zsh and Oh My Zsh.
- `curl` and `unzip` are required only when downloading the full catalog.

## Installation

Add `live-command-help` to the plugins array in `~/.zshrc`:

```zsh
plugins=(
  git
  live-command-help
)
```

Reload the shell:

```zsh
omz reload
```

You can also start a new terminal session or run `source ~/.zshrc`.

## Usage

Type a command normally and pause briefly to read the examples displayed after
the command line:

```text
git
git c
git commit
docker compose
find
tar
```

Continue typing to narrow the suggestions. Text wrapped in double braces, such
as `{{branch}}` or `{{file}}`, is a placeholder to replace with your own value.

### History suggestions and the help shortcut

When `zsh-autosuggestions` is installed, the two plugins follow these rules:

- A useful history suggestion is shown by itself; command examples stay hidden.
- A history suggestion whose remaining text is only `--help`, `-h`, or `help`
  is replaced by more practical examples.
- If there is no history suggestion, examples appear normally.
- After you accept a history suggestion, examples stay hidden until you edit
  the command.
- If you have already typed an option, examples stay hidden.

You can optionally bind a shortcut that switches between the active history
suggestion and command examples. Add this after your plugins are loaded in
`~/.zshrc`:

```zsh
bindkey '^Xh' live-command-help-toggle
```

Press `Ctrl-X`, then `h` to switch views. Press it again to return to the
history suggestion. The plugin deliberately does not claim a default key.

## Download the full catalog

The bundled starter catalog works immediately. To install the full English
tldr-pages catalog, run:

```zsh
live-command-help --update
```

The downloaded pages are stored in:

```text
${XDG_CACHE_HOME:-$HOME/.cache}/live-command-help/pages
```

After the download finishes, suggestions use the local cache and remain fully
offline. Run the update command again whenever you want to refresh the catalog.

To remove the downloaded catalog and return to the bundled starter data:

```zsh
live-command-help --clear-cache
```

## Configuration

Set options in `~/.zshrc` before Oh My Zsh is sourced:

```zsh
# Disable automatic suggestions.
LIVE_COMMAND_HELP_LIVE=0

# Minimum command length before suggestions appear. Default: 2.
LIVE_COMMAND_HELP_MIN_CHARS=2

# Maximum number of displayed examples. Default: 3.
LIVE_COMMAND_HELP_MAX_SUGGESTIONS=3

# Maximum hint width. Default: 60.
LIVE_COMMAND_HELP_MAX_WIDTH=100

# Override the catalog cache directory.
LIVE_COMMAND_HELP_CACHE_DIR="$HOME/.cache/live-command-help"
```

## Terminal and plugin compatibility

The plugin uses standard Zsh Line Editor functionality and does not require
iTerm2-specific configuration. It also works in other terminals that run Zsh.

The examples use a single-line, non-editable ZLE `POSTDISPLAY` hint. Each update
replaces the previous hint without moving the editor cursor. The hint is hidden
when the current command leaves too little horizontal space or contains an
option. A history suggestion and an example hint are mutually exclusive, so
they never appear joined as one command.

When `zsh-autosuggestions` is present, `live-command-help` removes its own hint
before an autosuggestion widget runs. Right Arrow, End, and partial-accept
widgets therefore accept only the history or completion suggestion—not the
example text. For the earliest integration, load `zsh-autosuggestions` before
`live-command-help`. Useful autosuggestions take priority, while suggestions
that only add a help flag yield to examples. Accepted suggestions remain free
of additional hints until the command is edited.

The integration also filters help markers accidentally saved to shell history
by early versions of this plugin.

## How it works

`live-command-help` registers a `line-pre-redraw` ZLE hook. When the command
context changes, it:

1. Reads the current editor buffer without evaluating it.
2. Removes supported prefixes and expands a simple leading alias.
3. Finds matching examples in the local catalog.
4. Replaces the previous single-line hint through `POSTDISPLAY`.

Repeated redraws of unchanged input reuse the previous result.

## Safety and privacy

- The command line is never evaluated or executed by the plugin.
- Typing does not send commands, arguments, paths, or other input over the
  network.
- Network access occurs only when you explicitly run
  `live-command-help --update`.
- Examples are reference material; review a command before running it.

## Example data

The plugin ships with an original starter catalog. The optional full catalog is
downloaded from the official tldr-pages release archive and remains subject to
the [tldr-pages license](https://github.com/tldr-pages/tldr/blob/main/LICENSE.md).

## Development

From the root of an Oh My Zsh checkout, run:

```zsh
zsh -n plugins/live-command-help/live-command-help.plugin.zsh
zsh -n plugins/live-command-help/bin/live-command-help
zsh plugins/live-command-help/tests/run.zsh
```

The tests use a temporary cache directory and do not modify the user's catalog.

## License

This plugin is distributed under the same MIT license as Oh My Zsh. Downloaded
tldr-pages content is licensed separately by the tldr-pages project.
