# Redmine Issue Lifecycle Plugin

Bu eklenti, Redmine üzerindeki işlerin (issues) **durum değişimlerini** ve her durumda geçen süreleri analiz eder.  
Her proje için ayrı ayrı:

- Üst menüde yeni bir **“Lifecycle”** sekmesi ekler.
- Projedeki tüm işler için **durum geçişlerini**, **kategoriyi**, **kimin değiştirdiğini** ve **harcanan süreleri** listeler.
- Durum sürelerini; kategori ve kullanıcı bazında **özet tablolar + basit grafik dağılımlar** ile gösterir.
- İş detay sayfasında, aynı sayfa üzerinde açılıp kapanan bir panelde ilgili işin **stacked bar** grafiğini gösterir.

---

## Özellikler

- **Proje bazlı aç/kapat**
  - `init.rb` içinde `project_module :issue_lifecycle` tanımlıdır.
  - Her proje için `Proje → Ayarlar → Modüller` ekranından **Issue lifecycle** modülünü açıp kapatabilirsiniz.
  - Modül açık olan projelerde üst menüde **Lifecycle** sekmesi görünür, kapalı projelerde görünmez.

- **Proje Lifecycle sayfası (`/projects/:project_id/lifecycle`)**
  - Üst menüde `Overview, Activity, Issues, ...` yanında **Lifecycle** sekmesi.
  - Liste görünümü:
    - İş numarası ve konu
    - Geçerli durum
    - İş kategorisi
    - Durum değişikliğini yapan kullanıcı
    - Başlangıç ve bitiş zamanı (segment bazında)
    - İşin toplamda sistemde kaldığı süre
    - İlgili segmentte (durumda) geçen süre
  - Sıralama:
    - Başlık satırındaki linkler üzerinden `id`, konu, kategori, kullanıcı ve toplam süreye göre **artan/azalan** sıralama yapılabilir.

- **Proje genelinde özetler**
  - **Kategoriye göre özet**
    - Her kategori için, o kategorideki işler boyunca durumlarda geçen toplam süreler toplanır.
    - Tablo + renkli küçük bar’lar ve **% (yüzde) kolonu** ile dağılım gösterilir.
    - Kategori kullanılmayan işler, `Hiçbiri` (None) altında gruplanır.
  - **Kullanıcıya göre özet**
    - Durum değişikliklerini yapan kullanıcı bazında, tüm işler boyunca harcanan toplam süreler toplanır.
    - Benzer şekilde tablo + renkli barlarla görsel olarak gösterilir.

- **İş detay sayfasında görsel panel**
  - `app/views/issue_lifecycle/_issue_panel.html.erb` partial’ı ile:
    - İş detay sayfasında, tıklanınca açılıp kapanan bir **“İş Durum Geçişleri / Durumda Geçen Süre”** paneli eklenir.
    - Bu panelde, ilgili iş için durumların zaman içindeki dağılımı **yatay stacked bar** (renkli şeritler) olarak çizilir.
    - Panel altında, her durum için:
      - İnsan okunabilir süre (`distance_of_time_in_words`)
      - Saat cinsinden toplam süre (`format_hours`)
      - Toplam iş süresi
    - Panel, ek bir sayfaya gitmeden **aynı sayfada** görüntülenir.

---

## Kurulum (Installation)

1. Eklenti klasörünü (`redmine_issue_lifecycle`) Redmine kurulumunuzun içindeki `plugins` dizinine kopyalayın.

   ```bash
   cd [redmine_root]/plugins
   git clone [repo_url] redmine_issue_lifecycle
   ```

2. Redmine ana dizinine dönün ve gerekli Ruby bağımlılıklarını yükleyin:

   ```bash
   cd [redmine_root]
   bundle install
   ```

3. Bu eklenti, Redmine’in mevcut `issues`, `journals` ve `journal_details` tablolarını kullandığı için **ek migration gerektirmez**.

4. Redmine sunucunuzu yeniden başlatın:

   ```bash
   touch tmp/restart.txt   # Passenger kullanıyorsanız
   # veya kullandığınız application server'ı yeniden başlatın (puma/unicorn/webrick vb.)
   ```

5. Redmine’da yönetici olarak oturum açın:
   - **Yönetim → Eklentiler (Plugins)** ekranında `Redmine Issue Lifecycle Plugin` yüklü görünüyor olmalı.
   - **Yönetim → Roller ve İzinler (Roles and permissions)** kısmından ilgili rollere:
     - `View issue lifecycle` (veya `view_issue_lifecycle`) iznini verin.
   - Her proje için:
     - `Proje → Ayarlar → Modüller` sekmesinde **Issue lifecycle** kutusunu işaretleyerek modülü aktifleştirin.

