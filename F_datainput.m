function [Para_modify,Num, Para] = F_datainput(mpc,Filename,Gsheet,ESSsheet,File_price_basis)

    Para.bigM = 100000;
    Num.D = size(mpc.bus,1);
    Num.N = size(mpc.bus,1);
    Num.B = 4;
    
    S_uncertainty_process; %生成的随机性场景
    
    %从excel中读入的文件名和sheet名
%     Filename = 'IEEE118_V5';
%     Gsheet = 'G3.0';
%     ESSsheet = 'ESS3.0'; % 

    %% sheet读入，读入储能信息
    [Rawdata_ESS,Name_ESS] = xlsread(Filename,ESSsheet);
    % Num.ESS = max(Rawdata_ESS(:,1));
    Num.ESS = size(Rawdata_ESS,1);
    [Para.storage,Num] = F_ESSstructBuild(Rawdata_ESS,Num,Name_ESS);
    
    %% 关键是只要在这里修改就可以了。新增一个储能试一试!
    
    
%     Para.storage(1).dishour = [20,21];
%     Para.storage(1).chahour = [11,12,13];
    Para.storage(1).discurve = zeros(1,24);  % 这里设计一个charge curve和discharge curve
    Para.storage(1).discurve(20) = 25;
    Para.storage(1).discurve(21) = 25;
    Para.storage(1).chacurve = zeros(1,24);
    Para.storage(1).chacurve(12) = 25;
    Para.storage(1).chacurve(11) = 18.75;
    Para.storage(1).chacurve(13) = 18.75;


    %% 读入demand信息
    for d = 1 : Num.D
        for t = 1:Num.T
    %         for w = 1:Num.S
                Para.demand(d).Pmax(t,:) = Para.scenario(w).normD(t) * mpc.bus(d,3)/Num.B * ones(Num.B,1);
                Para.demand(d).Pmin(t,:) = zeros(Num.B,1);
                Para.demand(d).Utility(t,:) = 1000  * ones(Num.B,1);
    %         end 
        %    consumer(d).Time(t).SNum = tempData_Demand(d,1);  %这个好像有点问题；
        end 
        Para.demand(d).Bus = d;      
    end
    
    
    Num.D = Num.D + 1;
    Para.demand(3).Pmax = Para.demand(3).Pmax * 0.5; %把最大的一个demand想办法调小
    Para.demand(Num.D).Bus = 3;
    Para.demand(Num.D).Pmax = Para.demand(3).Pmax;
    Para.demand(Num.D).Pmin = Para.demand(3).Pmin;

    for t = 1:Num.T
        Para.demand(Num.D).Utility(t,:) = 100 * [1;0.7;0.4;0.1];
    end
    
    
    % for w = 1:Num.S
    %     for t = 1:Num.T
    %         for d = 1:Num.D
    %             Para.scenario(w).Tdemandquant(d,t) = Para.demand(d).Pmax(t,w);
    %             Para.scenario(w).Tdemandutility(d,t) =  Para.demand(d).Utility(t,w);
    %         end 
    %     end 
    % end
    
    %% 读入Generator信息
    Rawdata_Supply = xlsread(Filename,Gsheet);
    Num.I = max(Rawdata_Supply(:,1));
    Para.generator = F_GstructBuild(Num, Rawdata_Supply);
    
    if Num.I > 0
        Num.genB = size(Para.generator(1).cost,2);
    else
        Num.genB = Num.B;
    end 
    %% 生成不同场景下的generation max
    for i = 1:Num.I
        if Para.generator(i).type == 4
            for w = 1:Num.S
                Para.generator(i).Pmax(:,w) = Para.generator(i).Gmax  * Para.scenario(w).normS;
                Para.generator(i).Pmin(:,w) =  Para.generator(i).Gmin  * ones(Num.T,1);
            end

        elseif Para.generator(i).type == 3
            for w = 1:Num.S
                Para.generator(i).Pmax(:,w) =  Para.generator(i).Gmax  * Para.scenario(w).normW;
                Para.generator(i).Pmin(:,w) =  Para.generator(i).Gmin  * ones(Num.T,1);
            end 
        else
            Para.generator(i).Pmax =  Para.generator(i).Gmax * ones(Num.T,Num.S);
            Para.generator(i).Pmin =  Para.generator(i).Gmin * ones(Num.T,Num.S);
        end 
    end 

   %% 生成Para_modify数据, 为什么要modify数据? 要方便进行market clearing
    Num.R = sum(([Para.generator.type] == 3) | ([Para.generator.type] == 4));
    Num.G = Num.I - Num.R;
    renewset = find([Para.generator.type] == 3 | [Para.generator.type] == 4);
    windset = find([Para.generator.type] == 3);
    solarset = find([Para.generator.type] == 4);
    genset = find([Para.generator.type] ~= 3 & [Para.generator.type] ~= 4);

    Para_modify.sumrenewable = sum([Para.generator(renewset).Pmax],2);
    Para_modify.sumwind = sum([Para.generator(windset).Pmax],2);
    Para_modify.sumsolar = sum([Para.generator(solarset).Pmax],2);
    Para_modify.sumdemand = sum(mpc.bus(:,3)) * [Para.scenario.normD];
    Para_modify.sumgen =  sum([Para.generator(genset).Pmax],2);
    Para_modify.sumstorage = sum([Para.storage.Pdismax],2);
    Para_modify.sumnetdemand = Para_modify.sumdemand - Para_modify.sumrenewable;
 
    for t = 1:Num.T
        for d = 1:Num.D
            Para_modify.demand(t).utility(d,:) = Para.demand(d).Utility(t,:);
            Para_modify.demand(t).Pmax(d,:) = Para.demand(d).Pmax(t,:);
            Para_modify.demand(t).Pmin(d,:) = Para.demand(d).Pmin(t,:);
        end
       
        for s = 1:Num.ESS

            Para_modify.ESS(t).cha_utility(s,:) = Para.storage(s).chacost;
            Para_modify.ESS(t).dis_cost(s,:) = Para.storage(s).discost;   
            
            Para_modify.ESS(t).Pchamax(s,:) = Para.storage(s).Pchamaxb *  Para.storage(1).chacurve(t) / Para.storage(1).Pchamax;
