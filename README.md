# go-web-server

## Requirements

Write a Dockerfile that compiles and then runs the web server in this repository.  

Please write it as if the container will be used in production.  

1. The Dockerfile must build an image for this go-web-server successfully.
2. The image must run successfully and have the go-web-server listening on port 3030.
3. Once you have the Dockerfile running **please provide the response** returned from the `/keyword` route to us.  

## Details

It exposes a web server on port 3030 and logs to STDOUT.  The port is configurable by setting the PORT environment variable.  

It has several routes that return status code 200 and some data: `/health`, `/hello`, and `/keyword`. All other routes will return 404: "404 page not found".  

## Docker Implementation

- Docker build uses multi stage build and intermediate contanier will be used to build the go lang binary
- Later the file be taken from the intermediate contanier layer and push to a new image.
- This can save us a large space consumption and image can be light weight too.
- Healthcheck has been defined to restart the container if the app is not responding.
- For the secutity measure the app will run in non priviledged mode.

## How to RUN

sh ```
docker-compose build
docker-compose up

(OR)

docker run -itd go-webapp
```