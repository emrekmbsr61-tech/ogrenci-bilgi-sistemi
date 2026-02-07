USE OgrBilgiSistemiDb;
GO

-- VIEW
-- 1. Výew, tablolarý tek tek birleþtirmek yerine bu View'i yazdým.
-- Öðrenci detaylarýný tek sorguda getirmemi saðlýyor.
CREATE OR ALTER VIEW vw_OgrenciDetaylari AS 
SELECT 
    o.OgrenciId, 
    o.OgrenciNo, 
    k.Ad + ' ' + k.Soyad AS OgrAd, 
    o.Sinif, 
    ISNULL(CAST(o.Agno AS VARCHAR), '-') AS AgnoGosterim, 
    d.DersAdi, 
    dk.HarfNotu, 
    dk.Durum, 
    dk.Ortalama 
FROM Ogrenciler o 
JOIN Kullanicilar k ON o.KullaniciId = k.KullaniciId 
LEFT JOIN DersKayitlari dk ON o.OgrenciId = dk.OgrenciId 
LEFT JOIN Dersler d ON dk.DersId = d.DersId;
GO
--SP
-- 1.SP DERS SEÇÝM LÝSTESÝ PROSEDÜRÜ
-- Öðrenci sayfayý açtýðýnda; Kaldýðý dersleri zorunlu olarak, geçtiði dersleri bilgi olarak,
-- üstten dersleri de AGNO'su yetiyorsa listeliyorum.

CREATE OR ALTER PROCEDURE sp_DersSecimListesi 
    @OgrenciId INT 
AS 
BEGIN
    DECLARE @Agno DECIMAL(5,2) = (SELECT ISNULL(Agno, 0) FROM Ogrenciler WHERE OgrenciId = @OgrenciId);
    DECLARE @Sinif INT = (SELECT Sinif FROM Ogrenciler WHERE OgrenciId = @OgrenciId);
    DECLARE @AktifDonem INT = (@Sinif * 2) - 1; 
    
    DECLARE @EksikZorunluDers INT = (SELECT COUNT(*) FROM Dersler d WHERE d.Donem <= @AktifDonem AND d.Donem % 2 = 1 AND d.ZorunluMu = 1 AND d.DersId NOT IN (SELECT DersId FROM DersKayitlari WHERE OgrenciId = @OgrenciId AND Durum IN ('Gecti', 'Devam')));
    DECLARE @UsttenAcikMi BIT = CASE WHEN @Agno >= 2.50 AND @EksikZorunluDers = 0 THEN 1 ELSE 0 END;

    -- ALTTAN DERSLER (Zorunlu)
    SELECT d.DersId, d.DersAdi, d.Akts, d.Donem, d.ZorunluMu, 'Alttan (Zorunlu)' AS Statu, 
           ISNULL(dk_gecmis.HarfNotu, 'FF') AS HarfNotu, 1 AS Oncelik, 1 AS SecilebilirMi, d.Kontenjan,
           CASE WHEN dk_gecmis.Durum = 'Devam' THEN 1 ELSE 0 END AS ZatenSecili
    FROM Dersler d 
    JOIN DersKayitlari dk_gecmis ON d.DersId = dk_gecmis.DersId
    WHERE dk_gecmis.OgrenciId = @OgrenciId 
      AND (dk_gecmis.Durum = 'Kaldý' OR (dk_gecmis.Durum = 'Devam' AND d.Donem < @AktifDonem))
      AND d.Donem < @AktifDonem AND d.Donem % 2 = 1

    UNION ALL
    -- DÖNEM DERSLERÝ (Standart)
    SELECT d.DersId, d.DersAdi, d.Akts, d.Donem, d.ZorunluMu, 'Dönem Dersi' AS Statu, 
           '-' AS HarfNotu, 2 AS Oncelik, 
           CASE WHEN @Sinif = 1 OR @Agno >= 2.00 THEN 1 ELSE 0 END AS SecilebilirMi, d.Kontenjan,
           CASE WHEN EXISTS (SELECT 1 FROM DersKayitlari WHERE OgrenciId = @OgrenciId AND DersId = d.DersId AND Durum = 'Devam') THEN 1 ELSE 0 END AS ZatenSecili
    FROM Dersler d WHERE d.Donem = @AktifDonem AND d.DersId NOT IN (SELECT DersId FROM DersKayitlari WHERE OgrenciId = @OgrenciId AND Durum IN ('Gecti', 'Kaldý'))

    UNION ALL
    -- ÜSTTEN DERSLER (Baþarýlýysa açýlýr)
    SELECT d.DersId, d.DersAdi, d.Akts, d.Donem, d.ZorunluMu, 'Üstten Ders' AS Statu, 
           '-' AS HarfNotu, 3 AS Oncelik, 
           CASE WHEN EXISTS (SELECT 1 FROM DersKayitlari WHERE OgrenciId = @OgrenciId AND DersId = d.DersId AND Durum = 'Devam') THEN 1 ELSE @UsttenAcikMi END AS SecilebilirMi, d.Kontenjan,
           CASE WHEN EXISTS (SELECT 1 FROM DersKayitlari WHERE OgrenciId = @OgrenciId AND DersId = d.DersId AND Durum = 'Devam') THEN 1 ELSE 0 END AS ZatenSecili
    FROM Dersler d WHERE d.Donem > @AktifDonem AND d.Donem % 2 = 1 
    AND d.DersId NOT IN (SELECT DersId FROM DersKayitlari WHERE OgrenciId = @OgrenciId AND Durum IN ('Gecti', 'Kaldý'))

    UNION ALL
    -- GEÇÝLEN DERSLER
    SELECT d.DersId, d.DersAdi, d.Akts, d.Donem, d.ZorunluMu, 'Geçildi' AS Statu, dk.HarfNotu, 4 AS Oncelik, 0 AS SecilebilirMi, d.Kontenjan, 0 AS ZatenSecili 
    FROM Dersler d JOIN DersKayitlari dk ON d.DersId = dk.DersId WHERE dk.OgrenciId = @OgrenciId AND dk.Durum = 'Gecti' 

    ORDER BY Oncelik, Donem;
