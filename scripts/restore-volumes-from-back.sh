#!/usr/bin/env bash
set -euo pipefail

source ./load_env.sh
source ./scripts/logger.sh

log_header "Восстанавливаю докер тома из бекапов"

BACKUP_ROOT="${XWIKI_BACKUP_ROOT:-backup}"
XWIKI_BACKUP_NAME="xwiki.tar.gz"
POSTGRES_BACKUP_NAME="pg.tar.gz"
XWIKI_DATA_BACKUP="${BACKUP_ROOT}/${XWIKI_BACKUP_NAME}"
POSTGRES_DATA_BACKUP="${BACKUP_ROOT}/${POSTGRES_BACKUP_NAME}"

# Volumes
XWIKI_VOL="${COMPOSE_PROJECT_NAME}_${XWIKI_DATA_VOL}"
POSTGRES_VOL="${COMPOSE_PROJECT_NAME}_${XWIKI_POSTGRES_VOL}"

is_error=0

log_info "Проверяю существование тома ${color_purple}'${XWIKI_VOL}'${color_info}"
if ! docker volume inspect "${XWIKI_VOL}" >/dev/null 2>&1; then
  log_error "Том ${color_purple}'${XWIKI_VOL}'${color_error} не существует!"
  is_error=1
fi

log_info "Проверяю существование тома ${color_purple}'${POSTGRES_VOL}'${color_info}"
if ! docker volume inspect "${POSTGRES_VOL}" >/dev/null 2>&1; then
  log_error "Том ${color_purple}'${POSTGRES_VOL}'${color_error} не существует!"
  is_error=1
fi

if [[ $is_error == 1 ]]; then
  log_error "Тома еще не созданы. Нужно запустить сервисы, чтобы создались тома. Выполните './make.sh run', потом './make.sh down'"
  exit 1
fi

if [[ ! -f "${XWIKI_DATA_BACKUP}" ]]; then
  log_error "Файл '${XWIKI_DATA_BACKUP}' не существует"
  is_error=1
fi

if [[ ! -f "${POSTGRES_DATA_BACKUP}" ]]; then
  log_error "Файл '${POSTGRES_DATA_BACKUP}' не существует"
  is_error=1
fi

if [[ $is_error == 1 ]]; then
  log_error "Были ошибки"
  exit 1
fi

log_info "Восстанавливаю том ${color_purple}'${XWIKI_VOL}'${color_info} из файла ${color_purple}'$(pwd)/${XWIKI_DATA_BACKUP}'${color_info}"
docker run --rm \
  -v "${XWIKI_VOL}":/data \
  -v "/$(pwd)/${BACKUP_ROOT}":/backup \
  alpine \
  tar xzf "/backup/${XWIKI_BACKUP_NAME}" -C /data
log_success "Том ${color_purple}'${XWIKI_VOL}'${color_success} успешно восстановлен!"

log_info "Восстанавливаю том ${color_purple}'${POSTGRES_VOL}'${color_info} из файла ${color_purple}'$(pwd)/${POSTGRES_DATA_BACKUP}'${color_info}"
docker run --rm \
  -v "${POSTGRES_VOL}":/data \
  -v "/$(pwd)/${BACKUP_ROOT}":/backup \
  alpine \
  tar xzf "/backup/${POSTGRES_BACKUP_NAME}" -C /data
log_success "Том ${color_purple}'${POSTGRES_VOL}'${color_success} успешно восстановлен!"

log_success "Готово!"