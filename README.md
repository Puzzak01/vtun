Автоматическая установка туннеля vtun
```
wget -O - https://raw.githubusercontent.com/Puzzak01/vtun/refs/heads/main/install.sh | bash
```

добавить камеру можно в файле /etc/vtund.conf 
пример 
```
E60BFB000001 {
  type ether;
  speed 0:0;
  password E60BFB000001;
  device tunnel1;
  up {
    ip "link set %% up multicast off mtu 1500";
    program "brctl addif br-ipcam %%";
  };
  down {
    program "brctl delif br-ipcam %%";
    ip "link set %% down";
  };
}
```
значение E60BFB000001 также как и значение password заменить на свой с камеры на прошивке openipc

сделать статический ip адрес в туннеле vtun можно в файле /etc/vtund.dhcp
пример
```
dhcp-host=AA:BB:CC:DD:EE:01,172.16.0.3
```
