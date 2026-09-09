# live-command-help

[![Tests](https://github.com/techarkio/live-command-help/actions/workflows/test.yml/badge.svg)](https://github.com/techarkio/live-command-help/actions/workflows/test.yml)

An Oh My Zsh plugin that automatically shows short, practical examples while
you type—without making you run a help command or read an entire manual page.

```text
% git
  examples:
    git status
    git log --oneline --graph --decorate --all
    git switch -c {{feature-name}}

% git commit
  examples:
    git add {{file1 file2}} && git commit -m "{{message}}"
    git commit --amend --no-edit
```

It works in iTerm2 and other Zsh terminals. The included starter catalog works
offline. An optional download of the official [TLDR pages](https://github.com/tldr-pages/tldr)
adds thousands of pages spanning common, macOS, Linux, and Windows commands.
Windows examples are useful as a reference from macOS/Linux; running the plugin
itself on Windows requires a Zsh environment such as WSL or MSYS2.

## Features

- Shows and narrows examples automatically as a command is typed.
- The panel is informational: it never changes or executes the editable line.
- `eg COMMAND [SUBCOMMAND]` remains available for a larger, described view.
- Press **Alt-E** to manually open that detailed view for the current line.
- Understands prefixes such as `sudo`, `env`, `command`, and assignments.
- Resolves simple Oh My Zsh aliases (`gst` is treated as `git status`).
- Supports `auto`, `common`, `osx`, `linux`, and `windows` platforms.
- Searches an offline starter catalog and a downloaded TLDR cache first.
- Falls back to an already-installed `tldr` client when available.
- Has no runtime dependency beyond Zsh for its built-in catalog.

## Install with Oh My Zsh

### Using zplug

Add this alongside your other `zplug` declarations, before `zplug check` and
`zplug load`:

```zsh
zplug "techarkio/live-command-help", defer:3
```

`defer:3` loads the live panel after plugins such as autosuggestions and syntax
highlighting. Install it and reload the configuration:

```zsh
zplug install
source ~/.zshrc
```

For local development, use the checkout directly:

```zsh
zplug "/absolute/path/to/live-command-help", \
  from:local, \
  use:"live-command-help.plugin.zsh", \
  defer:3
```

### Using Oh My Zsh directly

Clone the repository into the custom plugin directory:

```zsh
git clone https://github.com/techarkio/live-command-help \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/live-command-help"
```

Add `live-command-help` to the whitespace-separated plugin list in `~/.zshrc`:

```zsh
plugins=(git live-command-help)
```

Start a new shell or reload the configuration:

```zsh
source ~/.zshrc
```

### Optional iTerm2 key setup

Live suggestions need no special iTerm2 configuration. If you also want the
optional **Alt-E** detailed view and Alt-E types an accented character, open
**iTerm2 → Settings → Profiles → Keys → General** and set the Left Option key
to **Esc+**. Alternatively, choose any Zsh key sequence with
`LIVE_COMMAND_HELP_KEY` as shown below.

For the largest offline catalog, download the current English TLDR archive:

```zsh
eg --update
```

The update is stored under
`${XDG_CACHE_HOME:-$HOME/.cache}/live-command-help`; it does not modify Oh
My Zsh or the plugin checkout.

If you used an older name of this plugin, an existing
`~/.cache/ohmyzh-example-command/pages` catalog is detected automatically so it
does not need to be downloaded again.

## Usage

Just type a command normally. Suggestions appear once the command name has at
least two characters. As you add a subcommand, the panel narrows automatically:

```zsh
git                  # shows general Git examples
git c                # shows examples from matching Git subcommands
git commit           # shows Git commit examples
docker compose       # shows Docker Compose examples
```

The following explicit commands are optional:

```zsh
eg git                         # general Git examples
eg git rebase                  # resolves the git-rebase page first
eg docker compose up           # resolves docker-compose before docker
eg -p windows winget           # Windows examples from any host OS
eg --all curl                  # every locally available platform variant
eg --search "copy files"       # search names and descriptions
eg --list                      # list locally available pages
eg --update                    # update the complete TLDR cache
eg --clear-cache               # remove only downloaded pages
```

While editing a command, press **Alt-E**. For example, type
`sudo kubectl get pods`, press Alt-E to view the `kubectl` examples, then keep
editing or press Enter normally. The widget never executes the typed command.

Placeholders are shown as `{{value}}`; replace them before running an example.
Examples are educational, so review commands—especially ones using `sudo`,
deletion, permissions, disks, or production infrastructure—before executing.

## Configuration

Set variables before Oh My Zsh is sourced:

```zsh
# Do not create the eg/example shortcut functions; use live-command-help directly.
LIVE_COMMAND_HELP_NO_ALIASES=1

# Do not bind Alt-E.
LIVE_COMMAND_HELP_NO_WIDGET=1

# Turn off the automatic panel (the eg command and Alt-E still work).
LIVE_COMMAND_HELP_LIVE=0

# Tune when and how much the automatic panel displays.
LIVE_COMMAND_HELP_MIN_CHARS=2
LIVE_COMMAND_HELP_MAX_SUGGESTIONS=3
LIVE_COMMAND_HELP_MAX_WIDTH=100

# Change the widget key (this example is Ctrl-X followed by E).
LIVE_COMMAND_HELP_KEY='^Xe'

# Do not invoke an installed tldr client as a final fallback.
LIVE_COMMAND_HELP_USE_TLDR=0

# Put downloaded pages somewhere else.
LIVE_COMMAND_HELP_CACHE_DIR="$HOME/.local/share/live-command-help"
```

`NO_COLOR=1` disables colored output. `live-command-help --help` lists all options.

If you use a plugin that also draws inline text with ZLE `POSTDISPLAY`, put
`live-command-help` after it in the Oh My Zsh plugin list so this plugin can
preserve that text and append its panel below it.

## Development

Run the dependency-free test suite with:

```zsh
zsh tests/run.zsh
```

The starter pages live in `data/examples.db`. Each page begins with
`@@command|platform|summary` and uses the simple TLDR Markdown style below it.
Downloaded TLDR pages take precedence over starter pages.

## License

Plugin code and the original starter examples are released under the MIT
License. Pages downloaded by `eg --update` come from the TLDR project and are
covered by its license.
