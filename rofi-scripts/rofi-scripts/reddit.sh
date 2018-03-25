if [ -z $@ ]
then
    echo tennis; echo askreddit; echo something;
else
    firefox 'https://reddit.com/r/'$@;
fi
