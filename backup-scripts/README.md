# backup-scripts

Make a copy of config.sh.example for each repo you want to back up to, and fill them out (e.g. config-rd and config-ns). Store the repo passwords somewhere safe.

Install backup-system.timer for once-morningly backups.

Optional: To receive email on failures, install and configure msmtp (with /etc/msmtprc) for the user running the scripts. Set EMAIL_ON_ERROR_TO (or MAILTO) in your config file. You can also set EMAIL_FROM and EMAIL_SUBJECT_PREFIX.

In addition to config.sh.example, also check the existing config-*.sh files on machines.

Here are the commands I ran to set this up on a new server, assuming `rivques` is the username:

```bash
mkdir -p Documents
cd Documents
git clone https://github.com/rivques/backup-toolkit/
cd backup-toolkit/backup-scripts

cp config.sh.example config-ns.sh
nano config-ns.sh
cp config-ns.sh config-rd.sh
nano config-rd.sh

sudo apt install msmtp
sudo nano /etc/msmtprc

sudo apt install restic

./create-repo.sh config-ns.sh
./create-repo.sh config-rd.sh

sudo install -m 644 /home/rivques/Documents/backup-toolkit/backup-scripts/backup-system.service /etc/systemd/system/
sudo install -m 644 /home/rivques/Documents/backup-toolkit/backup-scripts/backup-system.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now backup-system.timer
sudo systemctl status backup-system.timer

sudo ./nightly-backup-and-maint.sh
^C^C
```