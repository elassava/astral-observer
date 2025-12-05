classdef UFOVisualizerApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        
        % Layout Containers
        SidebarPanel  matlab.ui.container.Panel
        MapPanel      matlab.ui.container.Panel
        ShapesPanel   matlab.ui.container.Panel
        YearsPanel    matlab.ui.container.Panel
        HoursPanel    matlab.ui.container.Panel
        PredictionPanel matlab.ui.container.Panel
        RandomPanel   matlab.ui.container.Panel
        WordCloudPanel matlab.ui.container.Panel
        WelcomePanel  matlab.ui.container.Panel
        StatsPanel    matlab.ui.container.Panel
        TopLocationsPanel matlab.ui.container.Panel
        MonthlyPanel  matlab.ui.container.Panel
        GlobePanel    matlab.ui.container.Panel
        
        % Sidebar Components
        HomeButton    matlab.ui.control.Button
        MapButton     matlab.ui.control.Button
        ShapesButton  matlab.ui.control.Button
        YearsButton   matlab.ui.control.Button
        HoursButton   matlab.ui.control.Button
        PredictionButton matlab.ui.control.Button
        RandomButton  matlab.ui.control.Button
        WordCloudButton matlab.ui.control.Button
        StatsButton   matlab.ui.control.Button
        TopLocationsButton matlab.ui.control.Button
        MonthlyButton matlab.ui.control.Button
        GlobeButton   matlab.ui.control.Button
        
        % Map View Components
        MapAxes       matlab.graphics.axis.GeographicAxes
        
        % Stats View Components
        PieAxes       matlab.ui.control.UIAxes
        TimeSeriesAxes matlab.ui.control.UIAxes
        HourlyAxes    matlab.ui.control.UIAxes
        
        % Prediction Components
        ShapeDropDown matlab.ui.control.DropDown
        CityDropDown  matlab.ui.control.DropDown
        MinuteEditField matlab.ui.control.NumericEditField
        DatePicker    matlab.ui.control.DatePicker
        HourEditField matlab.ui.control.NumericEditField
        DurationEditField matlab.ui.control.NumericEditField
        ModelDropDown matlab.ui.control.DropDown
        PredictButton matlab.ui.control.Button
        ResultPanel   matlab.ui.container.Panel
        InputPanel    matlab.ui.container.Panel
        ResultLabel   matlab.ui.control.Label
        PredictionGauge matlab.ui.control.LinearGauge
        
        % Random View Components
        DataCardPanel matlab.ui.container.Panel
        DescriptionPanel matlab.ui.container.Panel
        RandomTitleLabel matlab.ui.control.Label
        RandomDateLabel matlab.ui.control.Label
        RandomCityLabel matlab.ui.control.Label
        RandomShapeLabel matlab.ui.control.Label
        RandomDurationLabel matlab.ui.control.Label
        RandomDescTextArea matlab.ui.control.TextArea
        NextRandomButton matlab.ui.control.Button
        
        TitleLabel    matlab.ui.control.Label
        StatusLabel   matlab.ui.control.Label
        
        WelcomeImage  matlab.ui.control.Image
        
        % Stats Panel Components
        StatTotalLabel matlab.ui.control.Label
        StatAvgDurationLabel matlab.ui.control.Label
        StatTopShapeLabel matlab.ui.control.Label
        StatDateRangeLabel matlab.ui.control.Label
        
        % Top Locations Components
        TopLocationsAxes matlab.ui.control.UIAxes
        
        % Monthly Trend Components
        MonthlyAxes matlab.ui.control.UIAxes
        
        % Globe Panel Components
        GlobeAxes
    end

    properties (Access = private)
        Data          % Loaded data table
        WordCloudGenerated = false
        GlowTimer     % Timer for button glow animation
        GlowPhase = 0 % Animation phase
    end

    % Methods that perform app initialization and construction
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Veriyi yükle ve çiz
            app.loadAndPlotData();
            
            % Start glow animation
            app.startGlowTimer();
        end
        
        % Glow animation timer functions
        function startGlowTimer(app)
            app.GlowTimer = timer('ExecutionMode', 'fixedRate', ...
                'Period', 0.05, ...
                'TimerFcn', @(~,~) app.glowTimerCallback());
            start(app.GlowTimer);
        end
        
        function stopGlowTimer(app)
            if ~isempty(app.GlowTimer) && isvalid(app.GlowTimer)
                stop(app.GlowTimer);
                delete(app.GlowTimer);
            end
        end
        
        function glowTimerCallback(app)
            try
                app.GlowPhase = app.GlowPhase + 0.08;
                if app.GlowPhase > 2*pi
                    app.GlowPhase = 0;
                end
                
                % Pulsing glow effect on title
                glowIntensity = 0.5 + 0.5 * sin(app.GlowPhase);
                app.TitleLabel.FontColor = [0 glowIntensity 0.82*glowIntensity + 0.18];
            catch
                % Ignore if app is closing
            end
        end
        
        % Helper to reset all sidebar buttons to their original state
        function resetButtons(app)
            buttons = {app.HomeButton, app.MapButton, app.ShapesButton, app.YearsButton, ...
                       app.HoursButton, app.PredictionButton, app.RandomButton, app.WordCloudButton, ...
                       app.StatsButton, app.TopLocationsButton, app.MonthlyButton, app.GlobeButton};
            
            for i = 1:numel(buttons)
                btn = buttons{i};
                if ~isempty(btn) && isvalid(btn) && ~isempty(btn.UserData)
                    btn.BackgroundColor = btn.UserData; % Restore original color
                    btn.FontColor = [0 0 0]; % Restore black text
                end
            end
        end
        
        % Helper to highlight the active button
        function highlightButton(app, btn)
            btn.BackgroundColor = [1 1 1]; % White
            btn.FontColor = [0 0 0]; % Black
        end
        
        function loadAndPlotData(app)
            try
                app.StatusLabel.Text = 'Veri yükleniyor...';
                drawnow;

                % Veriyi yükle (Caching Strategy)
                if exist('dataset/ufo_optimized.mat', 'file')
                    app.StatusLabel.Text = 'Önbellek yükleniyor...';
                    drawnow;
                    loaded = load('dataset/ufo_optimized.mat', 'data');
                    app.Data = loaded.data;
                elseif exist('dataset/ufo_cleaned.mat', 'file')
                    app.StatusLabel.Text = 'Veri işleniyor...';
                    drawnow;
                    loaded = load('dataset/ufo_cleaned.mat', 'data');
                    raw_data = loaded.data;
                    
                    % Optimizasyon: Geçersiz tarihleri filtrele
                    validDates = ~isnat(raw_data.datetime_parsed);
                    app.Data = raw_data(validDates, :);
                    
                    % Optimizasyon: Kategorik veri tipi (Hızlandırır)
                    app.Data.shape = categorical(app.Data.shape);
                    
                    % Önbelleğe kaydet
                    data = app.Data; %#ok<NASGU>
                    save('dataset/ufo_optimized.mat', 'data');
                else
                    error('dataset/ufo_cleaned.mat bulunamadı.');
                end

                app.StatusLabel.Text = 'Harita hazırlanıyor...';
                drawnow;

                % SAMPLE
                N = min(2000,height(app.Data));
                idx = randperm(height(app.Data), N);
                sample = app.Data(idx,:);

                % COLORS
                shapes = unique(sample.shape);
                cmap = lines(numel(shapes));
                [~,shapeIdx] = ismember(sample.shape, shapes);
                shapeColors = cmap(shapeIdx,:);

                % ============================
                %   UFO GEOSCATTER
                % ============================
                hold(app.MapAxes, 'on');
                % geoscatter(lat, lon, size, color, ...)
                % geoscatter(lat, lon, size, color, ...)
                g = geoscatter(app.MapAxes, sample.latitude, sample.longitude, ...
                    20, shapeColors, 'filled', ...
                    'MarkerEdgeColor','none', ...
                    'MarkerFaceAlpha', 0.8);
                
                % Custom Tooltips
                row = dataTipTextRow('Shape', sample.shape);
                g.DataTipTemplate.DataTipRows(1) = row;
                g.DataTipTemplate.DataTipRows(2) = dataTipTextRow('Date', sample.datetime_parsed);
                g.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Duration', string(sample.duration_seconds) + "s");
                
                % Handle Description (check if exists)
                if ismember('comments', sample.Properties.VariableNames)
                    g.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Desc', sample.comments);
                end
                hold(app.MapAxes, 'off');

                % AXES STYLE
                % GeographicAxes properties are different from UIAxes
                title(app.MapAxes, sprintf("UFO Sightings (%d Points)", N), ...
                    'Color',[0.8 0.8 0.8],'FontSize',12);

                % ============================
                %   STATS PIE CHART
                % ============================
                % Calculate shape counts
                [g, shapes] = findgroups(app.Data.shape);
                counts = splitapply(@numel, app.Data.shape, g);
                
                % Sort for better visualization (Top 10 + Others)
                [sortedCounts, sortIdx] = sort(counts, 'descend');
                sortedShapes = shapes(sortIdx);
                
                if numel(sortedCounts) > 10
                    topCounts = sortedCounts(1:10);
                    topShapes = sortedShapes(1:10);
                    otherCount = sum(sortedCounts(11:end));
                    
                    finalCounts = [topCounts; otherCount];
                    finalShapes = [topShapes; "Others"];
                else
                    finalCounts = sortedCounts;
                    finalShapes = sortedShapes;
                end
                
                % Plot Pie Chart
                pie(app.PieAxes, finalCounts);
                legend(app.PieAxes, finalShapes, 'Location', 'eastoutside', 'TextColor', [0.9 0.97 1.0]);
                title(app.PieAxes, 'UFO Shapes Distribution', 'Color', [0 1 0.82], 'FontSize', 14, 'FontName', 'Consolas');
                app.PieAxes.Colormap = lines(numel(finalCounts)); % Keep lines for now, or custom?

                % ============================
                %   STATS TIME SERIES
                % ============================
                % Extract years
                years = year(app.Data.datetime_parsed);
                [yGroup, yVal] = findgroups(years);
                yCounts = splitapply(@numel, years, yGroup);
                
                % Plot Time Series
                plot(app.TimeSeriesAxes, yVal, yCounts, '-o', 'Color', [1 0.66 0], ...
                    'LineWidth', 2, 'MarkerFaceColor', [1 0.66 0], 'MarkerSize', 4);
                
                title(app.TimeSeriesAxes, 'Sightings per Year', 'Color', [1 0.66 0], 'FontSize', 14, 'FontName', 'Consolas');
                xlabel(app.TimeSeriesAxes, 'Year', 'Color', [0.9 0.97 1.0], 'FontName', 'Consolas');
                ylabel(app.TimeSeriesAxes, 'Count', 'Color', [0.9 0.97 1.0], 'FontName', 'Consolas');
                app.TimeSeriesAxes.XColor = [1 0.66 0];
                app.TimeSeriesAxes.YColor = [1 0.66 0];
                app.TimeSeriesAxes.Color = [0.043 0.07 0.125];
                grid(app.TimeSeriesAxes, 'on');
                app.TimeSeriesAxes.GridColor = [0.4 0.8 1];
                app.TimeSeriesAxes.GridAlpha = 0.3;

                % ============================
                %   HOURLY DISTRIBUTION
                % ============================
                hours = hour(app.Data.datetime_parsed);
                histogram(app.HourlyAxes, hours, 'NumBins', 24, 'FaceColor', [0.4 0.8 1], 'EdgeColor', 'none');
                
                title(app.HourlyAxes, 'Sightings by Hour of Day', 'Color', [0.4 0.8 1], 'FontSize', 14, 'FontName', 'Consolas');
                xlabel(app.HourlyAxes, 'Hour (0-23)', 'Color', [0.9 0.97 1.0], 'FontName', 'Consolas');
                ylabel(app.HourlyAxes, 'Count', 'Color', [0.9 0.97 1.0], 'FontName', 'Consolas');
                app.HourlyAxes.XColor = [0.4 0.8 1];
                app.HourlyAxes.YColor = [0.4 0.8 1];
                app.HourlyAxes.Color = [0.043 0.07 0.125];
                grid(app.HourlyAxes, 'on');
                app.HourlyAxes.GridColor = [0.4 0.8 1];
                app.HourlyAxes.GridAlpha = 0.3;
                xlim(app.HourlyAxes, [0 24]);

                % ============================
                %   POPULATE CITY DROPDOWN
                % ============================
                if ismember('city', app.Data.Properties.VariableNames)
                    cities = unique(string(app.Data.city));
                    cities(ismissing(cities) | cities == "") = [];
                    app.CityDropDown.Items = sort(cities);
                    if ~isempty(app.CityDropDown.Items)
                        app.CityDropDown.Value = app.CityDropDown.Items(1);
                    end
                end

                app.StatusLabel.Text = 'Hazır.';
                app.StatusLabel.FontColor = [0.39 0.83 0.07];

            catch ME
                app.StatusLabel.Text = 'Hata!';
                app.StatusLabel.FontColor = [1 0 0];
                uialert(app.UIFigure, ME.message,'Hata');
            end
        end

        function HomeButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.HomeButton);
            app.hideAllPanels();
            app.WelcomePanel.Visible = 'on';
        end

        function MapButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.MapButton);
            app.hideAllPanels();
            app.MapPanel.Visible = 'on';
        end

        function ShapesButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.ShapesButton);
            app.hideAllPanels();
            app.ShapesPanel.Visible = 'on';
        end

        function YearsButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.YearsButton);
            app.hideAllPanels();
            app.YearsPanel.Visible = 'on';
        end

        function HoursButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.HoursButton);
            app.hideAllPanels();
            app.HoursPanel.Visible = 'on';
        end

        function PredictionButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.PredictionButton);
            app.hideAllPanels();
            app.PredictionPanel.Visible = 'on';
        end

        function RandomButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.RandomButton);
            app.hideAllPanels();
            app.RandomPanel.Visible = 'on';
            
            % Show a random sighting immediately
            app.showRandomSighting();
        end
        
        function WordCloudButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.WordCloudButton);
            app.hideAllPanels();
            app.WordCloudPanel.Visible = 'on';
            
            if ~app.WordCloudGenerated
                app.StatusLabel.Text = 'Generating Word Cloud...';
                drawnow;
                
                try
                    % Sample Data
                    if height(app.Data) > 5000
                        idx = randperm(height(app.Data), 5000);
                        sampleData = app.Data(idx, :);
                    else
                        sampleData = app.Data;
                    end
                    
                    if ismember('comments', sampleData.Properties.VariableNames)
                        textData = string(sampleData.comments);
                        textData = lower(textData);
                        
                        % Remove Stop Words (Basic List)
                        stopWords = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "is", "was", "were", "it", "this", "that", "i", "my", "we", "saw", "seen", "ufo", "object", "light", "lights", "sky", "shaped", "shape", "from", "as", "be", "by", "not", "are", "have", "had", "very", "so", "just", "like", "about", "out", "up", "down", "over", "then", "when", "which", "what", "there", "here", "some", "one", "two", "three", "four", "five", "seconds", "minutes", "hours", "duration", "nuforc", "note", "pd"];
                        
                        % Create Word Cloud
                        wordcloud(app.WordCloudPanel, textData, 'HighlightColor', [0.486 1 0], 'Color', [0.9 0.97 1.0]);
                        
                        app.WordCloudGenerated = true;
                        app.StatusLabel.Text = 'Word Cloud Ready.';
                    else
                        uialert(app.UIFigure, 'No comments data found.', 'Error');
                    end
                catch ME
                    app.StatusLabel.Text = 'Error generating Word Cloud.';
                    disp(ME.message);
                end
            end
        end
        
        function NextRandomButtonPushed(app, event)
            app.showRandomSighting();
        end

        function showRandomSighting(app)
            try
                N = height(app.Data);
                if N == 0
                    return;
                end
                
                idx = randi(N);
                row = app.Data(idx, :);
                
                % Update Labels
                app.RandomDateLabel.Text = sprintf('Date: %s', datestr(row.datetime_parsed));
                app.RandomCityLabel.Text = sprintf('Location: %s, %s', string(row.city), string(row.country));
                app.RandomShapeLabel.Text = sprintf('Shape: %s', string(row.shape));
                app.RandomDurationLabel.Text = sprintf('Duration: %.0f seconds', row.duration_seconds);
                
                % Description
                if ismember('comments', row.Properties.VariableNames)
                    desc = string(row.comments);
                else
                    desc = "No description available.";
                end
                app.RandomDescTextArea.Value = desc;
                
            catch ME
                uialert(app.UIFigure, ME.message, 'Error');
            end
        end

        function PredictButtonPushed(app, event)
            try
                % Load Model based on Selection
                modelType = app.ModelDropDown.Value;
                if strcmp(modelType, 'Decision Tree')
                    modelFile = 'dataset/ufo_model_ct.mat';
                else
                    modelFile = 'dataset/ufo_model_nb.mat';
                end
                
                if ~exist(modelFile, 'file')
                    uialert(app.UIFigure, sprintf('Model file %s not found. Please run training script.', modelFile), 'Error');
                    return;
                end
                
                loaded = load(modelFile, 'model', 'shapes');
                model = loaded.model;
                shapes = loaded.shapes;
                
                % Prepare Input
                % Prepare Input
                cityStr = app.CityDropDown.Value;
                cityData = app.Data(string(app.Data.city) == cityStr, :);
                
                if isempty(cityData)
                    lat = 0; lon = 0; 
                else
                    lat = mean(cityData.latitude, 'omitnan');
                    lon = mean(cityData.longitude, 'omitnan');
                end
                
                dt = app.DatePicker.Value;
                monthVal = month(dt);
                hourVal = app.HourEditField.Value;
                duration = app.DurationEditField.Value;
                shapeStr = app.ShapeDropDown.Value;
                
                % Encode Shape
                [~, shapeIdx] = ismember(shapeStr, shapes);
                if shapeIdx == 0, shapeIdx = 1; end % Default if not found
                
                % Predict
                X = [lat, lon, monthVal, hourVal, duration, shapeIdx];
                [~, score] = predict(model, X);
                
                % Score is probability of class 1 (Sighting)
                prob = score(2); 
                
                % Update UI
                app.ResultLabel.Text = sprintf('%.1f%% Probability', prob * 100);
                app.PredictionGauge.Value = prob * 100;
                
                app.ResultLabel.FontColor = [1 0.43 0.78]; % Pink
                
                app.StatusLabel.Text = 'Analysis Complete.';
                
            catch ME
                uialert(app.UIFigure, ME.message, 'Prediction Error');
                app.StatusLabel.Text = 'Error.';
            end
        end
        
        % Helper to hide all panels
        function hideAllPanels(app)
            app.WelcomePanel.Visible = 'off';
            app.MapPanel.Visible = 'off';
            app.ShapesPanel.Visible = 'off';
            app.YearsPanel.Visible = 'off';
            app.HoursPanel.Visible = 'off';
            app.PredictionPanel.Visible = 'off';
            app.RandomPanel.Visible = 'off';
            app.WordCloudPanel.Visible = 'off';
            app.StatsPanel.Visible = 'off';
            app.TopLocationsPanel.Visible = 'off';
            app.MonthlyPanel.Visible = 'off';
            app.GlobePanel.Visible = 'off';
        end
        
        function StatsButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.StatsButton);
            app.hideAllPanels();
            app.StatsPanel.Visible = 'on';
            
            % Calculate and display stats
            app.updateStatsPanel();
        end
        
        function TopLocationsButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.TopLocationsButton);
            app.hideAllPanels();
            app.TopLocationsPanel.Visible = 'on';
            
            % Plot top locations
            app.plotTopLocations();
        end
        
        function MonthlyButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.MonthlyButton);
            app.hideAllPanels();
            app.MonthlyPanel.Visible = 'on';
            
            % Plot monthly trends
            app.plotMonthlyTrends();
        end
        
        function GlobeButtonPushed(app, event)
            app.resetButtons();
            app.highlightButton(app.GlobeButton);
            app.hideAllPanels();
            app.GlobePanel.Visible = 'on';
            
            % Plot 3D Globe
            app.plotGlobe();
        end
        
        function plotGlobe(app)
            try
                cla(app.GlobeAxes);
                hold(app.GlobeAxes, 'on');
                
                % Sample data for performance
                N = min(3000, height(app.Data));
                idx = randperm(height(app.Data), N);
                sample = app.Data(idx, :);
                
                % Load Earth topography data
                load('topo.mat', 'topo', 'topomap1');
                
                % topo is 180x360, but longitude is 0-360
                % Shift to -180 to 180 by moving western hemisphere
                topo_shifted = [topo(:, 181:360), topo(:, 1:180)];
                
                % Create sphere mesh
                [phi, theta] = meshgrid(linspace(-pi, pi, 360), linspace(-pi/2, pi/2, 180));
                
                R = 0.97;
                Xs = R * cos(theta) .* cos(phi);
                Ys = R * cos(theta) .* sin(phi);
                Zs = R * sin(theta);
                
                % Plot Earth with corrected texture
                surface(app.GlobeAxes, Xs, Ys, Zs, 'FaceColor', 'texturemap', ...
                    'EdgeColor', 'none', 'CData', topo_shifted, 'FaceAlpha', 0.95);
                colormap(app.GlobeAxes, topomap1);
                
                % Convert UFO lat/lon to 3D (same coordinate system)
                R_points = 1.02;
                lat_rad = deg2rad(sample.latitude);
                lon_rad = deg2rad(sample.longitude);
                
                x = R_points * cos(lat_rad) .* cos(lon_rad);
                y = R_points * cos(lat_rad) .* sin(lon_rad);
                z = R_points * sin(lat_rad);
                
                % Plot UFO points
                scatter3(app.GlobeAxes, x, y, z, 30, [1 0 0.5], 'filled', ...
                    'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', [1 1 0], 'LineWidth', 0.5);
                
                % Style
                app.GlobeAxes.Color = [0.02 0.027 0.039];
                app.GlobeAxes.XColor = 'none';
                app.GlobeAxes.YColor = 'none';
                app.GlobeAxes.ZColor = 'none';
                axis(app.GlobeAxes, 'equal');
                view(app.GlobeAxes, -100, 25); % View centered on North America
                
                rotate3d(app.GlobeAxes, 'on');
                
                title(app.GlobeAxes, sprintf('Earth UFO Hotspots (%d points)', N), ...
                    'Color', [0 1 0.82], 'FontSize', 14, 'FontName', 'Consolas');
                
                hold(app.GlobeAxes, 'off');
                
            catch ME
                disp(ME.message);
            end
        end
        
        function updateStatsPanel(app)
            try
                % Total sightings
                totalCount = height(app.Data);
                app.StatTotalLabel.Text = sprintf('%d sightings', totalCount);
                
                % Average duration
                avgDuration = mean(app.Data.duration_seconds, 'omitnan');
                if avgDuration < 60
                    app.StatAvgDurationLabel.Text = sprintf('%.1f seconds', avgDuration);
                elseif avgDuration < 3600
                    app.StatAvgDurationLabel.Text = sprintf('%.1f minutes', avgDuration/60);
                else
                    app.StatAvgDurationLabel.Text = sprintf('%.1f hours', avgDuration/3600);
                end
                
                % Most common shape
                [g, shapes] = findgroups(app.Data.shape);
                counts = splitapply(@numel, app.Data.shape, g);
                [~, maxIdx] = max(counts);
                topShape = string(shapes(maxIdx));
                app.StatTopShapeLabel.Text = sprintf('%s', upper(topShape));
                
                % Date range
                minDate = min(app.Data.datetime_parsed);
                maxDate = max(app.Data.datetime_parsed);
                app.StatDateRangeLabel.Text = sprintf('%d - %d', year(minDate), year(maxDate));
                
            catch ME
                app.StatTotalLabel.Text = 'Error loading';
                disp(ME.message);
            end
        end
        
        function plotTopLocations(app)
            try
                cla(app.TopLocationsAxes);
                
                % Get top 10 cities
                [g, cities] = findgroups(string(app.Data.city));
                counts = splitapply(@numel, app.Data.city, g);
                
                [sortedCounts, sortIdx] = sort(counts, 'descend');
                top10Counts = sortedCounts(1:min(10, numel(sortedCounts)));
                top10Cities = cities(sortIdx(1:min(10, numel(cities))));
                
                % Reverse for horizontal bar (top at top)
                top10Counts = flipud(top10Counts);
                top10Cities = flipud(top10Cities);
                
                % Plot horizontal bar
                barh(app.TopLocationsAxes, top10Counts, 'FaceColor', [1 0 0.5], 'EdgeColor', 'none');
                app.TopLocationsAxes.YTick = 1:numel(top10Cities);
                app.TopLocationsAxes.YTickLabel = top10Cities;
                
                xlabel(app.TopLocationsAxes, 'Number of Sightings', 'Color', [0.9 0.97 1.0], 'FontName', 'Consolas');
                title(app.TopLocationsAxes, 'Top 10 UFO Hotspots', 'Color', [1 0 0.5], 'FontSize', 16, 'FontName', 'Consolas');
                
                app.TopLocationsAxes.XColor = [1 0 0.5];
                app.TopLocationsAxes.YColor = [0.9 0.97 1.0];
                app.TopLocationsAxes.Color = [0.043 0.07 0.125];
                grid(app.TopLocationsAxes, 'on');
                app.TopLocationsAxes.GridColor = [1 0 0.5];
                app.TopLocationsAxes.GridAlpha = 0.3;
                
            catch ME
                disp(ME.message);
            end
        end
        
        function plotMonthlyTrends(app)
            try
                cla(app.MonthlyAxes);
                
                % Get month from dates
                months = month(app.Data.datetime_parsed);
                [g, monthVals] = findgroups(months);
                counts = splitapply(@numel, months, g);
                
                % Ensure all 12 months
                allCounts = zeros(12, 1);
                for i = 1:numel(monthVals)
                    allCounts(monthVals(i)) = counts(i);
                end
                
                % Plot bar chart
                b = bar(app.MonthlyAxes, 1:12, allCounts, 'FaceColor', [0 0.8 0.8], 'EdgeColor', 'none');
                
                % Month names
                monthNames = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
                app.MonthlyAxes.XTick = 1:12;
                app.MonthlyAxes.XTickLabel = monthNames;
                
                xlabel(app.MonthlyAxes, 'Month', 'Color', [0.9 0.97 1.0], 'FontName', 'Consolas');
                ylabel(app.MonthlyAxes, 'Sightings', 'Color', [0.9 0.97 1.0], 'FontName', 'Consolas');
                title(app.MonthlyAxes, 'Monthly UFO Activity', 'Color', [0 0.8 0.8], 'FontSize', 16, 'FontName', 'Consolas');
                
                app.MonthlyAxes.XColor = [0 0.8 0.8];
                app.MonthlyAxes.YColor = [0 0.8 0.8];
                app.MonthlyAxes.Color = [0.043 0.07 0.125];
                grid(app.MonthlyAxes, 'on');
                app.MonthlyAxes.GridColor = [0 0.8 0.8];
                app.MonthlyAxes.GridAlpha = 0.3;
                xlim(app.MonthlyAxes, [0.5 12.5]);
                
            catch ME
                disp(ME.message);
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 800];
            app.UIFigure.Name = 'Astral Observer';
            app.UIFigure.Color = [0.02 0.027 0.039]; % Neon Ops BG

            % ============================
            % SIDEBAR
            % ============================
            app.SidebarPanel = uipanel(app.UIFigure);
            app.SidebarPanel.Position = [1 1 200 800];
            app.SidebarPanel.BackgroundColor = [0.0235 0.0275 0.0471];
            app.SidebarPanel.BorderType = 'none';

            % Title in Sidebar
            app.TitleLabel = uilabel(app.SidebarPanel);
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontName = 'Consolas';
            app.TitleLabel.FontSize = 20;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = [0 1 0.82]; % Accent Aqua
            app.TitleLabel.Position = [10 740 180 50];
            app.TitleLabel.Text = '>>ASTRAL_OBS';
            
            % Home Button
            app.HomeButton = uibutton(app.SidebarPanel, 'push');
            app.HomeButton.Position = [20 700 160 40];
            app.HomeButton.Text = '>>HOME';
            app.HomeButton.FontName = 'Consolas';
            app.HomeButton.FontSize = 14;
            app.HomeButton.BackgroundColor = [0.8 0.8 0.8]; % Light Gray
            app.HomeButton.FontColor = [0 0 0];
            app.HomeButton.UserData = app.HomeButton.BackgroundColor; % Store original color
            app.HomeButton.ButtonPushedFcn = createCallbackFcn(app, @HomeButtonPushed, true);
            


            % Map Button
            app.MapButton = uibutton(app.SidebarPanel, 'push');
            app.MapButton.Position = [20 650 160 40];
            app.MapButton.Text = '>>MAP_VIEW';
            app.MapButton.FontName = 'Consolas';
            app.MapButton.FontSize = 14;
            app.MapButton.BackgroundColor = [0 1 0.82]; % Accent Aqua
            app.MapButton.FontColor = [0 0 0];
            app.MapButton.UserData = app.MapButton.BackgroundColor;
            app.MapButton.ButtonPushedFcn = createCallbackFcn(app, @MapButtonPushed, true);

            % 3D Globe Button (after Map - Geographic)
            app.GlobeButton = uibutton(app.SidebarPanel, 'push');
            app.GlobeButton.Position = [20 590 160 40];
            app.GlobeButton.Text = '>>3D_GLOBE';
            app.GlobeButton.FontName = 'Consolas';
            app.GlobeButton.FontSize = 14;
            app.GlobeButton.BackgroundColor = [0.2 0.4 0.8]; % Deep Blue
            app.GlobeButton.FontColor = [1 1 1]; % White text
            app.GlobeButton.UserData = app.GlobeButton.BackgroundColor;
            app.GlobeButton.ButtonPushedFcn = createCallbackFcn(app, @GlobeButtonPushed, true);

            % Stats Button (Overview)
            app.StatsButton = uibutton(app.SidebarPanel, 'push');
            app.StatsButton.Position = [20 530 160 40];
            app.StatsButton.Text = '>>STATS';
            app.StatsButton.FontName = 'Consolas';
            app.StatsButton.FontSize = 14;
            app.StatsButton.BackgroundColor = [1 0.84 0]; % Gold
            app.StatsButton.FontColor = [0 0 0];
            app.StatsButton.UserData = app.StatsButton.BackgroundColor;
            app.StatsButton.ButtonPushedFcn = createCallbackFcn(app, @StatsButtonPushed, true);

            % Top Cities Button (Location Analysis)
            app.TopLocationsButton = uibutton(app.SidebarPanel, 'push');
            app.TopLocationsButton.Position = [20 470 160 40];
            app.TopLocationsButton.Text = '>>TOP_CITIES';
            app.TopLocationsButton.FontName = 'Consolas';
            app.TopLocationsButton.FontSize = 14;
            app.TopLocationsButton.BackgroundColor = [1 0 0.5]; % Magenta
            app.TopLocationsButton.FontColor = [0 0 0];
            app.TopLocationsButton.UserData = app.TopLocationsButton.BackgroundColor;
            app.TopLocationsButton.ButtonPushedFcn = createCallbackFcn(app, @TopLocationsButtonPushed, true);

            % Yearly Trend Button (Time Analysis)
            app.YearsButton = uibutton(app.SidebarPanel, 'push');
            app.YearsButton.Position = [20 410 160 40];
            app.YearsButton.Text = '>>YEARLY_TREND';
            app.YearsButton.FontName = 'Consolas';
            app.YearsButton.FontSize = 14;
            app.YearsButton.BackgroundColor = [1 0.66 0]; % Accent Orange
            app.YearsButton.FontColor = [0 0 0];
            app.YearsButton.UserData = app.YearsButton.BackgroundColor;
            app.YearsButton.ButtonPushedFcn = createCallbackFcn(app, @YearsButtonPushed, true);

            % Monthly Button (Time Analysis)
            app.MonthlyButton = uibutton(app.SidebarPanel, 'push');
            app.MonthlyButton.Position = [20 350 160 40];
            app.MonthlyButton.Text = '>>MONTHLY';
            app.MonthlyButton.FontName = 'Consolas';
            app.MonthlyButton.FontSize = 14;
            app.MonthlyButton.BackgroundColor = [0 0.8 0.8]; % Cyan
            app.MonthlyButton.FontColor = [0 0 0];
            app.MonthlyButton.UserData = app.MonthlyButton.BackgroundColor;
            app.MonthlyButton.ButtonPushedFcn = createCallbackFcn(app, @MonthlyButtonPushed, true);

            % Hourly Button (Time Analysis)
            app.HoursButton = uibutton(app.SidebarPanel, 'push');
            app.HoursButton.Position = [20 290 160 40];
            app.HoursButton.Text = '>>HOURLY_DIST';
            app.HoursButton.FontName = 'Consolas';
            app.HoursButton.FontSize = 14;
            app.HoursButton.BackgroundColor = [0.4 0.8 1]; % Accent Blue
            app.HoursButton.FontColor = [0 0 0];
            app.HoursButton.UserData = app.HoursButton.BackgroundColor;
            app.HoursButton.ButtonPushedFcn = createCallbackFcn(app, @HoursButtonPushed, true);

            % Shapes Button (Category)
            app.ShapesButton = uibutton(app.SidebarPanel, 'push');
            app.ShapesButton.Position = [20 230 160 40];
            app.ShapesButton.Text = '>>SHAPES';
            app.ShapesButton.FontName = 'Consolas';
            app.ShapesButton.FontSize = 14;
            app.ShapesButton.BackgroundColor = [0.486 1 0]; % Accent Green
            app.ShapesButton.FontColor = [0 0 0];
            app.ShapesButton.UserData = app.ShapesButton.BackgroundColor;
            app.ShapesButton.ButtonPushedFcn = createCallbackFcn(app, @ShapesButtonPushed, true);

            % Word Cloud Button (Text)
            app.WordCloudButton = uibutton(app.SidebarPanel, 'push');
            app.WordCloudButton.Position = [20 170 160 40];
            app.WordCloudButton.Text = '>>WORD_CLOUD';
            app.WordCloudButton.FontName = 'Consolas';
            app.WordCloudButton.FontSize = 14;
            app.WordCloudButton.BackgroundColor = [0.486 1 0]; % Accent Green
            app.WordCloudButton.FontColor = [0 0 0];
            app.WordCloudButton.UserData = app.WordCloudButton.BackgroundColor;
            app.WordCloudButton.ButtonPushedFcn = createCallbackFcn(app, @WordCloudButtonPushed, true);

            % Random Button (Explore)
            app.RandomButton = uibutton(app.SidebarPanel, 'push');
            app.RandomButton.Position = [20 110 160 40];
            app.RandomButton.Text = '>>RANDOM_UFO';
            app.RandomButton.FontName = 'Consolas';
            app.RandomButton.FontSize = 14;
            app.RandomButton.BackgroundColor = [0 1 0.82]; % Accent Aqua
            app.RandomButton.FontColor = [0 0 0];
            app.RandomButton.UserData = app.RandomButton.BackgroundColor;
            app.RandomButton.ButtonPushedFcn = createCallbackFcn(app, @RandomButtonPushed, true);

            % Prediction Button (Interactive)
            app.PredictionButton = uibutton(app.SidebarPanel, 'push');
            app.PredictionButton.Position = [20 50 160 40];
            app.PredictionButton.Text = '>>PREDICTION';
            app.PredictionButton.FontName = 'Consolas';
            app.PredictionButton.FontSize = 14;
            app.PredictionButton.BackgroundColor = [1 0.43 0.78]; % Accent Pink
            app.PredictionButton.FontColor = [0 0 0];
            app.PredictionButton.UserData = app.PredictionButton.BackgroundColor;
            app.PredictionButton.ButtonPushedFcn = createCallbackFcn(app, @PredictionButtonPushed, true);

            % Status Label in Sidebar
            app.StatusLabel = uilabel(app.SidebarPanel);
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.FontName = 'Consolas';
            app.StatusLabel.FontSize = 10;
            app.StatusLabel.FontColor = [0.9 0.97 1.0];
            app.StatusLabel.Position = [10 10 180 22];
            app.StatusLabel.Text = 'Initializing...';

            % ============================
            % MAP PANEL
            % ============================
            app.MapPanel = uipanel(app.UIFigure);
            app.MapPanel.Position = [201 1 999 770];
            app.MapPanel.BackgroundColor = [0.043 0.07 0.125];
            app.MapPanel.BorderType = 'line';
            app.MapPanel.HighlightColor = [0 1 0.82];
            app.MapPanel.Title = '>> GEO_RADAR';
            app.MapPanel.FontName = 'Consolas';
            app.MapPanel.FontSize = 12;
            app.MapPanel.FontWeight = 'bold';
            app.MapPanel.ForegroundColor = [0 1 0.82];
            app.MapPanel.Visible = 'off';

            % Create MapAxes (GeographicAxes) in MapPanel
            app.MapAxes = geoaxes(app.MapPanel);
            app.MapAxes.Units = 'pixels';
            app.MapAxes.Position = [50 30 900 680];
            app.MapAxes.Visible = 'on';
            app.MapAxes.FontName = 'Consolas';
            app.MapAxes.FontSize = 12;
            app.MapAxes.Basemap = 'colorterrain';

            % ============================
            % SHAPES PANEL
            % ============================
            app.ShapesPanel = uipanel(app.UIFigure);
            app.ShapesPanel.Position = [201 1 999 770];
            app.ShapesPanel.BackgroundColor = [0.043 0.07 0.125];
            app.ShapesPanel.BorderType = 'line';
            app.ShapesPanel.HighlightColor = [0.486 1 0];
            app.ShapesPanel.Title = '>> SHAPE_ANALYSIS';
            app.ShapesPanel.FontName = 'Consolas';
            app.ShapesPanel.FontSize = 12;
            app.ShapesPanel.FontWeight = 'bold';
            app.ShapesPanel.ForegroundColor = [0.486 1 0];
            app.ShapesPanel.Visible = 'off';

            % Create PieAxes in ShapesPanel
            app.PieAxes = uiaxes(app.ShapesPanel);
            app.PieAxes.Position = [100 70 800 580];
            app.PieAxes.BackgroundColor = [0.043 0.07 0.125];
            app.PieAxes.XColor = 'none';
            app.PieAxes.YColor = 'none';
            app.PieAxes.Color = 'none';
            
            % ============================
            % YEARS PANEL
            % ============================
            app.YearsPanel = uipanel(app.UIFigure);
            app.YearsPanel.Position = [201 1 999 770];
            app.YearsPanel.BackgroundColor = [0.043 0.07 0.125];
            app.YearsPanel.BorderType = 'line';
            app.YearsPanel.HighlightColor = [1 0.66 0];
            app.YearsPanel.Title = '>> TIME_SERIES_SCAN';
            app.YearsPanel.FontName = 'Consolas';
            app.YearsPanel.FontSize = 12;
            app.YearsPanel.FontWeight = 'bold';
            app.YearsPanel.ForegroundColor = [1 0.66 0];
            app.YearsPanel.Visible = 'off';

            % Create TimeSeriesAxes in YearsPanel
            app.TimeSeriesAxes = uiaxes(app.YearsPanel);
            app.TimeSeriesAxes.Position = [50 30 900 680];
            app.TimeSeriesAxes.BackgroundColor = [0.043 0.07 0.125];
            app.TimeSeriesAxes.FontName = 'Consolas';
            app.TimeSeriesAxes.FontSize = 10;

            % ============================
            % HOURS PANEL
            % ============================
            app.HoursPanel = uipanel(app.UIFigure);
            app.HoursPanel.Position = [201 1 999 770];
            app.HoursPanel.BackgroundColor = [0.043 0.07 0.125];
            app.HoursPanel.BorderType = 'line';
            app.HoursPanel.HighlightColor = [0.4 0.8 1];
            app.HoursPanel.Title = '>> TEMPORAL_DISTRIBUTION';
            app.HoursPanel.FontName = 'Consolas';
            app.HoursPanel.FontSize = 12;
            app.HoursPanel.FontWeight = 'bold';
            app.HoursPanel.ForegroundColor = [0.4 0.8 1];
            app.HoursPanel.Visible = 'off';

            % Create HourlyAxes in HoursPanel
            app.HourlyAxes = uiaxes(app.HoursPanel);
            app.HourlyAxes.Position = [50 30 900 680];
            app.HourlyAxes.BackgroundColor = [0.043 0.07 0.125];
            app.HourlyAxes.FontName = 'Consolas';
            app.HourlyAxes.FontSize = 10;

            % ============================
            % PREDICTION PANEL
            % ============================
            app.PredictionPanel = uipanel(app.UIFigure);
            app.PredictionPanel.Position = [201 1 999 770];
            app.PredictionPanel.BackgroundColor = [0.043 0.07 0.125];
            app.PredictionPanel.BorderType = 'line';
            app.PredictionPanel.HighlightColor = [1 0.43 0.78];
            app.PredictionPanel.Title = '>> PREDICTION_CORE';
            app.PredictionPanel.FontName = 'Consolas';
            app.PredictionPanel.FontSize = 12;
            app.PredictionPanel.FontWeight = 'bold';
            app.PredictionPanel.ForegroundColor = [1 0.43 0.78];
            app.PredictionPanel.Visible = 'off';
            
            % Input Sentence Construction
            % "I saw a [Shape] shaped UFO in [City] on [Date] at [Hour]:[Minute] for [Duration] seconds."
            
            % Input Panel Container
            app.InputPanel = uipanel(app.PredictionPanel);
            app.InputPanel.Position = [50 500 900 200];
            app.InputPanel.BackgroundColor = [0.06 0.09 0.15];
            app.InputPanel.BorderType = 'line';
            app.InputPanel.HighlightColor = [1 0.43 0.78];
            app.InputPanel.Title = '>> SIGHTING_PARAMETERS';
            app.InputPanel.FontName = 'Consolas';
            app.InputPanel.FontSize = 12;
            app.InputPanel.FontWeight = 'bold';
            app.InputPanel.ForegroundColor = [1 0.43 0.78];

            % Row 1: "I saw a [Shape] shaped UFO in [City]"
            uilabel(app.InputPanel, 'Position', [20 130 80 30], 'Text', 'I saw a', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.9 0.97 1.0]);
            
            app.ShapeDropDown = uidropdown(app.InputPanel);
            app.ShapeDropDown.Position = [110 125 150 35];
            app.ShapeDropDown.Items = {'light', 'triangle', 'circle', 'fireball', 'other', 'unknown', 'sphere', 'disk', 'oval'};
            app.ShapeDropDown.FontName = 'Consolas';
            app.ShapeDropDown.FontSize = 14;
            app.ShapeDropDown.BackgroundColor = [0.043 0.07 0.125];
            app.ShapeDropDown.FontColor = [0.9 0.97 1.0];
            
            uilabel(app.InputPanel, 'Position', [270 130 130 30], 'Text', 'shaped UFO in', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.9 0.97 1.0]);
            
            app.CityDropDown = uidropdown(app.InputPanel);
            app.CityDropDown.Position = [410 125 460 35];
            app.CityDropDown.Items = {'Loading...'}; % Populated later
            app.CityDropDown.FontName = 'Consolas';
            app.CityDropDown.FontSize = 14;
            app.CityDropDown.BackgroundColor = [0.043 0.07 0.125];
            app.CityDropDown.FontColor = [0.9 0.97 1.0];

            % Row 2: "on [Date] at [Hour]:[Minute]"
            uilabel(app.InputPanel, 'Position', [20 80 30 30], 'Text', 'on', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.9 0.97 1.0]);
            
            app.DatePicker = uidatepicker(app.InputPanel);
            app.DatePicker.Position = [60 75 180 35];
            app.DatePicker.Value = datetime('today');
            app.DatePicker.FontSize = 14;
            app.DatePicker.BackgroundColor = [0.043 0.07 0.125];
            app.DatePicker.FontColor = [0.9 0.97 1.0];
            
            uilabel(app.InputPanel, 'Position', [260 80 30 30], 'Text', 'at', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.9 0.97 1.0]);
            
            app.HourEditField = uieditfield(app.InputPanel, 'numeric');
            app.HourEditField.Position = [300 75 60 35];
            app.HourEditField.Limits = [0 23];
            app.HourEditField.Value = 22;
            app.HourEditField.FontSize = 14;
            app.HourEditField.BackgroundColor = [0.043 0.07 0.125];
            app.HourEditField.FontColor = [0.9 0.97 1.0];
            
            uilabel(app.InputPanel, 'Position', [365 80 15 30], 'Text', ':', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.9 0.97 1.0]);
            
            app.MinuteEditField = uieditfield(app.InputPanel, 'numeric');
            app.MinuteEditField.Position = [385 75 60 35];
            app.MinuteEditField.Limits = [0 59];
            app.MinuteEditField.Value = 0;
            app.MinuteEditField.FontSize = 14;
            app.MinuteEditField.BackgroundColor = [0.043 0.07 0.125];
            app.MinuteEditField.FontColor = [0.9 0.97 1.0];
            
            % Row 3: "for [Duration] seconds" + Model Selection
            uilabel(app.InputPanel, 'Position', [20 30 30 30], 'Text', 'for', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.9 0.97 1.0]);
            
            app.DurationEditField = uieditfield(app.InputPanel, 'numeric');
            app.DurationEditField.Position = [60 25 100 35];
            app.DurationEditField.Value = 60;
            app.DurationEditField.FontSize = 14;
            app.DurationEditField.BackgroundColor = [0.043 0.07 0.125];
            app.DurationEditField.FontColor = [0.9 0.97 1.0];
            
            uilabel(app.InputPanel, 'Position', [170 30 80 30], 'Text', 'seconds', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.9 0.97 1.0]);
            
            % Model Selection (Same Row)
            uilabel(app.InputPanel, 'Position', [460 30 130 30], 'Text', 'Model:', 'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [1 0.43 0.78]);
            
            app.ModelDropDown = uidropdown(app.InputPanel);
            app.ModelDropDown.Position = [560 25 310 35];
            app.ModelDropDown.Items = {'Decision Tree', 'Naive Bayes'};
            app.ModelDropDown.Value = 'Decision Tree';
            app.ModelDropDown.FontName = 'Consolas';
            app.ModelDropDown.FontSize = 14;
            app.ModelDropDown.BackgroundColor = [0.043 0.07 0.125];
            app.ModelDropDown.FontColor = [0.9 0.97 1.0];

            % Predict Button (Below Input Panel)
            app.PredictButton = uibutton(app.PredictionPanel, 'push');
            app.PredictButton.Position = [50 450 900 60];
            app.PredictButton.Text = '>> ANALYZE PROBABILITY';
            app.PredictButton.FontName = 'Consolas';
            app.PredictButton.FontSize = 18;
            app.PredictButton.FontWeight = 'bold';
            app.PredictButton.BackgroundColor = [1 0.43 0.78]; % Pink
            app.PredictButton.FontColor = [0 0 0];
            app.PredictButton.ButtonPushedFcn = createCallbackFcn(app, @PredictButtonPushed, true);

            % Result Panel (Below Button)
            app.ResultPanel = uipanel(app.PredictionPanel);
            app.ResultPanel.Position = [50 200 900 230];
            app.ResultPanel.BackgroundColor = [0.06 0.09 0.15];
            app.ResultPanel.BorderType = 'line';
            app.ResultPanel.HighlightColor = [1 0.43 0.78];
            app.ResultPanel.Title = '>> ANALYSIS_RESULT';
            app.ResultPanel.FontName = 'Consolas';
            app.ResultPanel.FontSize = 12;
            app.ResultPanel.FontWeight = 'bold';
            app.ResultPanel.ForegroundColor = [1 0.43 0.78];
            
            % Prediction Gauge (Inside Result Panel)
            app.PredictionGauge = uigauge(app.ResultPanel, 'linear');
            app.PredictionGauge.Position = [20 130 860 50];
            app.PredictionGauge.Limits = [0 100];
            app.PredictionGauge.BackgroundColor = [0.043 0.07 0.125];
            app.PredictionGauge.ScaleColors = [1 0.43 0.78; 0.486 1 0];
            app.PredictionGauge.ScaleColorLimits = [0 50; 50 100];
            
            % Result Label (Inside Result Panel)
            app.ResultLabel = uilabel(app.ResultPanel);
            app.ResultLabel.Position = [20 30 860 80];
            app.ResultLabel.Text = 'Ready to analyze. Enter parameters and click the button above.';
            app.ResultLabel.FontName = 'Consolas';
            app.ResultLabel.FontSize = 20;
            app.ResultLabel.FontWeight = 'bold';
            app.ResultLabel.FontColor = [0.9 0.97 1.0];
            app.ResultLabel.HorizontalAlignment = 'center';

            % ============================
            % RANDOM PANEL
            % ============================
            app.RandomPanel = uipanel(app.UIFigure);
            app.RandomPanel.Position = [201 1 999 770];
            app.RandomPanel.BackgroundColor = [0.043 0.07 0.125];
            app.RandomPanel.BorderType = 'line';
            app.RandomPanel.HighlightColor = [0 1 0.82];
            app.RandomPanel.Title = '>> DATA_INTERCEPT';
            app.RandomPanel.FontName = 'Consolas';
            app.RandomPanel.FontSize = 12;
            app.RandomPanel.FontWeight = 'bold';
            app.RandomPanel.ForegroundColor = [0 1 0.82];
            app.RandomPanel.Visible = 'off';
            
            % Title
            app.RandomTitleLabel = uilabel(app.RandomPanel);
            app.RandomTitleLabel.Position = [50 680 900 50];
            app.RandomTitleLabel.Text = '>>RANDOM_SIGHTING_DETAILS';
            app.RandomTitleLabel.FontName = 'Consolas';
            app.RandomTitleLabel.FontSize = 24;
            app.RandomTitleLabel.FontWeight = 'bold';
            app.RandomTitleLabel.FontColor = [0 1 0.82]; % Aqua
            
            % Data Card Panel
            app.DataCardPanel = uipanel(app.RandomPanel);
            app.DataCardPanel.Position = [50 420 900 250];
            app.DataCardPanel.BackgroundColor = [0.06 0.09 0.15];
            app.DataCardPanel.BorderType = 'line';
            app.DataCardPanel.HighlightColor = [0 1 0.82];
            app.DataCardPanel.Title = '>> SIGHTING_DATA';
            app.DataCardPanel.FontName = 'Consolas';
            app.DataCardPanel.FontSize = 12;
            app.DataCardPanel.FontWeight = 'bold';
            app.DataCardPanel.ForegroundColor = [0 1 0.82];

            % Date
            app.RandomDateLabel = uilabel(app.DataCardPanel);
            app.RandomDateLabel.Position = [10 180 880 40];
            app.RandomDateLabel.Text = 'Date: ';
            app.RandomDateLabel.FontName = 'Consolas';
            app.RandomDateLabel.FontSize = 18;
            app.RandomDateLabel.FontColor = 'white';
            
            % City
            app.RandomCityLabel = uilabel(app.DataCardPanel);
            app.RandomCityLabel.Position = [10 130 880 40];
            app.RandomCityLabel.Text = 'Location: ';
            app.RandomCityLabel.FontName = 'Consolas';
            app.RandomCityLabel.FontSize = 18;
            app.RandomCityLabel.FontColor = 'white';
            
            % Shape
            app.RandomShapeLabel = uilabel(app.DataCardPanel);
            app.RandomShapeLabel.Position = [10 80 880 40];
            app.RandomShapeLabel.Text = 'Shape: ';
            app.RandomShapeLabel.FontName = 'Consolas';
            app.RandomShapeLabel.FontSize = 18;
            app.RandomShapeLabel.FontColor = 'white';
            
            % Duration
            app.RandomDurationLabel = uilabel(app.DataCardPanel);
            app.RandomDurationLabel.Position = [10 30 880 40];
            app.RandomDurationLabel.Text = 'Duration: ';
            app.RandomDurationLabel.FontName = 'Consolas';
            app.RandomDurationLabel.FontSize = 18;
            app.RandomDurationLabel.FontColor = 'white';
            
            % Description Panel
            app.DescriptionPanel = uipanel(app.RandomPanel);
            app.DescriptionPanel.Position = [50 170 900 220];
            app.DescriptionPanel.BackgroundColor = [0.06 0.09 0.15];
            app.DescriptionPanel.BorderType = 'line';
            app.DescriptionPanel.HighlightColor = [0 1 0.82];
            app.DescriptionPanel.Title = '>> ENCOUNTER_LOG';
            app.DescriptionPanel.FontName = 'Consolas';
            app.DescriptionPanel.FontSize = 12;
            app.DescriptionPanel.FontWeight = 'bold';
            app.DescriptionPanel.ForegroundColor = [0 1 0.82];
            
            app.RandomDescTextArea = uitextarea(app.DescriptionPanel);
            app.RandomDescTextArea.Position = [10 10 880 180];
            app.RandomDescTextArea.Editable = 'off';
            app.RandomDescTextArea.FontName = 'Consolas';
            app.RandomDescTextArea.FontSize = 14;
            app.RandomDescTextArea.BackgroundColor = [0.15 0.15 0.18];
            app.RandomDescTextArea.FontColor = 'white';
            
            % Next Button
            app.NextRandomButton = uibutton(app.RandomPanel, 'push');
            app.NextRandomButton.Position = [50 70 900 60]; % Full width
            app.NextRandomButton.Text = '>>SHOW_ANOTHER';
            app.NextRandomButton.FontName = 'Consolas';
            app.NextRandomButton.FontSize = 16;
            app.NextRandomButton.BackgroundColor = [0 1 0.82]; % Aqua
            app.NextRandomButton.FontColor = [0 0 0];
            app.NextRandomButton.ButtonPushedFcn = createCallbackFcn(app, @NextRandomButtonPushed, true);


            % ============================
            % WORD CLOUD PANEL
            % ============================
            app.WordCloudPanel = uipanel(app.UIFigure);
            app.WordCloudPanel.Position = [201 1 999 770];
            app.WordCloudPanel.BackgroundColor = [0.043 0.07 0.125];
            app.WordCloudPanel.BorderType = 'line';
            app.WordCloudPanel.HighlightColor = [0.486 1 0];
            app.WordCloudPanel.Title = '>> TEXT_ANALYSIS';
            app.WordCloudPanel.FontName = 'Consolas';
            app.WordCloudPanel.FontSize = 12;
            app.WordCloudPanel.FontWeight = 'bold';
            app.WordCloudPanel.ForegroundColor = [0.486 1 0];
            app.WordCloudPanel.Visible = 'off';
            
            % Title
            uilabel(app.WordCloudPanel, 'Position', [50 700 400 50], 'Text', '>>SIGHTING_DESCRIPTIONS', 'FontName', 'Consolas', 'FontSize', 24, 'FontWeight', 'bold', 'FontColor', [0.39 0.83 0.07]);

            % ============================
            % WELCOME PANEL (Default)
            % ============================
            app.WelcomePanel = uipanel(app.UIFigure);
            app.WelcomePanel.Position = [201 1 999 770];
            app.WelcomePanel.BackgroundColor = [0.02 0.027 0.039];
            app.WelcomePanel.BorderType = 'none';
            app.WelcomePanel.Visible = 'on';
            
            % Background Image
            if exist('bg.jpeg', 'file')
                app.WelcomeImage = uiimage(app.WelcomePanel);
                app.WelcomeImage.Position = [1 1 999 800];
                app.WelcomeImage.ImageSource = 'bg.jpeg';
                app.WelcomeImage.ScaleMethod = 'stretch';
            else
                % Placeholder if image missing
                lbl = uilabel(app.WelcomePanel);
                lbl.Position = [300 400 400 50];
                lbl.Text = 'Please add bg.png to the app folder.';
                lbl.FontColor = [1 1 1];
                lbl.FontSize = 20;
                lbl.HorizontalAlignment = 'center';
            end

            % ============================
            % STATS PANEL
            % ============================
            app.StatsPanel = uipanel(app.UIFigure);
            app.StatsPanel.Position = [201 1 999 770];
            app.StatsPanel.BackgroundColor = [0.043 0.07 0.125];
            app.StatsPanel.BorderType = 'line';
            app.StatsPanel.HighlightColor = [1 0.84 0];
            app.StatsPanel.Title = '>> DATA_OVERVIEW';
            app.StatsPanel.FontName = 'Consolas';
            app.StatsPanel.FontSize = 12;
            app.StatsPanel.FontWeight = 'bold';
            app.StatsPanel.ForegroundColor = [1 0.84 0];
            app.StatsPanel.Visible = 'off';

            % Stats Title
            uilabel(app.StatsPanel, 'Position', [50 680 400 50], 'Text', '>>SIGHTING_STATISTICS', ...
                'FontName', 'Consolas', 'FontSize', 24, 'FontWeight', 'bold', 'FontColor', [1 0.84 0]);

            % Stat Card 1: Total Sightings
            statCard1 = uipanel(app.StatsPanel);
            statCard1.Position = [50 450 420 200];
            statCard1.BackgroundColor = [0.06 0.09 0.15];
            statCard1.BorderType = 'line';
            statCard1.HighlightColor = [1 0.84 0];
            uilabel(statCard1, 'Position', [20 140 380 40], 'Text', 'TOTAL SIGHTINGS', ...
                'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.6 0.6 0.6]);
            app.StatTotalLabel = uilabel(statCard1);
            app.StatTotalLabel.Position = [20 50 380 80];
            app.StatTotalLabel.Text = 'Loading...';
            app.StatTotalLabel.FontName = 'Consolas';
            app.StatTotalLabel.FontSize = 28;
            app.StatTotalLabel.FontWeight = 'bold';
            app.StatTotalLabel.FontColor = [1 0.84 0];

            % Stat Card 2: Average Duration
            statCard2 = uipanel(app.StatsPanel);
            statCard2.Position = [500 450 420 200];
            statCard2.BackgroundColor = [0.06 0.09 0.15];
            statCard2.BorderType = 'line';
            statCard2.HighlightColor = [0 0.8 0.8];
            uilabel(statCard2, 'Position', [20 140 380 40], 'Text', 'AVERAGE DURATION', ...
                'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.6 0.6 0.6]);
            app.StatAvgDurationLabel = uilabel(statCard2);
            app.StatAvgDurationLabel.Position = [20 50 380 80];
            app.StatAvgDurationLabel.Text = 'Loading...';
            app.StatAvgDurationLabel.FontName = 'Consolas';
            app.StatAvgDurationLabel.FontSize = 28;
            app.StatAvgDurationLabel.FontWeight = 'bold';
            app.StatAvgDurationLabel.FontColor = [0 0.8 0.8];

            % Stat Card 3: Most Common Shape
            statCard3 = uipanel(app.StatsPanel);
            statCard3.Position = [50 220 420 200];
            statCard3.BackgroundColor = [0.06 0.09 0.15];
            statCard3.BorderType = 'line';
            statCard3.HighlightColor = [1 0 0.5];
            uilabel(statCard3, 'Position', [20 140 380 40], 'Text', 'MOST COMMON SHAPE', ...
                'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.6 0.6 0.6]);
            app.StatTopShapeLabel = uilabel(statCard3);
            app.StatTopShapeLabel.Position = [20 50 380 80];
            app.StatTopShapeLabel.Text = 'Loading...';
            app.StatTopShapeLabel.FontName = 'Consolas';
            app.StatTopShapeLabel.FontSize = 28;
            app.StatTopShapeLabel.FontWeight = 'bold';
            app.StatTopShapeLabel.FontColor = [1 0 0.5];

            % Stat Card 4: Data Range
            statCard4 = uipanel(app.StatsPanel);
            statCard4.Position = [500 220 420 200];
            statCard4.BackgroundColor = [0.06 0.09 0.15];
            statCard4.BorderType = 'line';
            statCard4.HighlightColor = [0.486 1 0];
            uilabel(statCard4, 'Position', [20 140 380 40], 'Text', 'DATA RANGE', ...
                'FontName', 'Consolas', 'FontSize', 16, 'FontColor', [0.6 0.6 0.6]);
            app.StatDateRangeLabel = uilabel(statCard4);
            app.StatDateRangeLabel.Position = [20 50 380 80];
            app.StatDateRangeLabel.Text = 'Loading...';
            app.StatDateRangeLabel.FontName = 'Consolas';
            app.StatDateRangeLabel.FontSize = 28;
            app.StatDateRangeLabel.FontWeight = 'bold';
            app.StatDateRangeLabel.FontColor = [0.486 1 0];

            % ============================
            % TOP LOCATIONS PANEL
            % ============================
            app.TopLocationsPanel = uipanel(app.UIFigure);
            app.TopLocationsPanel.Position = [201 1 999 770];
            app.TopLocationsPanel.BackgroundColor = [0.043 0.07 0.125];
            app.TopLocationsPanel.BorderType = 'line';
            app.TopLocationsPanel.HighlightColor = [1 0 0.5];
            app.TopLocationsPanel.Title = '>> HOTSPOT_ANALYSIS';
            app.TopLocationsPanel.FontName = 'Consolas';
            app.TopLocationsPanel.FontSize = 12;
            app.TopLocationsPanel.FontWeight = 'bold';
            app.TopLocationsPanel.ForegroundColor = [1 0 0.5];
            app.TopLocationsPanel.Visible = 'off';

            % Top Locations Axes
            app.TopLocationsAxes = uiaxes(app.TopLocationsPanel);
            app.TopLocationsAxes.Position = [50 50 900 680];
            app.TopLocationsAxes.BackgroundColor = [0.043 0.07 0.125];
            app.TopLocationsAxes.FontName = 'Consolas';
            app.TopLocationsAxes.FontSize = 12;

            % ============================
            % MONTHLY PANEL
            % ============================
            app.MonthlyPanel = uipanel(app.UIFigure);
            app.MonthlyPanel.Position = [201 1 999 770];
            app.MonthlyPanel.BackgroundColor = [0.043 0.07 0.125];
            app.MonthlyPanel.BorderType = 'line';
            app.MonthlyPanel.HighlightColor = [0 0.8 0.8];
            app.MonthlyPanel.Title = '>> SEASONAL_PATTERNS';
            app.MonthlyPanel.FontName = 'Consolas';
            app.MonthlyPanel.FontSize = 12;
            app.MonthlyPanel.FontWeight = 'bold';
            app.MonthlyPanel.ForegroundColor = [0 0.8 0.8];
            app.MonthlyPanel.Visible = 'off';

            % Monthly Axes
            app.MonthlyAxes = uiaxes(app.MonthlyPanel);
            app.MonthlyAxes.Position = [50 50 900 680];
            app.MonthlyAxes.BackgroundColor = [0.043 0.07 0.125];
            app.MonthlyAxes.FontName = 'Consolas';
            app.MonthlyAxes.FontSize = 12;

            % ============================
            % GLOBE PANEL (3D)
            % ============================
            app.GlobePanel = uipanel(app.UIFigure);
            app.GlobePanel.Position = [201 1 999 770];
            app.GlobePanel.BackgroundColor = [0.02 0.027 0.039];
            app.GlobePanel.BorderType = 'line';
            app.GlobePanel.HighlightColor = [0.2 0.4 0.8];
            app.GlobePanel.Title = '>> 3D_GLOBE_VIEW';
            app.GlobePanel.FontName = 'Consolas';
            app.GlobePanel.FontSize = 12;
            app.GlobePanel.FontWeight = 'bold';
            app.GlobePanel.ForegroundColor = [0.2 0.4 0.8];
            app.GlobePanel.Visible = 'off';

            % Globe Axes (3D)
            app.GlobeAxes = uiaxes(app.GlobePanel);
            app.GlobeAxes.Position = [50 50 900 680];
            app.GlobeAxes.BackgroundColor = [0.02 0.027 0.039];
            app.GlobeAxes.FontName = 'Consolas';
            app.GlobeAxes.FontSize = 12;
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = UFOVisualizerApp
            % Create UIFigure and components
            createComponents(app);

            % Register the app with App Designer
            registerApp(app, app.UIFigure);

            % Execute the startup function
            runStartupFcn(app, @startupFcn);
        end

        % Code that executes before app deletion
        function delete(app)
            % Stop glow timer
            app.stopGlowTimer();
            
            % Delete UIFigure when app is deleted
            delete(app.UIFigure);
        end
    end
end
