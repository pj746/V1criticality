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

data_path = 'C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\codes\data';
figures_path = 'C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\report\figures';
model_analysis_code_path = 'C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\codes\Arthur 2020 code\model code\data_analysis';

addpath(genpath(model_analysis_code_path));

x = load('C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\codes\data\optimiz_stim\20220713_cri_noncri_overall_plf.mat');
table_params_all = x.T;
fig = plot_dynamicrange_2_nets(table_params_all);
saveas(fig,fullfile(figures_path,'fig_1D.fig'),'fig');

% original_input_weight = 0.0085;
% table_params_all = load_csv_dataset(fullfile(data_path,'2020.02.28_phasespace_stimulation_input_strength_results.csv'));
% table_params_all = table_params_all(table_params_all.Weight_external_input == original_input_weight*8,:);
% 
% fig = plot_dynamicrange_3_nets(table_params_all);
% saveas(fig,'figures/fig_1S3B.eps','epsc');
struct

function fig = plot_dynamicrange_2_nets(table_params_all)
    noncrit_run_number	= 0;

    crit_run_number = 1;

    index_noncrit_all_stims	= find(table_params_all.Run_Number==noncrit_run_number);
    index_crit_all_stims      = find(table_params_all.Run_Number==crit_run_number);
    %%DYNRANGE
    color_blue = [0 0.5 1];
    color_green = [0.22 1 0.22];
%     color_red = [1 0.22 0.22];

    indexes_2nets = [index_noncrit_all_stims index_crit_all_stims];

    fsigm = @(param,xval) param(1)+(param(2)-param(1))./(1+10.^((param(3)-xval)*param(4)));
    fsigm_inv = @(param,xval) param(3)-reallog((param(2)-param(1))./(xval-param(1)) - 1) * 1/param(4);

    fig=figure('color','w');
    set(fig,'Position',[0 0 480 280]);
    warning off;
    cols=zeros(2,3);
    cols(1,:)=color_blue;
    cols(2,:)=color_green;
%     cols(3,:)=color_red;
    limits_dynamic_range = zeros(2,2);
    dynamicrange_values = zeros(1,2);
    for i = 1:2
        idx_for_unique_run = indexes_2nets(:,i);

        % calculate dynamic range for new networks

        [B,I] = sort(table_params_all.Stimulus_size(idx_for_unique_run));
        sorted_by_stim_idx_for_unique_run = idx_for_unique_run(I);

        stims = table_params_all.Stimulus_size(sorted_by_stim_idx_for_unique_run);
        data = table_params_all.PLF(sorted_by_stim_idx_for_unique_run);

        crt_data=data(data>0 & stims>0);
        crt_stims=stims(data>0 & stims>0);

        try
            params = sigm_fit(reallog(crt_stims),crt_data);

            x = reallog(crt_stims);
            fitDats = fsigm(params,x);

            plot(x,crt_data,'.','Color',cols(i,:),'LineWidth',1.2);
            hold on;
            plot(x,fitDats,'Color',cols(i,:),'LineWidth',1.2);

            max_fit_and_data = max(max(crt_data),max(fitDats));
            norm_fits = fitDats/max_fit_and_data;
            norm_crt_data = crt_data/max_fit_and_data;
            mse = mean((norm_fits-norm_crt_data).^2);

            mnFit = min(fitDats);
            mxFit = max(fitDats);
            tenPerc = (mxFit - mnFit)*0.1;
            ninetyPerc = mxFit - tenPerc;
            tenPerc = tenPerc + mnFit;

            xinv_10perc = fsigm_inv(params,tenPerc);
            xinv_90perc = fsigm_inv(params,ninetyPerc);

            plot(xinv_10perc,tenPerc,'x','Color',cols(i,:),'LineWidth',1.2);
            plot(xinv_90perc,ninetyPerc,'x','Color',cols(i,:),'LineWidth',1.2);

            %this ends up empty if the 
            if isempty(xinv_10perc) | isempty(xinv_90perc)
                rn = NaN;
            else
                if xinv_10perc > xinv_90perc
                    rn = NaN;
                else
                    rn = xinv_90perc-xinv_10perc;
                end
            end

            limits_dynamic_range(i,1)=xinv_10perc;
            limits_dynamic_range(i,2)=xinv_90perc;
            dynamicrange_values(i)=rn;

            if isnan(rn)
                countWithNan=countWithNan+1;
            end

            disp(rn);

        catch E
            disp(getReport(E));
            rn = NaN;
            mse = NaN;
        end

    end

    axis square;
    box off;

    xlabel('Neurons Stimulated');
    ylabel('PLF');
    xlim([0 reallog(180)]);
    yticks([0 0.5 1]);
    set(gca,'fontsize', 16);
    line(limits_dynamic_range(1,:),[1.3 1.3],'Color',color_blue,'LineWidth',1.2);
    line(limits_dynamic_range(2,:),[1.2 1.2],'Color',color_green,'LineWidth',2);
%     line(limits_dynamic_range(3,:),[1.2 1.2],'Color',color_red,'LineWidth',1.2);
    ylim([0 1.35]);
    text(limits_dynamic_range(1,2)+0.1,1.3,num2str(round(dynamicrange_values(1),2)));
%     text(limits_dynamic_range(2,2)+0.1,1.2,num2str(round(dynamicrange_values(2),2)));
    text(limits_dynamic_range(2,2)+0.1,1.2,num2str(round(dynamicrange_values(2),2)));
%     xticks(reallog([1 3 9 25 74 216 632 1800]));
    xticks(reallog([1 10 40 180]));
    xticklabels({'1','10','40','180'});
    xtickangle(45);
    
end