#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: backup-one-config-file.sh /path/to/config.sh
# On any error, this script will send an email if EMAIL_ON_ERROR_TO (or MAILTO) is set
# in the sourced config file or the environment. Optional: EMAIL_FROM, EMAIL_SUBJECT_PREFIX.

if [[ ${1:-} == "" ]]; then
	echo "Usage: $(basename "$0") /path/to/config.sh" >&2
	exit 2
fi

CONFIG_FILE=$1
CONFIG_BASENAME=$(basename -- "$CONFIG_FILE")
HOSTNAME_FQDN=$(hostname -f 2>/dev/null || hostname)
START_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Capture all output to a log file while still printing to console
LOG_FILE=$(mktemp -t backup-one-XXXXXX.log)
cleanup_log() { [[ -f "$LOG_FILE" ]] && rm -f "$LOG_FILE" || true; }
trap cleanup_log EXIT
exec > >(tee -a "$LOG_FILE") 2>&1

send_email() {
	# subject, body
	local subject=$1
	local body=$2
	local to=${EMAIL_ON_ERROR_TO:-${MAILTO:-}}
	if [[ -z "$to" ]]; then
		echo "[warn] EMAIL_ON_ERROR_TO/MAILTO not set; skipping error email" >&2
		return 0
	fi

	# Prefer msmtp if present
	if command -v msmtp >/dev/null 2>&1; then
		{
			printf "From: %s\n" "${EMAIL_FROM:-backup@${HOSTNAME_FQDN}}"
			printf "To: %s\n" "$to"
			printf "Subject: %s\n" "$subject"
			printf "MIME-Version: 1.0\n"
			printf "Content-Type: text/plain; charset=UTF-8\n\n"
			printf "%s\n" "$body"
		} | msmtp --read-envelope-from -t || echo "[warn] msmtp failed to send email" >&2
		return 0
	fi

	# Fallbacks if msmtp is not available
	if command -v sendmail >/dev/null 2>&1; then
		{
			printf "From: %s\n" "${EMAIL_FROM:-backup@${HOSTNAME_FQDN}}"
			printf "To: %s\n" "$to"
			printf "Subject: %s\n" "$subject"
			printf "MIME-Version: 1.0\n"
			printf "Content-Type: text/plain; charset=UTF-8\n\n"
			printf "%s\n" "$body"
		} | sendmail -t || echo "[warn] sendmail failed to send email" >&2
	elif command -v mail >/dev/null 2>&1; then
		printf "%s\n" "$body" | mail -s "$subject" "$to" || true
	elif command -v mailx >/dev/null 2>&1; then
		printf "%s\n" "$body" | mailx -s "$subject" "$to" || true
	else
		echo "[warn] no mailer available; could not send email" >&2
	fi
}

on_error() {
	# prevent re-entry loops and allow best-effort reporting
	local exit_code=$?
	trap - ERR
	set +e
	local failed_cmd=${BASH_COMMAND}
	local line_no=${BASH_LINENO[0]:-?}
	local when=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

	# Compose email subject/body
	local prefix=${EMAIL_SUBJECT_PREFIX:-"[backup]"}

	# Tail the log to keep message size reasonable
	local log_tail
	log_tail=$(tail -n 500 "$LOG_FILE" 2>/dev/null || true)

	# Minimal config context (may be empty if failure before sourcing)
	local repo=${RESTIC_REPOSITORY:-"(unknown)"}
	local subject="$prefix FAILURE on $HOSTNAME_FQDN: $CONFIG_BASENAME -> $repo"

	read -r -d '' body <<EOF || true
Backup failed
Host:        $HOSTNAME_FQDN
When (UTC):  $when (started $START_TS)
Config:      $CONFIG_FILE
Repository:  $repo
Exit code:   $exit_code
Failed at:   line $line_no: $failed_cmd

Last 500 lines of log ($LOG_FILE):
------------------------------------------------------------
$log_tail
------------------------------------------------------------
EOF

	send_email "$subject" "$body"

	# also echo a concise failure line for logs
	echo "[error] Backup failed (config: $CONFIG_BASENAME, repo: $repo)" >&2
	exit "$exit_code"
}
trap on_error ERR

source "$CONFIG_FILE"
echo "Backing up to $RESTIC_REPOSITORY (from $CONFIG_FILE)..."

eval "$BEFORE_BACKUP_COMMAND"

restic backup --one-file-system $PATHS_TO_BACKUP --exclude="$EXCLUDE" -vv

restic unlock

restic forget --retry-lock 1m --prune $RETENTION_POLICY

eval "$AFTER_BACKUP_COMMAND"

echo "Backup completed successfully for $RESTIC_REPOSITORY"