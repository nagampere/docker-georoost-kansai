FROM python:3.12.7-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV POETRY_HOME="/root/.local"

# 必要なパッケージ
RUN apt-get update && apt-get install -y \
    git \
    ssh \
    curl \
    zenity \
    x11-apps \
    build-essential \
    && apt-get clean

# Poetry install
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /root/.local/bin/poetry /usr/local/bin/poetry

WORKDIR /app

COPY clone_and_run.sh /app/clone_and_run.sh
RUN chmod +x /app/clone_and_run.sh

EXPOSE 8501

ENTRYPOINT ["/app/clone_and_run.sh"]
