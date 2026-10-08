function SpeechEnhancementSystem_Revised_v3
% ==============================================================
% DSP-BASED SPEECH ENHANCEMENT SYSTEM
% --------------------------------------------------------------
% Single MATLAB file
%
% Application:
%   Hearing assistance / speech enhancement in noisy environments
%
% DSP CONCEPTS:
%   Pre-processing
%   Framing
%   Hamming window
%   FFT / STFT
%   Automatic noise estimation
%   Spectral subtraction
%   Wiener filtering
%   Hard spectral masking
%   Noise gating
%   IFFT
%   Overlap-add
%   Butterworth filtering
%   Spectrogram analysis
%
% IMPORTANT:
% 100% suppression activates HARD SUPPRESSION MODE.
%
% Requirements:
%   MATLAB
%   Signal Processing Toolbox
% ==============================================================

%% ==============================================================
% APP DATA
% ==============================================================

app = struct();

app.original = [];
app.enhanced = [];
app.removedNoise = [];

app.fs = 16000;
app.fileName = '';

app.loaded = false;
app.processed = false;

app.suppression = 1.0;
app.speechPreservation = 0.82;

app.noiseDuration = 0.60;

app.frameLength = 512;
app.hop = 256;

app.noiseSpectrum = [];
app.gainMatrix = [];
app.frameEnergy = [];
app.frameGate = [];
app.frequency = [];

%% ==============================================================
% MAIN WINDOW
% ==============================================================

% The DSP algorithm is unchanged. Only UI spacing and graph-rendering/refresh logic below
% only give the UI more room so sliders, labels, tabs and plots do not
% overlap.
app.fig = uifigure( ...
    'Name','Speech Enhancement using Digital Signal Processing', ...
    'Position',[20 20 1500 900], ...
    'Color',[0.93 0.94 0.96]);

app.fig.CloseRequestFcn = @closeApplication;

%% ==============================================================
% HEADER
% ==============================================================

header = uipanel(app.fig, ...
    'Position',[0 840 1500 60], ...
    'BackgroundColor',[0.16 0.28 0.43], ...
    'BorderType','none');

uilabel(header, ...
    'Position',[25 28 900 25], ...
    'Text','Speech Enhancement using Digital Signal Processing', ...
    'FontSize',20, ...
    'FontWeight','bold', ...
    'FontColor',[1 1 1]);

uilabel(header, ...
    'Position',[27 7 800 18], ...
    'Text','Frequency-domain noise reduction for hearing assistance', ...
    'FontSize',10, ...
    'FontColor',[0.88 0.92 0.97]);

app.status = uilabel(header, ...
    'Position',[1110 20 350 25], ...
    'Text','READY', ...
    'HorizontalAlignment','right', ...
    'FontSize',12, ...
    'FontWeight','bold', ...
    'FontColor',[0.85 0.95 1]);

%% ==============================================================
% LEFT CONTROL PANEL
% ==============================================================

control = uipanel(app.fig, ...
    'Position',[15 35 320 790], ...
    'Title','CONTROLS', ...
    'FontSize',12, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.98 0.98 0.99], ...
    'ForegroundColor',[0.15 0.20 0.27]);

%% Upload

app.upload = uibutton(control,'push', ...
    'Position',[25 700 270 45], ...
    'Text','Upload Audio', ...
    'FontSize',13, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.20 0.42 0.68], ...
    'FontColor',[1 1 1]);

app.upload.ButtonPushedFcn = @uploadAudio;

%% File

uilabel(control, ...
    'Position',[25 665 270 20], ...
    'Text','Selected file', ...
    'FontSize',10, ...
    'FontWeight','bold', ...
    'FontColor',[0.25 0.40 0.60]);

app.fileLabel = uilabel(control, ...
    'Position',[25 625 270 38], ...
    'Text','No file selected', ...
    'FontSize',10, ...
    'FontColor',[0.25 0.28 0.32], ...
    'WordWrap','on');

app.audioInfo = uilabel(control, ...
    'Position',[25 555 270 60], ...
    'Text',sprintf(['Sampling rate: --\n' ...
                    'Duration: --\n' ...
                    'Channels: --']), ...
    'FontSize',10, ...
    'FontColor',[0.35 0.38 0.43]);

%% Playback

app.playOriginal = uibutton(control,'push', ...
    'Position',[25 505 128 38], ...
    'Text','Play Original', ...
    'FontSize',10);

app.playOriginal.ButtonPushedFcn = @playOriginalAudio;

app.playEnhanced = uibutton(control,'push', ...
    'Position',[167 505 128 38], ...
    'Text','Play Enhanced', ...
    'FontSize',10);

app.playEnhanced.ButtonPushedFcn = @playEnhancedAudio;

app.stop = uibutton(control,'push', ...
    'Position',[25 458 270 32], ...
    'Text','Stop Audio', ...
    'FontSize',10);

app.stop.ButtonPushedFcn = @stopAudio;

%% Noise duration

uilabel(control, ...
    'Position',[25 390 240 20], ...
    'Text','Noise estimation duration', ...
    'FontSize',10, ...
    'FontWeight','bold');

app.noiseSlider = uislider(control, ...
    'Position',[35 350 230 3], ...
    'Limits',[0.2 1.5], ...
    'Value',0.6);

app.noiseSlider.ValueChangedFcn = @noiseDurationChanged;

app.noiseValue = uilabel(control, ...
    'Position',[270 365 35 20], ...
    'Text','0.60 s', ...
    'FontSize',9);

uilabel(control, ...
    'Position',[25 310 270 30], ...
    'Text','The quietest frames are selected automatically.', ...
    'FontSize',8, ...
    'FontColor',[0.45 0.48 0.52], ...
    'WordWrap','on');

%% Suppression

uilabel(control, ...
    'Position',[25 275 240 20], ...
    'Text','Noise suppression', ...
    'FontSize',10, ...
    'FontWeight','bold');

app.suppressionSlider = uislider(control, ...
    'Position',[35 235 230 3], ...
    'Limits',[0 1], ...
    'Value',1);

