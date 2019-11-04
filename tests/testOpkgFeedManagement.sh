#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

declare -r S_OK=0
declare -r E_GENERIC_ERROR=1
declare -r E_INVALID_ARG=3
declare -r E_FEED_NOT_FOUND=4
declare -r E_FEED_ALREADY_EXISTS=5

declare -r CONF_DIR="/tmp/opkgFeedTest"
declare -r DEFAULT_OPKG_FEED_PATH="../opkg-feed"

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------

assertExitCode()
{
	local command="$1"
	local exitCode="$2"

	eval $command --conf-dir $CONF_DIR &>/dev/null
	local ret=$?
	if [[ "$ret" != "$exitCode" ]] ; then
		echo "ERROR: \"$command\" returned $ret instead of $exitCode"
		exit 1
	fi
}

assertExpectedFeedCount()
{
	local expectedFeedCount="$1"
	local actualFeedCount=$( "$OPKG_FEED" list --conf-dir "$CONF_DIR" | wc -l )

	if [[ "$expectedFeedCount" != "$actualFeedCount" ]] ; then
		echo "ERROR: expected $expectedFeedCount feeds but found $actualFeedCount"
		exit 1
	fi
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

# Test the script as people would generally use it
happyPathTest()
{
	assertExitCode "$OPKG_FEED" $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' help' $S_OK
	assertExitCode "$OPKG_FEED"' -h' $S_OK
	assertExitCode "$OPKG_FEED"' --help' $S_OK
	assertExitCode "$OPKG_FEED"' list' $S_OK
	assertExitCode "$OPKG_FEED"' list -h' $S_OK
	assertExitCode "$OPKG_FEED"' list --help' $S_OK
	assertExitCode "$OPKG_FEED"' list --key-value' $S_OK

	assertExitCode "$OPKG_FEED"' add' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' add feedNameWithoutUri' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' add feedNameWith\"Double\"Quotes\" --uri https://urldefense.com/v3/__http://somehost.com/somedir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgzfoNDzRA$ ' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' add someFeed --uri https://urldefense.com/v3/__http://some*5C*22host*5C*22.com/somedir__;JSUlJQ!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgw4XgAKxQ$ ' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' add someFeed --uri https://urldefense.com/v3/__http://somehost.com/somedir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgzfoNDzRA$ ' $S_OK
	assertExitCode "$OPKG_FEED"' add someFeed --uri https://urldefense.com/v3/__http://somehost.com/somedir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgzfoNDzRA$ ' $E_FEED_ALREADY_EXISTS
	assertExitCode "$OPKG_FEED"' add someFeed --uri https://urldefense.com/v3/__http://someotherhost.com/someotherdir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgxMT4RvEg$  --clobber' $S_OK
	assertExitCode "$OPKG_FEED"' add someFeed --uri https://urldefense.com/v3/__http://someotherhost.com/someotherdir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgxMT4RvEg$  --clobber --name addDoesNotAllowRename' $E_INVALID_ARG

	# The addition of --conf-dir <dir> means "--conf-dir" is treated as the feed name
	assertExitCode "$OPKG_FEED"' modify' $E_FEED_NOT_FOUND
	assertExitCode "$OPKG_FEED"' modify missingFeed' $E_FEED_NOT_FOUND
	assertExitCode "$OPKG_FEED"' modify missingFeed --clobber' $E_FEED_NOT_FOUND
	assertExitCode "$OPKG_FEED"' modify missingFeed --uri https://urldefense.com/v3/__http://missinghost.com/missingdir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgxJuwE9EQ$ ' $E_FEED_NOT_FOUND

	assertExitCode "$OPKG_FEED"' modify someFeed' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' modify someFeed --name feedNameWith\"Double\"Quotes\"' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' modify someFeed --uri https://urldefense.com/v3/__http://somehost.com/somedir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgzfoNDzRA$ ' $S_OK

	assertExitCode "$OPKG_FEED"' modify someFeed --enabled sometimes' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' modify someFeed --enabled 0' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --enabled 1' $S_OK

	assertExitCode "$OPKG_FEED"' modify someFeed --source-type blah' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' modify someFeed --source-type src' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --source-type src/gz' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --source-type dist' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --source-type dist/gz' $S_OK

	assertExitCode "$OPKG_FEED"' modify someFeed --trusted maybe' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' modify someFeed --trusted 1' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --trusted 0' $S_OK

	assertExitCode "$OPKG_FEED"' modify someFeed --name someFeed' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --name anotherFeed' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --uri https://urldefense.com/v3/__http://anotherhost.com/anotherdir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgzL7t9Bhw$ ' $E_FEED_NOT_FOUND

	assertExitCode "$OPKG_FEED"' add someFeed --uri https://urldefense.com/v3/__http://somehost.com/somedir__;!fqWJcnlTkjM!9i4Onh9iVJK9m0kcWmZI6WKisWsX5nNe__ZqOSr7If-Hh6WGsOE9HNr9-6dNcgzfoNDzRA$ ' $S_OK
	assertExitCode "$OPKG_FEED"' modify someFeed --name anotherFeed --enabled 0 --trusted 1' $E_FEED_ALREADY_EXISTS
	assertExitCode "$OPKG_FEED"' modify someFeed --name anotherFeed --enabled 0 --trusted 1 --clobber' $S_OK

	# The addition of --conf-dir <dir> means "--conf-dir" is treated as the feed name
	assertExitCode "$OPKG_FEED"' remove' $E_FEED_NOT_FOUND
	assertExitCode "$OPKG_FEED"' remove feedNameWith\"Double\"Quotes\"' $E_INVALID_ARG
	assertExitCode "$OPKG_FEED"' remove someFeed' $E_FEED_NOT_FOUND
	assertExitCode "$OPKG_FEED"' remove missingFeed' $E_FEED_NOT_FOUND
	assertExitCode "$OPKG_FEED"' remove anotherFeed' $S_OK
}

# Test regex metacharacters and shell escaping
dirtyTest()
{
	# Disable history expansion
	set +H

	local initialFeedCount=$( "$OPKG_FEED" list --conf-dir "$CONF_DIR" | wc -l )
	local withAdditionalFeedCount
	(( withAdditionalFeedCount = initialFeedCount + 1 ))

	# Use the same string for both the name and URI for coverage
	local testFeedNamesAndUris=( \
		'test' \
		'testtest' \
		'test \n ][][ ' \
		'test \n\s ][][ $' \
		'test test \n ][][ ' \
		'test test \n ]\[\s][   %$^#$' \
		"#^?#\$%()%\\(@\`#\$')file:///what(!_%%5C$#'(~%7B%7D%7D:%5C$'%5C$%5C$%5C$" \
	)

	for string in "${testFeedNamesAndUris[@]}" ; do
		"$OPKG_FEED" add "$string" --uri "$string" --conf-dir "$CONF_DIR" &> /dev/null
		local ret=$?
		if [[ "$ret" != '0' ]] ; then
			echo "ERROR: add \"$string\" failed with $ret"
			exit $ret
		fi
		assertExpectedFeedCount "$withAdditionalFeedCount"

		"$OPKG_FEED" modify "$string" --name "$string asdf" --enabled 0 --conf-dir "$CONF_DIR" &> /dev/null
		ret=$?
		if [[ "$ret" != '0' ]] ; then
			echo "ERROR: modify \"$string\" failed with $ret"
			exit $ret
		fi
		assertExpectedFeedCount "$withAdditionalFeedCount"

		"$OPKG_FEED" remove "$string asdf" --conf-dir "$CONF_DIR" &> /dev/null
		ret=$?
		if [[ "$ret" != '0' ]] ; then
			echo "ERROR: remove \"$string\" failed with $ret"
			exit $ret
		fi
		assertExpectedFeedCount "$initialFeedCount"
	done

	set -H
}

# -----------------------------------------------------------------------------
# main()
# -----------------------------------------------------------------------------

mkdir -p "$CONF_DIR"
export OPKG_FEED=${OPKG_FEED_PATH:-${DEFAULT_OPKG_FEED_PATH}}
echo "Testing opkg-feed script '$OPKG_FEED'"

happyPathTest
dirtyTest

if ! rmdir "$CONF_DIR" ; then
	exit 1
fi
echo "OK!"
exit 0
