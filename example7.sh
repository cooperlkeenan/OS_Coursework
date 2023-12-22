 #!/bin/bash

# Function to build Docker image and run container for each directory
build_and_run() {
    local docker_dir=$1
    local container_name=$2

    # Navigate to the Docker directory and build the image
    cd "$docker_dir" || exit
    docker build -t "$container_name-image" .

    # Navigate back to the original directory (optional, for clarity)
    cd -

    # Run the container in detached mode
    docker run -dit --name "$container_name" "$container_name-image"
}

# Function to list and sort files by length, returning only file names
sort_files() {
    docker exec "$1" sh -c "ls /usr/src/app | xargs -I{} wc -c /usr/src/app/{} | sort -n | awk '{print \$2}'"
}

# Function to concatenate file contents to the final text file
concatenate_files() {
    local container=$1
    local file_array=("${!2}")
    local index=$3
    local file_name=${file_array[$index]}

    # Skip the Dockerfile
    if [[ "$file_name" == "Dockerfile" ]]; then
        return
    fi

    if [ -n "$file_name" ]; then
        docker exec "$container" cat "/usr/src/app/$file_name" >> book.txt
        echo "" >> book.txt # Adding a newline for separation
    fi
}

# Ensure you're in the directory where Docker1, Docker2, and Docker3 are located
cd ~/coursework1/OS_Coursework

# Build images and run containers
build_and_run "Docker1" "docker1-container"
build_and_run "Docker2" "docker2-container"
build_and_run "Docker3" "docker3-container"


# List and sort files in each container
files_docker1=$(sort_files docker1-container)
files_docker2=$(sort_files docker2-container)
files_docker3=$(docker exec docker3-container ls /usr/src/app)

# Convert file lists into arrays
IFS=$'\n' sorted_files_docker1=($files_docker1)
IFS=$'\n' sorted_files_docker2=($files_docker2)
IFS=$'\n' files_docker3=($files_docker3)

# Clear or create the final book chapter file
> book.txt

# Round Robin assembly
index=0
max_length=$(echo "${#sorted_files_docker1[@]} ${#sorted_files_docker2[@]} ${#files_docker3[@]}" | awk '{print ($1>$2)? (($1>$3)? $1:$3) : (($2>$3)? $2:$3)}')

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
