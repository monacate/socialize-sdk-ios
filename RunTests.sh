#!/bin/sh

#set -o errexit

# If we aren't running from the command line, then exit
if [ "$GHUNIT_CLI" = "" ] && [ "$GHUNIT_AUTORUN" = "" ]; then
  exit 0
fi

export DYLD_ROOT_PATH="$SDKROOT"
export DYLD_FRAMEWORK_PATH="$CONFIGURATION_BUILD_DIR"
export IPHONE_SIMULATOR_ROOT="$SDKROOT"

export NSDebugEnabled=YES
export NSZombieEnabled=YES
export NSDeallocateZombies=NO
export NSHangOnUncaughtException=YES
export NSAutoreleaseFreedObjectCheckEnabled=YES

export DYLD_FRAMEWORK_PATH="$CONFIGURATION_BUILD_DIR"

TEST_TARGET_EXECUTABLE_PATH="$TARGET_BUILD_DIR/$EXECUTABLE_PATH"

if [ ! -e "$TEST_TARGET_EXECUTABLE_PATH" ]; then
  echo ""
  echo "  ------------------------------------------------------------------------"
  echo "  Missing executable path: "
  echo "     $TEST_TARGET_EXECUTABLE_PATH."
  echo "  The product may have failed to build or could have an old xcodebuild in your path (from 3.x instead of 4.x)."
  echo "  ------------------------------------------------------------------------"
  echo ""
  exit 1
fi

RUN_CMD="\"$TEST_TARGET_EXECUTABLE_PATH\" -RegisterForSystemEvents"

echo "Running: $RUN_CMD"
eval $RUN_CMD
RETVAL=$?

unset DYLD_ROOT_PATH
unset DYLD_FRAMEWORK_PATH
unset IPHONE_SIMULATOR_ROOT

if [ -n "$WRITE_JUNIT_XML" ]; then
  MY_TMPDIR=`/usr/bin/getconf DARWIN_USER_TEMP_DIR`
  RESULTS_DIR="${MY_TMPDIR}test-results"

  if [ -d "$RESULTS_DIR" ]; then
	`$CP -r "$RESULTS_DIR" "$BUILD_DIR" && rm -r "$RESULTS_DIR"`
  fi
fi

if [ ! -e "$BUILD_DIR/test-coverage/" ]; then
    mkdir -p "$BUILD_DIR/test-coverage/"

fi

eval "lcov --test-name \"Socialize iOS SDK\" --output-file \"$BUILD_DIR\"/test-coverage/SocializeSDK-iOS-Coverage_tmp.info --capture --directory \"$CONFIGURATION_TEMP_DIR\"/Socialize.build/Objects-normal/i386/"

eval "lcov --extract \"$BUILD_DIR\"/test-coverage/SocializeSDK-iOS-Coverage_tmp.info \"*/Socialize*/Classes*\" --output-file \"$BUILD_DIR\"/test-coverage/SocializeSDK-iOS-Coverage.info"

eval "rm -rf \"$BUILD_DIR\"/test-coverage/SocializeSDK-iOS-Coverage_tmp.info"

eval "genhtml --title \"Socialize SDK iOS\"  --output-directory \"$BUILD_DIR\"/test-coverage \"$BUILD_DIR\"/test-coverage/SocializeSDK-iOS-Coverage.info --legend"

exit $RETVAL