#!/bin/bash

# allgemeine Variablen
source_directory="/home/isa03/TestOrdner" # von welchem Ordner wird ein Backupgemacht (Dokumente innerhalb von diesem Ordner)
backup_destination="/home/isa03/BackupOrdner" # wo kommt das Backup hin
timestamp=$(date +%Y-%m-%d_%H:%M:%S)

# Variablen für inkrementelles Backup
incr_backup_foldername="incr_${timestamp}"
incr_backup_folderpath="${backup_destination}/${incr_backup_foldername}" # Fullpath zum inkrementelle Backupordner

# Variablen für Fullbackup
full_backup_foldername="full_${timestamp}" # Name vom Backup-Ordner
full_backup_folderpath="${backup_destination}/${full_backup_foldername}" # Fullpath zum Fullbackupordner



# prüft ob der Pfad gültig ist
function pfad_gueltig() {
	if [[ -d "$source_directory" ]]; then # -d signalisiert dass $pfad vom Datentyp directory sein sollte um gültig(true) zu sein
		return 0
	else
		echo "$source_directory is not a valid path."
		return 1
	fi
}

# Funktion für inkrementelles Backup
function incr() {
	if pfad_gueltig "$source_directory"; then

		# get latest backup timestamp
		latest_backup=$(ls -dt "${backup_destination}"/{incr,full}_* 2>/dev/null | head -n 1) #holds the path to the directory where the backups are stored 
	    
	    if [ -n "$latest_backup" ]; then #Checks if the variable is non-empty (-n, string lenght = zero); if non-empty = backup found
	        latest_timestamp=$(basename "$latest_backup" | sed -E 's/^(full|incr)_([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}:[0-9]{2}:[0-9]{2})$/\2 \3/')

	        # Convert the timestamp to the format required by touch (YYYYMMDDHHMM.SS)
	        latest_touch_timestamp=$(date -d "$latest_timestamp" +%Y%m%d%H%M.%S)
	    else
	        echo "No backups found."
	        latest_touch_timestamp="197001010000.00" # Use a default old timestamp if no backups exist
	    fi

	    	# create new incremental backup folder
			mkdir -p "${incr_backup_folderpath}"
			echo "New backup folder created: $incr_backup_folderpath"

			# Create a reference file with the latest backup timestamp
			reference="${backup_destination}/latest_backup_time"
			touch -t "$latest_touch_timestamp" "$reference"

			# Find new or modified files since the last backup
			new_files=$(find "$source_directory" -type f -newer "$reference") # timestamp comparison

		if [ -n "$new_files" ]; then
	    	echo "New or modified files in $source_directory found, copying them to the new backup folder..."
		    
	    	while IFS= read -r file; do
	        	# Copy the file to the new backup folder
	        	cp "$file" "$incr_backup_folderpath"
	    	done <<< "$new_files"
		    
	    	echo "Incremental backup completed: $incr_backup_folderpath"
	    	echo "incremental backup created" >> /home/isa03/BackupScripts/backup_log.txt
		else
	    	echo "No new or modified files since the last backup"
		fi

		cd $backup_destination
		rm latest_backup_time
	fi
}


# Funktion für Full-Backup
function full() {
	# Wenn Pfad gültig ist, führt das Programm den if-Teil aus, wenn der Pfad NICHT gültig ist, führt er den else-Teil aus
	if pfad_gueltig "$source_directory"; then
		
		# Erstelle neuen Backupfolder
		mkdir -p $full_backup_folderpath
		echo "New backup folder created: $full_backup_folderpath"

		# Files werden rüberkopiert in Backupordner
		echo "All files from $source_directory are being copied..."
		cp -a "${source_directory}/." "${full_backup_folderpath}"

		# Output
		echo "Fullbackup completed: $full_backup_folderpath"
		echo "fullbackup created" >> /home/isa03/BackupScripts/backup_log.txt
	fi
}

case "$1" in
	full)
		full
		;;
	incr)
		incr
		;;
	*)
		echo "Usage: $0 {full|incr}"
		exit 1
		;;
esac
