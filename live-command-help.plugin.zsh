# Oh My Zsh plugin entry point for live-command-help.

typeset -g LIVE_COMMAND_HELP_PLUGIN_DIR="${0:A:h}"

if (( ! ${path[(Ie)${LIVE_COMMAND_HELP_PLUGIN_DIR}/bin]} )); then
  path=("${LIVE_COMMAND_HELP_PLUGIN_DIR}/bin" $path)
fi

# Oh My Zsh adds a plugin's root to fpath before compinit, so the bundled
# _live-command-help file is discovered without doing extra work here.

# Expand one Oh My Zsh alias for lookup purposes without evaluating it. This
# lets `eg gst` show `git status` examples when the git plugin defines gst.
function _live_command_help_expand_alias() {
  emulate -L zsh
  setopt extended_glob
  local -a input=("$@") expansion
  local i word skip_next=0
  reply=("${input[@]}")

  for (( i=1; i<=${#input}; ++i )); do
    word=${input[i]}
    (( skip_next )) && { skip_next=0; continue; }
    case "$word" in
      sudo|command|builtin|noglob|nocorrect|env) continue ;;
      -u|-g|-h|-p|-C) skip_next=1; continue ;;
      --|-*) continue ;;
      [A-Za-z_][A-Za-z0-9_]#=*) continue ;;
    esac
    if (( ${+aliases[$word]} )); then
      expansion=( ${(z)aliases[$word]} )
      reply=()
      (( i > 1 )) && reply+=("${input[1,$(( i - 1 ))]}")
      reply+=("${(@)expansion}")
      (( i < ${#input} )) && reply+=("${input[$(( i + 1 )),-1]}")
    fi
    break
  done
}

# Short, memorable functions. Define LIVE_COMMAND_HELP_NO_ALIASES=1 before
# loading the plugin if either name conflicts with a command on your system.
if [[ "${LIVE_COMMAND_HELP_NO_ALIASES:-0}" != 1 ]]; then
  function eg() {
    local -a reply
    _live_command_help_expand_alias "$@"
    command live-command-help "${reply[@]}"
  }
  function example() { eg "$@"; }
fi

function _live_command_help_widget() {
  emulate -L zsh
  local -a words reply
  words=( ${=BUFFER} )
  _live_command_help_expand_alias "${words[@]}"
  zle -I
  print
  command live-command-help -- "${reply[@]}"
  zle reset-prompt
}

typeset -g _LIVE_COMMAND_HELP_LAST_CONTEXT=''
typeset -g _LIVE_COMMAND_HELP_PANEL=''

function _live_command_help_context() {
  emulate -L zsh
  setopt extended_glob
  local -a input=("$@") context
  local word skip_next=0 seen_command=0

  for word in "${input[@]}"; do
    (( skip_next )) && { skip_next=0; continue; }
    if (( ! seen_command )); then
      case "$word" in
        sudo|command|builtin|noglob|nocorrect|env) continue ;;
        -u|-g|-h|-p|-C) skip_next=1; continue ;;
        --|-*) continue ;;
        [A-Za-z_][A-Za-z0-9_]#=*) continue ;;
        *) seen_command=1 ;;
      esac
    elif [[ "$word" == -* || "$word" != [A-Za-z0-9_.:+-]## ]]; then
      break
    fi
    context+=("$word")
    (( ${#context} >= 4 )) && break
  done
  reply=("${context[@]}")
}

function _live_command_help_remove_old_panel() {
  emulate -L zsh
  REPLY=$POSTDISPLAY
  if [[ -n "$_LIVE_COMMAND_HELP_PANEL" && "$REPLY" == *${(b)_LIVE_COMMAND_HELP_PANEL} ]]; then
    REPLY=${REPLY%${(b)_LIVE_COMMAND_HELP_PANEL}}
  fi
}

function _live_command_help_live_update() {
  emulate -L zsh
  setopt extended_glob
  local base suggestions line display context command_word
  local -a words reply context_words display_lines

  _live_command_help_remove_old_panel
  base=$REPLY

  # Whitespace splitting deliberately tolerates incomplete quotes while the
  # user is still typing. Exact shell parsing would reject that common state.
  words=( ${=BUFFER} )
  _live_command_help_expand_alias "${words[@]}"
  words=("${reply[@]}")
  _live_command_help_context "${words[@]}"
  context_words=("${reply[@]}")
  context="${(j: :)context_words}"
  command_word=${context_words[1]:t}

  local min_chars=${LIVE_COMMAND_HELP_MIN_CHARS:-2}
  [[ "$min_chars" == <1-9> ]] || min_chars=2
  if [[ -z "$context" || ${#command_word} -lt min_chars ]]; then
    _LIVE_COMMAND_HELP_LAST_CONTEXT=$context
    _LIVE_COMMAND_HELP_PANEL=''
    POSTDISPLAY=$base
    return 0
  fi

  if [[ "$context" == "$_LIVE_COMMAND_HELP_LAST_CONTEXT" ]]; then
    POSTDISPLAY="${base}${_LIVE_COMMAND_HELP_PANEL}"
    return 0
  fi
  _LIVE_COMMAND_HELP_LAST_CONTEXT=$context

  suggestions=$(NO_COLOR=1 LIVE_COMMAND_HELP_USE_TLDR=0 \
    command live-command-help --suggest -- "${context_words[@]}" 2>/dev/null)
  if [[ -z "$suggestions" ]]; then
    _LIVE_COMMAND_HELP_PANEL=''
    POSTDISPLAY=$base
    return 0
  fi

  local width=${LIVE_COMMAND_HELP_MAX_WIDTH:-$(( COLUMNS - 6 ))}
  [[ "$width" == <20-999> ]] || width=74
  for line in "${(@f)suggestions}"; do
    display=$line
    if (( ${#display} > width )); then
      display="${display[1,$(( width - 3 ))]}..."
    fi
    display_lines+=("    $display")
  done
  _LIVE_COMMAND_HELP_PANEL=$'\n  examples:'
  for display in "${display_lines[@]}"; do
    _LIVE_COMMAND_HELP_PANEL+=$'\n'"$display"
  done
  POSTDISPLAY="${base}${_LIVE_COMMAND_HELP_PANEL}"
  return 0
}

if [[ -o interactive ]]; then
  if [[ "${LIVE_COMMAND_HELP_LIVE:-1}" != 0 ]]; then
    zmodload zsh/zle 2>/dev/null
    autoload -Uz add-zle-hook-widget
    add-zle-hook-widget -d line-pre-redraw _live_command_help_live_update 2>/dev/null
    add-zle-hook-widget line-pre-redraw _live_command_help_live_update
  fi

  if [[ "${LIVE_COMMAND_HELP_NO_WIDGET:-0}" != 1 ]]; then
    zle -N live-command-help _live_command_help_widget
    # Alt-E in most terminal profiles. Override after loading the plugin if
    # this key is already important to your setup.
    bindkey "${LIVE_COMMAND_HELP_KEY:-^[e}" live-command-help
  fi
fi
