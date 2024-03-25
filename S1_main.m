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
%% The case with consideration of capacity costs
% Iter.integer = 1;
Iter.capprice = 1; % If consider capacity costs
Iter.topo = 1; % If consider typo
Result_cap = F_marketclearing_V2(Iter,Para_modify,Num);
Resultcal_cap = F_calwelfare(Result_cap, Para_modify,Para, Num, Iter);

% To check the Lagrance multipliers
for t = 1:Num.T
    % Bus1, Demand1
    lag_G(t) = Para_modify.demand(t).utility(1,1)  - Result_cap(t).capprice - Result_cap(t).LMP(1) + Result_cap(t).Pdmiumin(1) - Result_cap(t).Pdmiumax(1);
    % Bus1, Renewable1
    lag_R(t) = - Para_modify.renew(t).cost(1,1)  + Result_cap(t).capprice + Result_cap(t).LMP(1) + Result_cap(t).Prmiumin(1) - Result_cap(t).Prmiumax(1);
    % Bus3, ESS1
    lag_ESS_dis(t) = - Para_modify.ESS(t).dis_cost(1)  + Result_cap(t).capprice + Result_cap(t).LMP(3) + Result_cap(t).Pdismiumin(1) - Result_cap(t).Pdismiumax(1);
end 
%% The case without consideration of capacity costs
Iter.capprice = 0;

for t = 1:Num.T
    Para_modify.ESS(t).Pchamax = zeros(Num.ESS, Num.ESScostblock);
end

Result_nocap = F_marketclearing_V2(Iter,Para_modify,Num);
Resultcal_nocap = F_calwelfare(Result_nocap, Para_modify,Para, Num, Iter); % 在没有实时容量价格的时候也要按照容量价格付费

%%
%
% 为啥要引入出清,主要是个体理性, 更能反映价格信号
% 出清结果的区别
%   出清的储能变化 (储能高峰期更能放电了)
%   出清的需求侧响应变化（需求侧相应更多，需求变少）
%   储能/需求侧响应的个体理性(总的福利的变化)
%% Check Results
%   ESS1, the welfare and power
% fprintf("The welfare of ESS 1\n clearing with no cap %f \n clearing with cap %f \n",Resultcal_nocap.ESS(1).welfare,Resultcal_cap.ESS(1).welfare)
ESSwelfareT = [Resultcal_nocap.ESS(ESS_index).welfareT ...
                Resultcal_cap.ESS(ESS_index).welfareT]; %没有容量价格的情况下根本就不出清
for t = 1:Num.T
    ESSpowerT(t,1) =  sum(Result_nocap(t).Pdis(ESS_index,:)) - sum(Result_nocap(t).Pcha(ESS_index,:));
    ESSpowerT(t,2) =  sum(Result_cap(t).Pdis(ESS_index,:)) - sum(Result_cap(t).Pcha(ESS_index,:)); 
end
sum(ESSwelfareT)
% LSD_ESSwelfareT = [Resultcal_nocap.ESS(ESS_index).welfareT Resultcal_cap.ESS(ESS_index).welfareT];
for t = 1:Num.T
    LSD_ESSpowerT(t,1) =  sum(Result_nocap(t).Pdis(LSD_ESS_index,:)) - sum(Result_nocap(t).Pcha(LSD_ESS_index,:));
    LSD_ESSpowerT(t,2) =  sum(Result_cap(t).Pdis(LSD_ESS_index,:)) - sum(Result_cap(t).Pcha(LSD_ESS_index,:)); 
end

%   Demand6, the welfare and power
% fprintf("The welfare of demand 6\n clearing with no cap %f \n clearing with cap %f \n",Resultcal_nocap.demand(6).welfare,Resultcal_cap.demand(6).welfare)
PRDwelfareT = [Resultcal_nocap.demand(PRD_index).welfareT Resultcal_cap.demand(PRD_index).welfareT];
PRDpowerT = zeros(Num.T,2);
for t = 1:Num.T
    PRDpowerT(t,1) = sum(Result_nocap(t).Pd(PRD_index,:));
    PRDpowerT(t,2) = sum(Result_cap(t).Pd(PRD_index,:));
end
sum(PRDwelfareT)
sum(PRDpowerT)
sum(PRDwelfareT(18:21,:))
sum(PRDpowerT(18:21,:))


% 这个地方待修改！这个地方为什么把这两个算在一起？因为LSD本来就是用一个正常负荷和一个储能建模的。
LSDwelfareT = [Resultcal_nocap.demand(LSD_index).welfareT + Resultcal_nocap.ESS(LSD_ESS_index).welfareT ...
               Resultcal_cap.demand(LSD_index).welfareT   + Resultcal_cap.ESS(LSD_ESS_index).welfareT] ;
