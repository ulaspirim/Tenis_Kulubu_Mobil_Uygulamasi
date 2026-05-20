# PROJE ADI: Ulaş Tenis Kulübü - Mobil Uygulaması

## Proje Tanımı: 
Ulaş Tenis Kulübü - Mobil Uygulaması, tenis kulübü üyelerinin ve yönetiminin kulüp içi faaliyetleri en verimli şekilde yürütmesini sağlayan entegre bir yönetim ve sosyal ağ platformudur. Üyelerin kort, havuz ve spor salonu rezervasyonlarını anlık yapabilmesi, turnuvalardan haberdar olması, diğer üyelerle iletişim kurabilmesi ve yönetimin üyeleri dinamik olarak asiste edebilmesi amacıyla geliştirilmiştir.

## Proje Kategorisi: 
Spor ve Kulüp Yönetim Sistemi / Sosyal İletişim Ağı
## Process Süreçleri: 
Proje Planı, Gereksinim Analizi, Durum Diyagramları, Durum Senaryoları, VT (Veritabanı) Diyagramları, Front-End, Back-End, Test, Geliştirici Dokümantasyonları.



# GEREKSİNİM ANALİZİ

## Gereksinimler
1. Üye Kaydı ve Giriş Yapma
2. Profil ve Üyelik Yönetimi
3. Tesis ve Kort Rezervasyonu (Hızlı Rezervasyon)
4. Rezervasyon Geçmişi ve Takibi
5. Duyurular ve Etkinlik Akışı
6. Kulüp İçi Sohbet Odaları (Grup Sohbetleri)
7. Yönetici (Admin) Paneli
8. Üye Yetkilendirme ve Durum Güncelleme
9. Bildirim Sistemi
10. Tesis İstatistikleri ve Raporlama


## Kişisel Gereksinim Analizi

1. Üye Kaydı ve Giriş Yapma:
Uygulamayı kullanmak isteyen kulüp üyelerinin ad, soyad, e-posta ve şifre bilgileriyle kayıt olabilmesi; mevcut üyelerin ise geçmiş rezervasyon verilerine ve üyelik haklarına erişebilmesi için güvenli bir giriş ekranının sisteme entegre edilmesi.

2. Profil ve Üyelik Yönetimi:
Kullanıcının kendi profil bilgilerini, avatarını ve şifresini güncelleyebilmesi. Ayrıca mevcut üyelik paketini (Gold, Silver vb.), kalan üyelik süresini ve tanımlı haklarını (örneğin aylık ücretsiz havuz kullanım hakkı) görebileceği bir profil alanının sunulması.

3. Tesis ve Kort Rezervasyonu (Hızlı Rezervasyon):
Üyelerin Tenis Kortu, Yüzme Havuzu veya Spor Salonu gibi alanları seçerek; tesis türü, tarih ve saat dilimi adımlarını içeren 4 aşamalı dinamik bir rezervasyon akışı ile anlık yer ayırtabilmesi.

4. Rezervasyon Geçmişi ve Takibi:
Kullanıcının aktif (gelecek) rezervasyonlarını görerek iptal veya değişiklik yapabilmesi; geçmişte gerçekleştirdiği rezervasyonların dökümünü profil sekmesi altından takip edebilmesi.

5. Duyurular ve Etkinlik Akışı:
Kulüp yönetiminin düzenlediği "Yaza Merhaba Turnuvası" gibi etkinliklerin, turnuva fikstürlerinin ve acil kulüp duyurularının tüm üyelere ana sayfa veya özel bir akış (feed) üzerinden güncel olarak ulaştırılması.

6. Kulüp İçi Sohbet Odaları (Grup Sohbetleri):
Üyelerin kendi aralarında partner bulabilmesi, turnuva süreçlerini organize edebilmesi ve sosyalleşebilmesi için "Tenis", "Genel Sohbet" veya turnuvalara özel ("Yaza Merhaba 2026") uygulama içi grup sohbet odalarının oluşturulması.

7. Yönetici (Admin) Paneli:
Kulüp yetkililerinin mobil uygulama içerisinden çıkmadan kulübü yönetebilmesi için özel bir arayüz. Bu panel üzerinden yeni duyuru yayınlama, yeni sohbet odası açma ve sistem genelini kontrol etme yetkisinin sağlanması.

8. Üye Yetkilendirme ve Durum Güncelleme (Admin):
Yöneticinin sisteme kayıtlı üyeleri listeleyebilmesi, üye detaylarına (Örn: Ulaş Pirim) erişebilmesi, üyelik tipini (VIP, Standart vb.) değiştirebilmesi, üyelik süresini uzatabilmesi veya kurallara uymayan üyeleri sistemden kaldırabilmesi.

9. Bildirim Sistemi:
Onaylanan rezervasyonlar, yaklaşan maç saatleri, yeni açılan turnuva kayıtları veya yöneticiler tarafından paylaşılan önemli duyurular için kullanıcılara anlık (push notification) bildirim gönderilmesi.

10. Tesis İstatistikleri ve Raporlama (Admin):
Yönetici panelinde kortların doluluk oranlarının, toplam üye sayısının, aktif rezervasyon grafiklerinin ve en çok tercih edilen saat dilimlerinin izlenebileceği analitik bir gösterge panelinin (Dashboard) bulunması.

# Kullanılacak Teknolojiler ve Hedefler
Cross-Platform Front-End: Uygulama, hem Android hem de iOS platformlarında akıcı ve modern bir UI/UX deneyimi sunmak adına Flutter (Dart) dili ile kodlanacaktır.

UI/UX Tasarımı: Uygulamanın modern, koyu tema ağırlıklı ve sportif arayüz bileşenleri Figma üzerinde tasarlanmış; hazır şablon yapılarında elements.envato.com kaynaklarından yararlanılmıştır.

Back-End ve Veritabanı: Sohbetlerin anlık iletilmesi (Real-time), rezervasyon çakışmalarının önlenmesi ve üye verilerinin güvenle saklanması amacıyla ilişkisel/NoSQL hibrit bir veritabanı mimarisi kullanılacaktır.

Bulut Altyapısı: Uygulamanın kesintisiz erişilebilirliği, yüksek veri trafiğini kaldırabilmesi ve admin panelinin stabil çalışması için Google Cloud Platform (GCP) ve Firebase servislerinden yararlanılması amaçlanmaktadır.
