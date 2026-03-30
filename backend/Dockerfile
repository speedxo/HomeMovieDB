# official Dlang runtime image
FROM dlang2/dmd-ubuntu:latest

# working directory inside the container
WORKDIR /app
ENV DC=dmd

# copy the source code into the container
COPY . .

# build application using dub
ARG BUILD_TYPE="release"
RUN cd movie && dub build --build=${BUILD_TYPE}

# privilege lowering - docker best practice
RUN useradd -r -s /bin/false vibeapp
USER vibeapp

# command to run the application when the container starts
CMD ["./movie/out/movie"]
