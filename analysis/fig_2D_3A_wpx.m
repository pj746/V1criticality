%     Originally created by Arthur-Ervin Avramiea (2020), arthur.avramiea@gmail.com

%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

addpath('support_functions_matlab');

data_path = 'C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\codes\data\optimiz_stim';
figures_path = 'C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\report\figures';
model_analysis_code_path = 'C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\codes\Arthur 2020 code\model code\data_analysis';

addpath(genpath(model_analysis_code_path));

noncrit_run_number	= 0;

crit_run_number = 1;

stimulus_size_to_analyze = 10;

non_cri_simulation_name = '2022-07-13_c_ee6_c_ei22_stim_size';
cri_simulation_name = '2022-07-05_c_ee11.57199543729056_stim_size';
%plot plf for critical networks at different stimulus sizes
[amplitude_bins_plf_noncrit,reg_amp_noncrit,phase_bins_plf_noncrit,phase_reg_noncrit] = get_prestim_regulation(data_path,...
    [non_cri_simulation_name,num2str(stimulus_size_to_analyze),'_stim_results.csv'],[non_cri_simulation_name,num2str(stimulus_size_to_analyze),'_tempo.csv']);
% [amplitude_bins_plf_crit,reg_amp_crit,phase_bins_plf_crit,phase_reg_crit] = get_prestim_regulation(fullfile(data_path,'runs',...
%     'without individual spikes',sprintf('EC%.2f.IC%.2f.Stim%i.Run%i',crit_exc_conn,crit_inh_conn,stimulus_size_to_analyze,crit_run_number)));
[amplitude_bins_plf_crit,reg_amp_crit,phase_bins_plf_crit,phase_reg_crit] = get_prestim_regulation(data_path,...
    [cri_simulation_name,num2str(stimulus_size_to_analyze),'_stim_results.csv'],[cri_simulation_name,num2str(stimulus_size_to_analyze),'_tempo.csv']);

color_blue = [0 0.5 1];
color_green = [0.22 1 0.22];
% color_red = [1 0.22 0.22];

%plot prestimulus amplitude regulation
fig = figure('color','w');
set(fig,'Position',[0 0 600 500]);
x_percentiles = 10:10:100;
plot(x_percentiles,amplitude_bins_plf_noncrit,'.','MarkerSize',15,'Color',color_blue);
h1=lsline;set(h1(1),'color',color_blue,'LineWidth',2);
hold on;
plot(x_percentiles,amplitude_bins_plf_crit,'.','MarkerSize',15,'Color',color_green);
h2=lsline;set(h2(1),'color',color_green,'LineWidth',2);
% plot(x_percentiles,amplitude_bins_plf_crit,'.','MarkerSize',15,'Color',color_red);
% h3=lsline;set(h3(1),'color',color_red,'LineWidth',2);
legend([h1(1) h2(1)],{num2str(round(reg_amp_noncrit,2)),num2str(round(reg_amp_crit,2)),num2str(round(reg_amp_crit,2))});
xticks(10:10:100);
ylim([0 0.5]);
yticks([0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]);
yticklabels({'0','','0.1','','0.2','','0.3','','0.4','','0.5'});
xticklabels({'','','','','50','','','','','100'});
set(gca,'fontsize', 16);
xlabel({'Pre-stimulus Amplitude';'(percentile)'});
ylabel('PLF');
saveas(fig,fullfile(figures_path,['fig_',num2str(stimulus_size_to_analyze),'_2D.fig']),'fig');

%plot prestimulus phase regulation
fig = figure('color','w');
set(fig,'Position',[0 0 600 500]);
x_phases = -pi:pi/16:pi;
plot(x_phases,phase_bins_plf_noncrit,'.-','MarkerSize',15,'Color',color_blue,'Linewidth',2);
hold on;
plot(x_phases,phase_bins_plf_crit,'.-','MarkerSize',15,'Color',color_green,'Linewidth',2);
% plot(x_phases,phase_bins_plf_crit,'.-','MarkerSize',15,'Color',color_red,'Linewidth',2);
legend({num2str(round(phase_reg_noncrit,2)),num2str(round(phase_reg_crit,2)),num2str(round(phase_reg_crit,2))});
xticks(-pi:pi/16:pi);
ylim([0 0.6]);
yticks([0 0.1 0.2 0.3 0.4 0.5 0.6]);
yticklabels({'0','','0.2','','0.4','','0.6'});
xticks([-pi -pi/2 0 pi/2 pi]);
xticklabels({'-\pi','','0','','\pi'});
set(gca,'fontsize', 16);
xlabel({'Pre-stimulus phase'});
ylabel('PLF');
saveas(fig,fullfile(figures_path,['fig_',num2str(stimulus_size_to_analyze),'_3A.fig']),'fig');

