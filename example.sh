#!/bin/bash

# Function to list files in a container
list_files() {
    docker exec $1 ls /data/
}

# Function to sort files by length
sort_files() {
    docker exec $1 sh -c "ls /data/ | xargs -I{} wc -c /data/{} | sort -n"
}

# Main script starts here

# List files in each container
files_docker1=$(list_files docker1-container)
files_docker2=$(list_files docker2-container)
files_docker3=$(list_files docker3-container)

# Sort files in docker1 and docker2
sorted_files_docker1=$(sort_files docker1-container)
sorted_files_docker2=$(sort_files docker2-container)

# Combine file names into an array
IFS=$'\n' sorted_files_docker1=($sorted_files_docker1)
IFS=$'\n' sorted_files_docker2=($sorted_files_docker2)
IFS=$'\n' files_docker3=($files_docker3)

# Round Robin assembly
final_text=""
index=0
max_length=$(echo "${#sorted_files_docker1[@]} ${#sorted_files_docker2[@]} ${#files_docker3[@]}" | awk '{print ($1>$2)? (($1>$3)? $1:$3) : (($2>$3)? $2:$3)}')

while [ $index -lt $max_length ]; do
    if [ $index -lt ${#sorted_files_docker1[@]} ]; then
        file_name=$(echo "${sorted_files_docker1[$index]}" | awk '{print $2}')
        final_text+=$(docker exec docker1-container cat /data/$file_name)
    fi
    if [ $index -lt ${#sorted_files_docker2[@]} ]; then
        file_name=$(echo "${sorted_files_docker2[$index]}" | awk '{print $2}')
        final_text+=$(docker exec docker2-container cat /data/$file_name)
    fi
    if [ $index -lt ${#files_docker3[@]} ]; then
        final_text+=$(docker exec docker3-container cat /data/${files_docker3[$index]})
    fi
    let "index++"
done

# Output the final text
echo "$final_text" > final_book_chapter.txt