app.suppressionSlider.ValueChangedFcn = @suppressionChanged;

app.suppressionValue = uilabel(control, ...
    'Position',[270 250 35 20], ...
    'Text','100%', ...
    'FontSize',9, ...
    'FontWeight','bold');

%% Speech preservation

uilabel(control, ...
    'Position',[25 175 240 20], ...
    'Text','Speech preservation', ...
    'FontSize',10, ...
    'FontWeight','bold');

app.speechSlider = uislider(control, ...
    'Position',[35 135 230 3], ...
    'Limits',[0.5 0.95], ...
    'Value',0.82);

app.speechSlider.ValueChangedFcn = @speechChanged;

app.speechValue = uilabel(control, ...
    'Position',[270 150 35 20], ...
    'Text','82%', ...
    'FontSize',9);

%% Enhancement button

app.enhance = uibutton(control,'push', ...
    'Position',[25 85 270 45], ...
    'Text','Enhance Speech', ...
    'FontSize',13, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.25 0.55 0.35], ...
    'FontColor',[1 1 1]);

app.enhance.ButtonPushedFcn = @enhanceAudio;

%% Save

app.save = uibutton(control,'push', ...
    'Position',[25 35 128 35], ...
    'Text','Save Enhanced', ...
    'FontSize',10);

app.save.ButtonPushedFcn = @saveAudio;

app.saveAnalysis = uibutton(control,'push', ...
    'Position',[167 35 128 35], ...
    'Text','Save Analysis', ...
    'FontSize',10);

app.saveAnalysis.ButtonPushedFcn = @saveAnalysis;

%% Mode information

app.modeLabel = uilabel(control, ...
    'Position',[25 5 270 25], ...
    'Text','Mode: Hard suppression at 100%', ...
    'FontSize',9, ...
    'FontWeight','bold', ...
    'FontColor',[0.20 0.45 0.30], ...
    'WordWrap','on');

%% ==============================================================
% MAIN TABS
% ==============================================================

main = uipanel(app.fig, ...
    'Position',[350 35 1135 790], ...
    'BackgroundColor',[0.94 0.95 0.97], ...
    'BorderType','none');

app.tabs = uitabgroup(main, ...
    'Position',[5 5 1125 780]);

% Refresh plots when a tab is opened. This is display-only; it does not
% modify any DSP processing or parameters.
app.tabs.SelectionChangedFcn = @tabChanged;

%% ==============================================================
% HOME TAB
% ==============================================================

home = uitab(app.tabs,'Title',' HOME ');

uilabel(home, ...
    'Position',[30 725 1050 30], ...
    'Text','Speech Enhancement Result', ...
    'FontSize',18, ...
    'FontWeight','bold', ...
    'FontColor',[0.15 0.20 0.27]);

uilabel(home, ...
    'Position',[30 700 1050 20], ...
    'Text','Listen to the original and enhanced signals, then inspect how much noise was removed.', ...
    'FontSize',10, ...
    'FontColor',[0.40 0.43 0.48]);

%% Original

app.homeOriginal = makeAxes(home,[30 405 520 270], ...
    '1. Original Noisy Speech','Time (s)','Amplitude');

%% Enhanced

app.homeEnhanced = makeAxes(home,[575 405 520 270], ...
    '2. Enhanced Speech','Time (s)','Amplitude');

%% Removed

app.homeRemoved = makeAxes(home,[30 90 520 270], ...
    '3. Component Removed by DSP','Time (s)','Amplitude');

%% Explanation

explanation = uipanel(home, ...
    'Position',[575 90 520 270], ...
    'BackgroundColor',[0.98 0.98 0.99]);

uilabel(explanation, ...
    'Position',[20 205 470 25], ...
    'Text','How to read these graphs', ...
    'FontSize',13, ...
    'FontWeight','bold', ...
    'FontColor',[0.20 0.35 0.52]);

uilabel(explanation, ...
    'Position',[20 45 470 145], ...
    'Text',sprintf([ ...
    'ORIGINAL: speech + background noise\n\n' ...
    'ENHANCED: speech after DSP processing\n\n' ...
    'REMOVED: approximate part removed by the algorithm\n\n' ...
    'At 100%% suppression, the third graph should contain mainly the noise that was removed.']), ...
    'FontSize',10, ...
    'FontColor',[0.25 0.28 0.33], ...
    'VerticalAlignment','top', ...
    'WordWrap','on');

%% ==============================================================
% ANALYSIS TAB
% ==============================================================

analysis = uitab(app.tabs,'Title',' ANALYSIS ');

uilabel(analysis, ...
    'Position',[30 725 1050 30], ...
    'Text','Time and Frequency Domain Analysis', ...
    'FontSize',18, ...
    'FontWeight','bold');

app.originalFFT = makeAxes(analysis,[30 410 520 270], ...
    'Original FFT: Noise + Speech','Frequency (Hz)','Magnitude (dB)');

app.enhancedFFT = makeAxes(analysis,[575 410 520 270], ...
    'Enhanced FFT: Reduced Noise','Frequency (Hz)','Magnitude (dB)');

app.originalSpec = makeAxes(analysis,[30 75 520 285], ...
    'Original Spectrogram','Time (s)','Frequency (Hz)');

app.enhancedSpec = makeAxes(analysis,[575 75 520 285], ...
    'Enhanced Spectrogram','Time (s)','Frequency (Hz)');

%% ==============================================================
% DSP DEMONSTRATION TAB
% ==============================================================

demo = uitab(app.tabs,'Title',' DSP DEMONSTRATION ');

uilabel(demo, ...
    'Position',[30 725 1050 30], ...
    'Text','What is the DSP Algorithm Actually Doing?', ...
    'FontSize',18, ...
    'FontWeight','bold');

%% Noise spectrum

app.noisePlot = makeAxes(demo,[30 420 520 250], ...
    'Step 1 - Estimated Background Noise','Frequency (Hz)','Noise power (dB)');

uilabel(demo, ...
    'Position',[35 375 510 30], ...
    'Text','This is the frequency pattern of the background noise estimated from quiet frames.', ...
    'FontSize',9, ...
    'FontColor',[0.35 0.38 0.43], ...
    'WordWrap','on');

