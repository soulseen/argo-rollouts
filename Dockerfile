FROM golang:1.13.1 as argo-rollouts-build

WORKDIR /go/src/github.com/argoproj/argo-rollouts

COPY . .
ARG MAKE_TARGET="controller"
RUN make ${MAKE_TARGET}

FROM ubuntu:18.04

COPY --from=argo-rollouts-build /go/src/github.com/argoproj/argo-rollouts/dist/rollouts-controller /bin/
#COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Use numeric user, allows kubernetes to identify this user as being
# non-root when we use a security context with runAsNonRoot: true
USER 999

WORKDIR /home/argo-rollouts

ENTRYPOINT [ "/bin/rollouts-controller" ]