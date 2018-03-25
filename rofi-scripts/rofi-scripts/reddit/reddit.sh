REDDIT_DIR=$HOME'/rofi-scripts/reddit';
REDDIT_URL='https://reddit.com/r/';
HISTORY_FILE_NAME='history';

HISTORY_ABS_PATH=$REDDIT_DIR/$HISTORY_FILE_NAME

if [[ ! (-f $HISTORY_ABS_PATH) ]]
then
    touch $HISTORY_ABS_PATH;
fi

if [ -z $@ ]
then
    sort $HISTORY_ABS_PATH | uniq -c | sort -rn | sed 's/[[:space:]]*[[:digit:]]*[[:space:]]//';
else
    xdg-open $REDDIT_URL$@;
    echo $@ >> $HISTORY_ABS_PATH;
fi

#TODO: keep count instead of all inputs??
