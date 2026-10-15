# tmux workspace: nvim (top-left), shell (bottom-left), claude (right).
# Attaches if the session exists, otherwise builds it first.
#   ws            -> current folder
#   ws <project>  -> ~/Code/<project> or ~/Code/*/<project>
#   ws <path>     -> any existing folder
ws() {
  local dir
  if (( $# == 0 )); then
    dir=$PWD
  elif [[ -d $1 ]]; then
    dir=${1:A}
  else
    local -a matches=(~/Code/$1(N/) ~/Code/*/$1(N/))
    if (( ${#matches} == 0 )); then
      echo "ws: no project '$1' in ~/Code" >&2; return 1
    elif (( ${#matches} > 1 )); then
      echo "ws: '$1' is ambiguous:" >&2; printf '  %s\n' $matches >&2; return 1
    fi
    dir=${matches[1]}
  fi
  local s=${${dir:t}//[.:]/_}   # tmux session names can't contain . or :
  if ! tmux has-session -t "=$s" 2>/dev/null; then
    tmux new-session -d -s $s -c $dir
    tmux split-window -h -t $s:1 -c $dir        # right pane
    tmux send-keys -t $s:1.2 'claude' C-m
    tmux split-window -v -t $s:1.1 -c $dir      # bottom-left pane
    tmux send-keys -t $s:1.1 'nvim' C-m
    tmux select-pane -t $s:1.1
  fi
  [[ -n $TMUX ]] && tmux switch-client -t "=$s" || tmux attach -t "=$s"
}
_ws() { compadd ~/Code/*(/:t) ~/Code/*/*(/:t) }
compdef _ws ws
