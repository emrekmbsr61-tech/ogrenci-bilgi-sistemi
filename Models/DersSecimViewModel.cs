namespace OgrBilgiSistemi.Models
{
    public class DersSecimViewModel
    {
        public int DersId { get; set; }
        public string DersAdi { get; set; }
        public int Akts { get; set; }     // SQL'de Kredi değil Akts diye çekmiştim bır sıkıntı olmasın dıye boyle yaptım.
        public int Donem { get; set; }
        public bool ZorunluMu { get; set; }
        public string Statu { get; set; }      // "Alttan", "Kendi Dönemi" vb.
        public string HarfNotu { get; set; }   // "AA", "FF", "--"
        public int Oncelik { get; set; }       // Sıralama için
        public int SecilebilirMi { get; set; } // 1: Seçebilir, 0: Seçemez
        public int? Kontenjan { get; set; }    // Kota kontrolü için

        public int ZatenSecili { get; set; }

    }
}