END
GO

-- 2.SP DERS KAYIT EKLEME
-- Kredi limiti kontrolü yapýyoruz, uygunsa dersi ekliyorum.
CREATE OR ALTER PROCEDURE sp_DersKayitEkle 
    @OId INT, @DId INT 
AS 
BEGIN 
    SET NOCOUNT ON; 
    DECLARE @MevcutKredi INT;
    SELECT @MevcutKredi = ISNULL(SUM(d.Akts), 0) FROM DersKayitlari dk JOIN Dersler d ON dk.DersId = d.DersId 
    WHERE dk.OgrenciId = @OId AND dk.Durum = 'Devam' AND dk.DersId <> @DId;

    DECLARE @YeniDersKredi INT; SELECT @YeniDersKredi = Akts FROM Dersler WHERE DersId = @DId;
    DECLARE @Limit INT; SELECT @Limit = KrediLimiti FROM Ogrenciler WHERE OgrenciId = @OId;

    IF (@MevcutKredi + @YeniDersKredi) > @Limit
    BEGIN RAISERROR('KREDÝ LÝMÝTÝ YETERSÝZ! Bu dersi alamazsýnýz.', 16, 1); RETURN; END

    IF EXISTS (SELECT 1 FROM DersKayitlari WHERE OgrenciId = @OId AND DersId = @DId)
        UPDATE DersKayitlari SET Durum = 'Devam', VizeNotu=NULL, FinalNotu=NULL, ButNotu=NULL, Ortalama=0, HarfNotu='-' WHERE OgrenciId = @OId AND DersId = @DId;
    ELSE 
        INSERT INTO DersKayitlari (OgrenciId, DersId, Durum, HarfNotu) VALUES (@OId, @DId, 'Devam', '-'); 
END
GO

-- 3.SP NOT GÝRÝÞÝ
CREATE OR ALTER PROCEDURE sp_NotGirisi 
    @OgrId INT, @DersId INT, @Vize DECIMAL(5,2), @Final DECIMAL(5,2), @But DECIMAL(5,2) = NULL 
