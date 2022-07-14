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

data_location = 'C:\Users\wpp_1\Documents\Neurasmus\VU\Internship\codes\data';

csv_filename = '2020.02.17_phasespace_stimulation_different_ee_results.csv';
simulation_parameter_variables = {'Run_Number','Excitatory_Connectivity','Inhibitory_Connectivity','eeGain'};
compute_dynamic_range_table(data_location,csv_filename,simulation_parameter_variables);

function table_unique_pairs_dynrange = compute_dynamic_range_table(data_location,csv_filename,simulation_parameter_variables)
    
    csv_path = fullfile(data_location,csv_filename);
    [~,name,ext]=fileparts(csv_path);

    table_params_all = load_csv_dataset(csv_path);

    table_unique_pairs_dynrange = unique(table_params_all(:,simulation_parameter_variables));

    table_unique_pairs_dynrange.DynRangePLF = NaN(size(table_unique_pairs_dynrange,1),1);

    fsigm = @(param,xval) param(1)+(param(2)-param(1))./(1+10.^((param(3)-xval)*param(4)));
    fsigm_inv = @(param,xval) param(3)-log10((param(2)-param(1))./(xval-param(1)) - 1) * 1/param(4);

    countTotal = 0;
    countWithNan = 0;

    for sim_idx=1:size(table_unique_pairs_dynrange,1)
        %this finds all sims with given value
        sims_with_value = cell(length(simulation_parameter_variables),1);
        for param_idx = 1:length(simulation_parameter_variables)
            sims_with_value{param_idx}=find(table_params_all.(simulation_parameter_variables{param_idx})==table_unique_pairs_dynrange.(simulation_parameter_variables{param_idx})(sim_idx));
        end
        idx_for_unique_run = sims_with_value{1};
        for param_idx = 1:length(simulation_parameter_variables)
            idx_for_unique_run = intersect(idx_for_unique_run,sims_with_value{param_idx});
        end

        [~,I] = sort(table_params_all.Stimulus_size(idx_for_unique_run));
        sorted_by_stim_idx_for_unique_run = idx_for_unique_run(I);

        stims = table_params_all.Stimulus_size(sorted_by_stim_idx_for_unique_run);

        data = table_params_all.PLF(sorted_by_stim_idx_for_unique_run);
        crt_data=data(data>0 & stims>0);
        crt_stims=stims(data>0 & stims>0);

        try
            params = sigm_fit(log10(crt_stims),crt_data);

            x = log10(crt_stims);
            fitDats = fsigm(params,x);

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

            %difference between the minimum and maximum part of the fit
            %should not be 0. the eps takes care of the floating point
            %representation. also min should not be higher than max :D.
            eps = 0.0001;

            %if percentiles are too close to each other there is not much
            %dynamic range to work with
            min_diff_between_percentiles = 0.1;

            if abs(mnFit-mxFit)<min_diff_between_percentiles || abs(xinv_10perc-xinv_90perc)<eps || mnFit > mxFit || xinv_10perc > xinv_90perc
                rn = 0;
            else
                rn = xinv_90perc-xinv_10perc;
            end

            if isnan(rn)
                countWithNan=countWithNan+1;
            end

            countTotal=countTotal+1;

        catch E
            disp(getReport(E));
            rn = NaN;
        end

        table_unique_pairs_dynrange.DynRangePLF(sim_idx)=rn;

    end

    writetable(table_unique_pairs_dynrange,fullfile(data_location,strcat(name,'_dynamicrange_plf.csv')),'Delimiter',';');
end