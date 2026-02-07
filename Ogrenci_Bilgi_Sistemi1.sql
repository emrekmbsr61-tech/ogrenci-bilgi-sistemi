USE OgrBilgiSistemiDb;
GO

-- 1. ADIM - TEMÝZLÝK VE TABLOLAR
-- Hocam, projeyi her çalýþtýrdýðýmýzda hata almayalým, çakýþma olmasýn diye
-- önce var olan tablolarý sildim.
IF OBJECT_ID('SistemLoglari', 'U') IS NOT NULL DROP TABLE SistemLoglari;
IF OBJECT_ID('DersKayitlari', 'U') IS NOT NULL DROP TABLE DersKayitlari;
IF OBJECT_ID('Dersler', 'U') IS NOT NULL DROP TABLE Dersler;
IF OBJECT_ID('Ogrenciler', 'U') IS NOT NULL DROP TABLE Ogrenciler;
IF OBJECT_ID('Akademisyenler', 'U') IS NOT NULL DROP TABLE Akademisyenler;
IF OBJECT_ID('Kullanicilar', 'U') IS NOT NULL DROP TABLE Kullanicilar;
IF OBJECT_ID('vw_OgrenciDetaylari', 'V') IS NOT NULL DROP VIEW vw_OgrenciDetaylari;
GO

-- Burasý sistemin ana giriþ kapýsý. Admin, Hoca ve Öðrenci hepsi burada.
-- Rol sütunuyla kimin ne olduðunu ayýrýyorum (1:Admin, 2:Hoca, 3:Öðrenci).
CREATE TABLE Kullanicilar (
    KullaniciId INT IDENTITY(1,1) PRIMARY KEY,
    Ad NVARCHAR(50), 
    Soyad NVARCHAR(50), 
    Email NVARCHAR(100) UNIQUE, 
    Sifre NVARCHAR(50) DEFAULT '123',--þifreyi 123 diye belirledim 
    Rol INT
);
GO

-- Akademisyenleri kullanýcý tablosuna baðladým.Unvan bilgilerini burada tutuyoruz.
CREATE TABLE Akademisyenler (
    AkademisyenId INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId INT REFERENCES Kullanicilar(KullaniciId),
    Bolum NVARCHAR(100) DEFAULT 'Bilgisayar Mühendisliði', 
    Unvan NVARCHAR(50)
);
GO

-- Öðrencilerin akademik bilgilerini (AGNO, Sýnýf, Danýþman) burada tutuyorum.
-- 'ON DELETE CASCADE' yaptýk ki, öðrenciyi silince ona ait veri kalmasýn.
CREATE TABLE Ogrenciler (
    OgrenciId INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciId INT REFERENCES Kullanicilar(KullaniciId) ON DELETE CASCADE,
    Bolum NVARCHAR(100) DEFAULT 'Bilgisayar Mühendisliði',
    OgrenciNo NVARCHAR(20) UNIQUE, 
    Sinif TINYINT, 
    Agno DECIMAL(5,2) DEFAULT 0,
    KrediLimiti INT DEFAULT 30, 
    DanismanId INT REFERENCES Akademisyenler(AkademisyenId)
);
GO

-- Derslerin kredisi, AKTS'si ve hocasý burada. 
-- Kontenjan kontrolü için burayý kullanacaðým.
CREATE TABLE Dersler (
    DersId INT IDENTITY(1,1) PRIMARY KEY,
    DersAdi NVARCHAR(100), 
    Donem INT, 
    Kredi INT DEFAULT 3, 
    Akts INT DEFAULT 3, 
    HocaId INT REFERENCES Akademisyenler(AkademisyenId), 
    Kontenjan INT DEFAULT 80, 
    ZorunluMu BIT DEFAULT 1, 
    AktifMi BIT DEFAULT 1
);
GO

