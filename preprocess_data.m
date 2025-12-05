%% UFO Sighting Data Preprocessing Script (Optimize Edilmiş)
% Bu script UFO gözlem verisini temizler ve görselleştirme için hazırlar

clear; clc; close all;

%% 1. Veriyi Yükle
fprintf('Veri yükleniyor...\n');
opts = detectImportOptions('dataset/scrubbed.csv');
opts.VariableNamingRule = 'preserve';

% OPTIMIZE: Sadece gerekli kolonları yükle
opts = setvartype(opts, {'latitude', 'longitude', 'duration (seconds)'}, 'double');

tic; % Zaman ölçümü başlat
data = readtable('dataset/scrubbed.csv', opts);
loadTime = toc;

fprintf('✓ Toplam %d satır veri yüklendi (%.1f saniye)\n\n', height(data), loadTime);

%% 2. Kolon İsimlerini Düzenle (Vectorized)
fprintf('Kolon isimleri düzenleniyor...\n');
data.Properties.VariableNames = strrep(data.Properties.VariableNames, ' ', '_');
data.Properties.VariableNames = strrep(data.Properties.VariableNames, '(', '');
data.Properties.VariableNames = strrep(data.Properties.VariableNames, ')', '');
data.Properties.VariableNames = strrep(data.Properties.VariableNames, '/', '_');

%% 3. OPTIMIZE: Latitude ve Longitude Temizleme
fprintf('Koordinat verileri temizleniyor...\n');

validCoords = ~isnan(data.latitude) & ~isnan(data.longitude) & ...
              data.latitude >= -90 & data.latitude <= 90 & ...
              data.longitude >= -180 & data.longitude <= 180;

fprintf('  - %d satırda geçerli koordinat var\n', sum(validCoords));
fprintf('  - %d satır kaldırılacak\n', sum(~validCoords));

data = data(validCoords, :);

%% 4. Tarih Verilerini Düzenle
fprintf('\nTarih verileri işleniyor...\n');

% Datetime verisini datetime formatına çevir
try
    data.datetime_parsed = datetime(data.datetime, 'InputFormat', 'M/d/yyyy HH:mm');
    fprintf('  - %d tarih başarıyla parse edildi\n', sum(~isnat(data.datetime_parsed)));
catch
    warning('Bazı tarihler parse edilemedi');
end

% Yıl, ay, gün bilgilerini ayır
data.year = year(data.datetime_parsed);
data.month = month(data.datetime_parsed);
data.day = day(data.datetime_parsed);

%% 5. Shape (Şekil) Kategorilerini Standardize Et
fprintf('\nŞekil kategorileri düzenleniyor...\n');

% Küçük harfe çevir ve boşlukları temizle
if iscell(data.shape)
    data.shape = lower(strtrim(data.shape));
    % Boş değerleri 'unknown' yap
    emptyShapes = cellfun(@isempty, data.shape);
    data.shape(emptyShapes) = {'unknown'};
elseif isstring(data.shape)
    data.shape = lower(strtrim(data.shape));
    data.shape(data.shape == "") = "unknown";
end

% Benzersiz şekilleri göster
uniqueShapes = unique(data.shape);
fprintf('  - Toplam %d farklı şekil kategorisi bulundu\n', length(uniqueShapes));
fprintf('  - İlk 10 şekil: %s\n', strjoin(uniqueShapes(1:min(10,length(uniqueShapes))), ', '));

%% 6. Ülke ve Eyalet Verilerini Temizle
fprintf('\nÜlke/eyalet verileri temizleniyor...\n');

% Küçük harfe çevir
if iscell(data.country)
    data.country = lower(strtrim(data.country));
elseif isstring(data.country)
    data.country = lower(strtrim(data.country));
end

if iscell(data.state)
    data.state = lower(strtrim(data.state));
elseif isstring(data.state)
    data.state = lower(strtrim(data.state));
end

% Benzersiz ülkeleri göster
uniqueCountries = unique(data.country);
fprintf('  - Toplam %d farklı ülke bulundu\n', length(uniqueCountries));

%% 7. Duration Verilerini İşle
fprintf('\nSüre verileri işleniyor...\n');

