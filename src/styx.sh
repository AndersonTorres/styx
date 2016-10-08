#! @shell@

#-------------------------------

# Functions

#-------------------------------

# Show help
display_usage() {
  cat << EOF
Styx $version -- Styx is a functional static site generator in Nix expression language.

Usage:

  styx <subcommand> options

Subcommands:
    new, n FOLDER              Create a new Styx site in FOLDER.
    build                      Build the site in the "public" or "--out" folder.
    preview                    Build the site and serve it locally, shortcut for 'styx serve --site-url "http://HOST:PORT"'.
                               This override the configuration file 'siteUrl' to not break links.
    live                       Similar to preview, but automatically rebuild the site on changes.
    serve                      Build the site and serve it.
    deploy                     Deploy the site, must be used with a deploy option.

Generic options:
    -h, --help                 Show this help.
    -v, --version              Print the name and version.
        --arg ARG VAL          Pass an argument ARG with the value VAL to the build and serve subcommands.
        --argstr ARG VAL       Pass an argument ARG with the value VAL as a string to the build and serve subcommands.
        --show-trace           Show debug trace messages.

Build options:
    -o, --out                  Set the build output, "public" by default.
        --drafts               Process and render drafts.

Serve options:
    -p, --port PORT            Set the server listening port number to PORT, default is "8080".
        --site-url URL         Override configuration "siteUrl" setting with the URL value.
        --server-host HOST     Set the server listening host to HOST, default is "127.0.0.1".
        --detach               Detach the server from the terminal.
        --drafts               Process and render drafts.

Deploy options:
    --init-gh-pages            If in a git repository, will create a gh-pages branch wit a .styx file.
    --gh-pages                 Build the site, copy the build results in the gh-pages branch and make a commit.

EOF
# Dev options:
#   --DEBUG                    Print the commands instead of running them, do not work with 'styx live'
    exit 0
}

# last changed timestamp
last_timestamp() {
  find . ! -path '*.git/*' ! -name '*.swp' -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f1 -d"."
}

# last changed date
last_change() {
  lastTimestamp=$(last_timestamp)
  date -d @"$lastTimestamp" -u +%Y-%m-%dT%TZ
}

# print a list of commands
print_commands(){
  echo -e "DEBUG MODE:\n\n---\n"
  for i in "${cmd[@]}"; do
    echo $i
  done
  echo -e "\n---\n"
}

# run a list of commands
run_commands(){
  for i in "${cmd[@]}"; do
    eval $i
  done
}

# current branch name
current_branch(){
  git rev-parse --symbolic-full-name --abbrev-ref HEAD
}


#-------------------------------

# Variables

#-------------------------------

# styx version
version=@version@
# original arguments
origArgs=("$@")
# action to execute
action=
# directory of this script
dir="$(dirname "${BASH_SOURCE[0]}")"
# styx share directory
share="$dir/../share/styx"
# debug mode
debug=
# list of commands that will run
cmd=()
# extra arguments to be appended to the nix-build command
extraFlags=()

# target default folder for the new action
target="styx-site"

# output for the build action
output="public"

# server program
server=@server@
# hostname or ip the server is listening on
serverHost="127.0.0.1"
# port used by the server
port=8080
# site url to use
siteUrl=
# run the server in background process
detachServer=

# deploy subcommand
deployAction=

if [ $# -eq 0 ]; then
  display_usage
  exit 1
fi


#-------------------------------

# Option parsing

#-------------------------------


while [ "$#" -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
# Generic options
	  -h|--help)
	    Display_usage
	    ;;
	  -v|--version)
      echo -e "styx $version"
	    ;;
    --arg|--argstr)
      extraFlags+=("$i" "$1" "$2"); shift 2
      ;;
    --show-trace)
      extraFlags+=("$i")
      ;;