-- Hangi öðrenci hangi dersi almýþ bu tabloda tutuyorum.
CREATE TABLE DersKayitlari (
    KayitId INT IDENTITY(1,1) PRIMARY KEY,
    OgrenciId INT REFERENCES Ogrenciler(OgrenciId) ON DELETE CASCADE,
    DersId INT REFERENCES Dersler(DersId),
    VizeNotu DECIMAL(5,2) NULL, 
    FinalNotu DECIMAL(5,2) NULL, 
    ButNotu DECIMAL(5,2) NULL, 
    Ortalama DECIMAL(5,2) DEFAULT 0, 
    Durum NVARCHAR(20) DEFAULT 'Devam', 
    HarfNotu NVARCHAR(2) DEFAULT '-', 
    CONSTRAINT UQ_Ogr_Ders UNIQUE(OgrenciId, DersId) -- FF olmayan Ayný dersi iki kere almayý engelledim.
);
GO

-- Arka planda kim ne iþlem yaparsa buraya kaydediyorum (Loglama).
CREATE TABLE SistemLoglari (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    OgrenciId INT, 
    DersId INT, 
    IslemTarihi DATETIME DEFAULT GETDATE(), 
    IslemTuru NVARCHAR(50), 
    Aciklama NVARCHAR(250)
);
GO

-- 2. ADIM - FONKSÝYONLAR

-- 1.Not ortalamasýna bakýp Harf Notunu (AA, BB, FF) çýkaran fonksiyonum.
CREATE OR ALTER FUNCTION fn_HarfNotuBul (@Ortalama DECIMAL(5,2), @FinalOrBut DECIMAL(5,2)) RETURNS NVARCHAR(2) AS 
BEGIN
    IF @FinalOrBut IS NULL OR @Ortalama IS NULL RETURN '-'
    -- Hocam kural gereði Finalden 50 alamayan direkt kalýr (FF).
    IF @FinalOrBut < 50 RETURN 'FF' 
    
    IF @Ortalama >= 90 RETURN 'AA' 
    IF @Ortalama >= 85 RETURN 'BA' 
    IF @Ortalama >= 80 RETURN 'BB' 
    IF @Ortalama >= 75 RETURN 'CB' 
    IF @Ortalama >= 70 RETURN 'CC' 
    IF @Ortalama >= 60 RETURN 'DC' 
    IF @Ortalama >= 50 RETURN 'DD' 
    
    RETURN 'FF' 
END
GO

-- 2.Öðrencinin AGNO'sunu hesaplayan fonksiyon.
-- Sadece kredi getiren dersleri (Geçti/Kaldý) topluyorum.
CREATE OR ALTER FUNCTION fn_AgnoHesapla (@OgrenciId INT) RETURNS DECIMAL(5,2) AS 
BEGIN
    DECLARE @Puan DECIMAL(10,2) = 0, @Akts INT = 0;
    SELECT @Puan = SUM(d.Akts * CASE dk.HarfNotu 
            WHEN 'AA' THEN 4.0 WHEN 'BA' THEN 3.5 WHEN 'BB' THEN 3.0 
            WHEN 'CB' THEN 2.5 WHEN 'CC' THEN 2.0 WHEN 'DC' THEN 1.5 
            WHEN 'DD' THEN 1.0 ELSE 0.0 END),
           @Akts = SUM(d.Akts) 
    FROM DersKayitlari dk JOIN Dersler d ON dk.DersId = d.DersId 
    WHERE dk.OgrenciId = @OgrenciId AND dk.Durum IN ('Gecti', 'Kaldý') AND dk.HarfNotu <> '-' AND dk.HarfNotu <> '--';
    
    RETURN CASE WHEN @Akts > 0 THEN @Puan / @Akts ELSE 0.00 END 
END
GO

-- 3.Dersin kotasý doldu mu dolmadý mý diye kontrol eden fonksiyonum.
CREATE OR ALTER FUNCTION fn_KontenjanDoluluk (@DersId INT) RETURNS INT AS 
BEGIN 
    RETURN (SELECT COUNT(*) FROM DersKayitlari WHERE DersId = @DersId AND Durum = 'Devam') 
END
GO

-- 3. ADIM - TRIGGERLAR (Sistemin Bekçileri)

