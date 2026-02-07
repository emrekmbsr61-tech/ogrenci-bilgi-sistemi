using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using OgrBilgiSistemi.Models;

namespace OgrBilgiSistemi.Controllers
{
    public class ProfilController : Controller
    {
        private readonly OgrBilgiSistemiDbContext _context;

        public ProfilController(OgrBilgiSistemiDbContext context)
        {
            _context = context;
        }
               // Şifre değiştirme.
        [HttpGet]
        public IActionResult SifreDegistir()
        {
            if (HttpContext.Session.GetInt32("KullaniciId") == null)
            {
                return RedirectToAction("Index", "Login");
            }
            return View();
        }

        [HttpPost]
        public IActionResult SifreDegistir(string eskiSifre, string yeniSifre)
        {
            int? kID = HttpContext.Session.GetInt32("KullaniciId");
            if (kID == null) return RedirectToAction("Index", "Login");

            try
            {
                // Şifreyi veritabanında SP ile değiştiriyorum.
                _context.Database.ExecuteSqlRaw("EXEC sp_SifreDegistir {0}, {1}, {2}", kID, eskiSifre, yeniSifre);

                TempData["Mesaj"] = "Şifreniz başarıyla değiştirildi.";
            }
            catch (Exception ex)
            {
                TempData["Hata"] = "Hata: Eski şifreniz yanlış olabilir.";
            }

            // YÖNLENDİRME AYARInı guncelledim.
            string rol = HttpContext.Session.GetString("Rol");

            if (rol == "Ogrenci")
                return RedirectToAction("Index", "Ogrenci");

            // Veritabanında rol 'Akademisyen' yazsa bile Kodda 'Ogretmen' controllerına gitmesini istiyorm.
            if (rol == "Akademisyen" || rol == "Ogretmen")
                return RedirectToAction("Index", "Ogretmen");

            if (rol == "Admin")
                return RedirectToAction("Index", "Admin");

            return RedirectToAction("SifreDegistir");
        }
    }
}