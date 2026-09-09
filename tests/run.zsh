#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipe_fail

readonly TEST_DIR=${0:A:h}
readonly PROJECT_DIR=${TEST_DIR:h}
readonly COMMAND="$PROJECT_DIR/bin/live-command-help"
readonly TEST_CACHE=$(mktemp -d "${TMPDIR:-/tmp}/live-command-help-test.XXXXXX")
export LIVE_COMMAND_HELP_CACHE_DIR="$TEST_CACHE"
trap 'rm -rf -- "$TEST_CACHE"' EXIT
typeset -gi passed=0

function assert_contains() {
  local name=$1 expected=$2
  shift 2
  local output
  output=$(NO_COLOR=1 LIVE_COMMAND_HELP_USE_TLDR=0 "$@")
  if [[ "$output" != *"$expected"* ]]; then
    print -u2 -- "not ok - $name"
    print -u2 -- "expected output to contain: $expected"
    print -u2 -- "$output"
    return 1
  fi
  print -- "ok - $name"
  (( ++passed ))
}

assert_contains "simple command" "# curl" "$COMMAND" curl
assert_contains "longest subcommand page" "# git-commit" "$COMMAND" git commit
assert_contains "shell line parsing" "# docker-compose" "$COMMAND" --line "sudo -u root docker compose up -d"
assert_contains "macOS auto platform" "Homebrew" "$COMMAND" -p osx brew
assert_contains "Windows override" "# robocopy" "$COMMAND" -p windows robocopy
assert_contains "search summaries" "scp" "$COMMAND" --search "copy files"
assert_contains "list pages" "systemctl" "$COMMAND" --list
assert_contains "command flags are not plugin flags" "# git" "$COMMAND" git --version
assert_contains "compact live suggestions" "git status" "$COMMAND" --suggest -- git
assert_contains "live subcommand narrowing" "git commit -m" "$COMMAND" --suggest -- git commit

local alias_output
alias_output=$(LIVE_COMMAND_HELP_PROJECT_DIR="$PROJECT_DIR" zsh -dfc '
  alias gst="git status"
  source "$LIVE_COMMAND_HELP_PROJECT_DIR/live-command-help.plugin.zsh"
  local -a reply
  _live_command_help_expand_alias gst
  NO_COLOR=1 LIVE_COMMAND_HELP_USE_TLDR=0 live-command-help "${reply[@]}"
')
if [[ "$alias_output" != *"# git"* ]]; then
  print -u2 -- "not ok - Oh My Zsh alias resolution"
  exit 1
fi
print -- "ok - Oh My Zsh alias resolution"
(( ++passed ))

mkdir -p "$TEST_CACHE/pages/common"
print -r -- $'# fixture\n> Cached test page.\n\n- Test it:\n\n`fixture --ok`' > "$TEST_CACHE/pages/common/fixture.md"
assert_contains "downloaded cache page" "fixture --ok" "$COMMAND" fixture
assert_contains "downloaded cache live suggestion" "fixture --ok" "$COMMAND" --suggest -- fixture

source "$PROJECT_DIR/live-command-help.plugin.zsh"
typeset BUFFER=git
typeset POSTDISPLAY='existing inline suggestion'
typeset -i COLUMNS=120
_live_command_help_live_update
if [[ "$POSTDISPLAY" != *"git status"* || "$POSTDISPLAY" != 'existing inline suggestion'* ]]; then
  print -u2 -- "not ok - inline suggestion panel"
  exit 1
fi
if [[ "$POSTDISPLAY" == *$'\n'* ]]; then
  print -u2 -- "not ok - suggestion panel stays on one line"
  exit 1
fi
print -- "ok - inline suggestion panel"
(( ++passed ))

BUFFER='git commit'
_live_command_help_live_update
if [[ "$POSTDISPLAY" != *"git commit -m"* || "$POSTDISPLAY" == *"git status"* ]]; then
  print -u2 -- "not ok - latest panel replaces previous panel"
  exit 1
fi
print -- "ok - latest panel replaces previous panel"
(( ++passed ))

BUFFER=''
_live_command_help_live_update
if [[ "$POSTDISPLAY" != 'existing inline suggestion' ]]; then
  print -u2 -- "not ok - empty input clears panel"
  exit 1
fi
print -- "ok - empty input clears panel"
(( ++passed ))

print -- "$passed tests passed"
