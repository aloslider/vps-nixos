{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.vps.services.ss-zapret2;
in
{
  config = mkIf cfg.enable {
    sops.secrets = {
      "ss-zapret2/password" = { };
    };

    sops.templates."ss-zapret2.env".content = ''
      SS_PORT=${toString cfg.ssPort}
      SOCKS_PORT=${toString cfg.socksPort}
      SS_ENCRYPT_METHOD=chacha20-ietf-poly1305
      SS_TIMEOUT=300
      SS_VERBOSE=0
      SS_PASSWORD=${config.sops.placeholder."ss-zapret2/password"}
    '';

    # TODO: move from common config
    vps.services.ss-zapret2.config = pkgs.writeText "ss-zapret2-config" ''
      FWTYPE=nftables

      SET_MAXELEM=522288
      IPSET_OPT="hashsize 262144 maxelem $SET_MAXELEM"
      IP2NET_OPT4="--prefix-length=22-30 --v4-threshold=3/4"
      IP2NET_OPT6="--prefix-length=56-64 --v6-threshold=5"

      AUTOHOSTLIST_INCOMING_MAXSEQ=4096
      AUTOHOSTLIST_RETRANS_MAXSEQ=32768
      AUTOHOSTLIST_RETRANS_RESET=1
      AUTOHOSTLIST_RETRANS_THRESHOLD=3
      AUTOHOSTLIST_FAIL_THRESHOLD=3
      AUTOHOSTLIST_FAIL_TIME=60
      AUTOHOSTLIST_UDP_IN=1
      AUTOHOSTLIST_UDP_OUT=4
      AUTOHOSTLIST_DEBUGLOG=0

      MDIG_THREADS=30
      GZIP_LISTS=1

      DESYNC_MARK=0x40000000
      DESYNC_MARK_POSTNAT=0x20000000

      ZL=/opt/lists
      ZB=/opt/zapret2/files/fake
      ZF="--hostlist=$ZL/list-general.txt --hostlist-exclude=$ZL/list-exclude.txt --ipset-exclude=$ZL/ipset-exclude.txt"
      ZI="--ipset=$ZL/ipset-all.txt --hostlist-exclude=$ZL/list-exclude.txt --ipset-exclude=$ZL/ipset-exclude.txt"

      NFQWS2_ENABLE=1
      NFQWS2_PORTS_TCP=80,443,2053,2083,2087,2096,5222,8443
      NFQWS2_PORTS_UDP=443,19294-19344,50000-50100
      # Empty PKT_OUT makes nft skip these lists and install only *_KEEPALIVE.
      # That left UDP voice and discord.media ports off the queue, and keepalive
      # mode fed every packet of a TCP download into nfqws2.
      NFQWS2_TCP_PKT_OUT=20
      NFQWS2_TCP_PKT_IN=10
      NFQWS2_UDP_PKT_OUT=5
      NFQWS2_UDP_PKT_IN=3

      NFQWS2_OPT="
      --blob=fl_tls_google:@$ZB/tls_clienthello_www_google_com.bin
      --blob=fl_quic_google:@$ZB/quic_initial_www_google_com.bin
      --blob=fl_sferum:@$ZB/tls_clienthello_www_sferum_ru.bin
      --filter-udp=443 --filter-l7=quic $ZF --payload=quic_initial --lua-desync=fake:blob=fl_quic_google:repeats=6 --new
      --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=fl_quic_google:repeats=6 --new
      --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=fl_tls_google:ip_id=zero --new
      --filter-udp=443 --hostlist=$ZL/list-google.txt --payload=quic_initial --lua-desync=fake:blob=fl_quic_google:repeats=6 --new
      --filter-tcp=443 --hostlist=$ZL/list-google.txt --payload=tls_client_hello --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=fl_tls_google:ip_id=zero --new
      --filter-tcp=80,443 $ZF --payload=tls_client_hello --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=fl_tls_google:ip_id=zero --payload=http_req --lua-desync=fake:blob=fl_sferum:repeats=6:tcp_seq=1000 --lua-desync=multisplit:pos=2 --new
      --filter-udp=443 $ZI --payload=quic_initial --lua-desync=fake:blob=fl_quic_google:repeats=6 --new
      --filter-tcp=80,443,5222 --ipset=$ZL/ipset-telegram.txt --filter-l7=mtproto --lua-desync=multisplit:pos=32 --new
      --filter-tcp=80,443,8443 $ZI --payload=tls_client_hello --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=fl_tls_google:ip_id=zero --payload=http_req --lua-desync=fake:blob=fl_sferum:repeats=6:tcp_seq=1000 --lua-desync=multisplit:pos=2
      "

      MODE_FILTER=none
      FLOWOFFLOAD=donttouch
      INIT_APPLY_FW=1
      FILTER_TTL_EXPIRED_ICMP=1
      '';
  };
}
