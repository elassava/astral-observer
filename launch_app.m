%% Launch UFO Visualizer App
% Bu script UFOVisualizerApp uygulamasını başlatır

close all; clear; clc;

fprintf('UFO Visualizer App başlatılıyor...\n');

% Uygulama dosyasının varlığını kontrol et
if ~exist('UFOVisualizerApp.m', 'file')
    error('UFOVisualizerApp.m bulunamadı!');
end

% Veri dosyasının varlığını kontrol et
if ~exist('dataset/ufo_cleaned.mat', 'file')
    warning('Veri dosyası bulunamadı. Önce preprocess_data çalıştırılıyor...');
    preprocess_data;
end

% Uygulamayı başlat
app = UFOVisualizerApp();

fprintf('✓ Uygulama açıldı.\n');