%             if isempty(Para.storage(s).chahour) || ~isempty(find(Para.storage(s).chahour == t))
%                 Para_modify.ESS(t).Pchamax(s,:) = Para.storage(s).Pchamaxb;
%             else
%                 Para_modify.ESS(t).Pchamax(s,:) = Para.storage(s).Pchaminb;
%             end
            Para_modify.ESS(t).Pdismax(s,:) = Para.storage(s).Pdismaxb *  Para.storage(1).discurve(t) / Para.storage(1).Pdismax;
%             if isempty(Para.storage(s).dishour) || ~isempty(find(Para.storage(s).dishour == t))
%                 Para_modify.ESS(t).Pdismax(s,:) = Para.storage(s).Pdismaxb;
%             else 
%                 Para_modify.ESS(t).Pdismax(s,:) = Para.storage(s).Pdisminb;
%             end 
            Para_modify.ESS(t).Pchamin(s,:) = Para.storage(s).Pchaminb;  
            Para_modify.ESS(t).Pdismin(s,:) = Para.storage(s).Pdisminb;  
        end 
    
        for g = 1:Num.G
            Para_modify.gen(t).cost(g,:) = Para.generator(genset(g)).cost;
            Para_modify.gen(t).Pmax(g,:) = Para.generator(genset(g)).Pmax(t) /Num.genB * ones(Num.genB,1);
            Para_modify.gen(t).Pmin(g,:) = Para.generator(genset(g)).Pmin(t) /Num.genB * ones(Num.genB,1);

        end 

        for r = 1:Num.R
            Para_modify.renew(t).cost(r,:) = Para.generator(renewset(r)).cost;
            Para_modify.renew(t).Pmax(r,:) = Para.generator(renewset(r)).Pmax(t) /Num.genB * ones(Num.genB,1);
            Para_modify.renew(t).Pmin(r,:) = Para.generator(renewset(r)).Pmin(t) /Num.genB * ones(Num.genB,1);
        end 

    end 

    %% 读入price_basis, 定价基准，这个price basis的线, 是stepwise还是分段线性
