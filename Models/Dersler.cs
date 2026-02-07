using System;
using System.Collections.Generic;

namespace OgrBilgiSistemi.Models;

public partial class Dersler
{
    public int DersId { get; set; }

    public string? DersAdi { get; set; }

    public int? Kredi { get; set; }

    public int? Akts { get; set; }

    public int? Donem { get; set; }

    public bool? ZorunluMu { get; set; }

    public int? HocaId { get; set; }

    public int? Kontenjan { get; set; }

    public bool? AktifMi { get; set; }

    public virtual ICollection<DersKayitlari> DersKayitlaris { get; set; } = new List<DersKayitlari>();

    public virtual Akademisyenler? Hoca { get; set; }
}
