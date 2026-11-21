
# Automated Backup and Restore Tool

## About
A menu-driven backup and restore utility developed using Bash shell scripting. It automates file backups, restores archived files, schedules recurring backups and maintains operation logs.

## Features
- Create compressed backups using tar and gzip.
- Restore previously created backups.
- Schedule automatic backups using cron.
- Maintain backup and restore logs.
- Search logs using grep.
- Generate backup summaries using awk.
- Clean log files using sed.
- Optional email log reporting.

## Technologies Used
- Bash Shell Scripting
- Unix/Linux Commands
- tar and gzip
- cron
- grep
- awk
- sed

## How to Run

1. Clone the repository:

   git clone https://github.com/YOUR-USERNAME/unix-automated-backup-restore.git

2. Navigate into the folder:

   cd unix-automated-backup-restore

3. Give execution permission:

   chmod +x backup_tool.sh

4. Run the program:

   ./backup_tool.sh

## Platform
Developed and tested on macOS. Some features may require additional configuration on macOS.

