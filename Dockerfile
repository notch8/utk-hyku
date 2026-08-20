FROM ghcr.io/samvera/hyku/base:d6ef0431 AS hyku-web
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

# Explicit CMD so this stage actually runs bin/web (which sizes the DB
# pool per-role) instead of silently inheriting the base image's own
# `bundle exec puma ...` CMD and bypassing bin/web entirely.
CMD ["./bin/web"]

FROM hyku-web AS hyku-worker
CMD ["./bin/worker"]

FROM nginxinc/nginx-unprivileged:1.29-alpine AS hyku-nginx
USER root
COPY ops/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ops/nginx/conf.d /opt/bitnami/nginx/conf/conf.d
COPY ops/nginx/bots.d /opt/bitnami/nginx/conf/bots.d
RUN mkdir -p /opt/bitnami/nginx/logs && chown -R nginx:nginx /opt/bitnami
COPY --from=hyku-web /app/samvera/hyrax-webapp/public/assets /app/samvera/hyrax-webapp/public/assets
COPY --from=hyku-web /app/samvera/hyrax-webapp/public/uv /app/samvera/hyrax-webapp/public/uv
COPY --from=hyku-web /app/samvera/hyrax-webapp/public/clover-iiif /app/samvera/hyrax-webapp/public/clover-iiif
USER nginx

# Use a Solr version with patched Log4j to address CVE-2021-44228
FROM solr:8.11.2 AS hyku-solr
ENV SOLR_USER="solr" \
    SOLR_GROUP="solr"
USER root
COPY --chown=solr:solr solr/security.json /var/solr/data/security.json
USER $SOLR_USER