LSDpowerT = zeros(Num.T,2);
for t = 1:Num.T
    LSDpowerT(t,1) = sum(Result_nocap(t).Pd(LSD_index,:)) - sum(Result_nocap(t).Pdis(LSD_ESS_index,:)) + sum(Result_nocap(t).Pcha(LSD_ESS_index,:));
    LSDpowerT(t,2) = sum(Result_cap(t).Pd(LSD_index,:)) - sum(Result_cap(t).Pdis(LSD_ESS_index,:)) + sum(Result_cap(t).Pcha(LSD_ESS_index,:));
end

sum(LSDwelfareT)
sum(LSDpowerT)
%%
% LMP(Node 3) and capacity price
for t = 1:Num.T
    LMPT(t).LMP1 = Result_nocap(t).LMP(LMP_node);
    LMPT(t).cap1 = Result_nocap(t).capprice;

    LMPT(t).LMP2 = Result_cap(t).LMP(LMP_node);
    LMPT(t).cap2 = Result_cap(t).capprice;
end 
% The totaldemand
% demandpowerT = [[Result_nocap.Pdsum]' [Result_cap.Pdsum]']
% The welfare delta
% Resultcal_cap.welfare - Resultcal_nocap.welfare 这里其实是假的welfare，不管它

% The total bidding load, renewable, cleared load(when considering capacity prices)
Para_modify.sumdemand;
Para_modify.sumrenewable;
Para_modify.sumwind;
Para_modify.sumsolar;


% The final demand
demandsumpowerT = zeros(Num.T,2);

for t = 1:Num.T
    demandsumpowerT(t,1) = sum(sum(Result_nocap(t).Pd(:,:))) - sum(Result_nocap(t).Pdis(LSD_ESS_index,:)) + sum(Result_nocap(t).Pcha(LSD_ESS_index,:));
    demandsumpowerT(t,2) = sum(sum(Result_cap(t).Pd(:,:))) - sum(Result_cap(t).Pdis(LSD_ESS_index,:)) + sum(Result_cap(t).Pcha(LSD_ESS_index,:));
end

% net_load的计算方式，负荷 - 新能源 - 储能
netloadpowerT = [[Result_nocap.Pnet]' [Result_cap.Pnet]'];
sum(netloadpowerT(18:21,:))

% 总共的需求/总共的风电/总共的光伏/实际的出清的总需求/实际的净负荷/容量价格
fact_data_output = [Para_modify.sumdemand,Para_modify.sumwind,Para_modify.sumsolar,...
    demandsumpowerT(:,2),netloadpowerT(:,2),[LMPT.cap2]'];

% The data needed for plot
compare_data_output = [PRDpowerT,ESSpowerT,LSDpowerT,[LMPT.LMP1]',[LMPT.LMP2]',[LMPT.cap1]',[LMPT.cap2]'];


%% 输出节点容量价格和节点净负荷
for t = 1:Num.T
    capprice(t,:) = Result_cap(t).node_capprice;
end

for t = 1:Num.T
    node_Pnet(t,:) = Result_cap(t).node_Pnet;
end

node_Pnet_norm = node_Pnet./mean(node_Pnet,1);
%节点2/3的容量价格，标准化净负荷，净负荷
node_output = [capprice(:,2:3), node_Pnet_norm(:,2:3), node_Pnet(:,2:3)];
%%

save_Path = ['Results\Results_',Filename];
mkdir(save_Path);
save_dir = ['.\', save_Path ,'\'];
save_Time = datestr(datetime('now'),30);   
save_Para = [Gsheet,'_',ESSsheet,'_',File_price_basis,'_Time_'];       
save_Name = [save_dir,save_Para,save_Time,'.mat']; %


xlswrite([save_dir,save_Para,save_Time,'.xlsx'],[{'总需求量','风电出力曲线','光伏出力曲线','中标需求量','实际净负荷量','容量价格'}],'fact_data_output','A1')
xlswrite([save_dir,save_Para,save_Time,'.xlsx'],fact_data_output,'fact_data_output','A2');



xlswrite([save_dir,save_Para,save_Time,'.xlsx'],[{'PRD中标电量_nocap','PRD中标电量_cap',...
    'ESS中标电量_nocap','ESS中标电量_cap','LSD中标电量_nocap','LSD中标电量_cap','LMP_nocap','LMP_cap','容量价格_nocap','容量价格_cap'}],'compare_data_output','A1')
xlswrite([save_dir,save_Para,save_Time,'.xlsx'],compare_data_output,'compare_data_output','A2');

xlswrite([save_dir,save_Para,save_Time,'.xlsx'],[{'节点2容量价格','节点3容量价格','节点2负荷曲线','节点3负荷曲线','节点2绝对负荷','节点3绝对负荷'}],'node_output','A1')
xlswrite([save_dir,save_Para,save_Time,'.xlsx'],node_output,'node_output','A2');


save(save_Name);

   