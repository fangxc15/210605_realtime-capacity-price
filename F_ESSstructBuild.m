% 读入储能的报价因子
function [storage,Num] = F_ESSstructBuild(Rawdata_ESS,Num,Name_ESS)
% 本函数用来读入储能信息，但是还没有加入分段里程报价和尾部SOC Valuation Function
for i = 1:Num.ESS
    storage(i).Pdismax = Rawdata_ESS(i,3);
    storage(i).Pdismin = Rawdata_ESS(i,4);
    storage(i).Pchamax = Rawdata_ESS(i,5);
    storage(i).Pchamin = Rawdata_ESS(i,6);
    storage(i).Emax = Rawdata_ESS(i,7);
    storage(i).Emin = Rawdata_ESS(i,8);
    storage(i).E0 = Rawdata_ESS(i,9);

    storage(i).eff_dis = Rawdata_ESS(i,12);
    storage(i).eff_cha = Rawdata_ESS(i,13);
    storage(i).Bus = Rawdata_ESS(i,14);
    if isempty(find(strcmp(Name_ESS,'chacostblock')))
         storage(i).chacost = Rawdata_ESS(i,11);
    else
        tempi = find(strcmp(Name_ESS,'chacostblock'));
        Num.ESScostblock = Rawdata_ESS(i,tempi);    
        storage(i).chacost = Rawdata_ESS(i,tempi+1:tempi+Num.ESScostblock);
        storage(i).Pchamaxb = ones(1,Num.ESScostblock) * storage(i).Pchamax/Num.ESScostblock;
        storage(i).Pchaminb = zeros(1,Num.ESScostblock);
    end
    
    if isempty(find(strcmp(Name_ESS,'discostblock')))
         storage(i).discost = Rawdata_ESS(i,10);
    else
        tempi = find(strcmp(Name_ESS,'discostblock'));
        Num.ESScostblock = Rawdata_ESS(i,tempi);    
        storage(i).discost = Rawdata_ESS(i,tempi+1:tempi+Num.ESScostblock);
        storage(i).Pdismaxb = ones(1,Num.ESScostblock) * storage(i).Pchamax/Num.ESScostblock;
        storage(i).Pdisminb = zeros(1,Num.ESScostblock);
    end
        
    
    if ~isempty(find(strcmp(Name_ESS,'valblock')))
        tempi = find(strcmp(Name_ESS,'valblock'));
        Num.ESSvalblock = Rawdata_ESS(i,tempi); % 这里指的是向上向下总共的段数
        storage(i).val = Rawdata_ESS(i,tempi+1:tempi+Num.ESSvalblock);
        num_neg = ceil(Num.ESSvalblock/2);
        num_pos = floor(Num.ESSvalblock/2);
        storage(i).valmax = [zeros(1,num_neg) ones(1,num_pos)*(storage(i).Emax - storage(i).E0)/num_pos];
        storage(i).valmin = [ones(1,num_neg)*(storage(i).Emin - storage(i).E0)/num_neg zeros(1,num_pos)];
    end
    
    if ~isempty(find(strcmp(Name_ESS,'chahour')))
        tempi = find(strcmp(Name_ESS,'chahour'));
        storage(i).chahour = Rawdata_ESS(i,tempi);
    else
        storage(i).chahour = [];
    end
    if ~isempty(find(strcmp(Name_ESS,'dishour')))
        tempi = find(strcmp(Name_ESS,'dishour'));
        storage(i).dishour = Rawdata_ESS(i,tempi);
    else
        storage(i).dishour = [];
    end 
    
end 