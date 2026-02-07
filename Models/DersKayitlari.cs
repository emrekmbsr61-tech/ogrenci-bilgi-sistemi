using System;
using System.Collections.Generic;

namespace OgrBilgiSistemi.Models;

public partial class DersKayitlari
{
    public int KayitId { get; set; }

    public int? OgrenciId { get; set; }

    public int? DersId { get; set; }

    // NOTLAR,Hepsi Decimal cinsinden oluşturdum.
    public decimal? VizeNotu { get; set; }

    public decimal? FinalNotu { get; set; }

    // ButNotunun tıpıını Decimal yaptım vize finalle uyumlu olsun.
    public decimal? ButNotu { get; set; }

    public decimal? Ortalama { get; set; }

    public string? HarfNotu { get; set; }

    public string? Durum { get; set; }
    
    public virtual Dersler? Ders { get; set; } // Bu kayıt hangi derse aitse, o dersin tüm detaylarını içinde taşıyacak.

    public virtual Ogrenciler? Ogrenci { get; set; } // Bu kaydı hangi öğrenci aldıysa, o öğrencinin tüm bilgilerini getirecek.
}