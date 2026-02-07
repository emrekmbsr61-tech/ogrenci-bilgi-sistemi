using System;
using System.Collections.Generic;

namespace OgrBilgiSistemi.Models;

public partial class Ogrenciler
{
    public int OgrenciId { get; set; }

    public int? KullaniciId { get; set; }

    public string? OgrenciNo { get; set; }

    public string? Bolum { get; set; }

    public byte? Sinif { get; set; }

    public decimal? Agno { get; set; }

    public int? KrediLimiti { get; set; }

    public int? DanismanId { get; set; }

    public virtual Akademisyenler? Danisman { get; set; }

    public virtual ICollection<DersKayitlari> DersKayitlaris { get; set; } = new List<DersKayitlari>();

    public virtual Kullanicilar? Kullanici { get; set; }
}
