FROM ubuntu:20.04
ARG REGION=ap-southeast-1
ARG TZ=Asia/Jakarta
ARG BORE_SERVER=bore.pub
ARG ROOT_PASS
ARG NTFY_TOPIC
ARG PORT=8080
LABEL maintainer="DevCulture" version="6.0" description="Rairu-Kun2 - Ubuntu 20.04 SSH VPS with bore tunnel + supervisord"
# No baked-in credentials. Set at deploy time: ROOT_PASS (auto-generated if empty), NTFY_TOPIC (optional), BORE_SERVER (default bore.pub). No token/card needed.
ENV DEBIAN_FRONTEND=noninteractive TZ=${TZ} REGION=${REGION} BORE_SERVER=${BORE_SERVER} ROOT_PASS=${ROOT_PASS} NTFY_TOPIC=${NTFY_TOPIC} PORT=${PORT}
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends ca-certificates curl openssl xz-utils vim nano sudo net-tools wget htop git unzip iproute2 iputils-ping procps passwd tmux screen lsof dnsutils jq tzdata zstd neofetch nginx supervisor && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && curl -fsSL https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz -o /tmp/bore.tgz && tar -xzf /tmp/bore.tgz -C /usr/local/bin bore && chmod +x /usr/local/bin/bore && rm /tmp/bore.tgz && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
RUN mkdir -p /run/sshd && ssh-keygen -A && sed -i -e 's/#PermitRootLogin.*/PermitRootLogin yes/' -e 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' -e 's/#PasswordAuthentication.*/PasswordAuthentication yes/' -e 's/PasswordAuthentication no/PasswordAuthentication yes/' -e 's/#ClientAliveInterval.*/ClientAliveInterval 60/' -e 's/#ClientAliveCountMax.*/ClientAliveCountMax 10/' -e 's/#MaxSessions.*/MaxSessions 50/' -e 's/#TCPKeepAlive.*/TCPKeepAlive yes/' -e 's/#Banner.*/Banner \/etc\/ssh\/banner.txt/' /etc/ssh/sshd_config && printf "DevCulture Rairu-Kun2 VPS\n" > /etc/ssh/banner.txt
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx-ollama.conf /etc/nginx/sites-available/ollama
RUN ln -sf /etc/nginx/sites-available/ollama /etc/nginx/sites-enabled/ollama && mkdir -p /var/www/ollama-ui
COPY index.html /var/www/ollama-ui/index.html
RUN chmod -R 755 /var/www/ollama-ui
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY devculture-banner.sh /etc/profile.d/99-devculture-banner.sh
COPY bore-setup.sh /usr/local/bin/bore-setup.sh
COPY entrypoint.sh /entrypoint.sh
COPY watchdog.sh /usr/local/bin/watchdog.sh
RUN chmod +x /etc/profile.d/99-devculture-banner.sh /usr/local/bin/bore-setup.sh /entrypoint.sh /usr/local/bin/watchdog.sh
RUN apt-get clean && rm -rf /tmp/* /var/tmp/*
EXPOSE 22 80 443 3000 8080 8888
CMD ["/entrypoint.sh"]
