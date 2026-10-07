# Shell Scripting – Homework

> Evidence refreshed: previous screenshots showed a different terminal account and have been removed. Historical output blocks below remain reference examples. Fresh checks from this repository are linked at the end; they validate only their stated scope.


**Name:** Mayank Gupta
**Roll No:** 24BCS10220

## Task: System Information Script

Script: [shellscript.sh](shellscript.sh)

| Requirement | How the script does it |
|---|---|
| Print the current date | `current_date=$(date)` then `echo` |
| Print the hostname | `host_name=$(hostname)` |
| Print the username | `user_name=$(whoami)` |
| Print the disk usage | `df -h` |
| Print the running processes | `ps` |
| Use variables | `current_date`, `host_name`, `user_name`, `work_dir`, `log_file`, `name`, `roll_no`, `comment` |
| Take user input | `read -p "Enter your name: " name` |
| Create a directory | `mkdir -p "$work_dir"` |
| Create a file | `touch "$log_file"` |
| Store the processes in the file using `>` | `ps > "$log_file"` |

## The script

```bash
#!/bin/bash
# System Information Script - DevOps Homework (Shell Scripting)

# Variables to store and reuse data
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)
work_dir="system_info"
log_file="$work_dir/process.log"

echo "========== System Information =========="
echo "Current date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"

echo
echo "========== Disk Usage =========="
df -h

echo
echo "========== Running Processes =========="
ps

# Take user input using read -p
echo
read -p "Enter your name: " name
read -p "Enter your roll number: " roll_no
read -p "Enter your comment: " comment

echo "My name is $name"
echo "My roll number is $roll_no"
echo "My comment is: $comment"

# Create a directory using mkdir and a file using touch
mkdir -p "$work_dir"
touch "$log_file"

# Store the running processes in the file using > output redirection
ps > "$log_file"

echo
echo "Directory '$work_dir' created"
echo "Process information saved in '$log_file'"
```

## How to run

```bash
chmod +x shellscript.sh
./shellscript.sh
```

## Output

The script was run inside the `ubuntu:24.04` container (the same environment used for the Linux tasks), so the process list stays short and readable. For this capture the three answers were sent to the script through a pipe, so the `read -p` prompts are not printed (bash only shows the prompt when the input comes from a terminal). When run by hand, the prompts `Enter your name:`, `Enter your roll number:` and `Enter your comment:` appear one by one.

```text
$ printf 'Mayank Gupta\n24BCS10220\nShell scripting homework\n' | ./shellscript.sh
========== System Information ==========
Current date : Thu Sep 17 17:30:13 UTC 2026
Hostname     : devops-lab
Username     : root

========== Disk Usage ==========
Filesystem              Size  Used Avail Use% Mounted on
overlay                 911G  153G  712G  18% /
tmpfs                    64M     0   64M   0% /dev
shm                      64M     0   64M   0% /dev/shm
/run/host_mark/private  927G  457G  470G  50% /work
/dev/vda1               911G  153G  712G  18% /etc/hosts
tmpfs                   4.0K     0  4.0K   0% /proc/scsi

========== Running Processes ==========
  PID TTY          TIME CMD
    1 ?        00:00:00 bash
  138 ?        00:00:00 bash
  143 ?        00:00:00 ps

My name is Mayank Gupta
My roll number is 24BCS10220
My comment is: Shell scripting homework

Directory 'system_info' created
Process information saved in 'system_info/process.log'
```

### Directory and file created by the script

```text
$ ls -la system_info
total 4
drwxr-xr-x 3 root root  96 Sep 17 17:30 .
drwxr-xr-x 6 root root 192 Sep 17 17:30 ..
-rw-r--r-- 1 root root 113 Sep 17 17:30 process.log

$ cat system_info/process.log
  PID TTY          TIME CMD
    1 ?        00:00:00 bash
  138 ?        00:00:00 bash
  146 ?        00:00:00 ps
```

The two `ps` snapshots differ by one PID (`143` vs `146`) because the `ps` inside the script and the `ps` that wrote the log file are two separate invocations, each getting its own process ID.

## What I understood

- `$(command)` stores the output of a command in a variable.
- `read -p "text" var` prints a prompt and saves what the user types in `var`.
- `>` overwrites the file with the command output, while `>>` appends to it.
- `mkdir -p` does not fail if the directory already exists, so the script can be run many times.
- Variables should be quoted (`"$log_file"`) so that paths with spaces do not break the script.

## Fresh evidence — Mayank Gupta (24BCS10220)

Representative checks for this topic ran in this repository’s GitHub Actions workflow. See the [expanded lab README](../Shell%20Scripting/README.md) for the exact execution scope.

![Mayank Gupta — actual CI check](../Shell%20Scripting/screenshots/validation.png)

[Full command log](../Shell%20Scripting/screenshots/validation.log) · [Run metadata](../Shell%20Scripting/screenshots/validation.json)
