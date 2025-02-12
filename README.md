# OpenVPN Debian Yükleyici

Bu script, Debian 11 ve üstü sistemler için optimize edilmiş bir OpenVPN kurulum aracıdır. Aşağıdaki adımları izleyerek OpenVPN sunucunuzu kolayca kurabilirsiniz.

## Gereksinimler

- Debian 11 veya daha yeni bir sürüm
- Root yetkileri
- Aktif TUN cihazı

## Kurulum

1. Scripti indirin ve çalıştırılabilir hale getirin:

   ```bash
   chmod +x openvpn-install.sh
   ```

2. Scripti çalıştırın:

   ```bash
   sudo ./openvpn-install.sh
   ```

3. Script, gerekli tüm paketleri yükleyecek ve OpenVPN'i yapılandıracaktır. Kurulum tamamlandıktan sonra, kullanıcı yapılandırma dosyasını şu konumda bulabilirsiniz:

   ```
   ~/client.ovpn
   ```

4. `client.ovpn` dosyasını bir OpenVPN istemcisine aktararak bağlantıyı başlatabilirsiniz.

## Kullanım

- **OpenVPN Hizmetini Başlat/Durdur**:

   ```bash
   sudo systemctl start openvpn-server@server
   sudo systemctl stop openvpn-server@server
   ```

- **Hizmet Durumunu Kontrol Etmek**:

   ```bash
   sudo systemctl status openvpn-server@server
   ```

- **Yeni Kullanıcı Ekleme**:

   Yeni bir kullanıcı eklemek için scripti tekrar çalıştırarak yeni bir kullanıcı oluşturabilirsiniz.

## Bilgilendirme

Bu script, **OpenVPN** kurulumu için gerekli tüm adımları basitleştirmek ve Debian sistemlerinde sorunsuz bir kurulum sağlamak amacıyla düzenlenmiştir.

Bu belge ve script, OpenVPN kurulumu hakkında bilgi sağlamak için yapay zeka tarafından düzenlenmiştir. 
