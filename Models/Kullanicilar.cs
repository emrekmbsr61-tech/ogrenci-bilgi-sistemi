using System;
using System.Collections.Generic;

namespace OgrBilgiSistemi.Models
{
    public partial class Kullanicilar
    {
        public int KullaniciId { get; set; }
        public string Ad { get; set; } = null!;
        public string Soyad { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Sifre { get; set; } = null!;
        public int Rol { get; set; }

        // 1 Kullanıcının sadece 1 tane Akademisyenliği veya Öğrenciliği olur.
        public virtual Akademisyenler? Akademisyen { get; set; }
        public virtual Ogrenciler? Ogrenci { get; set; }
    }
}