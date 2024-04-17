FROM golang:1.22.2-alpine3.18@sha256:d995eb689a0c123590a3d34c65f57f3a118bda3fa26f92da5e089ae7d8fd81a0

ARG VERSION_STATICCHECK=0.50.1

# Install gcc and other necessary build tools
RUN apk add --no-cache gcc musl-dev

# install staticcheck
RUN go install honnef.co/go/tools/cmd/staticcheck@2023.1.7

# set timezone
ENV TZ="Europe/Berlin"
ENV CGO_ENABLED=1
