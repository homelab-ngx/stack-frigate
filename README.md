# stack-frigate

[Frigate](https://frigate.video), the network video recorder with object
detection, as a stack for [homelab-ngx](https://github.com/homelab-ngx/homelab-ngx). Frigate runs from its official image under
podman inside the stack.

## Getting started

1. Add the stack: `homelab stacks add github:homelab-ngx/stack-frigate`, or
   Add stack on the dashboard's Stacks page.
2. On the stack's page, set `RECORDINGS_DIR` to a folder for recordings and
   `CAMERAS` to the cameras' addresses.
3. Approve the grants and start the stack.
4. Open `https://frigate.<your domain>` and write the config in Frigate's
   config editor: the cameras, the detector and MQTT.

Frigate's port 5000 has no login of its own. Its route is served only on
your private network.

The GPU grant gives video decoding and OpenVINO detection on Intel graphics:
set the detector to `openvino`.

For MQTT, set `MQTT_HOST` and `FRIGATE_MQTT_PASSWORD`. In Frigate's config,
write the broker as `host: "{FRIGATE_MQTT_HOST}"` and the password as
`password: "{FRIGATE_MQTT_PASSWORD}"`. Frigate fills them in.

The backup folder below is Frigate's config, without the list of recorded
events. Recordings are not among them: add `RECORDINGS_DIR` to a backup
yourself.

<!-- manifest:start -->
<!-- Made from homelab-stack.json. Change the manifest, not these lines. -->

## Grants

You approve each of these before the stack starts.

- Route: `frigate.<your domain>` to port 5000 in the stack.
- Storage: the folder in `RECORDINGS_DIR`, at `/var/lib/frigate/media` in the stack, read-write.
- GPU: the render devices of the host, `/dev/dri`.
- Network: out to the addresses you give in `CAMERAS` on port 554/tcp.
- Network: out to the addresses you give in `MQTT_HOST` on port 1883/tcp.
- Port: 1984/tcp on the host to port 1984 in the stack, from the addresses you give in `GO2RTC_CLIENTS`.
- Port: 8554/tcp on the host to port 8554 in the stack, from the addresses you give in `GO2RTC_CLIENTS`.
- Port: 8555/tcp on the host to port 8555 in the stack, from the LAN of the host.
- Port: 8555/udp on the host to port 8555 in the stack, from the LAN of the host.
- Containers: Podman runs in the stack.

## Variables

| Name | Kind | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `RECORDINGS_DIR` | path | yes |  | Where Frigate keeps recordings, snapshots and clips. It grows with the cameras and the retention you set in Frigate. |
| `CAMERAS` | address | yes |  | The cameras' IPv4 addresses. Frigate pulls their RTSP streams on port 554. |
| `MQTT_HOST` | address | no |  | Home Assistant's MQTT broker, which Frigate sends events to on port 1883. Frigate's config can use it as {FRIGATE_MQTT_HOST}. Leave it unset to run Frigate without MQTT. |
| `FRIGATE_MQTT_PASSWORD` | secret | no |  | Password of Frigate's MQTT user. Frigate's config reads it as {FRIGATE_MQTT_PASSWORD}. |
| `GO2RTC_CLIENTS` | address | no |  | Devices that may pull Frigate's camera restreams (the go2rtc API on 1984 and RTSP on 8554), such as Home Assistant. Leave it unset to keep them closed. |

## Backup

The stack recommends these folders. None is backed up until you add it to a backup.

- Frigate settings: `/var/lib/frigate/config` in the stack.
  - Without `/frigate.db*`. The list of recorded events. The recordings it points to are not backed up.

## Health

An update is kept when all of this holds, and rolled back when it does not.

- `podman-frigate.service` is active.

Manifest version 9, built with nixpkgs `nixos-unstable`. Runs on [homelab-ngx](https://github.com/homelab-ngx/homelab-ngx).

<!-- manifest:end -->

## License

MIT, see [LICENSE](LICENSE).
