function Resultcal = F_calwelfare(Result, Para_modify, Para, Num, Iter)
    for d = 1:Num.D
        Resultcal.demand(d).ene_cost = 0;
        Resultcal.demand(d).cap_cost = 0;
        Resultcal.demand(d).utility = 0;
        
        Resultcal.demand(d).ene_costT = zeros(Num.T,1);
        Resultcal.demand(d).cap_costT = zeros(Num.T,1);
        Resultcal.demand(d).utilityT = zeros(Num.T,1);
        Resultcal.demand(d).welfareT = zeros(Num.T,1);

        for t = 1:Num.T
            if Iter.topo == 0
                settleprice = Result(t).MCP;
            else
                settleprice = Result(t).LMP(Para.demand(d).Bus);
            end 
            Resultcal.demand(d).ene_cost = Resultcal.demand(d).ene_cost + sum(Result(t).Pd(d,:)) *  settleprice;
            Resultcal.demand(d).cap_cost = Resultcal.demand(d).cap_cost + sum(Result(t).Pd(d,:)) *  Result(t).capprice;
            Resultcal.demand(d).utility = Resultcal.demand(d).utility + sum(Result(t).Pd(d,:) .*  Para_modify.demand(t).utility(d,:));
            Resultcal.demand(d).welfare = Resultcal.demand(d).utility - Resultcal.demand(d).ene_cost - Resultcal.demand(d).cap_cost;
            
            Resultcal.demand(d).ene_costT(t) = sum(Result(t).Pd(d,:)) *  settleprice;
            Resultcal.demand(d).cap_costT(t) = sum(Result(t).Pd(d,:)) *  Result(t).capprice;
            Resultcal.demand(d).utilityT(t) = sum(Result(t).Pd(d,:) .*  Para_modify.demand(t).utility(d,:));
            Resultcal.demand(d).welfareT(t) = Resultcal.demand(d).utilityT(t) - Resultcal.demand(d).ene_costT(t) - Resultcal.demand(d).cap_costT(t);

        end
    end
    
    for r = 1:Num.R
        Resultcal.renew(r).ene_income = 0;
        Resultcal.renew(r).cap_income = 0;
        Resultcal.renew(r).cost = 0;
        for t = 1:Num.T
            if Iter.topo == 0
                settleprice = Result(t).MCP;
            else
                settleprice = Result(t).LMP(Para.generator(r + length(Para.genset)).bus);
            end 
            Resultcal.renew(r).ene_income = Resultcal.renew(r).ene_income + sum(Result(t).Pr(r,:)) *  settleprice;
            Resultcal.renew(r).cap_income = Resultcal.renew(r).cap_income + sum(Result(t).Pr(r,:)) *  Result(t).capprice;
            Resultcal.renew(r).cost = Resultcal.renew(r).cost + sum(Result(t).Pr(r,:) .*  Para_modify.renew(t).cost(r,:));     
            Resultcal.renew(r).welfare = Resultcal.renew(r).ene_income + Resultcal.renew(r).cap_income -  Resultcal.renew(r).cost ;
        end
    end
    
    for ess = 1:Num.ESS
        Resultcal.ESS(ess).ene_income = 0;
        Resultcal.ESS(ess).cap_income = 0;
        Resultcal.ESS(ess).dis_cost = 0;
        Resultcal.ESS(ess).cha_utility = 0;
        
        Resultcal.ESS(ess).ene_incomeT = zeros(Num.T,1);
        Resultcal.ESS(ess).cap_incomeT = zeros(Num.T,1);
        Resultcal.ESS(ess).dis_costT = zeros(Num.T,1);
        Resultcal.ESS(ess).cha_utilityT = zeros(Num.T,1);
        Resultcal.ESS(ess).welfareT = zeros(Num.T,1);
        for t = 1:Num.T
            if Iter.topo == 0
                settleprice = Result(t).MCP;
            else
                settleprice = Result(t).LMP(Para.storage(ess).Bus);
            end 
            Resultcal.ESS(ess).ene_income = Resultcal.ESS(ess).ene_income + sum(Result(t).Pdis(ess,:) - Result(t).Pcha(ess,:)) *  settleprice;
            Resultcal.ESS(ess).cap_income = Resultcal.ESS(ess).cap_income + sum(Result(t).Pdis(ess,:) - Result(t).Pcha(ess,:)) *  Result(t).capprice;
            Resultcal.ESS(ess).dis_cost = Resultcal.ESS(ess).dis_cost + sum(Result(t).Pdis(ess,:) .*  Para_modify.ESS(t).dis_cost(ess,:));
            Resultcal.ESS(ess).cha_utility = Resultcal.ESS(ess).cha_utility + sum(Result(t).Pcha(ess,:) .*  Para_modify.ESS(t).cha_utility(ess,:));   
            Resultcal.ESS(ess).welfare = Resultcal.ESS(ess).ene_income +  Resultcal.ESS(ess).cap_income  - Resultcal.ESS(ess).dis_cost + Resultcal.ESS(ess).cha_utility;
            
            Resultcal.ESS(ess).ene_incomeT(t) = sum(Result(t).Pdis(ess,:) - Result(t).Pcha(ess,:)) *  settleprice;
            Resultcal.ESS(ess).cap_incomeT(t) = sum(Result(t).Pdis(ess,:) - Result(t).Pcha(ess,:)) *  Result(t).capprice;
            Resultcal.ESS(ess).dis_costT(t) = sum(Result(t).Pdis(ess,:) .*  Para_modify.ESS(t).dis_cost(ess,:));
            Resultcal.ESS(ess).cha_utilityT(t) =  sum(Result(t).Pcha(ess,:) .*  Para_modify.ESS(t).cha_utility(ess,:));   
            Resultcal.ESS(ess).welfareT(t) = Resultcal.ESS(ess).ene_incomeT(t) +  Resultcal.ESS(ess).cap_incomeT(t)  - Resultcal.ESS(ess).dis_costT(t) + Resultcal.ESS(ess).cha_utilityT(t);

            
        end
    end
    
    for g = 1:Num.G
        Resultcal.gen(g).ene_income = 0;
        Resultcal.gen(g).cost = 0;

        for t = 1:Num.T
            if Iter.topo == 0
                settleprice = Result(t).MCP;
            else
                settleprice = Result(t).LMP(Para.generator(g).bus);
            end 
            Resultcal.gen(g).ene_income = Resultcal.gen(g).ene_income + sum(Result(t).Pg(g,:)) *  settleprice;
            Resultcal.gen(g).cost = Resultcal.gen(g).cost + sum(Result(t).Pg(g,:) .*   Para_modify.gen(t).cost(g,:));   
            Resultcal.gen(g).welfare = Resultcal.gen(g).ene_income - Resultcal.gen(g).cost;
        end
    end
    
    Resultcal.welfare = sum([Resultcal.demand.utility])-sum([Resultcal.renew.cost])-sum([Resultcal.ESS.dis_cost])+sum([Resultcal.ESS.cha_utility]) - sum([Resultcal.gen.cost]);
end