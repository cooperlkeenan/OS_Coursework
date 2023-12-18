#!/bin/bash

# Function to list files in a container
list_files() {
    docker exec $1 ls /data/
}

# Function to sort files by length and return only file names
sort_files() {
    docker exec $1 sh -c "ls /data/ | xargs -I{} wc -c /data/{} | sort -n | awk '{print \$2}'"
}

# Main script starts here

# List and sort files in each container
files_docker1=$(sort_files docker1-container)
files_docker2=$(sort_files docker2-container)
files_docker3=$(list_files docker3-container)

# Convert file lists into arrays
IFS=$'\n' sorted_files_docker1=($files_docker1)
IFS=$'\n' sorted_files_docker2=($files_docker2)
IFS=$'\n' files_docker3=($files_docker3)

# Function to concatenate file contents to the final text file
concatenate_files() {
    local container=$1
    local file_array=("${!2}")
    local index=$3
    local file_name=${file_array[$index]}

    if [ -n "$file_name" ]; then
        docker exec $container cat "/data/$file_name" >> final_book_chapter.txt
        echo "" >> final_book_chapter.txt # Adding a newline for separation
    fi
}

# Round Robin assembly
index=0
max_length=$(echo "${#sorted_files_docker1[@]} ${#sorted_files_docker2[@]} ${#files_docker3[@]}" | awk '{print ($1>$2)? (($1>$3)? $1:$3) : (($2>$3)? $2:$3)}')

> final_book_chapter.txt # Clear or create the final book chapter file

while [ $index -lt $max_length ]; do
    concatenate_files "docker1-container" sorted_files_docker1[@] $index
    concatenate_files "docker2-container" sorted_files_docker2[@] $index
    concatenate_files "docker3-container" files_docker3[@] $index
    let "index++"
done

# Terminal user interface (simplified version)
echo "The Game of Dockers Chapter has been created."
echo "Would you like to read Game of Dockers Chapter? (Yes/No)"
read answer
if [ "$answer" == "Yes" ]; then
    cat final_book_chapter.txt
fi

echo "Would you like to terminate the program? (Yes/No)"
read answer
if [ "$answer" == "Yes" ]; then
    exit 0
fi
