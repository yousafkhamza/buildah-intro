FROM golang:latest AS base
RUN mkdir /var/go
WORKDIR /var/go
COPY ./app.go .
RUN go build app.go

FROM alpine:3.8
COPY --from=base /var/go/app /var/app
RUN chmod +x /var/app
CMD ["/var/app"]