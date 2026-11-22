{ config, lib, pkgs, ... }:

# Frigate under podman inside the stack (the containers grant), with
# hardware decoding and OpenVINO detection on the GPU the grant binds in.
# Its config is edited in the Frigate UI and kept in /var/lib/frigate/config.
# The homelab daemon's host module opens the ports the manifest names.

let
  # Frigate reads FRIGATE_* environment variables into its config. The file
  # holds only those, written as root before every start into the unit's own
  # runtime directory, which systemd removes on stop.
  frigateEnv = "/run/frigate/frigate.env";
  writeFrigateEnv = pkgs.writeShellScript "frigate-env" ''
    set -eu
    umask 077
    : > ${frigateEnv}.tmp
    if [ -r /run/secrets/MQTT_HOST ]; then
      printf 'FRIGATE_MQTT_HOST=%s\n' "$(cat /run/secrets/MQTT_HOST)" >> ${frigateEnv}.tmp
    fi
    if [ -r /run/secrets/FRIGATE_MQTT_PASSWORD ]; then
      printf 'FRIGATE_MQTT_PASSWORD=%s\n' "$(cat /run/secrets/FRIGATE_MQTT_PASSWORD)" >> ${frigateEnv}.tmp
    fi
    mv ${frigateEnv}.tmp ${frigateEnv}
  '';
  libva = config.environment.sessionVariables.LIBVA_DRIVER_NAME or null;
in
{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  systemd.services.podman-frigate.serviceConfig = {
    RuntimeDirectory = "frigate";
    ExecStartPre = lib.mkBefore [ "${writeFrigateEnv}" ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/frigate/config 0755 root root -" ];

  virtualisation.oci-containers.containers.frigate = {
    # 0.18.2
    image = "ghcr.io/blakeblackshear/frigate@sha256:fd60f99ffd4eb6c42360ed4e14953e270586f239309ab3983e55b2e97ffac09a";
    ports = [
      "5000:5000" # UI and API, unauthenticated; Caddy on the host fronts it
      "1984:1984" # go2rtc API
      "8554:8554" # go2rtc RTSP restream
      "8555:8555/tcp" # go2rtc WebRTC
      "8555:8555/udp"
    ];
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/var/lib/frigate/config:/config"
      "/var/lib/frigate/media:/media/frigate"
    ];
    environment = lib.optionalAttrs (libva != null) { LIBVA_DRIVER_NAME = libva; };
    environmentFiles = [ frigateEnv ];
    extraOptions = [
      "--device=/dev/dri/renderD128"
      "--shm-size=256m"
      "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1g"
    ];
  };
}
