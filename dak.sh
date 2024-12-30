/interface wireguard add listen-port=2408 mtu=1420 name=wireguard1 private-key="kLaCS+syC4OKKrWS4NlOGgbIoXnQo9sHYCukhcIUOkk="

:delay 2
/interface wireguard peers add allowed-address=0.0.0.0/0 endpoint-address=162.159.192.1 endpoint-port=2408 interface=wireguard1 persistent-keepalive=25 public-key="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="

:delay 2
/ip address add address=172.16.0.2/32 interface=wireguard1

:delay 2
/ip route add distance=1 gateway=wireguard1 dst-address=0.0.0.0/0

:delay 2
/ip dns set servers=1.1.1.1

:delay 2
/ip firewall nat add chain=srcnat action=masquerade out-interface=wireguard1

/interface wireguard print
:delay 2
/interface wireguard peers print
:delay 2
/interface lte print

/ip route print
:delay 2
/ip route remove [find dst-address=0.0.0.0/0 gateway=wireguard1]
:delay 2
/ip route add dst-address=0.0.0.0/0 gateway=wireguard1 distance=1
:delay 2
/ip route add dst-address=162.159.192.1 gateway=lte1 distance=1

:log info "Finalizado."
