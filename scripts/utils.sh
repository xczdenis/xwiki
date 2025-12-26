#!/usr/bin/env bash

[ "${UTILS_SH_GUARD:-}" ] && return
UTILS_SH_GUARD=1

. ./scripts/logger.sh

check_service() {
    service_name=${1}
    host=${2}
    port=${3}
    timeout=${4:-30}

    log_info "Waiting for the service: ${color_purple}${service_name} (url=${host}:${port})${color_reset}"
    if ./scripts/wait-for-it.sh "${host}":"${port}" -t "${timeout}" --; then
        log_success "Сервис '${service_name}' доступен!${color_reset}"
    else
        log_error "Сервис '${service_name}' не доступен!${color_reset}"
        exit 1
    fi
    echo ""
}

check_env_is_activated() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo "${color_red}ERROR: Python virtual environment is not activated!${color_reset}"
        echo "Please make sure that virtual environment is activated and then run your command again."
        exit 1
    fi
}

to_upper() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

create_or_overwrite_file() {
    local source_file="$1"
    local target_file="$2"

    if [ -f "$target_file" ]; then
        read -p "Файл ${color_info}$target_file${color_reset} уже существует. Перезаписать его? [${color_yellow}y/n${color_reset}]: " yn
        case $yn in
            [Yy]* )
                cp "$source_file" "$target_file"
                echo "Файл ${color_info}$target_file${color_reset} перезаписан!"
                ;;
            * )
                echo "Ничего не произошло."
                ;;
        esac
    else
        cp "$source_file" "$target_file"
        echo "Файл ${color_info}$target_file${color_reset} создан из ${color_info}$source_file${color_reset}!"
    fi
}

check_required_vars() {
    local missing_vars=()
    for var_name in "$@"; do
        if [[ -z "${!var_name}" ]]; then
            log_error "Не заполнена переменная ${color_info}${var_name}${color_reset}"
            missing_vars+=("$var_name")
        fi
    done

    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        return 1
    fi
}

check_required_params() {
    local missing_vars=()
    for var_name in "$@"; do
        if [[ -z "${!var_name}" ]]; then
            log_error "Не предан параметр ${color_info}${var_name}${color_reset}"
            missing_vars+=("$var_name")
        fi
    done

    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        return 1
    fi
}

# Функция формирует строку подключения вида "server_name/db_name"
build_connection_string() {
    local server_name="$1"
    local db_name="$2"

    local result=""

    if [[ "$server_name" != "" && "$server_name" != "" ]]; then
        result="${server_name}/${db_name}"
    fi

    echo "$result"
    return 0
}

# Сборка всех файлов из указанной директории в одну папку.
# Важно!!! При выполнении операции папка назначения будет удалена, а потом создана заново
# Параметры:
#   1: Путь к исходной папке, откуда будут копироваться файлы.
#   2: Путь к папке назначения, в которую будут сложены все файлы. !!! Будет удалена перед выполнением скрипта
#
collect_files() {
    local src="$1"   # исходная папка
    local dst="$2"   # папка назначения

    # 1. Проверяем, что папки разные
    [[ "$src" -ef "$dst" ]] && {
        echo "Исходная и целевая папки совпадают."
        return 1
    }

    # 2. Готовим папку назначения
    rm -rf -- "$dst"
    mkdir -p -- "$dst"

    # 3. Копируем все обычные файлы за 1-2 прохода
    #    -exec ... {} + собирает много имён за раз
    find "$src" -type f -exec cp -t "$dst" -- {} + || return 2

    return 0
}

# Архивация файлов из указанной директории.
# Параметры:
#   1: Путь к исходной папке, откуда будут копироваться файлы.
#   2: Путь к архиву. Указывается без расширения tar.
#
# Функция создает временную папку в указанном месте назначения, копирует туда все файлы из исходной директории,
# архивирует эту папку в файл tar и удаляет временную папку.
# Название архива совпадает с названием временной папки, добавляется расширение .tar.
archive_files() {
    local source_dir="$1"  # Путь к исходной папке
    local destination_dir="$2"  # Путь к папке назначения
    local destination_dir_tmp="$destination_dir"_tmp
    local destination_tar="$destination_dir".tar  # Полный путь к архиву

    # Проверяем, не является ли исходная и целевая папка одной и той же
    if [[ "$source_dir" -ef "$destination_dir" ]]; then
        echo "Исходная и целевая папка совпадают."
        return 1
    fi

    # Проверка и удаление существующей директории
    if [[ -d "$destination_dir_tmp" ]]; then
        rm -rf "$destination_dir_tmp"
    fi
    if [[ -f "$destination_tar" ]]; then
        rm -f "$destination_tar"
    fi

    mkdir -p "$destination_dir_tmp"

    # Находим все файлы в исходной папке и копируем их в новую папку
    find "$source_dir" -type f -exec cp {} "$destination_dir_tmp" \; || {
        return 2
    }

    tar -cf "$destination_tar" -C "$destination_dir_tmp" . || {
        rm -rf "$destination_dir_tmp"  # Очистка после неудачной попытки
        return 3
    }

    rm -r "$destination_dir_tmp"

    return 0
}

# Функция заменяет переменные окружения в переданному файле и создает временную копию файл
replace_env_vars() {
    local file="$1"
    local tmp_file="$file.tmp"
    log_debug "Делаю бекап файла '$file' в '$tmp_file'"
    cp "$file" "$tmp_file"
    log_debug "Заменяю переменные окружения в файле '$file' на их значения"

    # Команда envsubst не обрабатывает кирилицу
    # envsubst < "$tmp_file" > "$file"

    perl -pe 's/\$(\w+)/$ENV{$1}/g' "$tmp_file" > "$file"
}

# Функция для восстановления файла из временной копии
restore_backup() {
    local file="$1"
    local tmp_file="$file.tmp"
    if [[ -f "$tmp_file" ]]; then
        log_debug "Восстанавливаю файл '$file' из бекапа '$tmp_file'"
        cp "$tmp_file" "$file"
        log_debug "Удаляю бекап '$tmp_file'"
        rm -f "$tmp_file"
    fi
}

run_command_with_logs() {
    header=${1}
    command=${2}

    echo ""
    echo "[= ${color_blue}${header}${color_reset} =]"
    echo "${color_yellow}run command: ${color_purple}${command}${color_reset}"
    eval "${command}" || true
}