AS 
BEGIN 
    UPDATE DersKayitlari SET VizeNotu=@Vize, FinalNotu=@Final, ButNotu=@But WHERE OgrenciId=@OgrId AND DersId=@DersId 
END
GO

-- 4.SP HOCAYA DERS ATAMA
CREATE OR ALTER PROCEDURE sp_HocaDersAtama 
    @DId INT, @AId INT 
AS 
BEGIN 
    UPDATE Dersler SET HocaId=@AId WHERE DersId=@DId 
END
GO

-- 5.SP ÞÝFRE DEÐÝÞTÝRME
CREATE OR ALTER PROCEDURE sp_SifreDegistir 
    @KId INT, @Sifre NVARCHAR(50) 
AS 
BEGIN 
    UPDATE Kullanicilar SET Sifre=@Sifre WHERE KullaniciId=@KId 
END
GO

-- 6.SP DERS SÝLME
CREATE OR ALTER PROCEDURE sp_DersSil 
    @DId INT 
AS 
BEGIN 
    DELETE FROM Dersler WHERE DersId=@DId 
END
GO

-- 7.SP ÖÐRENCÝ EKLEME
CREATE OR ALTER PROCEDURE sp_OgrenciEkle 
    @Ad NVARCHAR(50), @Soyad NVARCHAR(50), @No NVARCHAR(20), @Sinif INT, @Bolum NVARCHAR(100) = 'Bilgisayar Mühendisliði' 
AS 
BEGIN 
    INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES (@Ad, @Soyad, @No+'@uni.edu.tr', 3); 
    INSERT INTO Ogrenciler (KullaniciId, OgrenciNo, Sinif, Bolum) VALUES (SCOPE_IDENTITY(), @No, @Sinif, @Bolum); 
END
GO

-- 8.SP ÖÐRETMEN EKLEME
CREATE OR ALTER PROCEDURE sp_OgretmenEkle 
    @Ad NVARCHAR(50), @Soyad NVARCHAR(50), @Email NVARCHAR(100), @Unvan NVARCHAR(50), @Bolum NVARCHAR(100) = 'Bilgisayar Mühendisliði' 
AS 
BEGIN 
    INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES (@Ad, @Soyad, @Email, 2); 
    INSERT INTO Akademisyenler (KullaniciId, Unvan, Bolum) VALUES (SCOPE_IDENTITY(), @Unvan, @Bolum); 
END
GO

-- 9.SP ÖÐRENCÝ SÝLME
CREATE OR ALTER PROCEDURE sp_OgrenciSil 
    @OId INT 
AS 
BEGIN 
    DELETE FROM Ogrenciler WHERE OgrenciId=@OId 
END
GO

-- 10.SP ÖÐRETMEN SÝLME
CREATE OR ALTER PROCEDURE sp_OgretmenSil 
    @AId INT 
AS 
BEGIN 
    DELETE FROM Akademisyenler WHERE AkademisyenId=@AId 
END
GO

-- 11.SP DERS BIRAKMA
CREATE OR ALTER PROCEDURE sp_DersBirak 
    @OId INT, @DId INT 
AS 
BEGIN 
    DECLARE @OgrSinif INT; SELECT @OgrSinif = Sinif FROM Ogrenciler WHERE OgrenciId = @OId;
    DECLARE @DersDonem INT; SELECT @DersDonem = Donem FROM Dersler WHERE DersId = @DId;
    DECLARE @AktifDonem INT = (@OgrSinif * 2) - 1;

    -- Öðrenci alttan dersi býrakmaya çalýþýrsa sistem tekrar ff durumuna getirsin.
    IF @DersDonem < @AktifDonem
    BEGIN
        UPDATE DersKayitlari 
        SET Durum = 'Kaldý', HarfNotu = 'FF', VizeNotu = 0, FinalNotu = 0, Ortalama = 0
        WHERE OgrenciId = @OId AND DersId = @DId AND Durum = 'Devam';
    END
    ELSE
    -- Yeni dönem dersiyse direkt silsin
    BEGIN
        DELETE FROM DersKayitlari WHERE OgrenciId = @OId AND DersId = @DId AND Durum = 'Devam';
    END
END
GO

