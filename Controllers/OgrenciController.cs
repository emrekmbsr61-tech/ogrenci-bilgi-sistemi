using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OgrBilgiSistemi.Models;
using Microsoft.Data.SqlClient;
using System.Collections.Generic;
using System.Linq;

namespace OgrBilgiSistemi.Controllers
{
    public class OgrenciController : Controller
    {
        private readonly OgrBilgiSistemiDbContext _context;

        public OgrenciController(OgrBilgiSistemiDbContext context)
        {
            _context = context;
        }

        private int? OturumKontrol()
        {
            return HttpContext.Session.GetInt32("KullaniciID");
        }

        public IActionResult Index()
        {
            var kID = OturumKontrol();
            if (kID == null) return RedirectToAction("Index", "Login");

            var ogrenci = _context.Ogrencilers
                .Include(o => o.Kullanici)
                .Include(o => o.Danisman)
                .ThenInclude(d => d.Kullanici)
                .FirstOrDefault(o => o.KullaniciId == kID);

            if (ogrenci == null) return RedirectToAction("Index", "Login");

            return View(ogrenci);
        }

        [HttpGet]
        public IActionResult DersSecimi()
        {
            var kID = OturumKontrol();
            if (kID == null) return RedirectToAction("Index", "Login");

            var ogrenci = _context.Ogrencilers.FirstOrDefault(o => o.KullaniciId == kID);
            if (ogrenci == null) return RedirectToAction("Index", "Login");

            // SQL Parametresini burada güvenlik.
            var paramOid = new SqlParameter("@OgrenciId", ogrenci.OgrenciId);
            var dersListesi = _context.Set<DersSecimViewModel>()
                .FromSqlRaw("EXEC sp_DersSecimListesi @OgrenciId", paramOid)
                .ToList();

            var suAnkiKredi = dersListesi.Where(d => d.ZatenSecili == 1).Sum(d => d.Akts);

            ViewBag.Ogrenci = ogrenci;
            ViewBag.SuAnkiKredi = suAnkiKredi;

            return View(dersListesi);
        }

        [HttpPost]
        public IActionResult DersSecimi(List<int> secilenDersler)
        {
            var kID = OturumKontrol();
            if (kID == null) return RedirectToAction("Index", "Login");

            var ogrenci = _context.Ogrencilers.FirstOrDefault(o => o.KullaniciId == kID);
            if (secilenDersler == null) secilenDersler = new List<int>();

            try
            {
                
                var eskiSecimler = _context.DersKayitlaris
                    .Where(dk => dk.OgrenciId == ogrenci.OgrenciId && dk.Durum == "Devam");

                _context.DersKayitlaris.RemoveRange(eskiSecimler);
                _context.SaveChanges();

                
                foreach (var dersId in secilenDersler)
                {
                    // KRİTİK NOKTA: Parametreleri açıkça isimlendirerek gönderiyorum
                    var pOid = new SqlParameter("@OId", ogrenci.OgrenciId);
                    var pDid = new SqlParameter("@DId", dersId);

                    _context.Database.ExecuteSqlRaw("EXEC sp_DersKayitEkle @OId, @DId", pOid, pDid);
                }

                TempData["Mesaj"] = "Ders seçiminiz başarıyla güncellendi.";
            }
            catch (Exception ex)
            {
                // Eğer trigger'dan bir hata gelirse bildir.
                TempData["Hata"] = "İşlem sırasında hata oluştu: " + ex.Message;
            }

            return RedirectToAction("DersSecimi");
        }

        public IActionResult Transkript()
        {
            var kID = OturumKontrol();
            if (kID == null) return RedirectToAction("Index", "Login");

            var ogrenci = _context.Ogrencilers.FirstOrDefault(o => o.KullaniciId == kID);
            var notlar = _context.DersKayitlaris
                .Include(dk => dk.Ders)
                .Where(dk => dk.OgrenciId == ogrenci.OgrenciId && dk.Durum != "Devam")
                .OrderBy(dk => dk.Ders.Donem)
                .ToList();

            return View(notlar);
        }
    }
}