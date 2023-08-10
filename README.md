# Bash scripts

## Scripts
### borg_backup.sh
Create backups with borgbackup
#### Usage:
```bash
$ ./borg_backup.sh --help
Usage:
  ./borg_backup.sh [-ehpvV] [--env file] [--prune]

Options:
  -e, --env          Set borg_backup.env (required)
  -h, --help         Display this help and exit
  -p, --prune        Prune borg backups
  -v, --verbose      Print debugging messages
  -V, --version      Display the version number and exit

Examples:
  Create backup
  $ ./borg_backup.sh --env borg_backup.env

  Prune backups
  $ ./borg_backup.sh --env borg_backup.env --prune
```


## License
See repository license file.
