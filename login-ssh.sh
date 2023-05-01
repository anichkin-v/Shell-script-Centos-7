#!/usr/bin/env bash

# Basic info
source /etc/os-release
if [[ -z "$PRETTY_NAME" ]]; then
  HOSTNAME="Not available"
else
  HOSTNAME="$PRETTY_NAME"
fi

# Check which web servers are installed
WEB="Not installed"
WEB2="Not installed"
WEB_COMMANDS=("nginx" "httpd")
for cmd in "${WEB_COMMANDS[@]}"; do
  if command -v "$cmd" &>/dev/null; then
    version="$($cmd -v 2>&1 | awk -F/ '{print $2}')"
    case "$cmd" in
      "nginx") WEB="$version" ;;
      "httpd") WEB2="$version" ;;
    esac
  fi
done

# Check which PHP versions are installed
PHP="Not installed"
PHP_COMMANDS=("php")
for cmd in "${PHP_COMMANDS[@]}"; do
  if command -v "$cmd" &>/dev/null; then
    PHP="$($cmd -r 'echo PHP_VERSION;')"
    break
  fi
done

# Check which databases are installed
DB_PGSQL="Not installed"
DB_MYSQL="Not installed"
DB_COMMANDS=("psql" "mysql")
for cmd in "${DB_COMMANDS[@]}"; do
  if command -v "$cmd" &>/dev/null; then
    version="$($cmd -V 2>&1 | awk -F/ '{print $1}')"
    case "$cmd" in
      "psql") DB_PGSQL="$version" ;;
      "mysql") DB_MYSQL="$version" ;;
    esac
  fi
done

# Get system info
TIME=$(date -u)
UPTIME=$(uptime -p)
MEMORY=$(awk '/MemTotal/{total=$2}/MemFree/{free=$2}END{printf "%.2f/%.2f G", (total-free)/1024/1024, total/1024/1024}' /proc/meminfo 2>/dev/null || echo "Not available")

# Print banner after successful SSH login
echo "  ┬┌┐┌┌─┐┌─┐  ┌─┐┌─┐┬─┐┬  ┬┌─┐┬─┐"
echo "  ││││├┤ │ │  └─┐├┤ ├┬┘└┐┌┘├┤ ├┬┘"
echo "  ┴┘└┘└  └─┘  └─┘└─┘┴└─ └┘ └─┘┴└─"
echo -e " \033[32m "- Version OS ...........: " "$HOSTNAME"\033[0m"
echo -e " \033[35m "- Nginx WEB Server .....: " "$WEB"\033[0m"
echo -e " \033[35m "- Apache WEB Server ....: " "$WEB2"\033[0m"
echo -e " \033[34m "- PHP Version ..........: " "$PHP"\033[0m"
echo -e " \033[33m "- PostgreSQL Version ...: " "$DB_PGSQL"\033[0m"
echo -e " \033[33m "- MySQL Version ........: " "$DB_MYSQL"\033[0m"
echo -e " \033[32m "- Date/Time ............: " "$TIME"\033[0m"
echo -e " \033[31m "- Uptime ...............: " "$UPTIME"\033[0m"
echo -e " \033[31m "- Memory Used/Total ....: " "$MEMORY"\033[0m"
export PS1='[\u@\h \W]\$ '
