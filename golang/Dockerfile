FROM golang:1.22.3-alpine3.18@sha256:45319271acc6318e717a16a8f79539cffbee77cebd0602b32f4e55c26db9f78e

ARG VERSION_STATICCHECK=0.50.1

# Install gcc and other necessary build tools
RUN apk add --no-cache gcc musl-dev

# install staticcheck
RUN go install honnef.co/go/tools/cmd/staticcheck@2023.1.7

# set timezone
ENV TZ="Europe/Berlin"
ENV CGO_ENABLED=1
