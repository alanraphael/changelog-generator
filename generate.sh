#!/bin/bash

# Link to repository
LINK_REPOSITORY='https://github.com/alanraphael/changelog-generator'

DIRLOG='changelog'
FILE_HEADER=$DIRLOG/changelog-header.md
FILE_CONTENT=$DIRLOG/changelog-content.md
FILE_BUILD=$DIRLOG/changelog.md

FORMAT_COMMIT="- [%h]($LINK_REPOSITORY/commit/%H) %s \n"

mkdir -p $DIRLOG

LOGS=()

if [ -e "$FILE_CONTENT" ]
then

    tags=''
    lasttag=''

    i=0
    for tag in $(git tag -l --sort=-v:refname)
    do
        if [ $i == 1 ]
        then
            tags=$tag'...'$lasttag
            break
        fi

        lasttag=$tag

        ((i++))
    done

    commits=$(git log $tags --pretty=format:"$FORMAT_COMMIT" --reverse -- | grep -v Merge)

    str="- - -\n$lasttag\n==\n#### Commits\n--\n$commits"

    LOGS+=("$str")

else

    for tag in $(git tag -l --sort=v:refname)
    do
        if [ -z $oldtag ]
        then
            strtag=$tag
        else
            strtag=$oldtag'...'$tag
        fi

        commits=$(git log $strtag --pretty=format:"$FORMAT_COMMIT" --reverse -- | grep -v Merge)

        str="- - -\n$tag\n==\n#### Commits\n\n$commits"

        LOGS+=("$str")

        oldtag=$tag
    done

fi

# Creates the content file and clears the leading blanks for the correct markdown formatting.
create_content_file(){
    file=$1
    str=''

    cat $file | while read s
    do
        tag=$(echo -e $s | sed -e 's/^[[:space:]]*//')
        echo $tag >> $FILE_CONTENT
    done

    rm $file
}

total=(${!LOGS[@]})

for ((i=${#total[@]} - 1; i >= 0; i--))
do
    echo -e ${LOGS[total[i]]} >> $DIRLOG/_cache.md
done

cat $DIRLOG/_cache.md $FILE_CONTENT > $DIRLOG/_cache2.md

rm -f $FILE_CONTENT
rm $DIRLOG/_cache.md

create_content_file $DIRLOG/_cache2.md

cat $FILE_HEADER $FILE_CONTENT > $FILE_BUILD
