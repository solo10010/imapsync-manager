#!/bin/bash

# defining some variables

log_dir="/tmp/sync_debug/"
smtp_port="993"

function help(){
        echo ""
        echo " Usage: ./sync.sh [options...] -f --file <email_sunc.txt>
                -m --migrate <start_mail_migrate> -s --size <check_mail_size>"
        echo ""
        echo "  -f, --file              <mail.txt> Selecting a file with entered boxes for transfer"
        echo "  -m, --migrate   Run mail migration from file selected to -f"
    echo "  -s, --size          check mail size on portable and migrated mailboxes from a file -f"
    echo "  -p, --port          pass default SMTP port value always 993"
        echo ""
        echo "  An example of filling mailboxes into a file for transfer"
        echo ""
        echo "  host001_1;user001_1;password001_1;host001_2;user001_2;password001_2;"
        echo "  host002_1;user002_1;password002_1;host002_2;user002_2;password002_2;"
        echo "  host003_1;user003_1;password003_1;host003_2;user003_2;password003_2;"
        echo ""
        exit
}

# parse arguments

if [[ -z "$1" ]]
then
        help # calls help
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
            echo " -f, --file this parameter must be filled with the path to the file"
            echo "  -h, --help help on sync.sh"
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
    -p|--port)
    port="$1"
    smtp_port="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help) # reference
    shift # past argument
    shift # past value
    help # function calls help display
    ;;
    *) # processing of unknown parameters
    echo "  unknown parameter: $key"
    echo "  -h, --help help on sync.sh"
    exit 1
    ;;
esac
done

# hit on the hands of users

# Checking if a required parameter is set -f, --file
if [[ -z $file ]]; then
    echo "  Required parameter not set --file"
    echo "  -h, --help help on sync.sh"
    exit 1
fi

# create a log folder

mkdir -p $log_dir

# function to convert kiobytes to megabytes and gigabytes

convert_to_size() {
    local size_bytes=$1

    if (( size_bytes >= 1024 * 1024 * 1024 * 1024 )); then
        # Convert to terabytes
        size_tb=$(awk "BEGIN { printf \"%.2f\", $size_bytes / (1024 * 1024 * 1024 * 1024) }")
        echo "${size_tb} TB"
    elif (( size_bytes >= 1024 * 1024 * 1024 )); then
        # Convert to gigabytes
        size_gb=$(awk "BEGIN { printf \"%.2f\", $size_bytes / (1024 * 1024 * 1024) }")
        echo "${size_gb} GB"
    elif (( size_bytes >= 1024 * 1024 )); then
        # Convert to megabytes
        size_mb=$(awk "BEGIN { printf \"%.2f\", $size_bytes / (1024 * 1024) }")
        echo "${size_mb} MB"
    elif (( size_bytes >= 1024 )); then
        # Convert to kilobytes
        size_kb=$(awk "BEGIN { printf \"%.2f\", $size_bytes / 1024 }")
        echo "${size_kb} KB"
    else
        echo "${size_bytes} B"
    fi
}




# functions of size counting and magration operations

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
                 --host1 "$h1" --user1 "$u1" --password1 "$p1" --port1 $smtp_port  --ssl1 --notls1 \
                 --host2 "$h2" --user2 "$u2" --password2 "$p2" --nossl2 --notls2 --debug > "$log_name" 2>&1
        # Grab and display the results beautifully
        # Grab the number of folders
        host1_folder=$(grep -oaP 'Host1 Nb folders:\s+\K\d+' "$log_name")
        host2_folder=$(grep -oaP 'Host2 Nb folders:\s+\K\d+' "$log_name")
        host1_size=$(grep -oaP 'Host1 Total size:\s+\K\d+' "$log_name")
        host2_size=$(grep -oaP 'Host2 Total size:\s+\K\d+' "$log_name")

        host1_checksize_auth_on=$(grep -oaP 'Host1: success login' "$log_name" | grep -oP 'success login')
        host1_checksize_auth_error=$(grep -oaP 'Host1: failed login' "$log_name" | grep -oP 'failed login')
        host2_checksize_auth_on=$(grep -oaP 'Host2: success login' "$log_name" | grep -oP 'success login')
        host2_checksize_auth_error=$(grep -oaP 'Host2: failed login' "$log_name" | grep -oP 'failed login')

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

# Convert full value to MB GB
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
                 --host1 "$h1" --user1 "$u1" --password1 "$p1" --port1 $smtp_port  --ssl1 --notls1 \
                 --host2 "$h2" --user2 "$u2" --password2 "$p2" --nossl2 --notls2 --debug > "$log_name" 2>&1
                # We grab successful authentication in the box and not successful
                host1_migrate_auth_on=$(grep -oaP 'Host1: success login' "$log_name" | grep -oP 'success login')
                host1_migrate_auth_error=$(grep -oaP 'Host1: failed login' "$log_name" | grep -oP 'failed login')
                host2_migrate_auth_on=$(grep -oaP 'Host2: success login' "$log_name" | grep -oP 'success login')
                host2_migrate_auth_error=$(grep -oaP 'Host2: failed login' "$log_name" | grep -oP 'failed login')

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


function init(){ # running checks and all functions in the script

        if [[ -n $size ]]; then # check the size
                check_size
        elif [[ -n $migrate ]]; then # migrating mail
                migrate
        fi

}


init # run start function

