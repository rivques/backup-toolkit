# backup-scripts

Make a copy of config.sh.example for each repo you want to back up to, and fill them out (e.g. config-rd and config-ns). Store the repo passwords somewhere safe.

Install backup-system.timer for once-morningly backups.

Optional: To receive email on failures, install and configure msmtp for the user running the scripts. Set EMAIL_ON_ERROR_TO (or MAILTO) in your config file. You can also set EMAIL_FROM and EMAIL_SUBJECT_PREFIX.