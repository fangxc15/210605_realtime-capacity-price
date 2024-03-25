clear
%% Data Loading
mpc = case5;
Filename = 'test_data_V2';

% ������Ȼ��cost, ������ֱ��ָ������curve, ����1�ķŵ���20/21����20�������10/11/12�ֱ���15/15/20
% ����2�ķŵ���20/21�ֱ���20, �����13/14�ֱ���20
% ���������������ʵֻ��2/3/4�ֱ���300/300/400�����󣩣�
% 6��������PRD(��3�Žڵ�ֳ���һ��)��7��������LSD(��4�Žڵ�ֳ���5%)������LSDΪʲôû��������
% Demand��Ч�ö���100. PRD���Ķ����Ϊ100/70/40/40, LSD��������Ʋ�����

% ��Ϊ����LSD������һ�������ĸ��ɵ���һ�������γɵġ�

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
Resultcal_nocap = F_calwelfare(Result_nocap, Para_modify,Para, Num, Iter); % ��û��ʵʱ�����۸��ʱ��ҲҪ���������۸񸶷�

%%
%
% ΪɶҪ�������,��Ҫ�Ǹ�������, ���ܷ�ӳ�۸��ź�
% ������������
%   ����Ĵ��ܱ仯 (���ܸ߷��ڸ��ܷŵ���)
%   ������������Ӧ�仯���������Ӧ���࣬������٣�
%   ����/�������Ӧ�ĸ�������(�ܵĸ����ı仯)
%% Check Results
%   ESS1, the welfare and power
% fprintf("The welfare of ESS 1\n clearing with no cap %f \n clearing with cap %f \n",Resultcal_nocap.ESS(1).welfare,Resultcal_cap.ESS(1).welfare)
ESSwelfareT = [Resultcal_nocap.ESS(ESS_index).welfareT ...
                Resultcal_cap.ESS(ESS_index).welfareT]; %û�������۸������¸����Ͳ�����
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


% ����ط����޸ģ�����ط�Ϊʲô������������һ����ΪLSD����������һ���������ɺ�һ�����ܽ�ģ�ġ�
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
% Resultcal_cap.welfare - Resultcal_nocap.welfare ������ʵ�Ǽٵ�welfare��������

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

% net_load�ļ��㷽ʽ������ - ����Դ - ����
netloadpowerT = [[Result_nocap.Pnet]' [Result_cap.Pnet]'];
sum(netloadpowerT(18:21,:))

% �ܹ�������/�ܹ��ķ��/�ܹ��Ĺ��/ʵ�ʵĳ����������/ʵ�ʵľ�����/�����۸�
fact_data_output = [Para_modify.sumdemand,Para_modify.sumwind,Para_modify.sumsolar,...
    demandsumpowerT(:,2),netloadpowerT(:,2),[LMPT.cap2]'];

% The data needed for plot
compare_data_output = [PRDpowerT,ESSpowerT,LSDpowerT,[LMPT.LMP1]',[LMPT.LMP2]',[LMPT.cap1]',[LMPT.cap2]'];


%% ����ڵ������۸�ͽڵ㾻����
for t = 1:Num.T
    capprice(t,:) = Result_cap(t).node_capprice;
end

for t = 1:Num.T
    node_Pnet(t,:) = Result_cap(t).node_Pnet;
end

node_Pnet_norm = node_Pnet./mean(node_Pnet,1);
%�ڵ�2/3�������۸񣬱�׼�������ɣ�������
node_output = [capprice(:,2:3), node_Pnet_norm(:,2:3), node_Pnet(:,2:3)];
%%

save_Path = ['Results\Results_',Filename];
mkdir(save_Path);
save_dir = ['.\', save_Path ,'\'];
save_Time = datestr(datetime('now'),30);   
save_Para = [Gsheet,'_',ESSsheet,'_',File_price_basis,'_Time_'];       
save_Name = [save_dir,save_Para,save_Time,'.mat']; %


xlswrite([save_dir,save_Para,save_Time,'.xlsx'],[{'��������','����������','�����������','�б�������','ʵ�ʾ�������','�����۸�'}],'fact_data_output','A1')
xlswrite([save_dir,save_Para,save_Time,'.xlsx'],fact_data_output,'fact_data_output','A2');



xlswrite([save_dir,save_Para,save_Time,'.xlsx'],[{'PRD�б����_nocap','PRD�б����_cap',...
    'ESS�б����_nocap','ESS�б����_cap','LSD�б����_nocap','LSD�б����_cap','LMP_nocap','LMP_cap','�����۸�_nocap','�����۸�_cap'}],'compare_data_output','A1')
xlswrite([save_dir,save_Para,save_Time,'.xlsx'],compare_data_output,'compare_data_output','A2');

xlswrite([save_dir,save_Para,save_Time,'.xlsx'],[{'�ڵ�2�����۸�','�ڵ�3�����۸�','�ڵ�2��������','�ڵ�3��������','�ڵ�2���Ը���','�ڵ�3���Ը���'}],'node_output','A1')
xlswrite([save_dir,save_Para,save_Time,'.xlsx'],node_output,'node_output','A2');


save(save_Name);

   