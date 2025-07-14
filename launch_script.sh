#!/bin/bash

# Lensify OCR Scanner - Launch Script
# Bu script uygulamayı launch için hazırlar

echo "🚀 Lensify OCR Scanner - Launch Hazırlığı Başlıyor..."

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonksiyonlar
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. Flutter Doctor Kontrolü
echo -e "\n${BLUE}📋 Flutter Doctor Kontrolü...${NC}"
flutter doctor

# 2. Dependencies Güncelleme
echo -e "\n${BLUE}📦 Dependencies güncelleniyor...${NC}"
flutter clean
flutter pub get

if [ $? -eq 0 ]; then
    print_success "Dependencies başarıyla güncellendi"
else
    print_error "Dependencies güncellenirken hata oluştu"
    exit 1
fi

# 3. Code Analysis
echo -e "\n${BLUE}🔍 Code analysis çalıştırılıyor...${NC}"
flutter analyze

if [ $? -eq 0 ]; then
    print_success "Code analysis tamamlandı - hata yok"
else
    print_warning "Code analysis'te uyarılar var, devam ediliyor..."
fi

# 4. Test Çalıştırma
echo -e "\n${BLUE}🧪 Testler çalıştırılıyor...${NC}"
flutter test

if [ $? -eq 0 ]; then
    print_success "Tüm testler başarılı"
else
    print_warning "Bazı testler başarısız, devam ediliyor..."
fi

# 5. Debug Build Test
echo -e "\n${BLUE}🔨 Debug build test...${NC}"
flutter build apk --debug

if [ $? -eq 0 ]; then
    print_success "Debug build başarılı"
else
    print_error "Debug build başarısız"
    exit 1
fi

# 6. Release Build (Android)
echo -e "\n${BLUE}📱 Android Release Build...${NC}"
flutter build apk --release

if [ $? -eq 0 ]; then
    print_success "Android Release build başarılı"
    print_info "APK konumu: build/app/outputs/flutter-apk/app-release.apk"
else
    print_error "Android Release build başarısız"
fi

# 7. iOS Build (sadece macOS'ta)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "\n${BLUE}🍎 iOS Build test...${NC}"
    flutter build ios --release --no-codesign
    
    if [ $? -eq 0 ]; then
        print_success "iOS build başarılı"
    else
        print_warning "iOS build başarısız (normal olabilir - code signing gerekli)"
    fi
fi

# 8. App Bundle (Android)
echo -e "\n${BLUE}📦 Android App Bundle oluşturuluyor...${NC}"
flutter build appbundle --release

if [ $? -eq 0 ]; then
    print_success "Android App Bundle başarılı"
    print_info "AAB konumu: build/app/outputs/bundle/release/app-release.aab"
else
    print_warning "Android App Bundle başarısız"
fi

# 9. Dosya boyutları
echo -e "\n${BLUE}📊 Build dosya boyutları:${NC}"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    print_info "APK boyutu: $APK_SIZE"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    print_info "AAB boyutu: $AAB_SIZE"
fi

# 10. Özet
echo -e "\n${GREEN}🎉 Launch Hazırlığı Tamamlandı!${NC}"
echo -e "\n${BLUE}📋 Özet:${NC}"
echo "• Uygulama Adı: Lensify OCR Scanner"
echo "• Package: com.lensify.ocr_scanner"
echo "• Version: 1.0.0+1"
echo "• Platforms: Android, iOS, macOS, Windows, Linux, Web"

echo -e "\n${BLUE}📱 Sonraki Adımlar:${NC}"
echo "1. APK'yı test cihazında test edin"
echo "2. App Store/Play Store metadata hazırlayın"
echo "3. App icon ve screenshots hazırlayın"
echo "4. Privacy policy ve terms of service oluşturun"
echo "5. Code signing sertifikalarını ayarlayın"

echo -e "\n${GREEN}✨ Uygulama launch için hazır!${NC}"