%% Mask

app.maskPlot = makeAxes(demo,[575 420 520 250], ...
    'Step 2 - Suppression Mask','Frequency (Hz)','Gain');

uilabel(demo, ...
    'Position',[580 375 510 30], ...
    'Text','1 = frequency kept, 0 = frequency removed. At 100%, noise-dominated bins are forced toward zero.', ...
    'FontSize',9, ...
    'FontColor',[0.35 0.38 0.43], ...
    'WordWrap','on');

%% Spectrum

app.frameBeforeAfter = makeAxes(demo,[30 80 520 250], ...
    'Step 3 - One Speech Frame: Before / After','Frequency (Hz)','Magnitude (dB)');

uilabel(demo, ...
    'Position',[35 40 510 30], ...
    'Text','Notice how frequency components estimated as noise become much smaller after filtering.', ...
    'FontSize',9, ...
    'FontColor',[0.35 0.38 0.43], ...
    'WordWrap','on');

%% Gate

app.gatePlot = makeAxes(demo,[575 80 520 250], ...
    'Step 4 - Speech / Noise Frame Gate','Time (s)','Relative level');

uilabel(demo, ...
    'Position',[580 40 510 30], ...
    'Text','Quiet/noise-only regions are reduced while stronger speech regions are retained.', ...
    'FontSize',9, ...
    'FontColor',[0.35 0.38 0.43], ...
    'WordWrap','on');

%% ==============================================================
% PROCESS TAB
% ==============================================================

process = uitab(app.tabs,'Title',' DSP PROCESS ');

uilabel(process, ...
    'Position',[30 725 1050 30], ...
    'Text','DSP Processing Pipeline', ...
    'FontSize',18, ...
    'FontWeight','bold');

uilabel(process, ...
    'Position',[30 695 1050 20], ...
    'Text','The complete DSP sequence used by the existing algorithm. Scroll inside the box to view all steps.', ...
    'FontSize',10, ...
    'FontColor',[0.40 0.43 0.48]);

processPanel = uipanel(process, ...
    'Position',[30 35 1065 645], ...
    'BackgroundColor',[0.98 0.98 0.99]);

processText = sprintf([ ...
'STEP 1  |  INPUT AUDIO\n' ...
'The noisy speech recording is loaded into MATLAB.\n\n' ...

'STEP 2  |  PRE-PROCESSING\n' ...
'Stereo audio is converted to mono and resampled to 16 kHz.\n\n' ...

'STEP 3  |  FRAMING\n' ...
'The signal is divided into short overlapping frames of 512 samples.\n' ...
'This allows the system to analyze the signal locally.\n\n' ...

'STEP 4  |  HAMMING WINDOW\n' ...
'A Hamming window is applied to each frame to reduce spectral leakage.\n\n' ...

'STEP 5  |  FFT\n' ...
'Each frame is converted from time domain to frequency domain.\n\n' ...

'        X(k) = SUM [ x(n) w(n) exp(-j 2 pi k n / N) ]\n\n' ...

'STEP 6  |  NOISE ESTIMATION\n' ...
'Frame energies are calculated. The quietest frames are assumed to contain mainly background noise.\n\n' ...

'        N(k) = median( |X_noise(k)|^2 )\n\n' ...

'STEP 7  |  SPECTRAL SUBTRACTION\n' ...
'The estimated noise power is subtracted from the noisy spectrum.\n\n' ...

'        P_clean(k) = max(P_noisy(k) - alpha N(k), 0)\n\n' ...

'STEP 8  |  WIENER GAIN\n' ...
'A frequency-dependent gain determines how much of each component is retained.\n\n' ...

'        G(k) = P_clean(k) / [P_clean(k) + N(k)]\n\n' ...

'STEP 9  |  HARD NOISE MASK\n' ...
'At 100%% suppression, frequency bins dominated by noise are forced to zero.\n' ...
'No artificial minimum gain is added.\n\n' ...

'STEP 10 |  IFFT\n' ...
'The enhanced frequency-domain frame is converted back into the time domain.\n\n' ...

'        y(n) = IFFT{Y(k)}\n\n' ...

'STEP 11 |  OVERLAP-ADD\n' ...
'The enhanced frames are combined to reconstruct continuous speech.\n\n' ...

'STEP 12 |  FINAL SPEECH FILTER\n' ...
'A Butterworth band-pass filter keeps the main speech region and removes very low/high unwanted components.\n\n' ...

'FINAL OUTPUT\n' ...
'The resulting enhanced signal can be played or saved as a WAV file.' ...
]);

% A text area is used instead of one fixed uilabel so the complete
% process description remains readable and scrollable.
processTextArea = uitextarea(processPanel, ...
    'Position',[15 15 1035 615], ...
    'Value',strsplit(processText,newline), ...
    'Editable','off', ...
    'FontSize',11, ...
    'FontColor',[0.20 0.23 0.28], ...
    'BackgroundColor',[0.98 0.98 0.99]);

%% ==============================================================
% RESULT TAB
% ==============================================================

result = uitab(app.tabs,'Title',' RESULT ');

uilabel(result, ...
    'Position',[30 725 1050 30], ...
    'Text','Before / After Result', ...
    'FontSize',18, ...
    'FontWeight','bold');

app.resultComparison = makeAxes(result,[30 410 1065 270], ...
    'Original vs Enhanced Speech','Time (s)','Amplitude');

app.resultRemoved = makeAxes(result,[30 105 1065 250], ...
    'Noise / Signal Component Removed','Time (s)','Amplitude');

app.resultText = uilabel(result, ...
    'Position',[30 50 1065 35], ...
    'Text','No result yet. Upload audio and press Enhance Speech.', ...
    'FontSize',10, ...
    'FontWeight','bold', ...
    'FontColor',[0.20 0.40 0.60], ...
    'WordWrap','on');

%% ==============================================================
% START
% ==============================================================

updateStatus('READY');

