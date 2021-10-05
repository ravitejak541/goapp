FROM golang:alpine as build
RUN mkdir /go-temp
ADD go.mod main.go /go-temp
WORKDIR /go-temp
RUN go build -o go-webapp .

FROM alpine
COPY --from=build /go-temp/go-webapp .
RUN addgroup -S svcgrp && adduser -S svcuser -G svcgrp && apk add curl
EXPOSE 3030 
USER svcuser
CMD [ "./go-webapp" ]
