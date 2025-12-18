% Train Hoax Predictor Model (Weak Supervision)
% Uses heuristic rules to auto-label data and trains a ML model
% Output: dataset/hoax_predictor.mat

disp('Loading data...');
if exist('dataset/ufo_optimized.mat', 'file')
    loaded = load('dataset/ufo_optimized.mat', 'data');
    data = loaded.data;
else
    error('dataset/ufo_optimized.mat not found. Please run the app or preprocess_data.m first.');
end

fprintf('Total samples: %d\n', height(data));

% ==================================================
% 1. WEAK SUPERVISION (Auto-Labeling)
% ==================================================
disp('Auto-labeling data using heuristics...');

% Initialize scores (0-100)
scores = zeros(height(data), 1) + 20; % Base skepticism

% Rule 1: Shape Analysis
highRiskShapes = {'light', 'fireball', 'circle', 'flare', 'unknown', 'triangle'};
medRiskShapes = {'sphere', 'disk', 'oval', 'cylinder'};

sShape = string(data.shape);
scores(ismember(sShape, highRiskShapes)) = scores(ismember(sShape, highRiskShapes)) + 30; % Increased
scores(ismember(sShape, medRiskShapes)) = scores(ismember(sShape, medRiskShapes)) + 15;

% Rule 2: Duration Analysis
% Very long > 1 hour OR Very short < 10 sec
scores(data.duration_seconds > 1800) = scores(data.duration_seconds > 1800) + 20; % 30 min
scores(data.duration_seconds < 10) = scores(data.duration_seconds < 10) + 15;

% Rule 3: Time Analysis (Late night sightings are often misidentifications)
hours = hour(data.datetime_parsed);
scores(hours >= 20 | hours <= 5) = scores(hours >= 20 | hours <= 5) + 15; % Increased

% Rule 4: Keyword Analysis (Simple check)
if ismember('comments', data.Properties.VariableNames)
    comments = lower(string(data.comments));
    keywords = ["aircraft", "drone", "star", "planet", "venus", "mars", "satellite", "iss", "rocket", "fake", "hoax", "reflection", "formation", "lights", "sky", "scary"];
    
    for k = keywords
        matches = contains(comments, k);
        scores(matches) = scores(matches) + 35;
    end
end

% Normalize
scores = min(scores, 100);

% Create 3-Class Labels (Matching UI Thresholds)
% <40 = Credible, 40-70 = Inconclusive, >70 = Hoax
labels = repmat("Inconclusive", height(data), 1);
labels(scores < 40) = "Credible";
labels(scores >= 70) = "Hoax";
labels = categorical(labels, {'Credible', 'Inconclusive', 'Hoax'});

disp('Label distribution (Before Balancing):');
summary(labels)

% ==================================================
% 2. FEATURE ENGINEERING & BALANCING
% ==================================================
disp('Preparing features...');

% Numeric Shape
[~, shapes] = findgroups(data.shape);
[~, shapeIdx] = ismember(data.shape, shapes);

% Features table
X = table();
X.Shape = double(shapeIdx);
X.Duration = log1p(data.duration_seconds);
X.Hour = hours;
X.Month = month(data.datetime_parsed);
X.Latitude = data.latitude;
X.Longitude = data.longitude;
y = labels;

% --- UNDERSAMPLING FOR 3-CLASS BALANCE ---
credIdx = find(y == 'Credible');
inconcIdx = find(y == 'Inconclusive');
hoaxIdx = find(y == 'Hoax');

nCred = numel(credIdx);
nInconc = numel(inconcIdx);
nHoax = numel(hoaxIdx);

fprintf('Credible: %d, Inconclusive: %d, Hoax: %d\n', nCred, nInconc, nHoax);

% Balance to minimum class size
minSize = min([nCred, nInconc, nHoax]);
if minSize > 0
    disp('Balancing dataset (Undersampling to minimum class size)...');
    credIdx = credIdx(randperm(nCred, minSize));
    inconcIdx = inconcIdx(randperm(nInconc, minSize));
    hoaxIdx = hoaxIdx(randperm(nHoax, minSize));
    
    keepIdx = [credIdx; inconcIdx; hoaxIdx];
    X = X(keepIdx, :);
    y = y(keepIdx);
else
    disp('Warning: One class has 0 samples. Cannot balance.');
end

disp('Label distribution (After Balancing):');
summary(y)

% ==================================================
% 3. MODEL TRAINING
% ==================================================
disp('Training Gradient Boosting Model...');

% Use Bagged Trees (Random Forest equivalent) for robustness
t = templateTree('MaxNumSplits', 50, 'MinLeafSize', 10);
model = fitcensemble(X, y, ...
    'Method', 'Bag', ...
    'NumLearningCycles', 50, ...
    'Learners', t);

% Validation
cvModel = crossval(model, 'KFold', 5);
accuracy = (1 - kfoldLoss(cvModel)) * 100;
fprintf('Cross-Validation Accuracy: %.2f%%\n', accuracy);

% Feature Importance
imp = predictorImportance(model);
figure('Visible','off');
bar(imp);
xticklabels(X.Properties.VariableNames);
title('Feature Importance');
saveas(gcf, 'hoax_feature_importance.png');

% ==================================================
% 4. SAVE
% ==================================================
disp('Saving model to dataset/hoax_predictor.mat...');
save('dataset/hoax_predictor.mat', 'model', 'shapes');
disp('Done!');
