using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OgrBilgiSistemi.Models;
using System.Linq;

namespace OgrBilgiSistemi.Controllers
{
    public class AdminController : Controller
    {
        private readonly OgrBilgiSistemiDbContext _context;

        public AdminController(OgrBilgiSistemiDbContext context)
        {
            _context = context;
        }

        // GÜVENLİK
        private bool KontrolEt()
        {
            // Session'da Admin değilse false dönecek.
            if (HttpContext.Session.GetInt32("Rol") != 1) return false;
            return true;
        }

        // 1.ANA SAYFA
        public IActionResult Index()
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            // İstatistikleri çekiyorum
            ViewBag.OgrenciSayisi = _context.Ogrencilers.Count();
            ViewBag.HocaSayisi = _context.Akademisyenlers.Count();
            ViewBag.DersSayisi = _context.Derslers.Count(d => d.AktifMi == true);
            ViewBag.ToplamKayit = _context.DersKayitlaris.Count();

            // Admin ismini ekrana yazdırma işlemi
            var kID = HttpContext.Session.GetInt32("KullaniciID");
            var admin = _context.Kullanicilars.Find(kID);
            if (admin != null)
            {
                ViewBag.AdminAd = admin.Ad + " " + admin.Soyad;
            }

            return View();
        }

        // 2. ÖĞRENCİ YÖNETİMİ
        public IActionResult OgrenciListesi()
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            var ogrenciler = _context.Ogrencilers
                .Include(o => o.Kullanici)
                .OrderBy(o => o.OgrenciNo)
                .ToList();

            return View(ogrenciler);
        }

        [HttpGet]
        public IActionResult OgrenciEkle()
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");
            return View();
        }

        [HttpPost]
        public IActionResult OgrenciEkle(string ad, string soyad, string email, int sinif)
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            try
            {
                // ÖNEMLİ: Trigger hatasını aşmak için SP kullanıyorum.
                // EF Core'un standart Ekleme metodu yerine bu SQL komutunu çalıştırıyorum
                string sql = "EXEC sp_OgrenciEkle {0}, {1}, {2}, {3}";
                _context.Database.ExecuteSqlRaw(sql, ad, soyad, email, (byte)sinif);

                TempData["Mesaj"] = "Öğrenci başarıyla eklendi.";
                return RedirectToAction("OgrenciListesi");
            }
            catch (System.Exception ex)
            {
                ViewBag.Hata = "Kayıt Başarısız: " + ex.Message;
                return View();
            }
        }

        public IActionResult OgrenciSil(int id)
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            var ogr = _context.Ogrencilers.Find(id);
            if (ogr != null)
            {
                // İlişkili kayıtları temizler (Notlar -> Öğrenci -> Kullanıcı)
                var notlar = _context.DersKayitlaris.Where(x => x.OgrenciId == id).ToList();
                _context.DersKayitlaris.RemoveRange(notlar);

                var user = _context.Kullanicilars.Find(ogr.KullaniciId);
                _context.Ogrencilers.Remove(ogr);

                if (user != null) _context.Kullanicilars.Remove(user);

                _context.SaveChanges();
            }
            return RedirectToAction("OgrenciListesi");
        }

        // 3. ÖĞRETMEN YÖNETİMİ
        public IActionResult OgretmenListesi()
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            var hocalar = _context.Akademisyenlers
                .Include(a => a.Kullanici)
                .ToList();

            return View(hocalar);
        }

        [HttpPost]
        public IActionResult HocaAta(int dersId, int hocaId)
        {
            //  Dersin hocasını değiştirmE SP Sİ
            _context.Database.ExecuteSqlRaw("EXEC sp_HocaDersAtama {0}, {1}", dersId, hocaId);

            return RedirectToAction("Dersler");
        }

        [HttpGet]
        public IActionResult OgretmenEkle()
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");
            return View();
        }

        [HttpPost]
        public IActionResult OgretmenEkle(string ad, string soyad, string email, string unvan)
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            try
            {
                // Öğretmen eklerken de Trigger'a takılmamak için SP kullanıyorum.
                string sql = "EXEC sp_OgretmenEkle {0}, {1}, {2}, {3}";
                _context.Database.ExecuteSqlRaw(sql, ad, soyad, email, unvan);

                TempData["Mesaj"] = "Akademisyen başarıyla eklendi.";
                return RedirectToAction("OgretmenListesi");
            }
            catch (System.Exception ex)
            {
                ViewBag.Hata = "Kayıt Başarısız: " + ex.Message;
                return View();
            }
        }

        //         ÖĞRETMEN SİLME KODU
        public IActionResult OgretmenSil(int id)
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            try
            {
                // SQL'de oluşturduğum sp_OgretmenSil'i çağırıyorum.
                string sql = "EXEC sp_OgretmenSil {0}";
                _context.Database.ExecuteSqlRaw(sql, id);

                return RedirectToAction("OgretmenListesi");
            }
            catch (System.Exception ex)
            {
                TempData["Hata"] = "Silme işlemi başarısız: " + ex.Message;
                return RedirectToAction("OgretmenListesi");
            }
        }


        // 4. DERS YÖNETİMİ
        public IActionResult DersListesi()
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            var dersler = _context.Derslers
                .Include(d => d.Hoca).ThenInclude(h => h.Kullanici)
                .OrderBy(d => d.Donem)
                .ToList();

            return View(dersler);
        }

        public IActionResult DersSil(int id)
        {
            if (!KontrolEt()) return RedirectToAction("Index", "Login");

            try
            {
                // Trigger hatasına takılmadan silme işlemi yapıyorum.
                string sql = "EXEC sp_DersSil {0}";
                _context.Database.ExecuteSqlRaw(sql, id);

                // İşlem başarılıysa listeye dön.
                return RedirectToAction("DersListesi");
            }
            catch (System.Exception ex)
            {
                // Hata olursa
                // Hatayı geçici olarak TempData'ya atıp listeye dönüyorum
                TempData["Hata"] = "Silme işlemi başarısız: " + ex.Message;
                return RedirectToAction("DersListesi");
            }
        }
    }
}