%% ==============================================================
% UPLOAD FUNCTION
% ==============================================================

    function uploadAudio(~,~)

        [file,path] = uigetfile( ...
            {'*.wav;*.mp3;*.m4a;*.flac;*.ogg;*.aif;*.aiff', ...
             'Audio Files'; ...
             '*.*','All Files'}, ...
             'Select Noisy Speech');

        if isequal(file,0)
            return;
        end

        try

            updateStatus('LOADING...');

            [x,fs0] = audioread(fullfile(path,file));

            if size(x,2) > 1
                x = mean(x,2);
            end

            x = double(x(:));

            x = x - mean(x);

            if fs0 ~= 16000

                x = resample(x,16000,fs0);

            end

            app.fs = 16000;

            p = max(abs(x));

            if p > 0
                x = x/p;
            end

            app.original = x;

            app.fileName = file;

            app.loaded = true;
            app.processed = false;

            app.enhanced = [];
            app.removedNoise = [];

            app.fileLabel.Text = file;

            app.audioInfo.Text = sprintf( ...
                ['Sampling rate: %d Hz\n' ...
                 'Duration: %.2f s\n' ...
                 'Channels: Mono'], ...
                 app.fs,length(x)/app.fs);

            clearAllPlots();

            plotOriginal();

            % Return to HOME with the freshly rendered original waveform visible.
            app.tabs.SelectedTab = home;
            drawnow;

            updateStatus('AUDIO READY');

        catch ME

            updateStatus('ERROR');

            uialert(app.fig,ME.message, ...
                'Audio Loading Error','Icon','error');

        end

    end

