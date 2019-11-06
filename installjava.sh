#!/usr/bin/env bash
# shellcheck disable=SC2001
CONFIG_FILE=java-versions.cfg

# Make sure only root can run this script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# check if config file exist
if ! [[ -f $CONFIG_FILE ]]; then
  echo "$CONFIG_FILE can not be found"
  exit 1
fi

# check if dialog is installed
dialog --version >/dev/null 2>&1 || {
  echo >&2 "Dialog is requiered. Please install dialog and try again"
  exit 1
}

CONFIG_REGEX='[A-Za-z0-9]=https://*'
readarray configLines <$CONFIG_FILE
options=("${configLines[@]:1}") #removed the 1st element cause of comment

# validate file lines
for ((i = 0; i < ${#options[@]}; i++)); do
  if ! [[ ${options[$i]} =~ $CONFIG_REGEX ]]; then
    echo "Incorrect config file content"
    exit 1
  fi
done

# new associative array for URL to Java name map
declare -A NAME_TO_URL

MENU_SIZE=${#options[@]}
MENU_ARRAY_SIZE=$((MENU_SIZE * 2))

# some temp vars. yes, I need that
incr=1
indexOfOptionsArray=0

# too complicated to comment this part of code below...
for ((i = 0; i < MENU_ARRAY_SIZE; i++)); do
  if ! [[ $((incr % 2)) == 0 ]]; then
    key=${options[$indexOfOptionsArray]//=http*/}
    value=$(sed 's/^.*https/https/' <<<"${options[$indexOfOptionsArray]}")
    MENU_ARRAY[$i]=$key
    NAME_TO_URL[$key]=$value
  else
    for ((j = 0; j < MENU_SIZE; j++)); do
      if [[ $((j == indexOfOptionsArray)) ]]; then
        MENU_ARRAY[$i]=${NAME_TO_URL[$key]}
        break
      fi
    done
    indexOfOptionsArray=$((indexOfOptionsArray + 1))
  fi
  incr=$((incr + 1))
done

# menu dialog
HEIGHT=300
WIDTH=1000
CHOICE_HEIGHT=$MENU_SIZE
BACKTITLE="Java Installer"
TITLE="Java Installer"
MENU="Choose one of the following java version:"

KEY=$(dialog --clear \
  --backtitle "$BACKTITLE" \
  --title "$TITLE" \
  --menu "$MENU" \
  $HEIGHT $WIDTH "$CHOICE_HEIGHT" \
  "${MENU_ARRAY[@]}" \
  2>&1 >/dev/tty)

clear

if [ "$KEY" == "" ]; then
  exit 1
fi

URL=${NAME_TO_URL[$KEY]}
NAME_FOR_JAVA=$KEY

# ok, we can start with installation of java
JAVA_TAR_ARCHIV="/tmp"/$(basename "$URL")
DESTINATION="/opt/$NAME_FOR_JAVA"

wget -nc -P "/tmp" "${URL}"

if ! [ -d "$DESTINATION" ]; then
  mkdir "$DESTINATION"
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

echo "-----"
echo "Current Java Version:"
java -version
echo "-----"
