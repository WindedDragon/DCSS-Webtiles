#!/bin/bash
set -e

exec gosu crawl "$@"
