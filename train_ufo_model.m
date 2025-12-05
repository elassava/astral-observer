% Train UFO Prediction Model
% This script loads the optimized data, generates synthetic negative samples,
% trains a Decision Tree model, and saves it to 'dataset/ufo_model_ct.mat'.

disp('Loading data...');
if exist('dataset/ufo_optimized.mat', 'file')
    loaded = load('dataset/ufo_optimized.mat', 'data');
    data = loaded.data;
else
    error('dataset/ufo_optimized.mat not found. Please run the app once to generate it.');
end

disp('Preprocessing data...');
% Feature Selection
% We need: Latitude, Longitude, Month, Hour, Duration, Shape
% Convert Shape to numeric index
[g, shapes] = findgroups(data.shape);
shapeIdx = double(g);

% Extract features
lat = data.latitude;
lon = data.longitude;
months = month(data.datetime_parsed);
hours = hour(data.datetime_parsed);
duration = data.duration_seconds;

% Filter out extreme durations or NaNs
valid = ~isnan(lat) & ~isnan(lon) & ~isnan(duration) & duration < 86400; % Max 1 day
X_pos = [lat(valid), lon(valid), months(valid), hours(valid), duration(valid), shapeIdx(valid)];
y_pos = ones(size(X_pos, 1), 1); % Label 1 for sighting

disp('Generating synthetic negative samples...');
% Generate random "noise" data (Non-sightings)
% We'll generate same amount as positive samples
N = size(X_pos, 1);

% Random Lat/Lon (Global)
rand_lat = (rand(N, 1) * 180) - 90;
rand_lon = (rand(N, 1) * 360) - 180;

% Random Month (1-12)
rand_month = randi([1, 12], N, 1);

% Random Hour (0-23)
rand_hour = randi([0, 23], N, 1);

% Random Duration (10s to 3600s)
rand_duration = rand(N, 1) * 3600;

% Random Shape (1 to numel(shapes))
rand_shape = randi([1, numel(shapes)], N, 1);

X_neg = [rand_lat, rand_lon, rand_month, rand_hour, rand_duration, rand_shape];
y_neg = zeros(N, 1); % Label 0 for non-sighting

% Combine Data
X = [X_pos; X_neg];
y = [y_pos; y_neg];

% Shuffle
idx = randperm(size(X, 1));
X = X(idx, :);
y = y(idx, :);

disp('Training Decision Tree Model...');
% Train Classification Tree
% Predictors: Lat, Lon, Month, Hour, Duration, Shape
% MinLeafSize: 50 -> Ensures leaves have enough samples for probability estimation
% MaxNumSplits: 50 -> Prevents overfitting by limiting tree complexity
model = fitctree(X, y, ...
    'PredictorNames', {'Latitude', 'Longitude', 'Month', 'Hour', 'Duration', 'Shape'}, ...
    'ResponseName', 'IsUFO', ...
    'MinLeafSize', 50, ...
    'MaxNumSplits', 50);

% Save Model and Shape Map
disp('Saving model to dataset/ufo_model_ct.mat...');
save('dataset/ufo_model_ct.mat', 'model', 'shapes');

disp('Done.');
