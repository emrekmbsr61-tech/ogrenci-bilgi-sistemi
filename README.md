						Öğrenci Bilgi Sistemi Otomasyonu:
1-VERİ TABANI:
MS SQL veri tabanını kullandım.
SQL Server Management Stüdio açılıp önce;
 	Ogrenci_Bilgi_Sistemi1.sql daha sonra Ogrenci_Bilgi_Sistemi2.sql(Bunun çalışması 1,2 dakika arası sürüyor)çalıştırılır.
			(İkisini de Ctrl + A ile tümünü seç yapıp sırayla çalıştırın.)

2. PROJE AYARLARI (VISUAL STUDIO)

Proje veritabanı bağlantısı, varsayılan olarak yerel sunucuda (Server=.) çalışacak şekilde ayarlanmıştır.

Adım 1: OgrBilgiSistemi klasörüne girin
Adım 2: "OgrBilgiSistemi.sln" dosyasını Visual Studio ile açınız.
Adım 3: Sağ taraftaki "Solution Explorer" penceresinden "appsettings.json" dosyasını açın.
Adım 4: "ConnectionStrings" satırını bulun.
Adım 5: "Server=." kısmını silip, kendi bilgisayarınızdaki SQL Server adını yazın.
        (Örnek: "Server=DESKTOP-XYZ\SQLEXPRESS" veya "Server=(localdb)\mssqllocaldb")
Adım 6: Dosyayı kaydedin (CTRL + S) ve projeyi tekrar çalıştırın.

3-ÇALIŞTIRMA BİLGİLERİ:

A) Yönetici (Admin) Girişi:
   - Email: admin@uni.edu.tr
   - Şifre: 123
   - İşlem: 1-sayfasına girince Öğrenci listesi seçeneğine tıklayıp yeni öğrenci ekleyebilir öğrenci silebilir
	    2-Akademisyen yönetimi seçeneğine tıklayıp derse atanmamış hoca olan hoca20 yi silebilir yeni hoca ekleyebilir dersi olan hocayı silemez.
	    3-Ders işlemleri seçeneğine tıklayıp hocaya atanmamış olan dersleri silebilir (en altta bulunuyor).Hocası atanmış dersleri silemez.

B) Akademisyen (Hoca) Girişi:
   - Email: hoca1@uni.edu.tr(1,2,3,4... şeklinde 1 kısmı değişerek diğer hocaların sayfasına da girilebilir toplam 20 hoca var)
   - Şifre: 123(Herkesin şifresi aynı.)
   - işlem: Kendisine atanan dersleri görüyorlar ve derslere girip öğrencilere not girişi yaparlar.Vize, Final ve Büt şeklinde.

C) Öğrenci Girişi:
   - Email: ogr1@test.com(1. sınıf test öğrencim),ogr2@test.com(2. sınıf test öğrencim),ogr3@test.com(3. sınıf test öğrencim),
ogr4@test.com(4. sınıf test öğrencim)
   - Şifre: 123(Herkesin şifresi aynı.)
   - İşlem:  Güz dönemi ders seçimini yapar,kredisi duruma göre değişir alt dönem ve kendi dönem derslerini seçtikten sonra üst dönem dersleri açılır, notlarını ve transkriptini görüntüleyebilir.Verilen harf notlarına göre agnosu değişir.