# Commands
    new|n)
      action="$i"
      if [ -n "$1" ]; then
        target="$1"; shift 1
      fi
      ;;
	  build)
	    action="$i"
	    ;;
	  serve)
	    action="$i"
	    ;;
	  deploy)
	    action="$i"
	    ;;
	  preview)
	    action="serve"
      siteURL="PREVIEW"
	    ;;
    live)
      action="$i"
      ;;
# Build options
    --drafts)
      extraFlags+=(--arg renderDrafts true)
      ;;
	  -o|--output)
	    output="$1"; shift 1
	    ;;
# Serve options
	  -p|--port)
	    port="$1"; shift 1
	    ;;
	  --server-host)
	    serverHost="$1"; shift 1
	    ;;
	  --site-url)
	    siteUrl="$1"; shift 1
      ;;
	  --detach)
      detachServer=1
      ;;
# Deploy options
    --init-gh-pages)
      deployAction="init-gh-pages"
      ;;
    --gh-pages)
      deployAction="gh-pages"
      ;;
# Dev options
    --DEBUG)
      debug=1
      ;;
    *)
      echo "$0: unknown option \`$i'"
      exit 1
      ;;
  esac
done


#-------------------------------

# New

#-------------------------------

if [ "$action" = new ]; then
  folder="$(pwd)/$target"
  if [ -d "$folder" ]; then
    cmd+=("echo \"$target directory exists\"")
    cmd+=("exit 1")
  else
    cmd+=("mkdir \"\$folder\"")
    cmd+=("cp -r $share/sample/* \"$folder/\"")
    cmd+=("chmod -R u+rw $folder")
    cmd+=("echo -e \"New styx site installed in '$folder'.\"")
  fi
fi


#-------------------------------
#
# Build
#
#-------------------------------

if [ "$action" = build ]; then
  if [ -f $(pwd)/default.nix ]; then
    if [ -d "$(pwd)/$output" ]; then
      cmd+=("echo \"'\$output' folder already exists, doing nothing.\"")
      cmd+=("exit 1")
    else
      cmd+=("echo \"Building the site...\"")
      cmd+=("path=\$(nix-build --quiet --no-out-link --argstr lastChange \"$(last_change)\" \"${extraFlags[@]}\")")
      # copying the build results as normal files
      cmd+=("\$(cp -L -r \"\$path\" \"$output\")")
      # fixing permissions
      cmd+=("\$(chmod u+rw -R \"$output\")")
      cmd+=("echo \"Build in '$output' finished\"")
    fi
  else
    cmd+=("echo \"No 'default.nix' in current directory\"")
    cmd+=("exit 1")
  fi
fi


#-------------------------------
#
# Serve
#
#-------------------------------

if [ "$action" = serve ]; then
  if [ -f $(pwd)/default.nix ]; then
    siteUrlFlag=
    if [ -n "$siteURL" ]; then
      if [ "$siteURL" = "PREVIEW" ]; then
        siteUrlFlag="--argstr siteUrl \"http://$serverHost:$port\""
      else
        siteUrlFlag="--argstr siteUrl \"$siteURL\""
      fi
    fi
    cmd+=("path=\$(nix-build --quiet --no-out-link --argstr lastChange \"$(last_change)\" $siteUrlFlag \"${extraFlags[@]}\")")
    if [ -n "$detachServer" ]; then
      cmd+=("$server --root \"\$path\" --host \"$serverHost\" --port \"$port\" >/dev/null &")
      cmd+=("serverPid=\$!")
      cmd+=("echo \"server listening on http://$serverHost:$port qith pid ${serverPid}\"")
    else
      cmd+=("echo \"server listening on http://$serverHost:$port\"")
      cmd+=("echo \"press Ctrl+C to stop\"")
      cmd+=("\$($server --root \"\$path\" --host \"$serverHost\" --port \"$port\")")
    fi
  else
    cmd+=("echo \"No 'default.nix' in current directory\"")
    cmd+=("exit 1")
  fi
fi


#-------------------------------
#
# Live
#
#-------------------------------