-- 1. Trigger, Hoca not girdiði anda otomatik çalýþýyor;
-- Ortalamayý, harf notunu ve öðrencinin AGNO'sunu anýnda güncelliyor.
CREATE OR ALTER TRIGGER trg_NotHesapla ON DersKayitlari AFTER INSERT, UPDATE AS 
BEGIN
    SET NOCOUNT ON; 
    IF UPDATE(VizeNotu) OR UPDATE(FinalNotu) OR UPDATE(ButNotu) OR EXISTS(SELECT 1 FROM inserted WHERE VizeNotu IS NOT NULL) 
    BEGIN
        -- Bütünleme varsa final yerine onu sayýyorum.
        UPDATE dk SET 
            dk.Ortalama = (ISNULL(i.VizeNotu, 0) * 0.40) + (COALESCE(i.ButNotu, i.FinalNotu, 0) * 0.60),
            dk.HarfNotu = dbo.fn_HarfNotuBul((ISNULL(i.VizeNotu, 0) * 0.40) + (COALESCE(i.ButNotu, i.FinalNotu, 0) * 0.60), COALESCE(i.ButNotu, i.FinalNotu, 0)),
            dk.Durum = CASE WHEN dbo.fn_HarfNotuBul((ISNULL(i.VizeNotu, 0) * 0.40) + (COALESCE(i.ButNotu, i.FinalNotu, 0) * 0.60), COALESCE(i.ButNotu, i.FinalNotu, 0)) = 'FF' THEN 'Kaldý' ELSE 'Gecti' END
        FROM DersKayitlari dk JOIN inserted i ON dk.KayitId = i.KayitId
        WHERE i.VizeNotu IS NOT NULL AND i.FinalNotu IS NOT NULL;

        -- Notu eksikse ortalama 0 görünsün þu anlýk.
        UPDATE dk SET dk.Ortalama = 0, dk.HarfNotu = '-', dk.Durum = 'Devam'
        FROM DersKayitlari dk JOIN inserted i ON dk.KayitId = i.KayitId
        WHERE i.VizeNotu IS NULL OR i.FinalNotu IS NULL;

        -- AGNO deðiþtiði için kredi limitini de güncelliyorum. 
		--2.50 agno üstüne 35 kredi verdim altýna 30 kredi verdim
        UPDATE o SET 
            o.Agno = dbo.fn_AgnoHesapla(o.OgrenciId),
            o.KrediLimiti = CASE WHEN dbo.fn_AgnoHesapla(o.OgrenciId) >= 2.50 THEN 35 ELSE 30 END
        FROM Ogrenciler o JOIN inserted i ON o.OgrenciId = i.OgrenciId; 
    END 
END
GO

-- 2. Trigger Yanlýþlýkla hocasý olan ders silinmesin diye güvenliði saðlýyo..
CREATE OR ALTER TRIGGER trg_DersSilmeEngel ON Dersler INSTEAD OF DELETE AS 
BEGIN
    SET NOCOUNT ON; 
    IF EXISTS (SELECT 1 FROM deleted WHERE HocaId IS NOT NULL) 
    BEGIN 
        RAISERROR ('HOCASI OLAN DERS SÝLÝNEMEZ! Önce hocayý boþa çýkarýn.', 16, 1); 
        ROLLBACK TRANSACTION; 
    END
    ELSE 
    BEGIN 
        DELETE FROM DersKayitlari WHERE DersId IN (SELECT DersId FROM deleted); 
        DELETE FROM Dersler WHERE DersId IN (SELECT DersId FROM deleted); 
    END 
END
GO

-- 3. Trigger Ders seçerken kota dolduysa sistemi durduran trigger.
CREATE OR ALTER TRIGGER trg_KontenjanKontrol ON DersKayitlari AFTER INSERT AS 
BEGIN
    SET NOCOUNT ON; 
    IF EXISTS (SELECT 1 FROM inserted i JOIN Dersler d ON i.DersId = d.DersId WHERE dbo.fn_KontenjanDoluluk(i.DersId) > d.Kontenjan)
    BEGIN 
        RAISERROR('DERS KONTENJANI DOLU! Kayýt yapýlamadý.', 16, 1); 
        ROLLBACK TRANSACTION; 
    END 
END
GO

-- 4. Trigger Yapýlan ders iþlemlerini log tablosuna basmasýný saðladým.
CREATE OR ALTER TRIGGER trg_LogKayit ON DersKayitlari AFTER INSERT AS 
BEGIN 
    SET NOCOUNT ON; 
    INSERT INTO SistemLoglari (OgrenciId, DersId, IslemTuru, Aciklama) 
    SELECT OgrenciId, DersId, 'LOG', 'Islem yapildi' FROM inserted 
END
GO