%% ==============================================================
% ENHANCEMENT
% ==============================================================

    function enhanceAudio(~,~)

        if ~app.loaded

            uialert(app.fig, ...
                'Upload a noisy speech file first.', ...
                'Input Required');

            return;

        end

        try

            app.enhance.Enable = 'off';

            x = app.original;

            fs = app.fs;

            N = app.frameLength;

            H = app.hop;

            w = hamming(N,'periodic');

            originalLength = length(x);

            %% Padding

            if length(x) < N

                x = [x;zeros(N-length(x),1)];

            end

            numberOfFrames = ...
                ceil((length(x)-N)/H)+1;

            paddedLength = ...
                (numberOfFrames-1)*H+N;

            if length(x) < paddedLength

                x = [x; ...
                    zeros(paddedLength-length(x),1)];

            end

            %% =================================================
            % FRAMING
            % ==================================================

            updateStatus('1 / 8  FRAMING');

            frames = zeros(N,numberOfFrames);

            frameEnergy = zeros(numberOfFrames,1);

            for k = 1:numberOfFrames

                idx = ...
                    (k-1)*H+(1:N);

                frame = x(idx);

                frames(:,k) = frame.*w;

                frameEnergy(k) = ...
                    mean(frame.^2);

            end

            %% =================================================
            % FFT
            % ==================================================

            updateStatus('2 / 8  FFT ANALYSIS');

            X = fft(frames,N,1);

            Xpos = X(1:N/2+1,:);

            mag = abs(Xpos);

            power = mag.^2;

            phase = angle(Xpos);

            freq = ...
                (0:N/2)'*fs/N;

            %% =================================================
            % NOISE ESTIMATION
            % ==================================================

            updateStatus('3 / 8  ESTIMATING NOISE');

            desiredFrames = ...
                round(app.noiseDuration*fs/H);

            desiredFrames = ...
                max(3,desiredFrames);

            desiredFrames = ...
                min(desiredFrames,numberOfFrames);

            [~,order] = sort(frameEnergy,'ascend');

            noiseFrames = ...
                order(1:desiredFrames);

            noisePower = ...
                median(power(:,noiseFrames),2);

            noisePower = ...
                movmean(noisePower,7);

            noisePower = ...
                max(noisePower,1e-12);

            %% =================================================
            % NOISE REMOVAL
            % ==================================================

            updateStatus('4 / 8  REMOVING NOISE');

            strength = app.suppression;

            speechPreserve = ...
                app.speechPreservation;

            hardMode = strength >= 0.999;

            enhancedPos = zeros(size(Xpos));

            gainMatrix = zeros(size(Xpos));

            frameGate = zeros(numberOfFrames,1);

            %% Noise level

            noiseRMS = ...
                sqrt(mean(frameEnergy(noiseFrames)));

            noiseRMS = max(noiseRMS,1e-8);

            %% Process every frame

            for k = 1:numberOfFrames

                currentPower = power(:,k);

                %% Posterior SNR

                snrLinear = ...
                    currentPower ./ ...
                    (noisePower+eps);

                %% Spectral subtraction

                alpha = ...
                    1 + 4.5*strength;

                cleanPower = ...
                    currentPower - ...
                    alpha*noisePower;

                cleanPower = ...
                    max(cleanPower,0);

                %% Wiener gain

                wienerGain = ...
                    cleanPower ./ ...
                    (cleanPower + noisePower + eps);

                wienerGain = sqrt(wienerGain);

                %% Spectral subtraction gain

                subtractionGain = ...
                    sqrt(cleanPower ./ ...
                    (currentPower+eps));

                %% Combined gain

                gain = ...
                    0.55*wienerGain + ...
                    0.45*subtractionGain;

                %% Speech band

                speechBand = ...
                    freq >= 100 & freq <= 6500;

                %% Do not emphasize outside speech range

                gain(~speechBand) = ...
                    gain(~speechBand) * ...
                    (1-strength);

                %% HARD MODE
                %
                % At 100%, noise-dominated frequency bins
                % are explicitly removed.

                if hardMode

                    % SNR threshold.
                    %
                    % If signal power is not sufficiently larger
                    % than estimated noise power, remove it.

                    keep = ...
                        snrLinear > 2.2;

                    % Protect strong speech components.

                    keep(speechBand & ...
                         snrLinear > 1.6) = true;

                    gain(~keep) = 0;

                    % No gain floor.
                    gain = max(gain,0);

                    % Small frequency smoothing

                    smoothGain = ...
                        movmean(gain,5);

                    % Restore exact zeros to noise bins

                    smoothGain(~keep) = 0;

                    gain = smoothGain;

                else

                    %% Soft mode

                    gain = ...
                        strength*gain + ...
                        (1-strength);

                    %% Preserve speech

                    gain(speechBand) = ...
                        max(gain(speechBand), ...
                        speechPreserve);

                    gain = ...
                        movmean(gain,5);

                end

                %% Frame-level noise gate

                currentRMS = ...
                    sqrt(mean(frames(:,k).^2));

                frameSNR = ...
                    currentRMS/(noiseRMS+eps);

                if hardMode

                    if frameSNR < 1.45

                        frameGate(k) = 0;

                        gain(:) = 0;

                    else

                        frameGate(k) = 1;

                    end

                else

                    frameGate(k) = ...
                        min(1,max(0, ...
                        (frameSNR-0.8)/1.2));

                    gain = gain*frameGate(k);

                end

                %% Limit

                gain = max(gain,0);

                gain = min(gain,1);

                gainMatrix(:,k) = gain;

                %% Apply gain

                enhancedPos(:,k) = ...
                    mag(:,k).*gain.* ...
                    exp(1i*phase(:,k));

            end

            %% =================================================
            % MIRROR ONE-SIDED SPECTRUM
            % ==================================================

            updateStatus('5 / 8  RECONSTRUCTING SPECTRUM');

            enhancedFull = zeros(N,numberOfFrames);

            enhancedFull(1:N/2+1,:) = enhancedPos;

            enhancedFull(N/2+2:N,:) = ...
                conj(enhancedPos(N/2:-1:2,:));

            %% =================================================
            % IFFT
            % ==================================================

            enhancedFrames = ...
                real(ifft(enhancedFull,N,1));

            %% =================================================
            % OVERLAP ADD
            % ==================================================

            updateStatus('6 / 8  OVERLAP-ADD');

            y = zeros(paddedLength,1);

            windowSum = zeros(paddedLength,1);

            for k = 1:numberOfFrames

                idx = ...
                    (k-1)*H+(1:N);

                y(idx) = ...
                    y(idx)+ ...
                    enhancedFrames(:,k).*w;

                windowSum(idx) = ...
                    windowSum(idx)+w.^2;

            end

            valid = windowSum > 1e-8;

            y(valid) = ...
                y(valid)./windowSum(valid);

            y = y(1:originalLength);

            %% =================================================
            % FINAL SPEECH FILTER
            % ==================================================

            updateStatus('7 / 8  SPEECH FILTER');

            [b,a] = butter(6, ...
                [80 7000]/(fs/2), ...
                'bandpass');

            y = filtfilt(b,a,y);

            %% =================================================
            % VERY QUIET RESIDUAL NOISE REDUCTION
            % ==================================================

            if hardMode

                % Estimate residual noise from noise frames

                noiseSample = [];

                for q = 1:length(noiseFrames)

                    idx = ...
                        (noiseFrames(q)-1)*H+ ...
                        (1:N);

                    idx = idx(idx <= length(y));

                    noiseSample = ...
                        [noiseSample;y(idx)]; %#ok<AGROW>

                end

                if ~isempty(noiseSample)

                    residualRMS = ...
                        sqrt(mean(noiseSample.^2));

                    threshold = ...
                        max(0.002, ...
                        0.80*residualRMS);

                    % Only remove extremely small residual
                    % components. This avoids making speech
                    % sound clipped.

                    small = abs(y) < threshold;

                    y(small) = 0;

                end

            end

            %% =================================================
            % NORMALIZE
            % ==================================================

            y = y-mean(y);

            peak = max(abs(y));

            if peak > 0

                y = 0.95*y/peak;

            end

            %% =================================================
            % STORE
            % ==================================================

            app.enhanced = y;

            app.removedNoise = ...
                app.original - app.enhanced;

            app.noiseSpectrum = noisePower;

            app.gainMatrix = gainMatrix;

            app.frameEnergy = frameEnergy;

            app.frameGate = frameGate;

            app.frequency = freq;

            app.processed = true;

            %% =================================================
            % PLOTS
            % ==================================================

            updateStatus('8 / 8  GENERATING GRAPHS');

            % Refresh the original graphs after DSP processing as well.
            % This is display-only and does not alter the DSP algorithm.
            plotOriginal();

            plotEnhanced();

            plotDSP();

            plotResults();

            drawnow;

            %% =================================================
            % SAVE TEMP FILE
            % ==================================================

            audiowrite( ...
                fullfile(tempdir, ...
                'EnhancedSpeechOutput.wav'), ...
                app.enhanced, ...
                app.fs);

            %% =================================================
            % MESSAGE
            % ==================================================

            if hardMode

                app.modeLabel.Text = ...
                    'Mode: 100% HARD SUPPRESSION — noise-dominant bins removed';

                app.modeLabel.FontColor = ...
                    [0.15 0.45 0.25];

            else

                app.modeLabel.Text = ...
                    sprintf('Mode: %.0f%% suppression — soft spectral filtering', ...
                    strength*100);

            end

            updateStatus('COMPLETE');

            app.enhance.Enable = 'on';

            app.tabs.SelectedTab = home;

            uialert(app.fig, ...
                ['Enhancement completed.' newline newline ...
                 'Open the DSP DEMONSTRATION tab to see exactly what happened to the signal.' newline newline ...
                 'Open the RESULT tab to see the removed component.'], ...
                'Processing Complete','Icon','success');

        catch ME

            app.enhance.Enable = 'on';

            updateStatus('ERROR');

            uialert(app.fig, ...
                ME.message, ...
                'DSP Processing Error','Icon','error');

        end

    end

