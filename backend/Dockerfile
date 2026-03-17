# Use an official Dlang runtime image as the base
FROM dlang2/dmd-ubuntu:latest

# Set the working directory inside the container
WORKDIR /app
ENV DC=dmd

# Copy the source code into the container
COPY . .

# Build the application using dub (Dlang's package manager)
RUN cd movie && dub build --build=release

# Define the command to run the application when the container starts
CMD ["/movie/out/movie"]
