#! /bin/bash
# run the command on --local, --remote, or --all repositories

source "all-config.sh"

case "$1" in
    --local)
        repos=("${!repos_local[@]}")
        ;;
    --remote)
        repos=("${!repos_remote[@]}")
        ;;
    --all)
        repos=("${!repos_all[@]}")
        ;;
    *)
        echo "Invalid option. Use --local, --remote, or --all."
        exit 1
        ;;
esac

shift 1
command="$@"

for repo in "${repos[@]}"; do
    export RESTIC_REPOSITORY="$repo"
    export RESTIC_PASSWORD="${repos_all[$repo]}"
    echo "Running \"restic $command\" on $RESTIC_REPOSITORY..."
    restic $command
done