%% ==============================================================
% ORIGINAL PLOTS
% ==============================================================

    function plotOriginal()

        x = app.original;
        fs = app.fs;

        if isempty(x)
            return;
        end

        x = x(:);
        t = (0:length(x)-1)'/fs;

        drawnow;

        %% Original waveform

        cla(app.homeOriginal);
        plot(app.homeOriginal,t,x,'LineWidth',0.8);
        title(app.homeOriginal,'Original Noisy Speech');
        xlabel(app.homeOriginal,'Time (s)');
        ylabel(app.homeOriginal,'Amplitude');
        grid(app.homeOriginal,'on');

        % Force the axes to use the actual signal range rather than the
        % default 0-to-1 empty-axis range.
        xlim(app.homeOriginal,[0 max(t)]);
        peak = max(abs(x));
        if peak > 0
            ylim(app.homeOriginal,[-1.05*peak 1.05*peak]);
        end

        drawnow;

        %% Original FFT

        n = min(length(x),fs*8);
        segment = x(1:n);
        w = hamming(n);
        X = fft(segment.*w);

        half = floor(n/2);
        f = (0:half-1)*fs/n;

        mag = abs(X(1:half));
        mag = mag/(max(mag)+eps);
        db = 20*log10(mag+eps);

        cla(app.originalFFT);
        plot(app.originalFFT,f,db,'LineWidth',0.8);
        xlim(app.originalFFT,[0 8000]);
        title(app.originalFFT,'Original FFT: Noise + Speech');
        xlabel(app.originalFFT,'Frequency (Hz)');
        ylabel(app.originalFFT,'Magnitude (dB)');
        grid(app.originalFFT,'on');

        drawnow;

        %% Original Spectrogram

        cla(app.originalSpec);

        % Keep the original STFT settings. The only addition is a small
        % validity check so short recordings do not prevent the remaining
        % original graphs from being displayed.
        if length(x) >= 512

            [S,F,T] = spectrogram( ...
                x, ...
                hamming(512), ...
                384, ...
                1024, ...
                fs);

            imagesc(app.originalSpec, ...
                T,F,20*log10(abs(S)+1e-8));

            axis(app.originalSpec,'xy');
            xlim(app.originalSpec,[0 max(T)]);
            ylim(app.originalSpec,[0 8000]);

        else
            text(app.originalSpec,0.5,0.5, ...
                'Audio is shorter than the 512-sample analysis window.', ...
                'HorizontalAlignment','center');
        end

        title(app.originalSpec,'Original Spectrogram');
        xlabel(app.originalSpec,'Time (s)');
        ylabel(app.originalSpec,'Frequency (Hz)');
        grid(app.originalSpec,'on');

        drawnow;

    end

%% ==============================================================
% ENHANCED PLOTS
% ==============================================================

    function plotEnhanced()

        x = app.enhanced;
        fs = app.fs;

        if isempty(x)
            return;
        end

        x = x(:);
        t = (0:length(x)-1)'/fs;

        drawnow;

        %% Enhanced waveform

        cla(app.homeEnhanced);
        plot(app.homeEnhanced,t,x,'LineWidth',0.8);
        title(app.homeEnhanced,'Enhanced Speech');
        xlabel(app.homeEnhanced,'Time (s)');
        ylabel(app.homeEnhanced,'Amplitude');
        grid(app.homeEnhanced,'on');

        xlim(app.homeEnhanced,[0 max(t)]);
        peak = max(abs(x));
        if peak > 0
            ylim(app.homeEnhanced,[-1.05*peak 1.05*peak]);
        end

        drawnow;

        %% Removed noise

        cla(app.homeRemoved);
        plot(app.homeRemoved,t,app.removedNoise,'LineWidth',0.8);
        title(app.homeRemoved,'Approximate Component Removed by DSP');
        xlabel(app.homeRemoved,'Time (s)');
        ylabel(app.homeRemoved,'Amplitude');
        grid(app.homeRemoved,'on');

        xlim(app.homeRemoved,[0 max(t)]);
        removedPeak = max(abs(app.removedNoise));
        if removedPeak > 0
            ylim(app.homeRemoved, ...
                [-1.05*removedPeak 1.05*removedPeak]);
        end

        drawnow;

        %% Enhanced FFT

        n = min(length(x),fs*8);
        segment = x(1:n);
        w = hamming(n);
        X = fft(segment.*w);

        half = floor(n/2);
        f = (0:half-1)*fs/n;

        mag = abs(X(1:half));
        mag = mag/(max(mag)+eps);
        db = 20*log10(mag+eps);

        cla(app.enhancedFFT);
        plot(app.enhancedFFT,f,db,'LineWidth',0.8);
        xlim(app.enhancedFFT,[0 8000]);
        title(app.enhancedFFT,'Enhanced FFT: Reduced Noise');
        xlabel(app.enhancedFFT,'Frequency (Hz)');
        ylabel(app.enhancedFFT,'Magnitude (dB)');
        grid(app.enhancedFFT,'on');

        drawnow;

        %% Enhanced spectrogram

        cla(app.enhancedSpec);

        if length(x) >= 512

            [S,F,T] = spectrogram( ...
                x, ...
                hamming(512), ...
                384, ...
                1024, ...
                fs);

            imagesc(app.enhancedSpec, ...
                T,F,20*log10(abs(S)+1e-8));

            axis(app.enhancedSpec,'xy');
            xlim(app.enhancedSpec,[0 max(T)]);
            ylim(app.enhancedSpec,[0 8000]);

        else
            text(app.enhancedSpec,0.5,0.5, ...
                'Audio is shorter than the 512-sample analysis window.', ...
                'HorizontalAlignment','center');
        end

        title(app.enhancedSpec,'Enhanced Spectrogram');
        xlabel(app.enhancedSpec,'Time (s)');
        ylabel(app.enhancedSpec,'Frequency (Hz)');
        grid(app.enhancedSpec,'on');

        drawnow;

    end

