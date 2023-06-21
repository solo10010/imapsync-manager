#!/bin/bash

function help(){
	echo ""
	echo " Использование: ./sync.sh [options...] -f --file <email_sunc.txt> 
		-m --migrate <start_mail_migrate> -s --size <check_mail_size>"
	echo ""
	echo "  -f, --file 		<mail.txt> Выбор файла с внесенными ящиками для переноса"
	echo "  -m, --migrate 	Запустить миграцию почты из файла выбранного в -f"
        echo "  -s, --size 		проверить размер почты на переносимых и перенесенных ящиках из файла -f"
	echo ""
	echo "  Пример заполнения почтовых ящиков в файл для переноса"
	echo ""
	echo "  хост001_1;пользователь001_1;пароль001_1;хост001_2;пользователь001_2;пароль001_2;"
        echo "  хост002_1;пользователь002_1;пароль002_1;хост002_2;пользователь002_2;пароль002_2;"
	echo "  хост003_1;пользователь003_1;пароль003_1;хост003_2;пользователь003_2;пароль003_2;"
	echo ""
	exit
}

# парсим аргументы

if [[ -z "$1" ]]
then
	help # вызывает справка
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--file)
    file="$2"
    shift # past argument
    shift # past value
    if [[ -z $file ]]
    then
	    echo " -f, --file этот параметр должен быть заполенн путем к файлу"
	    echo "  -h, --help справка по sync.sh"
	    exit
    fi
    ;;
    -m|--migrate)
    migrate="$1"
    shift # past argument
    shift # past value
    ;;
    -s|--size)
    size="$1"
    shift # past argument
    shift # past value
    ;;
    -h|--help) # справка
    shift # past argument
    shift # past value
    help # функция вызывает показ справки
    ;;
    *) # обработка неизвестных параметров
    echo "  Неизвестный параметр: $key"
    echo "  -h, --help справка по sync.sh"
    exit 1
    ;;
esac
done

# бьем по рукам юзеров

# Проверка, задан ли обязательный параметр -f, --file
if [[ -z $file ]]; then
    echo "  Не задан обязательный параметр --file"
    echo "  -h, --help справка по sync.sh"
    exit 1
fi

# создаем папку лога

mkdir -p /tmp/sync_debug/

# оперделяем некоторые переменные

log_dir="/tmp/sync_debug/"


# функция конвертировани киобайт в мегабайты и гигабайты

convert_to_size() {
    local size_kb=$1

    if (( size_kb >= 1024 * 1024 )); then
        # Преобразовать в гигабайты
        size_gb=$(awk "BEGIN { printf \"%.2f\", $size_kb / (1024 * 1024) }")
        echo "${size_gb} GB"
    elif (( size_kb >= 1024 )); then
        # Преобразовать в мегабайты
        size_mb=$(awk "BEGIN { printf \"%.2f\", $size_kb / 1024 }")
        echo "${size_mb} MB"
    elif (( size_kb > 0 )); then
        echo "${size_kb} KB"
    else
        echo "${size_kb} KB"
    fi
}



# функции операций подсчета размера и маграций