%     File_price_basis = 'price_basis';
    [Rawdata_basis,Name_basis] = xlsread(File_price_basis);
    
    % 调整Rawdata_basis
    Rawdata_basis(:,3) = Rawdata_basis(:,3) * max(Para_modify.sumnetdemand)/Rawdata_basis(1,3) * 1.1;

    % 处理曲线数据
    newset = [1];
    startl = 1;
    for l = 2:size(Rawdata_basis,1)
        if (Rawdata_basis(startl,2) - Rawdata_basis(l,2) > 1) || (Rawdata_basis(startl,3) - Rawdata_basis(l,3) > 5)
            newset = [newset,l];
            startl = l;
        end
    end

    Rawdata_basis = Rawdata_basis(newset,:);
    
    % 生成可用的参数
    Num.L = size(Rawdata_basis,1) + 1;
    
    newdata = zeros(Num.L,2);
    newdata(1,1) = 0;
    newdata(1,2) = Rawdata_basis(1,2);
    for l = 1:Num.L - 2
        newdata(l+1,1) = 0;
        newdata(l+1,2) = (Rawdata_basis(l,2) + Rawdata_basis(l+1,2))/2;
    end 
    newdata(Num.L,1) = 0;
    newdata(Num.L,2) = Rawdata_basis(Num.L-1,2);
%     newdata = zeros(Num.L,2);
%     newdata(1,1) = 0;
%     newdata(1,2) = Rawdata_basis(1,2);
%     for l = 1:Num.L - 2
%         % 斜率
%         newdata(l+1,1) = (Rawdata_basis(l,2) - Rawdata_basis(l+1,2))/(Rawdata_basis(l,3) - Rawdata_basis(l+1,3)); % 价格(y)之差 除以 负荷水平(x)之差
%         % 截距
%         newdata(l+1,2) =  Rawdata_basis(l,2) - Rawdata_basis(l,3) * newdata(l+1,1);
%     end 
% 
%     newdata(Num.L,1) = Rawdata_basis(Num.L-1,2)/Rawdata_basis(Num.L-1,3); %斜率
%     newdata(Num.L,2) = 0; %截距

    Para_modify.costcurve.x = newdata(:,1);
    Para_modify.costcurve.y = newdata(:,2);
    Para_modify.costcurve.Pmax = [Para.bigM;Rawdata_basis(:,3)];
    Para_modify.costcurve.Pmin = [Rawdata_basis(:,3);-Para.bigM];
    Para_modify.costcurve.y = fillmissing(Para_modify.costcurve.y,'previous');
    Para_modify.costcurve.x = fillmissing(Para_modify.costcurve.x,'previous');
    Para_modify.costcurve.Plen = Para_modify.costcurve.Pmax - max(0,Para_modify.costcurve.Pmin);
    %% 读入拓扑, 拓扑可能不一定需要用
    Num.Branch = size(mpc.branch,1);
    for ibranch = 1:Num.Branch
        if mpc.branch(ibranch,6) ~=0
            Para_modify.branch(ibranch).Pmax = mpc.branch(ibranch,6);
        else 
            Para_modify.branch(ibranch).Pmax = Para.bigM;
        end 
       Para_modify.branch(ibranch).LNum = ibranch;
       Para_modify.branch(ibranch).Node1 = mpc.branch(ibranch,1);
       Para_modify.branch(ibranch).Node2 = mpc.branch(ibranch,2);
       Para_modify.branch(ibranch).Bvalue = 1/mpc.branch(ibranch,4);
    end 
    Para_modify.Bmatrix = makeBdc(mpc);
    for nnode = 1:Num.N
        Para_modify.nodeinstrument(nnode).G = intersect(find([Para.generator.bus] == nnode),genset);
        Para_modify.nodeinstrument(nnode).R = intersect(find([Para.generator.bus] == nnode),renewset) - length(genset);
        Para_modify.nodeinstrument(nnode).D = find([Para.demand.Bus] == nnode);
        Para_modify.nodeinstrument(nnode).ESS = find([Para.storage.Bus] == nnode);
    end 
    Para_modify.refnode = find(mpc.bus(:,2) == 3);
    Para_modify.noderelation = F_buildnoderelation(Num,Para_modify);
    
    Para_modify.GSDF_lb = makePTDF(mpc); % 横坐标是支路，纵坐标是节点
    Para_modify.GSDFG_lg = Para_modify.GSDF_lb(:,[Para.generator(genset).bus]);
    Para_modify.GSDFP_lp = Para_modify.GSDF_lb(:,[Para.generator(renewset).bus]);
    Para_modify.GSDFD_ld = Para_modify.GSDF_lb(:,[Para.demand.Bus]);
    Para_modify.GSDFS_ls = Para_modify.GSDF_lb(:,[Para.storage.Bus]);
    
    Para.renewset = renewset;
    Para.genset = genset;
end
