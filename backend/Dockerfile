# official Dlang runtime image
FROM dlang2/dmd-ubuntu:latest

# working directory inside the container
WORKDIR /app
ENV DC=dmd

# copy the source code into the container
COPY . .

# build application using dub
RUN cd movie && dub build --build=release

# command to run the application when the container starts
CMD ["./movie/out/movie"]
