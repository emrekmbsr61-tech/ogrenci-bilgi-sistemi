using Microsoft.EntityFrameworkCore;
using OgrBilgiSistemi.Models;
using OgrBilgiSistemi.Models;

var builder = WebApplication.CreateBuilder(args);

// 1. Veritabaný Baðlantýsýný Tanýtýyorum
builder.Services.AddDbContext<OgrBilgiSistemiDbContext>(options =>
    options.UseSqlServer("Server=.;Database=OgrBilgiSistemiDb;Trusted_Connection=True;TrustServerCertificate=True;"));

// 2. Oturum Açýyorum
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(20); // 20 dk hareketsiz kalýnca çýkýþ yapýlsýn.
});

builder.Services.AddControllersWithViews();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
}

app.UseStaticFiles();
app.UseRouting();

// 3. Sýralama : önce oturum açýlýr, sonra yetkilendirme
app.UseSession();
app.UseAuthorization();

// Baþlangýç rotasý Login olsun
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Login}/{action=Index}/{id?}");

app.Run();