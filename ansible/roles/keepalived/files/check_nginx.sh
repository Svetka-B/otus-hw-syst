#!/bin/bash
curl -fsS http://127.0.0.1/nginx-health >/dev/null || exit 1
exit 0
