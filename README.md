```
 _
(_)
 _ _ __ ___   __ _ _ __  ___ _   _ _ __   ___ ______ _ __ ___   __ _ _ __   __ _  __ _  ___ _ __
| | '_ ` _ \ / _` | '_ \/ __| | | | '_ \ / __|______| '_ ` _ \ / _` | '_ \ / _` |/ _` |/ _ \ '__|
| | | | | | | (_| | |_) \__ \ |_| | | | | (__       | | | | | | (_| | | | | (_| | (_| |  __/ |
|_|_| |_| |_|\__,_| .__/|___/\__, |_| |_|\___|      |_| |_| |_|\__,_|_| |_|\__,_|\__, |\___|_|
                  | |         __/ |                                               __/ |
                  |_|        |___/                                               |___/
```

# DESCRIPTION

imapsync-manager - bash script is an add-on for the imapsync utility, the script helps to migrate and check the size of the mail, it also determines the mailboxes with which there are access problems, the script is notable for the fact that it displays accurate and understandable information in a human-readable form.

# INSTALLATION

!ATTENTION - *the utility itself must already be installed in the system, check it simply by running imapsync in the console
if the utility is missing, install following the author's instructions *  https://imapsync.lamiral.info/#install

```
git clone https://github.com/solo10010/imapsync-manager
cd imapsync-manager
chmod +x sync.sh
./sync.sh --help
```

To use the utility on mailboxes, create a listmail.txt file

```
touch listmail.txt
```

Fill out the file following this template

```
host001_1;user001_1;password001_1;host001_2;user001_2;password001_2;
host002_1;user002_1;password002_1;host002_2;user002_2;password002_2;
host003_1;user003_1;password003_1;host003_2;user003_2;password003_2;
```

# REFERENCE

```
~/imapsync-manager (master*) # ./sync.sh --help

 Usage: ./sync.sh [options...] -f --file <email_sunc.txt>
                -m --migrate <start_mail_migrate> -s --size <check_mail_size>

  -f, --file            <mail.txt> Selecting a file with entered boxes for transfer
  -m, --migrate         Run mail migration from file selected to -f
  -s, --size            check mail size on portable and migrated mailboxes from a file -f
  -p, --port            pass default SMTP port value always 993

  An example of filling mailboxes into a file for transfer

  host001_1;user001_1;password001_1;host001_2;user001_2;password001_2;
  host002_1;user002_1;password002_1;host002_2;user002_2;password002_2;
  host003_1;user003_1;password003_1;host003_2;user003_2;password003_2;

```

# LAUNCH EXAMPLES

Check mailbox size
```
./sync.sh --file listmail.txt --size
```

Run migration of all mailboxes

```
./sync.sh --file listmail.txt --migrate
```
Run mailbox size check by port 143
```
./sync.sh --file listmail.txt --port 143 --size
```

Examples of utility output in different launch modes

```
~/imapsync-manager (master*) # ./sync.sh --file listmail.txt --size
==================== start check mails (3)  =====================
perenos1@oibai.ru: success login MailSize:5.14 MB Folder:5 -> perenos2@oibai.ru: success login MailSize:5.14 MB Folder:5 <-> SUCCES!
perenos3@oibai.ru: success login MailSize:0 KB Folder:5 -> perenos4@oibai.ru: success login MailSize:0 KB Folder:5 <-> SUCCES!
perenos3@oibai.ru: failed login MailSize:0 KB Folder: -> perenos4@oibai.ru: failed login MailSize:0 KB Folder: <X> FAILED!

====================== SOURCE MAIL ==============================
SOURCE      Total Mail Size: 5.14 MB
SOURCE      Total Folder Count: 10
=================== DESTANATION MAIL ============================
DESTENATION Total Mail Size:  5.14 MB
DESTENATION Total Folder Count: 10

============ Error Summary sync_errors.log ======================
NO ERROR LOG FILE

```

```
~/imapsync-manager (master*) # ./sync.sh --file listmail.txt --migrate
================== start migrate mails (3)  =====================
perenos1@oibai.ru: success login -> perenos1@oibai.ru: success login -> SUCCES!
perenos3@oibai.ru: success login -> perenos3@oibai.ru: success login -> SUCCES!
perenos3@oibai.ru: failed login -> perenos3@oibai.ru: failed login -X FAILED!

============ Error Summary sync_errors.log ======================
NO ERROR LOG FILE
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
~/imapsync-manager (master*) #
```