-- 5. ADIM: VERÝ YÜKLEME
INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES ('Admin','Sistem','admin@uni.edu.tr',1); --Adminin Bilgileri

-- HOCALAR (20 TANE) hoca1,2... seklýnde @uni.edu.tr ile kullanýcý bilgileri girilip þifreye de 123 yazýnca sisteme giriyor.
DECLARE @hi INT = 1; WHILE @hi <= 20 BEGIN INSERT INTO Kullanicilar (Ad, Soyad, Email, Sifre, Rol) VALUES ('Hoca', CAST(@hi AS NVARCHAR), 'hoca' + CAST(@hi AS NVARCHAR) + '@uni.edu.tr', '123', 2); INSERT INTO Akademisyenler (KullaniciId, Unvan) VALUES (SCOPE_IDENTITY(), 'Dr. Öðr. Üyesi'); SET @hi += 1; END
GO

-- DERSLER sýrayla hocalara daðýtýlacak en sonki hocayý hiçbir derse atamayacaðým ki o hocayý silebildiðimiz görülsün(hoca20).
DECLARE @di INT = 1; 
WHILE @di <= 64 
BEGIN 
    DECLARE @AtanacakHocaId INT;
    -- Ýlk 60 ders için Hoca atadým (1-19 hocalarýý arasý).
    IF @di <= 60
        SET @AtanacakHocaId = ((@di - 1) % 19) + 1;
    ELSE
        -- Son 4 ders (61-64) için Hoca YOK bu sayede atanmamýþ dersler silinebilsin.
        SET @AtanacakHocaId = NULL;

    INSERT INTO Dersler (DersAdi, Donem, Kredi, Akts, HocaId) 
    VALUES ('Ders ' + CAST(@di AS NVARCHAR), ((@di-1)/8)+1, 3, 3, @AtanacakHocaId); 
    
    SET @di += 1; 
END
GO

-- TEST ÖÐRENCÝLERÝM  4 adet her sýnýftan 1 tane olacak þekilde.
INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES ('ogr1','Bir','ogr1@test.com',3); INSERT INTO Ogrenciler (KullaniciId, OgrenciNo, Sinif) VALUES (SCOPE_IDENTITY(), '2025001', 1);
INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES ('ogr2','Iki','ogr2@test.com',3); INSERT INTO Ogrenciler (KullaniciId, OgrenciNo, Sinif) VALUES (SCOPE_IDENTITY(), '2024001', 2);
INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES ('ogr3','Capraz','ogr3@test.com',3); INSERT INTO Ogrenciler (KullaniciId, OgrenciNo, Sinif) VALUES (SCOPE_IDENTITY(), '2023001', 3);
INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES ('ogr4','Dort','ogr4@test.com',3); INSERT INTO Ogrenciler (KullaniciId, OgrenciNo, Sinif) VALUES (SCOPE_IDENTITY(), '2022001', 4);

-- EKSTRA ÖÐRENCÝLER (60 ADET) - sistem dolu olsun diye.
DECLARE @si INT = 1; WHILE @si <= 60 BEGIN INSERT INTO Kullanicilar (Ad, Soyad, Email, Rol) VALUES ('Ogrenci',CAST(@si AS VARCHAR), 'ogrenci'+CAST(@si AS VARCHAR)+'@test.com', 3); INSERT INTO Ogrenciler (KullaniciId, OgrenciNo, Sinif) VALUES (SCOPE_IDENTITY(), '20251'+CAST(@si AS VARCHAR), (@si % 4) + 1); SET @si += 1; END
GO

-- Notlarý ve derssleri burada daðýttým.
DECLARE @op INT, @sp INT, @email NVARCHAR(100); 
DECLARE cur CURSOR FOR SELECT OgrenciId, Sinif, Email FROM Kullanicilar k JOIN Ogrenciler o ON k.KullaniciId=o.KullaniciId WHERE Sinif >= 1; 
OPEN cur; 
FETCH NEXT FROM cur INTO @op, @sp, @email; 

