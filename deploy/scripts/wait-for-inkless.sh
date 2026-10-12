#!/bin/sh
set -eu

url="http://127.0.0.1:8080/"

attempt=1
while [ "$attempt" -le 60 ]; do
    if /usr/bin/curl --silent --fail --max-time 2 "$url" --output /dev/null; then
        echo "Inkless is responding through Nginx."
        exit 0
    fi

    sleep 3
    attempt=$((attempt + 1))
done

echo "Inkless did not become ready through Nginx within five minutes." >&2
exit 1
