#!/bin/bash

# Function to list files in a container
list_files() {
    docker exec $1 ls /data/
}

# Function to sort files by length and return only names
sort_files() {
    docker exec $1 sh -c "ls /data/ | xargs -I{} wc -c /data/{} | sort -n | awk '{print \$2}'"
}

# Create and initialize the final text file
final_book_chapter="final_book_chapter.txt"
echo "Creating Final Book Chapter..." > $final_book_chapter

# List and sort files in each container
files_docker1=($(list_files docker1-container))
sorted_files_docker1=($(sort_files docker1-container))
sorted_files_docker2=($(sort_files docker2-container))
files_docker3=($(list_files docker3-container))

# Round Robin assembly
index=0
max_length=$(( ${#sorted_files_docker1[@]} > ${#sorted_files_docker2[@]} ? ${#sorted_files_docker1[@]} : ${#sorted_files_docker2[@]} ))
max_length=$(( $max_length > ${#files_docker3[@]} ? $max_length : ${#files_docker3[@]} ))

while [ $index -lt $max_length ]; do
    if [ $index -lt ${#sorted_files_docker1[@]} ]; then
        echo "Appending from Docker 1: ${sorted_files_docker1[$index]}" >> $final_book_chapter
        docker exec docker1-container cat "/data/${sorted_files_docker1[$index]}" >> $final_book_chapter
        echo -e "\n---\n" >> $final_book_chapter
    fi
    if [ $index -lt ${#sorted_files_docker2[@]} ]; then
        echo "Appending from Docker 2: ${sorted_files_docker2[$index]}" >> $final_book_chapter
        docker exec docker2-container cat "/data/${sorted_files_docker2[$index]}" >> $final_book_chapter
        echo -e "\n---\n" >> $final_book_chapter
    fi
    if [ $index -lt ${#files_docker3[@]} ]; then
        echo "Appending from Docker 3: ${files_docker3[$index]}" >> $final_book_chapter
        docker exec docker3-container cat "/data/${files_docker3[$index]}" >> $final_book_chapter
        echo -e "\n---\n" >> $final_book_chapter
    fi
    let "index++"
done

echo "Final Book Chapter created: $final_book_chapter"

