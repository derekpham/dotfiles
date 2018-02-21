if [ -f ~/.aliases]; then
    source ~/.aliases
fi

if [ -f ~/.env]; then
    source ~/.env
fi

source /usr/share/doc/pkgfile/command-not-found.bash
