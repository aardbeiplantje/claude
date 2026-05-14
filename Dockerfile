FROM node:20 AS runtime

ARG TZ
ENV TZ="$TZ"

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  iputils-ping \
  socat \
  netcat-openbsd \
  aggregate \
  jq \
  lsof \
  nano \
  vim \
  tmux \
  ripgrep \
  fd-find \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create fd symlink (Debian packages it as fdfind to avoid conflicts)
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Add docker group (GID 983 to match host) and add node user to it
# Also add containerd group if it doesn't exist
RUN groupadd -g 983 docker || groupmod -g 983 docker || true \
  && usermod -aG 983 node \
  && groupadd -g 999 containerd 2>/dev/null || true \
  && usermod -aG 999 node 2>/dev/null || true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude /home/node/.local /home/node/.local/share /home/node/.local/lib /home/node/.local/bin \
  && chown node:node /workspace \
  && chown -R node:node /home/node/ \
  && chmod go+rw /home/node/ -R

WORKDIR /workspace
# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Install Claude
USER root
ADD https://claude.ai/install.sh /tmp/install_claude.sh
RUN chown node /tmp/install_claude.sh
USER node
ENV CLAUDE_CONFIG_DIR=/workspace/.claude
ARG CLAUDE_CODE_VERSION=2.1.68
RUN bash /tmp/install_claude.sh $CLAUDE_CODE_VERSION
RUN chmod o+rw -R $CLAUDE_CONFIG_DIR

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  perl \
  libxml-libxml-perl \
  libjson-xs-perl \
  libyaml-libyaml-perl \
  imagemagick \
  python3-pip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Python requirements and install as node user
COPY --chown=node:node requirements.txt /tmp/requirements.txt
USER node
RUN python3 -m pip install \
    --upgrade \
    --prefer-binary \
    --no-cache-dir \
    --user \
    --no-warn-script-location \
    --break-system-packages \
    -r /tmp/requirements.txt
RUN \
     python3 -c "import httpx; print('httpx version:', httpx.__version__)" \
  && python3 -c "import requests; print('requests version:', requests.__version__)" \
  && python3 -c "import bs4; print('beautifulsoup4 version:', bs4.__version__)" \
  && perl -MXML::LibXML -e 'print "XML::LibXML version: ", $XML::LibXML::VERSION, "\n"' \
  && perl -MJSON::XS -e 'print "JSON::XS version: ", $JSON::XS::VERSION, "\n"' \
  && perl -MYAML::XS -e 'print "YAML::XS version: ", $YAML::XS::VERSION, "\n"'
RUN rm -rf /home/node/.claude* /home/node/.cache /tmp/install_claude.sh; mkdir -p /home/node/.git
RUN mkdir -p /home/node/.npm
ENV T_UID=1000
ENV PATH=$PATH:/home/node/.local/bin
ENV PYTHONPATH=/home/node/.local/lib/python3.11/site-packages
ENV CLAUDE_CODE_ENABLE_TELEMETRY=0
ENV DISABLE_AUTOUPDATER=1
ENV CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
ENV DISABLE_TELEMETRY=1
ENV DISABLE_ERROR_REPORTING=1
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
ENV CLAUDE_TRUST_ALL=1
ENV CLAUDE_CONFIG_DIR=/workspace/.claude
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV XDG_CACHE_HOME=/workspace/.cache
ENV GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET"
USER root
COPY claude.pl /

USER root
RUN rm -rf /tmp/*
ENTRYPOINT ["/usr/bin/perl", "/claude.pl"]

