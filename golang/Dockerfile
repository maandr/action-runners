FROM golang:1.22.3-alpine3.18@sha256:d1a601b64de09e2fa38c95e55838961811d5ca11062a8f4230a5c434b3ae2a34

ARG VERSION_STATICCHECK=0.50.1

# Install gcc and other necessary build tools
RUN apk add --no-cache gcc musl-dev

# install staticcheck
RUN go install honnef.co/go/tools/cmd/staticcheck@2023.1.7

# set timezone
ENV TZ="Europe/Berlin"
ENV CGO_ENABLED=1
