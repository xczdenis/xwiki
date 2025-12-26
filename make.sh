#!/usr/bin/env bash

source ./load_env.sh
source ./scripts/logger.sh
source ./scripts/utils.sh
source ./scripts/cli.sh

DEFAULT_HOST="http://${XWIKI_HOST:-localhost}"
DEFAULT_PORT="${XWIKI_PORT:-8080}"

down() {
    log_header "Останавливаю запущенные контейнеры"
    docker compose down
}

up() {
    log_header "Запускаю сервисы"
    docker compose up -d --build
}

run() {
    host="${CLI_ARG_HOST:-${DEFAULT_HOST}}"
    port="${CLI_ARG_PORT:-${DEFAULT_PORT}}"
    
    down
    if [[ $? -ne 0 ]]; then
        log_error "Не удалось остановить запущенные контейнеры!"
        exit 1
    fi

    up
    if [[ $? -ne 0 ]]; then
        log_error "Не удалось запустить сервис!"
        exit 1
    fi

    log_info "Вики доступна по адресу: ${color_warn}${host}:${port}/${color_reset}"

}

backup() {
    (. scripts/backup.sh "$@")
}

restore() {
    (. scripts/restore-volumes-from-back.sh "$@")
}

# Команды
add_cmd down "Остановить и удалить все запущенные контейнеры"

add_cmd up "Запустить докер сервисы, запущенные контейнеры не удаляются"

add_cmd run "Запустить докер сервисы, перед этим запущенные контейнеры будут удалены"
add_cmd_arg run host "${DEFAULT_HOST}" "Хост (пример: http://10.76.35.141)"
add_cmd_arg run port "${DEFAULT_PORT}" "Порт (пример: 8080)"

add_cmd backup "Создать бекапы докер томов"
add_cmd restore "Восстановить докер тома из бекапов"

# ---------- старт ----------
cli_run "$@"
