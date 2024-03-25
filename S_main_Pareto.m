clear
%% Data Loading
mpc = case5;
Filename = 'test_data_V2';

% 储能虽然有cost, 但现在直接指定它的curve, 储能1的放电在20/21各自20，充电在10/11/12分别是15/15/20
% 储能2的放电在20/21分别是20, 充电在13/14分别是20
% 本来是五个需求（其实只有2/3/4分别有300/300/400的需求），
% 6号需求是PRD(从3号节点分出来一半)，7号需求是LSD(从4号节点分出来5%)。但是LSD为什么没看出来？
% Demand的效用都是100. PRD的四段设计为100/70/40/40, LSD的需求设计不出来

% 因为本来LSD就是用一个正常的负荷叠加一个储能形成的。

Gsheet = 'G1.0';
ESSsheet = 'ESS1.0';
File_price_basis = 'price_basis';
[Para_modify,Num,Para] = F_datainput_V2(mpc,Filename,Gsheet,ESSsheet,File_price_basis);
LSD_ESS_index = 2;
PRD_index = 6;
LSD_index = 7;
ESS_index = 1;
LMP_node = 3;
%%
scale_array = 0:0.1:2;
Iter.capprice = 1; % If consider capacity costs
Iter.topo = 1; % If consider typo
origin_y = Para_modify.costcurve.y;
for i = 1:length(scale_array)
    scale = scale_array(i);
    Para_modify.costcurve.y = origin_y * scale;
    Result_cap = F_marketclearing_V2(Iter,Para_modify,Num);
    Resultcal_cap = F_calwelfare(Result_cap, Para_modify,Para, Num, Iter);
    Result_Pareto(i).Result = Result_cap;
    Result_Pareto(i).Resultcal = Resultcal_cap;  
    Result_Pareto(i).cap_surplus = sum([Result_cap.capprice] .* [Result_cap.Pnet]);
    Result_Pareto(i).nodecap_surplus = sum([Result_cap.node_capprice] .* [Result_cap.node_Pnet]);
    Result_Pareto(i).D_capC = sum([Resultcal_cap.demand.cap_cost]);
    Result_Pareto(i).R_capI = sum([Resultcal_cap.renew.cap_income]);
    Result_Pareto(i).ESS_capI = sum([Resultcal_cap.ESS.cap_income]);
    Result_Pareto(i).cap_all = Result_Pareto(i).D_capC - Result_Pareto(i).R_capI - Result_Pareto(i).ESS_capI;
    Result_Pareto(i).scale = scale_array(i);
    Result_Pareto(i).SW = Resultcal_cap.welfare;
end
%%
F_plot_Pareto(1, Result_Pareto)
mkdir('Result_Pareto');
save('Result_Pareto\\Pareto')

%%
% scale = 0;
% Para_modify.costcurve.y = origin_y * scale;
% Result_cap = F_marketclearing_V2(Iter,Para_modify,Num);
% Resultcal_cap = F_calwelfare(Result_cap, Para_modify,Para, Num, Iter);
% i = 21;
% Result_Pareto(i).Result = Result_cap;
% Result_Pareto(i).Resultcal = Resultcal_cap;  
% Result_Pareto(i).cap_surplus = sum([Result_cap.capprice] .* [Result_cap.Pnet]);
% Result_Pareto(i).nodecap_surplus = sum([Result_cap.node_capprice] .* [Result_cap.node_Pnet]);
% Result_Pareto(i).D_capC = sum([Resultcal_cap.demand.cap_cost]);
% Result_Pareto(i).R_capI = sum([Resultcal_cap.renew.cap_income]);
% Result_Pareto(i).ESS_capI = sum([Resultcal_cap.ESS.cap_income]);
% Result_Pareto(i).cap_all = Result_Pareto(i).D_capC - Result_Pareto(i).R_capI - Result_Pareto(i).ESS_capI;
% Result_Pareto(i).scale = 0;
% Result_Pareto(i).SW = Resultcal_cap.welfare;
% 
% Result_temp =Result_Pareto(21);
% for i = 20:-1:1
%     Result_Pareto(i+1) = Result_Pareto(i);
% end
% Result_Pareto(1) = Result_temp;

%%
% for i = 1:length(scale_array)
%     Result_Pareto(i).scale = scale_array(i);
%     Result_Pareto(i).SW = Result_Pareto(i).Resultcal.welfare;
% end