%% ==============================================================
% DSP DEMONSTRATION PLOTS
% ==============================================================

    function plotDSP()

        f = app.frequency;

        half = 1:length(f);

        %% ------------------------------------------------------
        % Noise spectrum
        % -------------------------------------------------------

        cla(app.noisePlot);

        noiseDB = ...
            10*log10(app.noiseSpectrum+eps);

        noiseDB = ...
            noiseDB-max(noiseDB);

        plot(app.noisePlot, ...
            f,noiseDB, ...
            'LineWidth',1.2);

        xlim(app.noisePlot,[0 8000]);

        title(app.noisePlot, ...
            'Estimated Background Noise');

        xlabel(app.noisePlot,'Frequency (Hz)');
        ylabel(app.noisePlot,'Relative power (dB)');

        grid(app.noisePlot,'on');

        %% ------------------------------------------------------
        % Gain
        % -------------------------------------------------------

        [~,strongest] = ...
            max(app.frameEnergy);

        gain = ...
            app.gainMatrix(:,strongest);

        cla(app.maskPlot);

        plot(app.maskPlot, ...
            f,gain, ...
            'LineWidth',1.2);

        xlim(app.maskPlot,[0 8000]);

        ylim(app.maskPlot,[-0.05 1.05]);

        title(app.maskPlot, ...
            'Suppression Mask');

        xlabel(app.maskPlot,'Frequency (Hz)');
        ylabel(app.maskPlot,'Gain');

        grid(app.maskPlot,'on');

        %% ------------------------------------------------------
        % One frame before / after
        % -------------------------------------------------------

        originalFrame = ...
            abs(fft( ...
            app.original( ...
            1:min(app.frameLength,length(app.original))) .* ...
            hamming(min(app.frameLength,length(app.original)))));

        if length(originalFrame) < app.frameLength

            originalFrame = ...
                [originalFrame; ...
                 zeros(app.frameLength-length(originalFrame),1)];

        end

        originalFrame = ...
            originalFrame(1:length(f));

        enhancedFrame = ...
            abs(fft( ...
            app.enhanced( ...
            1:min(app.frameLength,length(app.enhanced))) .* ...
            hamming(min(app.frameLength,length(app.enhanced)))));

        if length(enhancedFrame) < app.frameLength

            enhancedFrame = ...
                [enhancedFrame; ...
                 zeros(app.frameLength-length(enhancedFrame),1)];

        end

        enhancedFrame = ...
            enhancedFrame(1:length(f));

        db1 = ...
            20*log10(originalFrame/(max(originalFrame)+eps)+eps);

        db2 = ...
            20*log10(enhancedFrame/(max(enhancedFrame)+eps)+eps);

        cla(app.frameBeforeAfter);

        plot(app.frameBeforeAfter, ...
            f,db1,'LineWidth',1);

        hold(app.frameBeforeAfter,'on');

        plot(app.frameBeforeAfter, ...
            f,db2,'LineWidth',1);

        hold(app.frameBeforeAfter,'off');

        xlim(app.frameBeforeAfter,[0 8000]);

        legend(app.frameBeforeAfter, ...
            {'Before','After'});

        title(app.frameBeforeAfter, ...
            'One Speech Frame');

        xlabel(app.frameBeforeAfter,'Frequency (Hz)');
        ylabel(app.frameBeforeAfter,'Magnitude (dB)');

        grid(app.frameBeforeAfter,'on');

        %% ------------------------------------------------------
        % Frame gate
        % -------------------------------------------------------

        time = ...
            ((0:length(app.frameEnergy)-1)* ...
            app.hop + app.frameLength/2)/app.fs;

        energy = ...
            10*log10(app.frameEnergy+eps);

        energy = ...
            energy-max(energy);

        gate = ...
            app.frameGate;

        gateDB = ...
            20*log10(gate+eps);

        cla(app.gatePlot);

        plot(app.gatePlot, ...
            time,energy, ...
            'LineWidth',1);

        hold(app.gatePlot,'on');

        plot(app.gatePlot, ...
            time,gateDB, ...
            'LineWidth',1);

        hold(app.gatePlot,'off');

        legend(app.gatePlot, ...
            {'Frame energy','Gate'});

        title(app.gatePlot, ...
            'Speech / Noise Frame Decision');

        xlabel(app.gatePlot,'Time (s)');
        ylabel(app.gatePlot,'Relative level');

        grid(app.gatePlot,'on');

        drawnow;

    end

%% ==============================================================
% RESULT PLOTS
% ==============================================================

    function plotResults()

        x = app.original;

        y = app.enhanced;

        r = app.removedNoise;

        fs = app.fs;

        L = min([length(x),length(y),length(r)]);

        x = x(1:L);
        y = y(1:L);
        r = r(1:L);

        t = (0:L-1)/fs;

        %% Comparison

        cla(app.resultComparison);

        plot(app.resultComparison,t,x, ...
            'LineWidth',0.8);

        hold(app.resultComparison,'on');

        plot(app.resultComparison,t,y, ...
            'LineWidth',1.0);

        hold(app.resultComparison,'off');

        legend(app.resultComparison, ...
            {'Original','Enhanced'}, ...
            'Location','northeast');

        title(app.resultComparison, ...
            'Original vs Enhanced Speech');

        xlabel(app.resultComparison,'Time (s)');
        ylabel(app.resultComparison,'Amplitude');

        grid(app.resultComparison,'on');

        %% Removed

        cla(app.resultRemoved);

        plot(app.resultRemoved,t,r);

        title(app.resultRemoved, ...
            'Approximate Noise / Signal Component Removed');

        xlabel(app.resultRemoved,'Time (s)');
        ylabel(app.resultRemoved,'Amplitude');

        grid(app.resultRemoved,'on');

        %% Metrics

        noiseLevel = ...
            rmsFromQuietFrames(x, ...
            app.frameEnergy, ...
            app.hop, ...
            app.frameLength);

        noiseAfter = ...
            rmsFromQuietFrames(y, ...
            app.frameEnergy, ...
            app.hop, ...
            app.frameLength);

        reduction = ...
            20*log10( ...
            max(noiseLevel,eps)/ ...
            max(noiseAfter,eps));

        app.resultText.Text = sprintf( ...
            'Estimated residual-noise reduction: %.2f dB    |    Suppression setting: %.0f%%    |    100%% activates hard spectral masking.', ...
            reduction,app.suppression*100);

    end

