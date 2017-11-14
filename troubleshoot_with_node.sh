#!/bin/bash

CONTAINER=ts_via_nodejs
VERSION=0.0.10
IMAGE='yopgflanbr-node-ts'
NODEJS_SHELL_COMMAND='id'
PORT=8282

main() {
  set -ex
  [[ ! -d tmp41 ]] || rm -rf tmp41
  mkdir tmp41
  cd tmp41 && {
    init;
    local already_image=$(docker images -f=reference="$IMAGE:$VERSION" --format '{{.ID}}')
    [[ $already_image ]] && echo "NOTE: Image '$IMAGE:$VERSION' already exists; not re-building." \
    || { docker_build; }
    local already_running=$(docker ps -f "name=$CONTAINER" --format '{{.ID}}')
    [[ $already_running ]] && { already_running=$(handle_already_running); }
    local container_exists=$(docker ps -a -f "name=$CONTAINER" --format '{{.ID}}')
    [[ $already_running ]] || {
      if [[ $container_exists ]] ; then
        echo "WARNING: Container '$CONTAINER' already exists, albeit stopped. Removing it now."
        docker rm -f $CONTAINER
      fi ;
      echo "NOTE: Not already running. Starting it now."
      echo "NODEJS_SHELL_COMMAND=$NODEJS_SHELL_COMMAND"
      export NODEJS_SHELL_COMMAND_B64=$(echo "$NODEJS_SHELL_COMMAND" | base64)
      echo "NODEJS_SHELL_COMMAND_B64=$NODEJS_SHELL_COMMAND_B64"
      #   -w /$(get_container_volume)/ # Ignored by docker run for some reason.
      docker run --rm -itd --name $CONTAINER \
        -e NODEJS_SHELL_COMMAND_B64 \
        -p $PORT:8080 \
        "$IMAGE:$VERSION" \
      ;
      sleep 5
      curl localhost:$PORT
    }
  }
}
init() {
  cat > server.js <<'EOFsj'
var http = require('http');
var exec = require("child_process").exec;
var handleRequest = function(request, response) {
  console.log('Received request for URL: ' + request.url);
  response.writeHead(200);
  exec('echo $NODEJS_SHELL_COMMAND_B64 | base64 -d | bash -c "$(cat)"', (err, stdout, stderr) => {
    var outputStr;
    if (err) {
      outputStr = 'ERROR: Failed to execute "' + process.env.NODEJS_SHELL_COMMAND_B64 + '": {' + err + '}';
    } else {
      outputStr = `STDOUT: {${stdout}}<br />STDERR: {${stderr}}` ;
    }
    response.write(outputStr);
    response.end();
  });
  //response.end(outputStr);
};
var www = http.createServer(handleRequest);
www.listen(8080);
EOFsj
  cat > Dockerfile <<'EOFd'
FROM node
EXPOSE 8080
COPY server.js .
ENV NODEJS_SHELL_COMMAND_B64='aWQ='
CMD node server.js
EOFd
}



base64_d() {
  echo -n 'base64 '
  local zee='MAo='
  local dash='-'
  echo "$zee" | base64 -d >/dev/null 2>&1 && echo "${dash}d" || echo "${dash}D"
}
docker_build() {
  docker build \
    --rm -t "$IMAGE:$VERSION" .
  #
}
handle_already_running() {
    if running_this_version 1>&2; then
      echo "WARNING: Container '$CONTAINER' is already running." 1>&2 ;
      echo 1
    else
      echo "NOTE: Already running but badly. Stopping and re-running." 1>&2 ;
      docker rm -f $CONTAINER 1>&2 ;
      # already_running=''
      echo ''
    fi ;
}
running_this_version() {
  local what_runs=$(docker ps -a -f "name=$CONTAINER" --format '{{.Image}}')
  [[ $what_runs == "$IMAGE:$VERSION" ]] || {
    echo "NOTE: Already running '$CONTAINER' container is the wrong version. Updating it from $what_runs to version $VERSION.";
    return 1
  }
}



pwd0=$(pwd)
e=''
main || e=$?
cd "$pwd0"
[[ $e -eq 0 ]] || echo "ERROR: $e from main()."

#