WHILE @@FETCH_STATUS = 0 
BEGIN
    DECLARE @DersId INT;
    DECLARE @AktifDonem INT = (@sp * 2) - 1;
    DECLARE @IsTestStudent BIT = 0;

    -- Test Öðrencilerimin ders secme lisstesinde hiçbir ders seçilmesin diye ayarladýmki biz seçelim görelim.
    IF @email IN ('ogr1@test.com', 'ogr2@test.com', 'ogr3@test.com', 'ogr4@test.com') SET @IsTestStudent = 1;

    -- Geçmiþ Dersleri herkes için yükledim
    DECLARE ders_cursor_gecmis CURSOR FOR SELECT DersId FROM Dersler WHERE Donem < @AktifDonem;
    OPEN ders_cursor_gecmis;
    FETCH NEXT FROM ders_cursor_gecmis INTO @DersId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Vize INT = NULL, @Final INT = NULL, @But INT = NULL;
        
        -- NOT BELÝRLEME
        IF @email = 'ogr3@test.com' -- Çapraza kalan test öðrencim.
        BEGIN
            IF (ABS(CHECKSUM(NEWID())) % 2) = 0 -- %50 FF
            BEGIN
                SET @Vize = 25 + (ABS(CHECKSUM(NEWID())) % 15);
                SET @Final = 30 + (ABS(CHECKSUM(NEWID())) % 15);
            END
            ELSE -- %50 Geçer (DD/DC)
            BEGIN
                SET @Vize = 45 + (ABS(CHECKSUM(NEWID())) % 15);
                SET @Final = 55 + (ABS(CHECKSUM(NEWID())) % 15);
            END
        END
        ELSE IF @email IN ('ogr2@test.com', 'ogr4@test.com') --Ýyi ortalamalý test öðrencilerim
        BEGIN
            SET @Vize = 65 + (ABS(CHECKSUM(NEWID())) % 35);
            SET @Final = 65 + (ABS(CHECKSUM(NEWID())) % 35);
        END
        ELSE -- Random öðrencilerimi yüksek agnolu yaptým.
        BEGIN
            SET @Vize = 55 + (ABS(CHECKSUM(NEWID())) % 40); -- En az 55
            SET @Final = 55 + (ABS(CHECKSUM(NEWID())) % 40);
        END

        -- BÜT KONTROL
        IF ((@Vize * 0.4) + (@Final * 0.6)) < 50
        BEGIN
            IF @email = 'ogr3@test.com'
                SET @But = 35 + (ABS(CHECKSUM(NEWID())) % 30); -- Yine kalabilir
            ELSE
                SET @But = 60 + (ABS(CHECKSUM(NEWID())) % 30);
        END

        INSERT INTO DersKayitlari (OgrenciId, DersId, VizeNotu, FinalNotu, ButNotu) 
        VALUES (@op, @DersId, @Vize, @Final, @But);

        FETCH NEXT FROM ders_cursor_gecmis INTO @DersId;
    END
    CLOSE ders_cursor_gecmis; DEALLOCATE ders_cursor_gecmis;

    -- 2. ADIM: Þu Anki Dönem Derslerini Yüklüyorum random öðrencilerim için rastgele daðýtýyorum.
    IF @IsTestStudent = 0 
    BEGIN
        DECLARE ders_cursor_aktif CURSOR FOR SELECT DersId FROM Dersler WHERE Donem = @AktifDonem;
        OPEN ders_cursor_aktif;
        FETCH NEXT FROM ders_cursor_aktif INTO @DersId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Notlar boþ, durum 'Devam'
            INSERT INTO DersKayitlari (OgrenciId, DersId, VizeNotu, FinalNotu, ButNotu) 
            VALUES (@op, @DersId, NULL, NULL, NULL);

            FETCH NEXT FROM ders_cursor_aktif INTO @DersId;
        END
        CLOSE ders_cursor_aktif; DEALLOCATE ders_cursor_aktif;
    END
    
	FETCH NEXT FROM cur INTO @op, @sp, @email; 
END 

CLOSE cur; DEALLOCATE cur;

--AGNO hesapldýma ve bitirdim.
UPDATE Ogrenciler SET Agno = dbo.fn_AgnoHesapla(OgrenciId);
UPDATE Ogrenciler SET KrediLimiti = CASE WHEN Agno >= 2.50 THEN 35 ELSE 30 END;
GO