#!/bin/bash

set_default() {
  local name=$1
  local default_value=$2

  # Устанавливает значение переменной только если она не существует
  # Если переменной установлено значение пустая строка - она останется пустой строкой
  export "$name=${!name-$default_value}"
}

filename=".env"
if [ -f "${filename}" ]; then
    set -a
    source "${filename}"
    set +a
fi

set_default "LOG_COLOR_TYPE" "2"


