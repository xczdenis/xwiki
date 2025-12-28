#!/usr/bin/env bash
set -euo pipefail

source ./load_env.sh
source ./scripts/logger.sh

log_header "Бекап докер томов xwiki"

# Настройки
BACKUP_ROOT="${XWIKI_BACKUP_ROOT:-backup}"
KEEP="${XWIKI_MAX_BACKUPS:-2}"

# Volumes
XWIKI_VOL="${COMPOSE_PROJECT_NAME}_${XWIKI_DATA_VOL}"
POSTGRES_VOL="${COMPOSE_PROJECT_NAME}_${XWIKI_POSTGRES_VOL}"

# Каталоги сервисов
XWIKI_DIR="${BACKUP_ROOT}/xwiki-web"
POSTGRES_DIR="${BACKUP_ROOT}/xwiki-db"

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
  log_error "Были ошибки"
  exit 1
fi

# Дата
TS="$(date +%Y_%m_%d_%H_%M)"

mkdir -p "${XWIKI_DIR}" "${POSTGRES_DIR}"

log_info "Сохраняю том ${color_purple}'${XWIKI_VOL}'${color_info} в директорию ${color_purple}'$(pwd)/${XWIKI_DIR}'${color_info}"
docker run --rm \
  -v "${XWIKI_VOL}":/data:ro \
  -v "/$(pwd)/${XWIKI_DIR}":/backup \
  alpine \
  tar czf "/backup/${XWIKI_VOL}_${TS}.tar.gz" -C /data .
log_success "Том ${color_purple}'${XWIKI_VOL}'${color_success} успешно сохранен здесь ${color_purple}'$(pwd)/${XWIKI_DIR}'${color_success}"

log_info "Сохраняю том ${color_purple}'${POSTGRES_VOL}'${color_info} в директорию ${color_purple}'$(pwd)/${POSTGRES_DIR}'${color_info}"
docker run --rm \
  -v "${POSTGRES_VOL}":/data:ro \
  -v "/$(pwd)/${POSTGRES_DIR}":/backup \
  alpine \
  tar czf "/backup/${POSTGRES_VOL}_${TS}.tar.gz" -C /data .
log_success "Том ${color_purple}'${POSTGRES_VOL}'${color_success} успешно сохранен здесь ${color_purple}'$(pwd)/${POSTGRES_DIR}'${color_success}"

log_info "Выполняю ротацию бекапов (максимальное количество бекапов: ${KEEP})"
ls -1t "${XWIKI_DIR}"/*.tar.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
ls -1t "${POSTGRES_DIR}"/*.tar.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f

log_success "Готово!"
