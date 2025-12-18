% Train Duration Category Predictor Model (Optimized)
% Binary Classification: Short (<2 min) vs Long (>=2 min)
% Uses Gradient Boosting (AdaBoost) for better accuracy
% Output: dataset/duration_predictor.mat

disp('Loading data...');
if exist('dataset/ufo_optimized.mat', 'file')
    loaded = load('dataset/ufo_optimized.mat', 'data');
    data = loaded.data;
else
    error('dataset/ufo_optimized.mat not found. Please run the app once to generate it.');
end

disp('Preprocessing data...');

% Filter valid data (Outlier Cleaning applied)
valid = ~isnan(data.latitude) & ~isnan(data.longitude) & ...
        ~isnan(data.duration_seconds) & ...
        data.duration_seconds >= 5 & ...      % At least 5 seconds
        data.duration_seconds <= 3600;        % Max 1 hour (remove extreme outliers)

data = data(valid, :);
fprintf('Valid samples: %d\n', height(data));

% BINARY CLASSIFICATION: Short vs Long
% Using median as threshold for balanced classes
medianDuration = median(data.duration_seconds);
fprintf('Median duration: %.1f seconds (%.1f minutes)\n', medianDuration, medianDuration/60);

duration = data.duration_seconds;
durationCategory = categorical(repmat("Long", height(data), 1));
durationCategory(duration < 120) = "Short";  % < 2 minutes = Short
durationCategory(duration >= 120) = "Long";  % >= 2 minutes = Long

% Show distribution
disp('Duration category distribution (Binary):');
summary(durationCategory)

% Encode shape to numeric
[~, shapes] = findgroups(data.shape);
[~, shapeIdx] = ismember(data.shape, shapes);

% ===== ENHANCED FEATURES =====
lat = data.latitude;
lon = data.longitude;
months = month(data.datetime_parsed);
hours = hour(data.datetime_parsed);
shapeNum = double(shapeIdx);

% Day of week
dayOfWeek = weekday(data.datetime_parsed);

% Season
season = ones(height(data), 1);
season(months >= 3 & months <= 5) = 2;
season(months >= 6 & months <= 8) = 3;
season(months >= 9 & months <= 11) = 4;

% Is Weekend
isWeekend = double(dayOfWeek == 1 | dayOfWeek == 7);

% Is USA
isUSA = double(string(data.country) == "us");

% Is Night (20:00 - 06:00)
isNight = double(hours >= 20 | hours <= 6);

% Feature matrix
X = [shapeNum, lat, lon, months, hours, dayOfWeek, season, isWeekend, isUSA, isNight];
y = durationCategory;

fprintf('Features: Shape, Lat, Lon, Month, Hour, DayOfWeek, Season, IsWeekend, IsUSA, IsNight\n');
fprintf('Total features: %d\n', size(X, 2));

% Shuffle
idx = randperm(size(X, 1));
X = X(idx, :);
y = y(idx);

disp('Training Gradient Boosting (AdaBoost) Duration Predictor...');
fprintf('Training samples: %d\n', size(X, 1));
disp('NOTE: Optimization is enabled. This will take a few minutes to find the best parameters...');

% Train AdaBoost with Hyperparameter Optimization
t = templateTree('MaxNumSplits', 20); % Start with simple trees
model = fitcensemble(X, y, ...
    'Method', 'AdaBoostM1', ...
    'Learners', t, ...
    'OptimizeHyperparameters', {'NumLearningCycles', 'LearnRate'}, ...
    'HyperparameterOptimizationOptions', struct('AcquisitionFunctionName', 'expected-improvement-plus', 'ShowPlots', false, 'Verbose', 1));

% Cross-validation for accuracy
disp('Evaluating with 5-fold cross-validation...');
cvModel = crossval(model, 'KFold', 5);
cvLoss = kfoldLoss(cvModel);
fprintf('Cross-validation error: %.2f%%\n', cvLoss * 100);
fprintf('Cross-validation accuracy: %.2f%%\n', (1 - cvLoss) * 100);

% Save Model and Shape Map
disp('Saving model to dataset/duration_predictor.mat...');
save('dataset/duration_predictor.mat', 'model', 'shapes');

disp('Done. Optimized binary duration predictor saved!');