# Note: debug is not available in live mode
if [ "$action" = live ]; then
  serverPid=
  if [ -f $(pwd)/default.nix ]; then
    # get last change
    lastChange=$(last_timestamp)
    # building to result a first time
    path=$(nix-build --no-out-link --quiet --argstr lastChange "$(last_change)" --argstr siteUrl "http://$serverHost:$port" "${extraFlags[@]}")
    # start the server
    $server --root "$path" --host "$serverHost" --port "$port" >/dev/null &
    echo "Started live preview on http://$serverHost:$port"
    echo "Press q to quit"
    # saving the pid
    serverPid=$!
    while true; do
      curLastChange=$(last_timestamp)
      if [ "$curLastChange" -gt "$lastChange" ]; then
        # rebuild
        echo "Change detected, rebuilding..."
        path=$(nix-build --no-out-link --quiet --argstr lastChange "$(last_change)" --argstr siteUrl "http://$serverHost:$port" "${extraFlags[@]}")
        #echo "$path"
        # kill the server
        echo "Restarting the server..."
        disown "$serverPid"
        kill -9 "$serverPid"
        # start the server
        $server --root "$path" --host "$serverHost" --port "$port" >/dev/null &
        echo "Done!"
        # updating the pid
        serverPid=$!
        # sleep a little to avoid chained rebuilds
        sleep 3
        # update the timestamp
        lastChange=$(last_timestamp)
      fi
      read -t 1 -N 1 input
      if [[ $input = "q" ]] || [[ $input = "Q" ]]; then
        disown "$serverPid"
        kill -9 "$serverPid"
        echo -e "\rBye!"
        echo
        break
      fi
    done
  fi
fi


#-------------------------------
#
# Deploy
#
#-------------------------------

if [ "$action" = deploy ]; then
  if [ "$deployAction" == "init-gh-pages" ]; then
    if [ -d $(pwd)/.git ]; then
      cmd+=("git checkout --orphan gh-pages")
      cmd+=("git rm -rf .")
      cmd+=("touch .styx")
      cmd+=("git add .styx")
      cmd+=("git commit -m \"initialized gh-pages branch\"")
      cmd+=("git checkout \"$(current_branch)\"")
      cmd+=("echo \"Successfully created the 'gh-pages' branch.\"")
      cmd+=("echo \"You can now update the 'gh-pages' branch by running 'styx deploy --gh-pages'.\"")
    else
      cmd+=("echo \"Not in a git repository, doing nothing.\"")
      cmd+=("exit 1")
    fi
  elif [ "$deployAction" == "gh-pages" ]; then
    if [ -d $(pwd)/.git ]; then
      if [ -n "$(git show-ref refs/heads/gh-pages)" ]; then
        # Everytime a checkout is done, files atime and ctime are modified
        # This means that 2 consecutive styx deploy --gh-pages will update the lastChange
        # and update the feed
        cmd+=("echo \"Building the site\"")
        cmd+=("path=\$(nix-build --quiet --no-out-link --argstr lastChange \"\$(last_change)\" \"\${extraFlags[@]}\")")
        cmd+=("git checkout gh-pages")
        cmd+=("\$(cp -L -r \"\$path\"/* ./)")
        cmd+=("\$(chmod u+rw -R ./)")
        cmd+=("git add .")
        cmd+=("git commit -m \"Styx update - \$(git rev-parse --short HEAD)\"")
        cmd+=("git checkout \"$(current_branch)\"")
        cmd+=("echo \"Successfully updated the gh-pages branch.\"")
        cmd+=("echo \"Push the 'gh-pages' branch to the GitHub repository to publish your site.\"")
      else
        cmd+=("echo \"There is no 'gh-pages' branch, run 'styx deploy --init-gh-pages' to GiHub pages deployment it..\"")
        cmd+=("exit 1")
      fi
    else
      cmd+=("echo \"Not in a git repository, doing nothing.\"")
      cmd+=("exit 1")
    fi
  fi
fi


#-------------------------------
#
# Debug
#
#-------------------------------

if [ -n "$debug" ]; then
  print_commands cmd
else
  run_commands cmd
fi
