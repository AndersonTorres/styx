#!/usr/bin/env bash

#-------------------------------
#
# Styx test script
#
# This will run most of the styx tasks in /tmp/styx-test
# Use with care as during the test it will bind port 8080, and kill every caddy processes
#
#-------------------------------

target=/tmp
name="styx-test"
dir="$target/$name"
themesDir="$target/$name/themes"
totalTests=0
successTests=0
cleanup=0

sep (){
  echo -e "\n---\n"
}


while [ "$#" -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --cleanup)
      cleanup=1
      ;;
    *)
      echo "$0: unknown option \`$i'"
      exit 1
      ;;
  esac
done

echo -e "\nStyx test suite"

sep

#-------------------------------
#
# Building Styx
#
#-------------------------------

totalTests=$(( totalTests + 1 ))
echo "Building Styx:"
styxPath=$(nix-build --quiet --no-out-link)

if [ $? -eq 0 ]; then
  styx="$styxPath/bin/styx"
  $styx --version
  echo "Success!"
  successTests=$(( successTests + 1 ))
else
  echo "Could not build styx, exiting test suite"
  exit 1
fi

sep

#-------------------------------
#
# Styx new
#
#-------------------------------

totalTests=$(( totalTests + 1 ))

echo "Testing 'styx new':"

$styx new site $name --in $target

if [ $? -eq 0 ]; then
  echo "Success!"
  successTests=$(( successTests + 1 ))
else
  echo "Could not create the Styx site, exiting test suite."
  exit 1
fi

sep

#-------------------------------
#
# Getting themes
#
#-------------------------------

echo "Getting all the themes:"

git clone --depth 1 --recursive https://github.com/styx-static/themes.git "$themesDir"

sep

#-------------------------------
#
# Styx build
#
#-------------------------------

for theme in $themesDir/*/ ; do

  totalTests=$(( totalTests + 1 ))

  echo "Testing 'styx build' on $theme example site:"

  $styx build --in "$theme/example"

  if [ $? -eq 0 ]; then
    echo "Success!"
    successTests=$(( successTests + 1 ))
  else
    echo "Failure"
  fi

  sep

done

# Using showcase for all the following tests
showcaseExample=$themesDir/showcase/example

#-------------------------------
#
# Styx preview
#
#-------------------------------

totalTests=$(( totalTests + 1 ))

echo "Testing 'styx preview':"

$styx preview --in $showcaseExample --detach
serveOk=$?

# wait the server is ready
sleep 1

curl -s -o "/dev/null" http://127.0.0.1:8080
curlOk=$?

if [ $serveOk -eq 0 ] && [ $curlOk -eq 0 ]; then
  echo "Success!"
  successTests=$(( successTests + 1 ))
else
  echo "Failure"
fi

# killing the server
pidof caddy | xargs kill -9

sep

#-------------------------------
#
# Styx serve
#
#-------------------------------

totalTests=$(( totalTests + 1 ))

echo "Testing 'styx serve':"

$styx serve --site-url "http://127.0.0.1" --in $showcaseExample --detach
serveOk=$?

# wait the server is ready
sleep 1

curl -s -o "/dev/null" http://127.0.0.1:8080
curlOk=$?

if [ $serveOk -eq 0 ] && [ $curlOk -eq 0 ]; then
  echo "Success!"
  successTests=$(( successTests + 1 ))
else
  echo "Failure"
fi

# killing the server
pidof caddy | xargs kill -9

sep

#-------------------------------
#
# Styx deploy
#
#-------------------------------

totalTests=$(( totalTests + 1 ))

echo "Testing 'styx deploy --init-gh-pages':"

# Making a git repository in the test directory
(
  cd $showcaseExample
  git init
  git add .
  git commit -m "init"
)

$styx deploy --init-gh-pages --in $showcaseExample

if [ $? -eq 0 ]; then
  echo "Success!"
  successTests=$(( successTests + 1 ))
else
  echo "Failure."
fi

sep

totalTests=$(( totalTests + 1 ))

echo "Testing 'styx deploy --gh-pages':"

$styx deploy --gh-pages --in $showcaseExample

if [ $? -eq 0 ]; then
  echo "Success!"
  successTests=$(( successTests + 1 ))
else
  echo "Failure."
fi

sep

#-------------------------------
#
# Finishing
#
#-------------------------------

if [ $cleanup -eq 1 ]; then
  echo "Cleaning up:"
  if [ -e $dir ] && [ -d $dir ]; then
    rm -fr "$dir"
  fi
  sep
fi

echo "Test results: $successTests/$totalTests"

sep

echo -e "Finished!\n"
