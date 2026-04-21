import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

/// Design Report PDF Generator
///
/// Generates a professional PDF report of the YIO Recipe App design analysis.
/// Usage:
/// ```dart
/// await DesignReportPdfGenerator.generateAndSave();
/// ```
class DesignReportPdfGenerator {
  static Future<void> generateAndSave() async {
    final pdf = pw.Document();

    // Build PDF pages
    pdf.addPage(_buildPage1(pdf));
    pdf.addPage(_buildPage2(pdf));
    pdf.addPage(_buildPage3(pdf));
    pdf.addPage(_buildPage4(pdf));

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/yio_design_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Show print dialog
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'yio_design_report.pdf',
    );
  }

  static pw.Page _buildPage1(pw.Document pdf) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 2, color: PdfColors.orange),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'YIO Recipe App',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Profesyonel Tasarım Analizi',
                    style: const pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Tarih: ${DateTime.now().toString().substring(0, 10)}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Overall Score
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GENEL DEĞERLENDİRME',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange800,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 80,
                              height: 80,
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.orange,
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '7.5',
                                  style: pw.TextStyle(
                                    fontSize: 36,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 16),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'İyi - Geliştirilebilir',
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Solid foundation üzerine kurulu modern tasarım. '
                                    'Material Design 3 kullanımı ve consistent component library.',
                                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Strengths Section
            _buildSectionTitle('GÜÇLÜ YÖNLER'),
            pw.SizedBox(height: 12),
            _buildStrengthItem('1. Renk Paleti (8/10)', [
              'Primary: #FF7A45 (Coral Orange) — Sıcak, iştah açıcı',
              'Background: #F5F5F5 — Göz yormayan soft gray',
              'Text Hiyerarşisi: 3 seviye (#2D2D2D → #666666 → #999999)',
              'Artı: Coral orange yemek/food kategorisinde mükemmel',
              'Eksi: İkincil accent color eksik (örn. sage green)',
            ]),
            pw.SizedBox(height: 12),
            _buildStrengthItem('2. Tipografi (7/10)', [
              'Font: Poppins (Google Fonts) — Modern, okunabilir',
              'Hierarchy: Display (32px) → Body (14-16px) → Caption (12px)',
              'Weight: Bold (600-700) başlıklar, Regular (400) body',
              'Artı: Poppins clean ve modern',
              'Eksi: Font-size scale biraz agresif',
            ]),
            pw.SizedBox(height: 12),
            _buildStrengthItem('3. Component Consistency (8/10)', [
              'Border radius: 12-16px (tutarlı)',
              'Padding: 16-24px (standardize)',
              'Shadows: Soft, subtle (0x1A000000)',
              'Cards: White background, consistent elevation',
              'Artı: Material Design 3 kullanımı modern',
              'Eksi: Bazı hardcoded değerler var',
            ]),
            pw.SizedBox(height: 12),
            _buildStrengthItem('4. Edit Profile Screen (9/10)', [
              'Instagram + Apple Settings ilhamı başarılı',
              'Gradient avatar premium hissi veriyor',
              'Section-based card layout clean',
              'Animations (fade, scale, slide) smooth',
              'Artı: Production-level UI',
              'Eksi: FAB scroll-based hide/show bazen distracting',
            ]),
          ],
        );
      },
    );
  }

  static pw.Page _buildPage2(pw.Document pdf) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('GELİŞTİRİLEBİLİR YÖNLER'),
            pw.SizedBox(height: 12),

            _buildWeaknessItem('1. Visual Hierarchy (6/10)', [
              'Sorun: RecipeCard\'da information density yüksek',
              'Şef adı + avatar, Recipe title, Description, Category badge,',
              'Difficulty badge, Time + Calories, Like + Comment buttons',
              'Öneri: Description\'ı kaldır veya sadece detail\'de göster',
              'Badge\'leri tek satırda birleştir',
            ]),
            pw.SizedBox(height: 12),
            _buildWeaknessItem('2. Spacing & Breathing Room (6/10)', [
              'Sorun: Bazı ekranlarda vertical spacing tight',
              'Home feed\'de kartlar arası 8px margin yetersiz',
              'ProfileScreen\'de sections arası 24px iyi ama artırılabilir',
              'Öneri: margin: EdgeInsets.symmetric(vertical: 12)',
            ]),
            pw.SizedBox(height: 12),
            _buildWeaknessItem('3. Color Accessibility (7/10)', [
              'Sorun: Text light (#999999) on background (#F5F5F5) contrast düşük',
              'WCAG AA standardı: 4.5:1 minimum',
              'Mevcut: ~3.5:1 (approx)',
              'Öneri: static const Color textLight = Color(0xFF777777)',
            ]),
            pw.SizedBox(height: 12),
            _buildWeaknessItem('4. Micro-interactions (5/10)', [
              'Eksik:',
              '- Like butonu için scale animation yok',
              '- Card tap\'te ripple effect var ama subtle',
              '- Pull-to-refresh indicator yok',
              '- Empty state\'lerde illustration yok',
              'Öneri: AnimatedScale ile like button\'a animation ekle',
            ]),
            pw.SizedBox(height: 12),
            _buildWeaknessItem('5. Dark Mode (0/10)', [
              'Sorun: Dark mode desteği yok',
              'AppColors.darkBackground tanımlı ama kullanılmıyor',
              'AppTheme.darkTheme yok',
              'Öneri: Dark theme ekle (gece modu popular)',
            ]),
          ],
        );
      },
    );
  }

  static pw.Page _buildPage3(pw.Document pdf) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ÖZEL ÖNERİLER'),
            pw.SizedBox(height: 12),

            _buildRecommendationItem('1. Recipe Card Redesign', [
              'Hero image (200px height) with gradient overlay',
              'Meta badges (compact) - Easy • 30 min',
              'Recipe title (18px bold)',
              'by @chef_name (12px muted)',
              'Stats row: ❤️ 124  💬 12',
            ]),
            pw.SizedBox(height: 12),
            _buildRecommendationItem('2. Home Feed Header', [
              'Personalized greeting: "Good morning, 👋"',
              'Prominent search bar',
              'Categories horizontal scroll',
            ]),
            pw.SizedBox(height: 12),
            _buildRecommendationItem('3. Color System Expansion', [
              'Extended palette oluştur:',
              'primary50: #FFFFF0EB (Lightest)',
              'primary100: #FFFFD4C4',
              'primary200: #FFFFB088',
              'primary300: #FFFF9B6E',
              'primary400: #FFFF7A45 (Base)',
              'primary500: #FFE56A35 (Darker)',
              'primary600: #FFCC5A28',
              'Secondary accent (sage green): #7CB342',
            ]),
            pw.SizedBox(height: 12),
            _buildRecommendationItem('4. Typography Scale', [
              'Modüler scale (1.25) kullan:',
              'displayLarge: 32px',
              'displayMedium: 28px',
              'displaySmall: 24px',
              'headlineLarge: 20px',
              'headlineMedium: 18px',
              'titleLarge: 16px',
              'bodyLarge: 16px',
              'bodyMedium: 14px',
              'bodySmall: 12px',
            ]),
          ],
        );
      },
    );
  }

  static pw.Page _buildPage4(pw.Document pdf) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('BENCHMARK COMPARISON'),
            pw.SizedBox(height: 12),

            // Comparison Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              tableWidth: pw.TableWidth.max,
              columnWidths: {
                0: const pw.FixedColumnWidth(200), // Feature
                1: const pw.FixedColumnWidth(100), // YIO
                2: const pw.FixedColumnWidth(100), // Instagram
                3: const pw.FixedColumnWidth(100), // Pinterest
                4: const pw.FixedColumnWidth(100), // Tasty
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange100),
                  children: [
                    _buildTableCell('Özellik', isHeader: true),
                    _buildTableCell('YIO', isHeader: true),
                    _buildTableCell('Instagram', isHeader: true),
                    _buildTableCell('Pinterest', isHeader: true),
                    _buildTableCell('Tasty', isHeader: true),
                  ],
                ),
                // Rows
                _buildTableRow('Color Palette', ['7/10', '9/10', '9/10', '8/10']),
                _buildTableRow('Typography', ['7/10', '8/10', '8/10', '7/10']),
                _buildTableRow('Card Design', ['7/10', '9/10', '10/10', '8/10']),
                _buildTableRow('Micro-interactions', ['5/10', '9/10', '10/10', '7/10']),
                _buildTableRow('Accessibility', ['6/10', '8/10', '8/10', '7/10']),
                _buildTableRow('Dark Mode', ['0/10', '10/10', '10/10', '10/10']),
                // Average Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('ORTALAMA', isHeader: true),
                    _buildTableCell('5.3/10', isHeader: true),
                    _buildTableCell('8.8/10', isHeader: true),
                    _buildTableCell('9.2/10', isHeader: true),
                    _buildTableCell('7.8/10', isHeader: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Priority List
            _buildSectionTitle('ÖNCELİKLİ İYİLEŞTİRMELER'),
            pw.SizedBox(height: 12),

            _buildPrioritySection('Yüksek Öncelik', [
              'Dark mode ekle',
              'Recipe card information density azalt',
              'Text light rengini koyulaştır (accessibility)',
              'Like butonuna scale animation ekle',
            ]),
            pw.SizedBox(height: 12),
            _buildPrioritySection('Orta Öncelik', [
              'Extended color palette oluştur',
              'Typography scale\'i modüler yap',
              'Empty state illustrations ekle',
              'Pull-to-refresh indicator',
            ]),
            pw.SizedBox(height: 12),
            _buildPrioritySection('Düşük Öncelik', [
              'Haptic feedback ekle',
              'Skeleton loading states',
              'Custom app icon tasarımı',
              'Onboarding illustrations',
            ]),
            pw.SizedBox(height: 24),

            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'SONUÇ',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'YIO Recipe App\'in tasarımı solid foundation üzerine kurulu. '
                    'Material Design 3 kullanımı, consistent component library, '
                    've Edit Profile screen\'deki attention to detail profesyonel bir seviyede.',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'En büyük eksiklikler: Dark mode ve micro-interactions. '
                    'Bu ikisi eklendiğinde tasarım 8.5/10 seviyesine çıkacaktır.',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Güçlü yön: Renk paleti ve tipografi seçimi food/recipe kategorisine çok uygun. '
                    'Coral orange + Poppins kombinasyonu modern ve appetizing bir his veriyor.',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(width: 4, color: PdfColors.orange),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.orange800,
        ),
      ),
    );
  }

  static pw.Widget _buildStrengthItem(String title, List<String> points) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...points.map((point) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: pw.Text(
                  '• $point',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildWeaknessItem(String title, List<String> points) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...points.map((point) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: pw.Text(
                  '• $point',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildRecommendationItem(String title, List<String> points) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...points.map((point) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: pw.Text(
                  '• $point',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildPrioritySection(String title, List<String> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: pw.Text(
                  '• $item',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
              )),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, List<String> scores) {
    return pw.TableRow(
      children: [
        _buildTableCell(label),
        ...scores.map((score) => _buildTableCell(score)),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey800,
        ),
      ),
    );
  }
}

/// Custom PDF colors
class PdfColors {
  static const PdfColor orange = PdfColor.fromInt(0xFFFF7A45);
  static const PdfColor orange50 = PdfColor.fromInt(0xFFFFF0EB);
  static const PdfColor orange100 = PdfColor.fromInt(0xFFFFD4C4);
  static const PdfColor orange800 = PdfColor.fromInt(0xFFCC5A28);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor grey = PdfColor.fromInt(0xFF666666);
  static const PdfColor grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor grey700 = PdfColor.fromInt(0xFF616161);
  static const PdfColor grey800 = PdfColor.fromInt(0xFF424242);
  static const PdfColor black = PdfColor.fromInt(0xFF000000);
}
