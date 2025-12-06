FROM ghcr.io/parkervcp/yolks:wine_latest

ENV AUTO_UPDATE=1
ENV GAME_MODE=normal
ENV SRV_PW=changeme
ENV SRCDS_APPID=2465200
ENV SRV_NAME="Pterodactyl hosted Server"
ENV WINDOWS_INSTALL=1
ENV WINEDEBUG=-all
ENV WINETRICKS_RUN="mono vcrun2019"
ENV BLOBSYNC_PORT=9700
ENV MAX_PLAYERS=4
ENV QUERY_PORT=27016
ENV SAVE_SLOT=0000000001
ENV SKIP_TESTS=false
ENV WINEARCH=win64
ENV WINEPATH=/home/container
ENV SERVERDATAPATH=serverconfig
ENV STARTUP='wine ./SonsOfTheForestDS.exe -userdatapath "/home/container/{{SERVERDATAPATH}}" -dedicatedserver.IpAddress "0.0.0.0" -dedicatedserver.GamePort "{{SERVER_PORT}}" -dedicatedserver.QueryPort "{{QUERY_PORT}}" -dedicatedserver.BlobSyncPort "{{BLOBSYNC_PORT}}" -dedicatedserver.MaxPlayers "{{MAX_PLAYERS}}" -dedicatedserver.Password "{{SRV_PW}}" -dedicatedserver.GameMode "{{GAME_MODE}}" -dedicatedserver.SkipNetworkAccessibilityTest "{{SKIP_TESTS}}" -dedicatedserver.SaveSlot "{{SAVE_SLOT}}" -dedicatedserver.LogFilesEnabled "true" -dedicatedserver.TimestampLogFilenames "true"'

VOLUME /home/container

COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.py /healthcheck.py

RUN chmod +x /entrypoint.sh

# Install Python + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install the A2S query module
RUN pip3 install a2s

ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD python3 /healthcheck.py
