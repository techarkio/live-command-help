# Oh My Zsh plugin entry point for live-command-help.

typeset -g LIVE_COMMAND_HELP_PLUGIN_DIR="${0:A:h}"

if (( ! ${path[(Ie)${LIVE_COMMAND_HELP_PLUGIN_DIR}/bin]} )); then
  path=("${LIVE_COMMAND_HELP_PLUGIN_DIR}/bin" $path)
fi

# Oh My Zsh adds a plugin's root to fpath before compinit, so the bundled
# _live-command-help file is discovered without doing extra work here.

# Expand one Oh My Zsh alias for lookup purposes without evaluating it. This
# lets typing `gst` show `git status` examples when the git plugin defines gst.
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

typeset -g _LIVE_COMMAND_HELP_LAST_CONTEXT=''
typeset -g _LIVE_COMMAND_HELP_PANEL=''
typeset -gi _LIVE_COMMAND_HELP_CONTEXT_HAS_OPTION=0

function _live_command_help_context() {
  emulate -L zsh
  setopt extended_glob
  local -a input=("$@") context
  local word skip_next=0 seen_command=0
  _LIVE_COMMAND_HELP_CONTEXT_HAS_OPTION=0

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
    elif [[ "$word" == -* ]]; then
      _LIVE_COMMAND_HELP_CONTEXT_HAS_OPTION=1
      break
    elif [[ "$word" != [A-Za-z0-9_.:+-]## ]]; then
      break
    fi
    context+=("$word")
    (( ${#context} >= 4 )) && break
  done
  reply=("${context[@]}")
}

function _live_command_help_remove_old_panel() {
  emulate -L zsh
  local prefix_length
  REPLY=$POSTDISPLAY
  if [[ -n "$_LIVE_COMMAND_HELP_PANEL" && "$REPLY" == *"$_LIVE_COMMAND_HELP_PANEL" ]]; then
    prefix_length=$(( ${#REPLY} - ${#_LIVE_COMMAND_HELP_PANEL} ))
    if (( prefix_length )); then
      REPLY=${REPLY[1,$prefix_length]}
    else
      REPLY=''
    fi
  fi
}

function _live_command_help_remove_legacy_panel() {
  emulate -L zsh
  local value=$1

  # Older releases could leak their display into history through
  # zsh-autosuggestions. Remove those exact legacy markers when such a history
  # entry is offered again.
  value=${value%%$'\n  examples:'*}
  value=${value%%$'\nexamples:'*}
  value=${value%%'  examples: '*}
  REPLY=$value
}

function _live_command_help_strip_panel() {
  emulate -L zsh
  _live_command_help_remove_old_panel
  if (( ${+functions[_zsh_autosuggest_accept]} ||
        ${+functions[_live_command_help_original_autosuggest_accept]} )); then
    _live_command_help_remove_legacy_panel "$REPLY"
  fi
  POSTDISPLAY=$REPLY
}

# zsh-autosuggestions accepts POSTDISPLAY when Right Arrow, End, or one of its
# other accept widgets runs. Keep our informational suffix out of the accepted
# command while leaving the autosuggestion itself intact.
function _live_command_help_install_autosuggest_integration() {
  emulate -L zsh

  if (( ${+functions[_zsh_autosuggest_accept]} &&
        ! ${+functions[_live_command_help_original_autosuggest_accept]} )); then
    functions[_live_command_help_original_autosuggest_accept]=$functions[_zsh_autosuggest_accept]
    function _zsh_autosuggest_accept() {
      _live_command_help_strip_panel
      _live_command_help_original_autosuggest_accept "$@"
    }
  fi

  if (( ${+functions[_zsh_autosuggest_execute]} &&
        ! ${+functions[_live_command_help_original_autosuggest_execute]} )); then
    functions[_live_command_help_original_autosuggest_execute]=$functions[_zsh_autosuggest_execute]
    function _zsh_autosuggest_execute() {
      _live_command_help_strip_panel
      _live_command_help_original_autosuggest_execute "$@"
    }
  fi

  if (( ${+functions[_zsh_autosuggest_partial_accept]} &&
        ! ${+functions[_live_command_help_original_autosuggest_partial_accept]} )); then
    functions[_live_command_help_original_autosuggest_partial_accept]=$functions[_zsh_autosuggest_partial_accept]
    function _zsh_autosuggest_partial_accept() {
      _live_command_help_strip_panel
      _live_command_help_original_autosuggest_partial_accept "$@"
    }
  fi

  if (( ${+functions[_zsh_autosuggest_modify]} &&
        ! ${+functions[_live_command_help_original_autosuggest_modify]} )); then
    functions[_live_command_help_original_autosuggest_modify]=$functions[_zsh_autosuggest_modify]
    function _zsh_autosuggest_modify() {
      _live_command_help_strip_panel
      _live_command_help_original_autosuggest_modify "$@"
    }
  fi

  if (( ${+functions[_live_command_help_original_autosuggest_accept]} )); then
    autoload -Uz add-zsh-hook
    add-zsh-hook -d precmd _live_command_help_install_autosuggest_integration 2>/dev/null
  fi
}

function _live_command_help_live_update() {
  emulate -L zsh
  setopt extended_glob
  local base suggestions line display context command_word panel
  local requested_width available_width width
  local -a words reply context_words examples

  _live_command_help_remove_old_panel
  base=$REPLY
  if (( ${+functions[_zsh_autosuggest_accept]} ||
        ${+functions[_live_command_help_original_autosuggest_accept]} )); then
    _live_command_help_remove_legacy_panel "$base"
    base=$REPLY
  fi
  if [[ -n "$base" ]]; then
    _LIVE_COMMAND_HELP_LAST_CONTEXT=''
    _LIVE_COMMAND_HELP_PANEL=''
    POSTDISPLAY=$base
    return 0
  fi

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
  if (( _LIVE_COMMAND_HELP_CONTEXT_HAS_OPTION )) ||
     [[ -z "$context" || ${#command_word} -lt min_chars ]]; then
    _LIVE_COMMAND_HELP_LAST_CONTEXT=''
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

  requested_width=${LIVE_COMMAND_HELP_MAX_WIDTH:-60}
  [[ "$requested_width" == <20-999> ]] || requested_width=60
  # Reserve room for the prompt and measure from the end of the full buffer,
  # not CURSOR, so moving left or right cannot make the hint wrap.
  available_width=$(( COLUMNS - ${#BUFFER} - ${#base} - 20 ))
  width=$(( requested_width < available_width ? requested_width : available_width ))
  if (( width < 20 )); then
    _LIVE_COMMAND_HELP_PANEL=''
    POSTDISPLAY=$base
    return 0
  fi

  for line in "${(@f)suggestions}"; do
    display=$line
    examples+=("$display")
  done
  panel="  examples: ${(j: | :)examples}"
  if (( ${#panel} > width )); then
    panel="${panel[1,$(( width - 3 ))]}..."
  fi
  _LIVE_COMMAND_HELP_PANEL=$panel
  POSTDISPLAY="${base}${_LIVE_COMMAND_HELP_PANEL}"
  return 0
}

if [[ -o interactive ]] && [[ "${LIVE_COMMAND_HELP_LIVE:-1}" != 0 ]]; then
  zmodload zsh/zle 2>/dev/null
  autoload -Uz add-zle-hook-widget
  add-zle-hook-widget -d line-pre-redraw _live_command_help_live_update 2>/dev/null
  add-zle-hook-widget line-pre-redraw _live_command_help_live_update

  # Usually zsh-autosuggestions is already loaded. The precmd fallback also
  # covers configurations that load it after this plugin.
  _live_command_help_install_autosuggest_integration
  if (( ! ${+functions[_live_command_help_original_autosuggest_accept]} )); then
    autoload -Uz add-zsh-hook
    add-zsh-hook -d precmd _live_command_help_install_autosuggest_integration 2>/dev/null
    add-zsh-hook precmd _live_command_help_install_autosuggest_integration
  fi
fi
