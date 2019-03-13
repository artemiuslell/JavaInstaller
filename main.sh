#!/bin/bash

# Make sure only root can run this script
if [[ $EUID -ne 0 ]]
then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Make sure two parameter is given
if [ $# -ne 2 ]
then
    echo "Please enter two parameters"
    exit 1
fi

if [[ $1 == https:'//'* ]]
then
    LINK=$1;
else
    echo "wrong parameter";
    exit 1;
fi

NAME_FOR_JAVA=$2;
JAVA_TAR_ARCHIV="/tmp"/$(basename "$LINK");
DESTINATION="/opt/$NAME_FOR_JAVA";

function download () {
    wget -nc -P "/tmp" "${LINK}"
}

download;

if ! [ -d "$DESTINATION" ]
then
    mkdir "$DESTINATION";
fi

tar -xzf "$JAVA_TAR_ARCHIV" -C /"$DESTINATION"/
DIRECTORY_NAME_INSIDE_ARCHIVE=$(tar -tzf "$JAVA_TAR_ARCHIV" | head -1 | cut -f1 -d"/")
FULL_PATH_TO_JAVA="$DESTINATION/$DIRECTORY_NAME_INSIDE_ARCHIVE"
chmod -R 755 "$FULL_PATH_TO_JAVA"
chown -R root:root "$FULL_PATH_TO_JAVA"

update-alternatives --install "/usr/bin/java" "java" "$FULL_PATH_TO_JAVA/bin/java" 1500
update-alternatives --install "/usr/bin/javac" "javac" "$FULL_PATH_TO_JAVA/bin/javac" 1500
update-alternatives --install "/usr/bin/jar" "jar" "$FULL_PATH_TO_JAVA/bin/jar" 1500

update-alternatives --set "java" "$FULL_PATH_TO_JAVA/bin/java"
update-alternatives --set "javac" "$FULL_PATH_TO_JAVA/bin/javac"
update-alternatives --set "jar" "$FULL_PATH_TO_JAVA/bin/jar"

echo "-----";
echo "Current Java Version:"
java -version;
echo "-----";
