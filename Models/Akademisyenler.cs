using System;
using System.Collections.Generic;

namespace OgrBilgiSistemi.Models;

public partial class Akademisyenler
{
    public int AkademisyenId { get; set; }

    public int? KullaniciId { get; set; }

    public string? Unvan { get; set; }

    public virtual ICollection<Dersler> Derslers { get; set; } = new List<Dersler>();

    public virtual Kullanicilar? Kullanici { get; set; }

    public virtual ICollection<Ogrenciler> Ogrencilers { get; set; } = new List<Ogrenciler>();
}
