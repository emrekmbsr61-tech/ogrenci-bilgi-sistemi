using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OgrBilgiSistemi.Models;
using System.Linq;
using System;
using System.Globalization;

namespace OgrBilgiSistemi.Controllers
{
    public class OgretmenController : Controller
    {
        private readonly OgrBilgiSistemiDbContext _context;

        public OgretmenController(OgrBilgiSistemiDbContext context)
        {
            _context = context;
        }

        private int? OturumKontrol()
        {
            if (HttpContext.Session.GetInt32("Rol") != 2) return null;
            return HttpContext.Session.GetInt32("KullaniciID");
        }

        public IActionResult Index()
        {
            var kID = OturumKontrol();
            if (kID == null) return RedirectToAction("Index", "Login");

            var hoca = _context.Akademisyenlers.Include(a => a.Kullanici).FirstOrDefault(a => a.KullaniciId == kID);
            var dersler = _context.Derslers.Where(d => d.HocaId == hoca.AkademisyenId).ToList();

            ViewBag.HocaAd = hoca.Unvan + " " + hoca.Kullanici.Ad + " " + hoca.Kullanici.Soyad;
            return View(dersler);
        }

        [HttpGet]  // Not girme
        public IActionResult NotGiris(int id)
        {
            var kID = OturumKontrol();
            if (kID == null) return RedirectToAction("Index", "Login");

            var ders = _context.Derslers.Find(id);
            if (ders == null) return RedirectToAction("Index");

            var kayitlar = _context.DersKayitlaris
                .Include(dk => dk.Ogrenci).ThenInclude(o => o.Kullanici)
                .Where(dk => dk.DersId == id)
                .OrderBy(dk => dk.Ogrenci.OgrenciNo)
                .ToList();

            ViewBag.DersAdi = ders.DersAdi;
            ViewBag.DersId = id;
            return View(kayitlar);
        }

        [HttpPost]
        public IActionResult NotKaydet(int ogrenciId, int dersId, string vize, string final, string but)
        {
            if (OturumKontrol() == null) return RedirectToAction("Index", "Login");

            try
            {
                // Formatı düzeltiyorum
                string Normalize(string val) => string.IsNullOrWhiteSpace(val) ? null : val.Replace(",", ".");

                // DBNull hatasını önlemek için decimal? kullandım.
                decimal? vizeNot = null;
                decimal? finalNot = null;
                decimal? butNot = null;

                if (!string.IsNullOrWhiteSpace(vize)) vizeNot = decimal.Parse(Normalize(vize), CultureInfo.InvariantCulture);
                if (!string.IsNullOrWhiteSpace(final)) finalNot = decimal.Parse(Normalize(final), CultureInfo.InvariantCulture);
                if (!string.IsNullOrWhiteSpace(but)) butNot = decimal.Parse(Normalize(but), CultureInfo.InvariantCulture);

                string sql = "EXEC sp_NotGirisi {0}, {1}, {2}, {3}, {4}";
                _context.Database.ExecuteSqlRaw(sql, ogrenciId, dersId, vizeNot, finalNot, butNot);

                TempData["Mesaj"] = "Başarıyla kaydedildi.";
            }
            catch (Exception ex)
            {
                TempData["Hata"] = "Hata: " + ex.Message;
            }

            return RedirectToAction("NotGiris", new { id = dersId });
        }
    }
}