function check_size(){
mail_file_count=$(wc -l "$file")
echo "==================== start check mails ($mail_file_count)  ====================="

all_src_mail_size="0"
all_dest_mail_size="0"

all_src_folder_count="0"
all_dest_folder_count="0"

{
    while IFS=';' read -r h1 u1 p1 h2 u2 p2
    do
	log_name="${log_dir}out_${u1}_sunc_${u2}" 
        imapsync --justfoldersizes \
                 --host1 "$h1" --user1 "$u1" --password1 "$p1" --port1 993  --ssl1 --notls1 \
                 --host2 "$h2" --user2 "$u2" --password2 "$p2" --nossl2 --notls2 --debug > "$log_name" 2>&1 
	# Грепаем и выводим результаты красиво
	# Грепаем количество папок 
	host1_folder=$(grep -oP 'Host1 Nb folders:\s+\K\d+' "$log_name")
	host2_folder=$(grep -oP 'Host2 Nb folders:\s+\K\d+' "$log_name")
	host1_size=$(grep -oP 'Host1 Total size:\s+\K\d+' "$log_name")
	host2_size=$(grep -oP 'Host2 Total size:\s+\K\d+' "$log_name")

	host1_checksize_auth_on=$(grep -oP 'Host1: success login' "$log_name" | grep -oP 'success login')
	host1_checksize_auth_error=$(grep -oP 'Host1: failed login' "$log_name" | grep -oP 'failed login')
	host2_checksize_auth_on=$(grep -oP 'Host2: success login' "$log_name" | grep -oP 'success login')
	host2_checksize_auth_error=$(grep -oP 'Host2: failed login' "$log_name" | grep -oP 'failed login')	

	if [[ $host1_checksize_auth_on == "success login" ]] && [[ $host2_checksize_auth_on == "success login" ]]; then
		host1_convert_size=$(convert_to_size "$host1_size")
		host2_convert_size=$(convert_to_size "$host2_size")
  		echo "$u1: $host1_checksize_auth_on$host1_checksize_auth_error MailSize:$host1_convert_size Folder:$host1_folder -> $u2: $host2_checksize_auth_on$host2_checksize_auth_error MailSize:$host2_convert_size Folder:$host2_folder <-> SUCCES!"
	elif [[ $host1_checksize_auth_error != "failed login" ]] || [[ $host2_checksize_auth_error != "failed login" ]]; then
    		echo "$u1: $host1_checksize_auth_on$host1_checksize_auth_error MailSize:$host1_convert_size Folder:$host1_folder -> $u2: $host1_checksize_auth_on$host1_checksize_auth_error MailSize:$host2_convert_size Folder:$host2_folder -X FAILED!"
	else
    		echo "$u1: $host1_checksize_auth_on$host1_checksize_auth_error MailSize:$host1_convert_size Folder:$host1_folder -> $u2: $host1_checksize_auth_on$host1_checksize_auth_error MailSize:$host2_convert_size Folder:$host2_folder <X> FAILED!"
	fi


	(("all_src_mail_size=all_src_mail_size+host1_size"))
	(("all_dest_mail_size=all_dest_mail_size+host2_size"))

	(("all_src_folder_count=all_src_folder_count+host1_folder"))
	(("all_dest_folder_count=all_dest_folder_count+host2_folder"))

    done

} < "$file"

# Сконвертим полное значение в МБ ГБ
total_src_mail_size=$(convert_to_size "$all_src_mail_size")
total_dest_mail_size=$(convert_to_size "$all_dest_mail_size")
echo ""
echo "====================== SOURCE MAIL =============================="
echo "SOURCE      Total Mail Size: $total_src_mail_size"
echo "SOURCE      Total Folder Count: $all_src_folder_count"
echo "=================== DESTANATION MAIL ============================"
echo "DESTENATION Total Mail Size:  $total_dest_mail_size"
echo "DESTENATION Total Folder Count: $all_dest_folder_count"
echo ""
echo "============ Error Summary sync_errors.log ======================"

if [[ -f "LOG_imapsync/sync_errors.log" ]]; then
	cat LOG_imapsync/sync_errors.log
else
	echo "NO ERROR LOG FILE"
fi

}

function migrate(){
mail_file_count=$(wc -l "$file")
echo "================== start migrate mails ($mail_file_count)  ====================="


{
    while IFS=';' read -r h1 u1 p1 h2 u2 p2
    do
        log_name="${log_dir}out_${u1}_sunc_${u2}"
        imapsync \
                 --host1 "$h1" --user1 "$u1" --password1 "$p1" --port1 993  --ssl1 --notls1 \
                 --host2 "$h2" --user2 "$u2" --password2 "$p2" --nossl2 --notls2 --debug > "$log_name" 2>&1
		# Грепаем успешную аутентификацию в ящик и не успешную
		host1_migrate_auth_on=$(grep -oP 'Host1: success login' "$log_name" | grep -oP 'success login')
		host1_migrate_auth_error=$(grep -oP 'Host1: failed login' "$log_name" | grep -oP 'failed login')
		host2_migrate_auth_on=$(grep -oP 'Host2: success login' "$log_name" | grep -oP 'success login')
		host2_migrate_auth_error=$(grep -oP 'Host2: failed login' "$log_name" | grep -oP 'failed login')
		
		if [[ $host1_migrate_auth_on == "success login" ]] && [[ $host2_migrate_auth_on == "success login" ]]; then
			echo "$u1: $host1_migrate_auth_on$host1_migrate_auth_error -> $u1: $host2_migrate_auth_on$host2_migrate_auth_error -> SUCCESS!"
		elif [[ $host1_migrate_auth_error != "failed login" ]] || [[ $host2_migrate_auth_error != "failed login" ]]; then 
			echo "$u1: $host1_migrate_auth_on$host1_migrate_auth_error -> $u1: $host2_migrate_auth_on$host2_migrate_auth_error -X FAILED!"
		else
			echo "$u1: $host1_migrate_auth_on$host1_migrate_auth_error -> $u1: $host2_migrate_auth_on$host2_migrate_auth_error -X FAILED!"
		fi
    done

} < "$file"

echo ""
echo "============ Error Summary sync_errors.log ======================"
if [[ -f "LOG_imapsync/sync_errors.log" ]]; then
        cat LOG_imapsync/sync_errors.log
else
        echo "NO ERROR LOG FILE"
fi

}


function install(){
 echo "install"
}


function init(){ # запуск проверок и всех функций в скрипте
	
	if [[ -n $size ]]; then # чекаем размер
		check_size
	elif [[ -n $migrate ]]; then # мигрируем почту
		migrate
	fi

}


init # запускаем стартовую функцию





