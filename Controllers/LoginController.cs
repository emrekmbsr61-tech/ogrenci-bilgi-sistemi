using Microsoft.AspNetCore.Mvc;
using OgrBilgiSistemi.Models;


namespace OgrenciBilgiSistemi.Controllers
{
    public class LoginController : Controller
    {
        private readonly OgrBilgiSistemiDbContext _context;

        // Veritabanını çağırıyorum
        public LoginController(OgrBilgiSistemiDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Index(string email, string sifre)
        {
            // Kullanıcıyı veritabanında buluyorum.
            var kullanici = _context.Kullanicilars
                .FirstOrDefault(k => k.Email == email && k.Sifre == sifre);

            if (kullanici != null)
            {
                // Giriş Başarılı, Bilgileri hafızaya atıyorum
                HttpContext.Session.SetInt32("KullaniciID", kullanici.KullaniciId);
                HttpContext.Session.SetString("AdSoyad", kullanici.Ad + " " + kullanici.Soyad);
                HttpContext.Session.SetInt32("Rol", (int)kullanici.Rol);

                // Role göre yönlendir
                if (kullanici.Rol == 1) return RedirectToAction("Index", "Admin");       // Admin
                if (kullanici.Rol == 2) return RedirectToAction("Index", "Ogretmen");    // Öğretmen
                if (kullanici.Rol == 3) return RedirectToAction("Index", "Ogrenci");     // Öğrenci
            }

            // Hatalı giriş
            ViewBag.Hata = "E-Posta veya Şifre hatalı!";
            return View();
        }

        public IActionResult CikisYap()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Index");
        }
    }
}