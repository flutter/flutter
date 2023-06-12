#
# This script should not be run directly (hence, it does not have +x attribute)
# It should be included in the current environment via
#
#  source hello_completion_init.sh
#

APP_NAME=example.dart
COMPLETION_NAME=example-completion.sh

APP_DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

if [ ! -f $APP_DIR/$APP_NAME ]
then
  echo $APP_NAME does not exist in the expected directory
  exit 1
fi

if [ ! -f $APP_DIR/$COMPETION_NAME ]
then
  echo $COMPLETION_NAME does not exist in the expected directory
  exit 1
fi

echo Initializing your environment to run the $APP_NAME completion sample
echo

echo 'sourcing' $COMPLETION_NAME to enable command completion
source $APP_DIR/$COMPLETION_NAME

echo
echo Adding $APP_NAME directory \($APP_DIR\) to PATH environment
export PATH=$PATH:$APP_DIR

echo
echo Success!