---

## Kullanım (Usage)

### 1. Proje Lifecycle Sekmesi

- İlgili projede `Issue lifecycle` modülü açıkken, proje sayfasının üst menüsünde **Lifecycle** sekmesi görünür.
- Bu sekmeye tıkladığınızda:
  - Projedeki tüm işler için durum segmentlerinin satır satır listelendiği bir tablo görürsünüz.
  - Tablodaki kolon başlıklarına tıklayarak:
    - İş numarasına göre
    - Konuya göre
    - Kategoriye göre
    - Kullanıcıya göre
    - Toplam süreye göre  
    sıralama yapabilirsiniz.
  - Sayfanın alt kısmında:
    - **Kategoriye göre iş süreleri** özeti
    - **Kullanıcıya göre iş süreleri** özeti  
    yer alır; burada her satırda toplam süreler ve yüzde dağılımı gösterilir.

### 2. İş Detay Sayfasındaki Panel

- Herhangi bir iş (issue) detay sayfasında:
  - `IssueLifecycleCalculator` ile hesaplanan süreler kullanılarak, `_issue_panel.html.erb` partial’ı üzerinden **yatay stacked bar** grafiği çizilir.
  - Panel başlığındaki linke tıklayarak gövde kısmını açıp kapatabilirsiniz.
  - Panel, bu eklentinin bir parçası olarak issue sayfasına eklemlenecek şekilde tasarlanmıştır.

---

## Teknik Mimari ve Seçimler

### 1. Veri Kaynağı Olarak Journals

- **Seçim:** Eklenti, durum değişimlerini takip etmek için yeni bir veritabanı tablosu oluşturmak yerine Redmine’ın kendi:
  - `journals`
  - `journal_details`  
  tablolarını analiz eder.

- **Gerekçe:**
  - **Geriye dönük uyumluluk:** Eklenti kurulduktan sonra geçmişte yapılmış tüm durum değişimlerini anında raporlayabilir.
  - **Ek tablo yok:** Veritabanında fazladan tablo tutmadan çalışır, migration ihtiyacını ortadan kaldırır.
  - **Veri bütünlüğü:** Redmine’ın kendi değişiklik kayıtlarını kullanır, veri tekrarını önler.

### 2. Hesaplama Sınıfı: `IssueLifecycleCalculator`

- **Konum:** `app/models/issue_lifecycle_calculator.rb`
- **Görev:**
  - Bir issue için status journal’larını kronolojik olarak okuyarak zaman segmentleri oluşturur.
  - Her segment için:
    - Eski durum
    - Kullanıcı
    - Başlangıç ve bitiş zamanları
    - Süre (saniye)
  - Bu segmentlerden:
    - Durum bazlı toplam süreler (`status_times`)
    - Toplam yaşam süresi (`total_time`)
    - Ham segment listesi (`segments`)  
    hesaplanır ve controller/view katmanına döner.

- **Seçim Gerekçeleri:**
  - **Separation of Concerns:** Controller sade kalır; iş mantığı model benzeri sınıfta toplanır.
  - **Test edilebilirlik:** Hesaplama mantığı tek bir sınıf içinde olduğu için birim test yazmak kolaydır.

### 3. Performans: Eager Loading

- **Seçim:** Controller içinde:

  ```ruby
  @issues = @project.issues.includes(:status, :author, :category, :assigned_to, :journals => :details)
  ```

- **Amaç:**
  - N+1 query problemini azaltmak.
  - Çok sayıda issue içeren projelerde bile kabul edilebilir performansla rapor üretmek.

### 4. Görselleştirme Yaklaşımı

- **Seçim:** Harici bir grafik kütüphanesi (Chart.js, Highcharts vs.) eklemek yerine:
  - Basit HTML div yapıları
  - Inline CSS stilleri
  - Rails helper’ları (`distance_of_time_in_words`, `format_time`, vb.)  
  ile **stacked bar** tarzı gösterimler oluşturulmuştur.

- **Gerekçe:**
  - Ek JS/CSS bağımlılığı olmadan, Redmine çekirdeğiyle uyumlu hafif bir çözüm sunar.
  - Redmine güncellemelerinde bozulma riski düşüktür.

---

## Kullanılan Teknolojiler

- **Ruby on Rails** (Redmine çekirdeği üzerinde çalışır)
- **Redmine Plugin API**
- **Vanilla CSS** (hafif görselleştirme)
- **I18n (Internationalization)** – Türkçe çeviri desteği (`config/locales/tr.yml`)