% duration_seconds kolonunu sayısal formata çevir
data.duration_seconds = double(data.duration_seconds);

% Aşırı değerleri filtrele (örn. 1 saniyeden az veya 1 günden fazla)
validDuration = data.duration_seconds >= 1 & data.duration_seconds <= 86400; % 1 gün = 86400 saniye
fprintf('  - %d satır geçerli süre verisi\n', sum(validDuration));
fprintf('  - %d satır geçersiz süre verisi (bunlar saklanacak ama analiz dışı bırakılmalı)\n', sum(~validDuration));

%% 8. Şehir ve Açıklama Verilerini Temizle
fprintf('\nMetin verileri temizleniyor...\n');

% Şehir isimlerini küçük harfe çevir
if iscell(data.city)
    data.city = lower(strtrim(data.city));
elseif isstring(data.city)
    data.city = lower(strtrim(data.city));
end

% Açıklamaları temizle (HTML karakterlerini kaldır)
if iscell(data.comments)
    data.comments = regexprep(data.comments, '&#\d+;', ' ');
    data.comments = regexprep(data.comments, '&[a-z]+;', ' ');
elseif isstring(data.comments)
    data.comments = regexprep(data.comments, '&#\d+;', ' ');
    data.comments = regexprep(data.comments, '&[a-z]+;', ' ');
end

%% 9. Son İstatistikler
fprintf('\n=== TEMİZLENMİŞ VERİ İSTATİSTİKLERİ ===\n');
fprintf('Toplam satır sayısı: %d\n', height(data));
fprintf('Tarih aralığı: %s - %s\n', ...
    datestr(min(data.datetime_parsed)), datestr(max(data.datetime_parsed)));
fprintf('Koordinat aralığı:\n');
fprintf('  Latitude: %.2f - %.2f\n', min(data.latitude), max(data.latitude));
fprintf('  Longitude: %.2f - %.2f\n', min(data.longitude), max(data.longitude));

%% 10. Temizlenmiş Veriyi Kaydet
fprintf('\nTemizlenmiş veri kaydediliyor...\n');
save('dataset/ufo_cleaned.mat', 'data', '-v7.3');
fprintf('✓ Veri başarıyla kaydedildi: dataset/ufo_cleaned.mat\n');

%% 11. OPTIMIZE: Temel İstatistikleri Görselleştir
fprintf('\nTemel istatistikler oluşturuluyor...\n');

figure('Position', [100, 100, 1200, 350]);

% Yıllara göre gözlem (sadece modern veriler: 1990+)
subplot(1,3,1);
modernData = data(data.year >= 1990, :);
histogram(modernData.year, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'none');
title('Yıllara Göre Gözlemler (1990+)');
xlabel('Yıl');
ylabel('Gözlem Sayısı');
grid on;

% Top 10 Şekiller (optimize edilmiş)
subplot(1,3,2);
shapeCount = groupcounts(data, 'shape');
shapeCount = sortrows(shapeCount, 'GroupCount', 'descend');
topShapes = shapeCount(1:min(10, height(shapeCount)), :);
barh(1:height(topShapes), topShapes.GroupCount, 'FaceColor', [0.8 0.4 0.2]);
set(gca, 'YTick', 1:height(topShapes), 'YTickLabel', topShapes.shape);
title('En Çok Görülen 10 Şekil');
xlabel('Gözlem Sayısı');
grid on;

% Top 5 Ülkeler
subplot(1,3,3);
countryCount = groupcounts(data, 'country');
countryCount = sortrows(countryCount, 'GroupCount', 'descend');
topCountries = countryCount(1:min(5, height(countryCount)), :);
bar(topCountries.GroupCount, 'FaceColor', [0.3 0.7 0.4]);
set(gca, 'XTickLabel', topCountries.country);
title('Top 5 Ülke');
ylabel('Gözlem Sayısı');
grid on;
xtickangle(45);

saveas(gcf, 'dataset/basic_stats.png');
fprintf('✓ İstatistik grafikleri kaydedildi\n');

fprintf('\n=== ✅ PREPROCESSİNG TAMAMLANDI ===\n');
fprintf('Toplam işlem süresi: %.1f saniye\n', toc);

