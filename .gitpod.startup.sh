#!/bin/bash

# start docker if not running
if ! pgrep -x "docker-up" > /dev/null
then
  sudo docker-up &
fi

# wait for docker to run
while ! pgrep -x "docker-up" > /dev/null; do
  sleep 1
done

CONTAINER=affinity_dashboard_1

if [[ $(docker inspect --format '{{json .State.Running}}' $CONTAINER) != true ]]; then
  echo "containers not running"
  export VUE_APP_PARSE_URL=$(gp url 8080)/parse
  docker-compose up &
else
  echo "running"
fi

# Set timeout to the number of seconds you are willing to wait.
timeout=500; counter=0

# This first echo is important for keeping the output clean and not overwriting the previous line of output.
echo "Waiting for $CONTAINER to be ready (${counter}/${timeout})"

#This says that until docker inspect reports the container is in a running state, keep looping.
until [[ $(docker inspect --format '{{json .State.Running}}' $CONTAINER) == true ]]; do
  # If we've reached the timeout period, report that and exit to prevent running an infinite loop.
  if [[ $timeout -lt $counter ]]; then
    echo "ERROR: Timed out waiting for $CONTAINER to come up."
    exit 1
  fi

  # Every 5 seconds update the status
  if (( $counter % 5 == 0 )); then
    echo -e "\e[1A\e[KWaiting for $CONTAINER to be ready (${counter}/${timeout})"
  fi

  # Wait a second and increment the counter
  sleep 1s
  ((counter++))
done

CONTAINER=affinity_mongo_1
echo -e "\e[1A\e[KWaiting for $CONTAINER to be ready (${counter}/${timeout})"

until [[ $(docker inspect --format '{{json .State.Running}}' $CONTAINER) == true ]]; do
  if [[ $timeout -lt $counter ]]; then
    echo "ERROR: Timed out waiting for $CONTAINER to come up."
    exit 1
  fi

  if (( $counter % 5 == 0 )); then
    echo -e "\e[1A\e[KWaiting for $CONTAINER to be ready (${counter}/${timeout})"
  fi

  sleep 1s
  ((counter++))
done

CONTAINER=affinity_parse_1
echo -e "\e[1A\e[KWaiting for $CONTAINER to be ready (${counter}/${timeout})"

until [[ $(docker inspect --format '{{json .State.Running}}' $CONTAINER) == true ]]; do
  if [[ $timeout -lt $counter ]]; then
    echo "ERROR: Timed out waiting for $CONTAINER to come up."
    exit 1
  fi

  if (( $counter % 5 == 0 )); then
    echo -e "\e[1A\e[KWaiting for $CONTAINER to be ready (${counter}/${timeout})"
  fi

  sleep 1s
  ((counter++))
done

sleep 3s

echo "Containers running"

# init db
npm run dev:db

# init db fixtures
npm run dev:db:mock-data

sleep 3s

# create .env file for live server

cat .env.development.local.template > .env.development.local
cat >> .env.development.local << EOF
VUE_APP_PARSE_URL=$(gp url 8080)/parse
EOF

# run parse dev server
(npm run dev:run-parse & npm run serve)
