using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace OgrBilgiSistemi.Models
{
    public partial class OgrBilgiSistemiDbContext : DbContext
    {
        public OgrBilgiSistemiDbContext()
        {
        }

        public OgrBilgiSistemiDbContext(DbContextOptions<OgrBilgiSistemiDbContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Akademisyenler> Akademisyenlers { get; set; }
        public virtual DbSet<DersKayitlari> DersKayitlaris { get; set; }
        public virtual DbSet<Dersler> Derslers { get; set; }
        public virtual DbSet<Kullanicilar> Kullanicilars { get; set; }
        public virtual DbSet<Ogrenciler> Ogrencilers { get; set; }


        // SQL'deki View'i karşılamak için eklediğimiz sanal tablo
        public virtual DbSet<DersSecimViewModel> DersSecimViewModels { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            {
                //'DersSecimViewModel' gerçek bir tablo değil, SQL View'inden gelen
                // veriyi tutmak için kullandığım bir model. O yüzden 'HasNoKey' dedim.
                modelBuilder.Entity<DersSecimViewModel>().HasNoKey();

                base.OnModelCreating(modelBuilder);
            }
            // 1. DERS KAYITLARI 
            modelBuilder.Entity<DersKayitlari>(entity =>
            {
                entity.HasKey(e => e.KayitId);
                entity.ToTable("DersKayitlari");

                // Eski sütun tanımlarını (ButunlemeNotu, OnaylandiMi vs.) kaldırdım.
                // Sadece veritabanında olanları yazdım.

                entity.Property(e => e.VizeNotu).HasColumnType("decimal(5, 2)").HasDefaultValueSql("((0))");
                entity.Property(e => e.FinalNotu).HasColumnType("decimal(5, 2)").HasDefaultValueSql("((0))");
                entity.Property(e => e.ButNotu).HasColumnType("decimal(5, 2)"); // Yeni isim

                entity.Property(e => e.Ortalama).HasColumnType("decimal(5, 2)").HasDefaultValueSql("((0))");
                entity.Property(e => e.Durum).HasMaxLength(10).HasDefaultValueSql("('Devam')");
                entity.Property(e => e.HarfNotu).HasMaxLength(2).HasDefaultValueSql("('--')");

                entity.HasOne(d => d.Ders).WithMany(p => p.DersKayitlaris)
                    .HasForeignKey(d => d.DersId).OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(d => d.Ogrenci).WithMany(p => p.DersKayitlaris)
                    .HasForeignKey(d => d.OgrenciId).OnDelete(DeleteBehavior.Cascade);
            });

            // 2. KULLANICILAR
            modelBuilder.Entity<Kullanicilar>(entity =>
            {
                entity.HasKey(e => e.KullaniciId);
                entity.ToTable("Kullanicilar");
                entity.HasIndex(e => e.Email, "UQ_Kullanici_Email").IsUnique();

                entity.Property(e => e.KullaniciId).HasColumnName("KullaniciID");
                entity.Property(e => e.Ad).HasMaxLength(50);
                entity.Property(e => e.Email).HasMaxLength(100);
                entity.Property(e => e.Sifre).HasMaxLength(20).HasDefaultValueSql("('123')");
                entity.Property(e => e.Soyad).HasMaxLength(50);
                entity.Property(e => e.Rol).HasColumnType("int");
            });

            // 3. AKADEMISYENLER
            modelBuilder.Entity<Akademisyenler>(entity =>
            {
                entity.HasKey(e => e.AkademisyenId);
                entity.ToTable("Akademisyenler");
                entity.HasIndex(e => e.KullaniciId, "UQ_Akademisyen_Kullanici").IsUnique();
                entity.Property(e => e.AkademisyenId).HasColumnName("AkademisyenID");
                entity.Property(e => e.KullaniciId).HasColumnName("KullaniciID");
                entity.Property(e => e.Unvan).HasMaxLength(20);

                entity.HasOne(d => d.Kullanici).WithOne(p => p.Akademisyen)
                    .HasForeignKey<Akademisyenler>(d => d.KullaniciId)
                    .OnDelete(DeleteBehavior.ClientSetNull);
            });

            // 4. OGRENCILER
            modelBuilder.Entity<Ogrenciler>(entity =>
            {
                entity.HasKey(e => e.OgrenciId);
                entity.ToTable("Ogrenciler");
                entity.HasIndex(e => e.KullaniciId, "UQ_Ogrenci_Kullanici").IsUnique();
                entity.HasIndex(e => e.OgrenciNo, "UQ_Ogrenci_No").IsUnique();
                entity.Property(e => e.Agno).HasColumnType("decimal(4, 2)").HasDefaultValueSql("((0))");
                entity.Property(e => e.Bolum).HasMaxLength(50).HasDefaultValueSql("('Bilgisayar Mühendisliği')");
                entity.Property(e => e.KrediLimiti).HasDefaultValueSql("((30))");
                entity.Property(e => e.OgrenciNo).HasMaxLength(20);

                entity.HasOne(d => d.Danisman).WithMany(p => p.Ogrencilers)
                    .HasForeignKey(d => d.DanismanId).OnDelete(DeleteBehavior.SetNull);

                entity.HasOne(d => d.Kullanici).WithOne(p => p.Ogrenci)
                    .HasForeignKey<Ogrenciler>(d => d.KullaniciId)
                    .OnDelete(DeleteBehavior.ClientSetNull);
            });

            // 5. DERSLER
            modelBuilder.Entity<Dersler>(entity =>
            {
                entity.HasKey(e => e.DersId);
                entity.ToTable("Dersler");
                entity.Property(e => e.AktifMi).HasDefaultValueSql("((1))");
                entity.Property(e => e.DersAdi).HasMaxLength(100);
                entity.Property(e => e.Kontenjan).HasDefaultValueSql("((20))");
                entity.Property(e => e.ZorunluMu).HasDefaultValueSql("((1))");

                entity.HasOne(d => d.Hoca).WithMany(p => p.Derslers)
                    .HasForeignKey(d => d.HocaId).OnDelete(DeleteBehavior.SetNull);
            });

            OnModelCreatingPartial(modelBuilder);
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
    }
}