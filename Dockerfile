FROM ghcr.io/samvera/hyku/base:d6ef0431 AS hyku-base
# The bunder and asset build are ONBUILD commands in the base. they still get run
# as if they were included right after the from line. See https://docs.docker.com/engine/reference/builder/#onbuild
RUN sed -i '/require .enumerator./d' /usr/local/bundle/gems/sass-3.7.4/lib/sass/util.rb
RUN ln -sf /app/samvera/branding /app/samvera/hyrax-webapp/public/branding
# Set environment variables for kubectl installation
ENV KUBECTL_VERSION=v1.27.3
USER root
# Determine the architecture and set the download URL accordingly
RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
  ARCH="amd64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  ARCH="arm64"; \
  elif [ "$ARCH" = "armv7l" ]; then \
  ARCH="arm"; \
  else \
  echo "Unsupported architecture: $ARCH"; exit 1; \
  fi && \
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
  rm kubectl
USER app

FROM hyku-base AS hyku-worker
CMD ./bin/worker
