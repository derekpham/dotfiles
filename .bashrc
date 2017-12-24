export PATH=$PATH:~/bin

alias rm="rm -I"
alias cdneu="cd ~/Desktop/Northeastern"
alias clean="rm *~"

source /etc/profile.d/rvm.sh
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
