# docker-update-history.sh
### Description
Show docker update history log

### Usage:
```bash
$ ./docker-update-history.sh
Usage:
  update-container-log.sh {update history JSON file}

Examples:
  Show logs from JSON file
  $ update-container-log.sh update_history_pihole_log.jsonl
```

### JSON log file example:
```json
$ cat update_history_*_log.jsonl
{"timestamp": "2023-11-07 00:34:17", "version": "", "image": "bf5ab2292b67"}
{"timestamp": "2023-11-09 22:43:35", "version": "", "image": "1bb7d7fe8467"}
{"timestamp": "2023-11-11 23:50:11", "version": "", "image": "da2ae97ea953"}
{"timestamp": "2023-11-21 21:34:51", "version": "", "image": "3a16b0c229fa"}
```

### Script output example:
```bash
$ update-container-log.sh update_history_*_log.jsonl
+-----------------------------------------------------+
| Timestamp           | Version        | Image        |
+-----------------------------------------------------+
| 2023-11-07 00:34:17 |                | bf5ab2292b67 |
| 2023-11-09 22:43:35 |                | 1bb7d7fe8467 |
| 2023-11-11 23:50:11 |                | da2ae97ea953 |
| 2023-11-21 21:34:51 |                | 3a16b0c229fa |
+-----------------------------------------------------+
```

### License
See repository license file.