%% ==============================================================
% QUIET FRAME RMS
% ==============================================================

    function value = rmsFromQuietFrames(signal,energy,hop,N)

        if isempty(signal)

            value = 0;

            return;

        end

        [~,idx] = sort(energy,'ascend');

        count = max(3, ...
            round(0.10*length(idx)));

        count = min(count,length(idx));

        values = [];

        for q = 1:count

            k = idx(q);

            startIndex = ...
                (k-1)*hop+1;

            endIndex = ...
                min(startIndex+N-1,length(signal));

            if startIndex <= length(signal)

                segment = ...
                    signal(startIndex:endIndex);

                values = ...
                    [values;segment]; %#ok<AGROW>

            end

        end

        if isempty(values)

            value = sqrt(mean(signal.^2));

        else

            value = sqrt(mean(values.^2));

        end

    end

%% ==============================================================
% PLAYBACK
% ==============================================================

    function playOriginalAudio(~,~)

        if ~app.loaded

            uialert(app.fig, ...
                'Upload audio first.', ...
                'Input Required');

            return;

        end

        sound(app.original,app.fs);

        updateStatus('PLAYING ORIGINAL');

    end

    function playEnhancedAudio(~,~)

        if ~app.processed

            uialert(app.fig, ...
                'Enhance the audio first.', ...
                'No Enhanced Audio');

            return;

        end

        sound(app.enhanced,app.fs);

        updateStatus('PLAYING ENHANCED');

    end

    function stopAudio(~,~)

        clear sound;

        updateStatus('READY');

    end

%% ==============================================================
% SLIDERS
% ==============================================================

    function noiseDurationChanged(src,~)

        app.noiseDuration = src.Value;

        app.noiseValue.Text = ...
            sprintf('%.2f s',src.Value);

    end

    function suppressionChanged(src,~)

        app.suppression = src.Value;

        app.suppressionValue.Text = ...
            sprintf('%.0f%%',src.Value*100);

        if src.Value >= 0.999

            app.modeLabel.Text = ...
                'Mode: 100% HARD SUPPRESSION — noise-dominant bins removed';

            app.modeLabel.FontColor = ...
                [0.15 0.45 0.25];

        else

            app.modeLabel.Text = ...
                sprintf('Mode: %.0f%% suppression — soft spectral filtering', ...
                src.Value*100);

            app.modeLabel.FontColor = ...
                [0.20 0.35 0.55];

        end

    end

    function speechChanged(src,~)

        app.speechPreservation = src.Value;

        app.speechValue.Text = ...
            sprintf('%.0f%%',src.Value*100);

    end

%% ==============================================================
% SAVE AUDIO
% ==============================================================

    function saveAudio(~,~)

        if ~app.processed

            uialert(app.fig, ...
                'Enhance the speech first.', ...
                'No Output');

            return;

        end

        [file,path] = uiputfile( ...
            '*.wav', ...
            'Save Enhanced Speech', ...
            'Enhanced_Speech.wav');

        if isequal(file,0)

            return;

        end

        audiowrite( ...
            fullfile(path,file), ...
            app.enhanced, ...
            app.fs);

        uialert(app.fig, ...
            'Enhanced WAV file saved successfully.', ...
            'Saved','Icon','success');

        updateStatus('AUDIO SAVED');

    end

%% ==============================================================
% SAVE ANALYSIS SCREEN
% ==============================================================

    function saveAnalysis(~,~)

        if ~app.processed

            uialert(app.fig, ...
                'Process the audio first.', ...
                'No Analysis');

            return;

        end

        [file,path] = uiputfile( ...
            '*.png', ...
            'Save Current Analysis');

        if isequal(file,0)

            return;

        end

        exportgraphics( ...
            app.fig, ...
            fullfile(path,file), ...
            'Resolution',150);

        uialert(app.fig, ...
            'Current MATLAB analysis screen saved as an image.', ...
            'Analysis Saved','Icon','success');

    end

%% ==============================================================
% CLEAR
% ==============================================================

    function clearAllPlots()

        cla(app.homeOriginal);
        cla(app.homeEnhanced);
        cla(app.homeRemoved);

        cla(app.originalFFT);
        cla(app.enhancedFFT);

        cla(app.originalSpec);
        cla(app.enhancedSpec);

        cla(app.noisePlot);
        cla(app.maskPlot);
        cla(app.frameBeforeAfter);
        cla(app.gatePlot);

        cla(app.resultComparison);
        cla(app.resultRemoved);

        app.resultText.Text = ...
            'No result yet. Upload audio and press Enhance Speech.';

    end

%% ==============================================================
% AXES CREATOR
% ==============================================================

    function ax = makeAxes(parent,position,titleText,xText,yText)

        ax = uiaxes(parent, ...
            'Position',position, ...
            'Color',[1 1 1], ...
            'XColor',[0.25 0.28 0.32], ...
            'YColor',[0.25 0.28 0.32], ...
            'FontSize',9);

        title(ax,titleText, ...
            'FontWeight','bold');

        xlabel(ax,xText);
        ylabel(ax,yText);

        grid(ax,'on');

        ax.GridAlpha = 0.20;

    end

%% ==============================================================
% TAB DISPLAY REFRESH
% ==============================================================

    function tabChanged(~,event)

        if isempty(app.original)
            return;
        end

        try

            selectedTab = event.NewValue;

            if isequal(selectedTab,home)

                if app.processed
                    plotEnhanced();
                else
                    plotOriginal();
                end

            elseif isequal(selectedTab,analysis)

                plotOriginal();

            elseif isequal(selectedTab,demo)

                if app.processed
                    plotDSP();
                end

            elseif isequal(selectedTab,result)

                if app.processed
                    plotResults();
                end

            end

            drawnow;

        catch ME

            updateStatus('GRAPH DISPLAY ERROR');

            uialert(app.fig,ME.message, ...
                'Graph Display Error','Icon','error');

        end

    end

%% ==============================================================
% STATUS
% ==============================================================

    function updateStatus(txt)

        app.status.Text = txt;

        drawnow;

    end

%% ==============================================================
% CLOSE
% ==============================================================

    function closeApplication(~,~)

        clear sound;

        if isvalid(app.fig)

            delete(app.fig);

        end

    end

end