function [amplitude_bins_plf,reg_amp,phase_bins_plf,phase_reg] = get_prestim_regulation(folder_path, simu_file_name, stimu_file_name)

    [time_series,stimulus_timeseries] = get_timeseries(folder_path, simu_file_name, stimu_file_name);
%     time_series_noise = add_white_noise(time_series,3);
    time_series_noise = time_series;

    delta_lp = 4;
    delta_hp = 0.5;

    pre_stim_ms =  750;
    post_stim_ms = 750;
    poststim_point = 250;
    index_poststim_point = pre_stim_ms+poststim_point+1;%+1 to skip the stimulation time
    
    Fs=1000;

    %check that I have enough time before and after the
    %stimulus in the timeseries to cover the
    %prestim/poststim analysis
    stimulus_timeseries = stimulus_timeseries(stimulus_timeseries>=pre_stim_ms & stimulus_timeseries<=length(time_series_noise)-post_stim_ms);

    no_stims = length(stimulus_timeseries);

    %% Filter signal and extract phase and amplitude
    filtered = filter_fir(time_series_noise,delta_hp,delta_lp,Fs,2/delta_hp);

    filtered = filtered - mean(filtered);
    signal_phase = angle(hilbert(filtered));
    signal_amplitude = abs(hilbert(filtered));

    %% Split phase and amplitudes timeseries by trial
    phase_per_trial = zeros(pre_stim_ms+post_stim_ms+1, no_stims);
    amplitude_per_trial  = zeros(pre_stim_ms+post_stim_ms+1, no_stims);

    for stim_idx = 1:no_stims
        stimulation_time = floor(stimulus_timeseries(stim_idx));
        phase_per_trial(:,stim_idx)  = signal_phase(stimulation_time-pre_stim_ms:(stimulation_time + post_stim_ms))';
        amplitude_per_trial(:,stim_idx)  = signal_amplitude(stimulation_time-pre_stim_ms:(stimulation_time + post_stim_ms))';
    end

    %% Compute pre-stimulus amplitude regulation
    prestimulus_amplitude_interval = [-150,-50];

    %calculate, for all trials, the amplitude in the
    %prestimulus interval
    amplitude_prestim = zeros(size(stimulus_timeseries));
    for stim_idx=1:length(stimulus_timeseries)
        amplitude_prestim(stim_idx)=mean(signal_amplitude(stimulus_timeseries(stim_idx)+prestimulus_amplitude_interval(1):stimulus_timeseries(stim_idx)+prestimulus_amplitude_interval(2)));
    end

    %sort by prestimulus amplitude
    [~,stim_index] = sort(amplitude_prestim);

    %split into 10 percentiles, by prestimulus amplitude
    amplitude_bins_plf = zeros(10,1);                
    percentile_length = length(stim_index)/10;
    percentile_start_indexes = round(percentile_length * (0:9))+1;
    percentile_end_indexes = [percentile_start_indexes(2:10)-1 length(stim_index)];

    %compute prestimulus regulation at 150 ms poststimulus
    %compute plf for trials in each bin
    for percentile_idx=1:10
        amplitude_bins_plf(percentile_idx)=circ_r(phase_per_trial(index_poststim_point,stim_index(percentile_start_indexes(percentile_idx):percentile_end_indexes(percentile_idx)))');
    end
    reg_amp = corr((1:10)',amplitude_bins_plf,'Type','Spearman');

    %% Compute prestimulus phase dependence for all timepoints around stimulus

    %make phase bins spaced at pi/16
    phases_sort_time = -5;
    index_sort_time = pre_stim_ms+phases_sort_time;
    bins_phases = -pi:pi/16:pi;
    % each bin is assigned trials wih prestimulus phases within
    % a binwidth, centered on the bin
    bin_width = pi/4;
    for bin_idx = 1:length(bins_phases)
        orig = abs(circ_dist(phase_per_trial(index_sort_time,:),bins_phases(bin_idx)));
        pcks = orig < bin_width/2;
        noPcks(bin_idx) = nnz(pcks);
    end
    minPcks = min(noPcks);

    phase_bins_plf = zeros(length(bins_phases),1);
    for bin_idx = 1:length(bins_phases)
        orig = abs(circ_dist(phase_per_trial(index_sort_time,:),bins_phases(bin_idx)));
        pcks = orig < bin_width/2;
        pcks = find(pcks);
        pcks = pcks(1:minPcks);
        phase_bins_plf(bin_idx) = circ_r(phase_per_trial(index_poststim_point,pcks)');
    end

    phase_reg = circ_r(bins_phases',phase_bins_plf);
end