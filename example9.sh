 #!/bin/bash

# Build Docker image and run container for each directory
build_and_run() {
    local docker_dir=$1
    local container_name=$2
    echo "Building image for $container_name..."

    # Navigate to the Docker directory and build the image
    cd "$docker_dir" || exit
    docker build -t "$container_name-image" . > /dev/null 2>&1 #stops detailed output 

    echo "Running $container_name container..."
    docker run -dit --name "$container_name" "$container_name-image" > /dev/null 2>&1
    echo "$container_name created..."
    cd - > /dev/null 2>&1
}

# Function to list and sort files by length, returning only file names
sort_files() {
    docker exec docker exec "$container_name" ls -s /usr/src/app | head -n 2
}

# concatenate file contents to the text file
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
        echo "" >> book.txt # newline for separation
    fi
}

# Ensure you're in the directory where Docker1, Docker2, and Docker3 are located
cd ~/OS_Coursework

# Build images and run containers
echo "Creating Docker containers...."
build_and_run "Docker1" "docker1-container"
build_and_run "Docker2" "docker2-container"
build_and_run "Docker3" "docker3-container"

# List and sort files in each container
echo "Loading files to Docker containers..."
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
round_robin() {
    local -n _files=$1
    local container_name=$2

    for file_name in "${_files[@]}"; do
        # Skip the Dockerfile
        if [[ "$file_name" == "Dockerfile" ]]; then
            continue
        fi

        # Concatenate the file content
        if [ -n "$file_name" ]; then
            docker exec "$container_name" cat "/usr/src/app/$file_name" >> book.txt
            echo "" >> book.txt  # Adding a newline for separation
        fi
    done
}

# Perform a simple round robin operation on each set of files
echo "Beginning text creation GAME_OF_DOCKERS.txt..."
round_robin sorted_files_docker1 "docker1-container"
round_robin sorted_files_docker2 "docker2-container"
round_robin files_docker3 "docker3-container"
echo "Finished loading text..."

# Terminal user interface 
echo "The Game of Dockers Chapter has been created."
echo "Would you like to read Game of Dockers Chapter? (Yes/No)"
read read_answer

if [ "$read_answer" == "Yes" ]; then
    cat book.txt
fi

echo "Would you like to add any text to Game of Dockers? (Yes/No)"
read add_answer

if [ "$add_answer" == "Yes" ]; then
    echo "Enter the text you want to add (finish with CTRL+D):"
    cat >> book.txt
fi

echo "Would you like to remove any text from Game of Dockers? (Yes/No)"
read remove_answer

if [ "$remove_answer" == "Yes" ]; then
    echo "Please specify the text or line number you want to remove (this will open the file in an interactive editor):"
    nano book.txt  
fi

exit 0
