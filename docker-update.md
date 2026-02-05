# docker-update.sh
### Description
Write log messages in json format

### Usage:
```bash
# docker-update.sh ?
fatal: File "?" not found

Usage:
  docker-update.sh {docker compose file}

Examples:
  Update all container from docker-compose file
  $ docker-update.sh docker-compose.yml
```

### Script output example:
```bash
$ docker-update.sh
[info]  Start update container: omada
[debug] Current container image: da2ae97ea953
[debug] Current container version:
[+] Pulling 7/7
 ✔ omada-controller 6 layers [⣿⣿⣿⣿⣿⣿]  0B/0B  Pulled  24.0s
   ✔ 0a3cf3b5b88b Pull  complete  0.9s
   ✔ 7224150b4198 Pull complete   0.5s
   ✔ 630002fb3dda Pull complete   5.0s
   ✔ 082678bd9f38 Pull complete   1.0s
   ✔ 4f4fb700ef54 Pull complete   1.4s
   ✔ 24a2edeae4eb Pull complete   6.2s
[+] Building 0.0s (0/0)           docker:default
[+] Running 1/1
 ✔ Container omada  Started      15.5s
[debug] New container image: 3a16b0c229fa
[debug] New container version:
[info]  Image version has changed
[debug] Write in log file: "/data/omada/update_history_omada_log.jsonl"
[info]  Finised update container: omada
```

### License
See repository license file.

