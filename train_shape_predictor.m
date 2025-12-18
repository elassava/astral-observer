% Train UFO Shape Predictor Model (Improved - Random Forest)
% This script trains a Random Forest to predict UFO shape based on
% location, month, hour, and duration with class balancing.
% Output: dataset/shape_predictor.mat

disp('Loading data...');
if exist('dataset/ufo_optimized.mat', 'file')
    loaded = load('dataset/ufo_optimized.mat', 'data');
    data = loaded.data;
else
    error('dataset/ufo_optimized.mat not found. Please run the app once to generate it.');
end

disp('Preprocessing data...');

% Extract features
lat = data.latitude;
lon = data.longitude;
months = month(data.datetime_parsed);
hours = hour(data.datetime_parsed);
duration = data.duration_seconds;
dayOfWeek = weekday(data.datetime_parsed); % New feature

% Get shape distribution and filter to top 10
[g, shapes] = findgroups(data.shape);
counts = splitapply(@numel, data.shape, g);
[sortedCounts, sortIdx] = sort(counts, 'descend');
top10Shapes = shapes(sortIdx(1:min(10, numel(shapes))));

disp('Top 10 shapes:');
for i = 1:numel(top10Shapes)
    fprintf('  %d. %s (%d sightings)\n', i, string(top10Shapes(i)), sortedCounts(i));
end

% Filter data to only include top 10 shapes
validShapes = ismember(data.shape, top10Shapes);
valid = validShapes & ~isnan(lat) & ~isnan(lon) & ~isnan(duration) & duration < 86400;

% Feature matrix with more features
X = [lat(valid), lon(valid), months(valid), hours(valid), duration(valid), dayOfWeek(valid)];
y = data.shape(valid);

% Convert to categorical for classification
y = categorical(y);

% Shuffle data
idx = randperm(size(X, 1));
X = X(idx, :);
y = y(idx);

% Calculate class weights for balancing (inverse frequency)
[gY, shapesY] = findgroups(y);
classCounts = splitapply(@numel, y, gY);
classWeights = max(classCounts) ./ classCounts; % Inverse frequency
weightMap = containers.Map(string(shapesY), classWeights);

% Create sample weights
sampleWeights = zeros(size(y));
for i = 1:numel(y)
    sampleWeights(i) = weightMap(string(y(i)));
end

disp('Training Random Forest Shape Predictor...');
fprintf('Training samples: %d\n', size(X, 1));
fprintf('Using ensemble of 100 trees with class balancing\n');

% Train Random Forest (TreeBagger) for multi-class with better parameters
model = TreeBagger(100, X, y, ...
    'Method', 'classification', ...
    'MinLeafSize', 20, ...           % Smaller leaves = more sensitive
    'NumPredictorsToSample', 'all', ... % Use all features at each split
    'OOBPrediction', 'on', ...       % Enable out-of-bag error estimation
    'Weights', sampleWeights, ...    % Class balancing
    'PredictorNames', {'Latitude', 'Longitude', 'Month', 'Hour', 'Duration', 'DayOfWeek'});

% Display OOB error
oobErr = oobError(model);
fprintf('Out-of-bag error: %.2f%%\n', oobErr(end) * 100);

% Save Model and Shape List
disp('Saving model to dataset/shape_predictor.mat...');
shapeList = top10Shapes;
save('dataset/shape_predictor.mat', 'model', 'shapeList');

disp('Done. Improved model saved successfully!');
