#!/bin/bash
export HOME=/home/container
cd /home/container

# Download and Install steamcmd
if [ ! -d ./steamcmd ]; then
  cd /tmp
  curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
  tar -xzvf steamcmd.tar.gz -C .steamcmd/
fi

# Information output
echo "Running on Debian $(cat /etc/debian_version)"
echo "Current timezone: $(cat /etc/timezone)"
wine --version

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

## just in case someone removed the defaults.
if [ "${STEAM_USER}" == "" ]; then
    echo -e "steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

## if auto_update is not set or to 1 update or the server isn't installed
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" || ! -f .install_done ]; then 
    # Update Server
    if [ ! -z ${SRCDS_APPID} ]; then
        ./.steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update ${SRCDS_APPID} $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" )  $( [[ -z ${VALIDATE} ]] || printf %s "validate" ) +quit
    else
        echo -e "No appid set. Starting Server"
    fi
    touch .install_done
else
    echo -e "Not updating game server as auto update was set to 0. Starting Server"
fi

if [[ $XVFB == 1 ]]; then
        Xvfb :0 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH} &
fi

## set up 32 bit libraries
if [ ! -d .steam/sdk32]; then
  mkdir -p .steam/sdk32
  cp -v linux32/steamclient.so .steam/sdk32/steamclient.so
fi

## set up 64 bit libraries
if [ ! -d .steam/sdk64]; then
  mkdir -p .steam/sdk64
  cp -v linux64/steamclient.so .steam/sdk64/steamclient.so
fi

## add below your custom commands if needed
if [ ! -d ${SERVERDATAPATH} ]; then
  mkdir -p ${SERVERDATAPATH}
  
  FILE=$SERVERDATAPATH/dedicatedserver.cfg
  if [ -f "$FILE" ]; then
    echo -e "-------------------------------------------------"
    echo -e "dedicatedserver.cfg found."
    echo -e "-------------------------------------------------"
  else  
    echo -e "-------------------------------------------------"
    echo -e "No dedicatedserver.cfg found. Downloading default..."
    echo -e "-------------------------------------------------"
    curl -sSL -o ${FILE} https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/steamcmd_servers/sonsoftheforest/dedicatedserver.cfg
  fi
  
  FILE=$SERVERDATAPATH/ownerswhitelist.txt
  if [ -f "${FILE}" ]; then
    echo -e "-------------------------------------------------"
    echo -e "ownerswhitelist.txt found."
    echo -e "-------------------------------------------------"
  else  
    echo -e "-------------------------------------------------"
    echo -e "No ownerswhitelist.txt found. Downloading default..."
    echo -e "-------------------------------------------------"
    curl -sSL -o ${FILE} https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/steamcmd_servers/sonsoftheforest/ownerswhitelist.txt
  fi
fi
# Install necessary to run packages
echo "First launch will throw some errors. Ignore them"

mkdir -p $WINEPREFIX

# Check if wine-gecko required and install it if so
if [[ $WINETRICKS_RUN =~ gecko ]]; then
        echo "Installing Gecko"
        WINETRICKS_RUN=${WINETRICKS_RUN/gecko}

        if [ ! -f "$WINEPREFIX/gecko_x86.msi" ]; then
                wget -q -O $WINEPREFIX/gecko_x86.msi http://dl.winehq.org/wine/wine-gecko/2.47.4/wine_gecko-2.47.4-x86.msi
        fi

        if [ ! -f "$WINEPREFIX/gecko_x86_64.msi" ]; then
                wget -q -O $WINEPREFIX/gecko_x86_64.msi http://dl.winehq.org/wine/wine-gecko/2.47.4/wine_gecko-2.47.4-x86_64.msi
        fi

        wine msiexec /i $WINEPREFIX/gecko_x86.msi /qn /quiet /norestart /log $WINEPREFIX/gecko_x86_install.log
        wine msiexec /i $WINEPREFIX/gecko_x86_64.msi /qn /quiet /norestart /log $WINEPREFIX/gecko_x86_64_install.log
fi

# Check if wine-mono required and install it if so
if [[ $WINETRICKS_RUN =~ mono ]]; then
        echo "Installing mono"
        WINETRICKS_RUN=${WINETRICKS_RUN/mono}

        if [ ! -f "$WINEPREFIX/mono.msi" ]; then
                wget -q -O $WINEPREFIX/mono.msi https://dl.winehq.org/wine/wine-mono/9.1.0/wine-mono-9.1.0-x86.msi
        fi

        wine msiexec /i $WINEPREFIX/mono.msi /qn /quiet /norestart /log $WINEPREFIX/mono_install.log
fi

# List and install other packages
for trick in $WINETRICKS_RUN; do
        echo "Installing $trick"
        winetricks -q $trick
done

# Replace Startup Variables
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
