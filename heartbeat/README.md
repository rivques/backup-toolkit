# heartbeat
send a ping to healthchecks.io with machine info.

## setup
copy `.env.example` to `.env`.
go to healthchecks.io. create a new check w/ a 10min period. copy the ping url to heartbeat/.env file.
run `./healthcheck-heartbeat.sh` to test the script, `chmod +x` if needed.
run `crontab -e` and add the following line to run every 10 minutes:
```
*/10 * * * * $HOME/Documents/backup-toolkit/heartbeat/healthcheck-heartbeat.sh
```