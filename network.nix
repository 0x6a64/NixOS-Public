# NetworkManager profiles with sops-nix secrets
# Uses nm2nix format: https://github.com/janik-haag/nm2nix
{config, ...}: {
  sops.secrets = {
    # WiFi passwords
    "HOME_WIFI_PSK" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    "WORK_WIFI_PSK" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    # WireGuard
    "WG_PRIVATE_KEY" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  # NetworkManager profiles defined declaratively
  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      # Provide sops secrets as environment variables
      environmentFiles = [
        config.sops.secrets.HOME_WIFI_PSK.path
        config.sops.secrets.WORK_WIFI_PSK.path
        config.sops.secrets.WG_PRIVATE_KEY.path
      ];

      profiles = {
        # Wifi
        HomeWifi = {
          connection = {
            id = "HomeWifi";
            interface-name = "wlp1s0";
            type = "wifi";
            uuid = "89ea9ea1-304a-4295-baf5-4ffea9deefd2";
          };
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = {};
          wifi = {
            mode = "infrastructure";
            ssid = "HomeWifi";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$HOME_WIFI_PSK";
          };
        };

        WorkWifi = {
          connection = {
            id = "WorkWifi";
            interface-name = "wlp1s0";
            type = "wifi";
            uuid = "664e007a-4149-4092-9129-eedecb8cfc15";
          };
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = {};
          wifi = {
            mode = "infrastructure";
            ssid = "WorkWifi";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$WORK_WIFI_PSK";
          };
        };

        # Wireguard
        Homev6-wg = {
          connection = {
            autoconnect = "false";
            id = "Homev6-wg";
            interface-name = "Homev6-wg";
            permissions = "user:user:;";
            type = "wireguard";
            uuid = "3538213e-8979-4aa8-8d96-7d1609075a27";
          };
          ipv4 = {
            address1 = "10.0.0.2/32";
            dns = "10.0.0.1;";
            dns-search = "~;";
            method = "manual";
          };
          ipv6 = {
            addr-gen-mode = "default";
            address1 = "fd00::2/128";
            dns = "fd00::1;";
            dns-search = "~;";
            method = "manual";
          };
          proxy = {};
          wireguard = {
            listen-port = "51820";
            private-key = "$WG_PRIVATE_KEY";
          };
          # WireGuard peer configuration
          # The section name includes the peer's public key: YOUR_WIREGUARD_PEER_PUBLIC_KEY=
          "wireguard-peer.YOUR_WIREGUARD_PEER_PUBLIC_KEY=" = {
            allowed-ips = "0.0.0.0/0;::/0;";
            endpoint = "vpn.example.com:51821";
          };
        };

        # VLAN
        ManVLAN = {
          connection = {
            autoconnect = "false";
            id = "ManVLAN";
            interface-name = "eth0.90";
            permissions = "user:user:;";
            type = "vlan";
            uuid = "8c9e6a7a-8873-46c0-9076-bcd355781b39";
          };
          ethernet = {};
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = {};
          vlan = {
            flags = "1";
            id = "90";
            parent = "eth0";
          };
        };
      };
    };
  };
}
