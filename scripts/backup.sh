#!/usr/bin/env bash
set -euo pipefail

source ./load_env.sh
source ./scripts/logger.sh

log_header "Бекап докер томов xwiki"

# Настройки
BACKUP_ROOT="${1:-${XWIKI_BACKUP_ROOT:-backup}}"
KEEP="${2:-${XWIKI_MAX_BACKUPS:-2}}"

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

if [[ "${is_error}" == "1" ]]; then
  log_error "Были ошибки"
  exit 1
fi

# Дата (имя папки бекапа)
TS="$(date +%Y_%m_%d_%H_%M)"
BACKUP_DIR="${BACKUP_ROOT}/${TS}"

mkdir -p "${BACKUP_DIR}"

log_info "Сохраняю том ${color_purple}'${XWIKI_VOL}'${color_info} в ${color_purple}'$(pwd)/${BACKUP_DIR}/xwiki.tar.gz'${color_info}"
docker run --rm \
  -v "${XWIKI_VOL}":/data:ro \
  -v "/$(pwd)/${BACKUP_DIR}":/backup \
  alpine \
  tar czf "/backup/xwiki.tar.gz" -C /data .
log_success "Том ${color_purple}'${XWIKI_VOL}'${color_success} сохранен: ${color_purple}'$(pwd)/${BACKUP_DIR}/xwiki.tar.gz'${color_success}"

log_info "Сохраняю том ${color_purple}'${POSTGRES_VOL}'${color_info} в ${color_purple}'$(pwd)/${BACKUP_DIR}/pg.tar.gz'${color_info}"
docker run --rm \
  -v "${POSTGRES_VOL}":/data:ro \
  -v "/$(pwd)/${BACKUP_DIR}":/backup \
  alpine \
  tar czf "/backup/pg.tar.gz" -C /data .
log_success "Том ${color_purple}'${POSTGRES_VOL}'${color_success} сохранен: ${color_purple}'$(pwd)/${BACKUP_DIR}/pg.tar.gz'${color_success}"

log_info "Выполняю ротацию бекапов (максимальное количество папок: ${KEEP})"
mkdir -p "${BACKUP_ROOT}"

# Удаляем старые каталоги, оставляя KEEP самых новых
# Сортировка по имени каталога работает, потому что формат TS лексикографически упорядочен по времени
ls -1d "${BACKUP_ROOT}"/*/ 2>/dev/null |
  sed 's:/*$::' |
  sort -r |
  tail -n +$((KEEP + 1)) |
  while IFS= read -r old_dir; do
    [[ -z "${old_dir}" ]] && continue
    log_info "Удаляю старый бекап: ${color_purple}'${old_dir}'${color_info}"
    rm -rf "${old_dir}"
  done

log_success "Готово!"
