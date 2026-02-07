using System;
using System.Collections.Generic;

namespace OgrBilgiSistemi.Models;

public partial class VwOgrenciTranskriptDetay
{
    public string? OgrenciNo { get; set; }

    public string OgrenciAdSoyad { get; set; } = null!;

    public string? DersAdi { get; set; }

    public decimal? VizeNotu { get; set; }

    public decimal? FinalNotu { get; set; }

    public decimal? Ortalama { get; set; }

    public string? HarfNotu { get; set; }

    public string? Durum { get; set; }
}
