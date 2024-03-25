function Result = F_marketclearing(Iter,Para, Num)

    ops = sdpsettings('solver','gurobi','verbose',1,'saveyalmipmodel',1);
    % 定义变量
    for t = 1:Num.T
        VarDAT(t).Pd = sdpvar(Num.D, Num.B,'full');
        VarDAT(t).Pg = sdpvar(Num.G, Num.genB,'full');
        VarDAT(t).Pcha = sdpvar(Num.ESS, Num.B,'full');
        VarDAT(t).Pdis = sdpvar(Num.ESS, Num.B,'full');
        VarDAT(t).Pr = sdpvar(Num.R, Num.genB,'full');
        VarDAT(t).Pnet = sdpvar(1,1);
        VarDAT(t).Pnetl = sdpvar(Num.L, 1);
        if Iter.integer == 1
            VarDAT(t).bnetl = binvar(Num.L, 1);
        end 
        if Iter.topo == 1
            VarDAT(t).delta = sdpvar(Num.N, 1);
            VarDAT(t).Pl = sdpvar(Num.Branch,1);
        end 
    end
    % 进行出清
    for t = 1:Num.T
         obj = 0;
         Cons = [];
         
         % 设置目标函数
         obj = obj + sum(sum(VarDAT(t).Pd .* Para.demand(t).utility)) ...
         + sum(sum(VarDAT(t).Pcha .* Para.ESS(t).cha_utility)) ...
         - sum(sum(VarDAT(t).Pg .* Para.gen(t).cost)) ...
         - sum(sum(VarDAT(t).Pr .* Para.renew(t).cost))  ...
         - sum(sum(VarDAT(t).Pdis .* Para.ESS(t).dis_cost));
%         obj = obj - sum(Para.costcurve.x .* (VarDAT(t).Pnetl .^2) + (Para.costcurve.y .* VarDAT(t).Pnetl));  
        obj = obj - sum(Para.costcurve.y .* VarDAT(t).Pnetl);
        
        % 设置约束
        % 容量约束
        Cons = [Cons, VarDAT(t).Pd <= Para.demand(t).Pmax];
        Dual.Pdmiumax(t) = length(Cons);
        Cons = [Cons, VarDAT(t).Pd >= Para.demand(t).Pmin];
        Dual.Pdmiumin(t) = length(Cons);
        Cons = [Cons, VarDAT(t).Pg <= Para.gen(t).Pmax];
        Cons = [Cons, VarDAT(t).Pg >= Para.gen(t).Pmin];
        Cons = [Cons, VarDAT(t).Pr <= Para.renew(t).Pmax];
        Dual.Prmiumax(t) = length(Cons);
        Cons = [Cons, VarDAT(t).Pr >= Para.renew(t).Pmin];
        Dual.Prmiumin(t) = length(Cons);
        Cons = [Cons, VarDAT(t).Pcha <= Para.ESS(t).Pchamax];
        Cons = [Cons, VarDAT(t).Pcha >= Para.ESS(t).Pchamin];
        Cons = [Cons, VarDAT(t).Pdis <= Para.ESS(t).Pdismax];
        Dual.Pdismiumax(t) = length(Cons);
        Cons = [Cons, VarDAT(t).Pdis >= Para.ESS(t).Pdismin];
        Dual.Pdismiumin(t) = length(Cons);
        
%         Cons = [Cons, sum(sum(VarDAT(t).Pg)) + sum(sum(VarDAT(t).Pr)) + sum(sum(VarDAT(t).Pdis)) - sum(sum(VarDAT(t).Pd)) - sum(sum(VarDAT(t).Pcha)) >= 0]; 
%         Dual.MCP(t) = length(Cons);
%         
%         if Iter.topo == 1
%             Cons = [Cons, VarDAT(t).Pl == Para.GSDFG_lg * sum(VarDAT(t).Pg,2) + Para.GSDFP_lp * sum(VarDAT(t).Pr,2) - Para.GSDFD_ld * sum(VarDAT(t).Pd,2) + ...
%                 Para.GSDFS_ls * sum(VarDAT(t).Pdis - VarDAT(t).Pcha,2)];
%             
%             for b = 1:Num.Branch
%                 Cons = [Cons, VarDAT(t).Pl(b) <= Para.branch(b).Pmax];
%                 Dual.Plmiumax(t,b) = length(Cons);
%                 Cons = [Cons, VarDAT(t).Pl(b) >= -Para.branch(b).Pmax];
%                 Dual.Plmiumin(t,b) = length(Cons);
%             end
%         end
        
        if Iter.topo == 0
            % 系统能量平衡约束
            Cons = [Cons, sum(sum(VarDAT(t).Pg)) + sum(sum(VarDAT(t).Pr)) + sum(sum(VarDAT(t).Pdis)) - sum(sum(VarDAT(t).Pd)) - sum(sum(VarDAT(t).Pcha)) >= 0]; 
            Dual.MCP(t) = length(Cons);
        else
            % 节点能量平衡约束
            for n = 1:Num.N
                Cons = [Cons, sum(sum(VarDAT(t).Pg(Para.nodeinstrument(n).G,:))) + sum(sum(VarDAT(t).Pr(Para.nodeinstrument(n).R,:))) + ...
                    sum(sum(VarDAT(t).Pdis(Para.nodeinstrument(n).ESS,:))) - sum(sum(VarDAT(t).Pcha(Para.nodeinstrument(n).ESS,:))) - ...
                    sum(sum(VarDAT(t).Pd(Para.nodeinstrument(n).D,:))) - Para.Bmatrix(n,:) * VarDAT(t).delta >=0];
                Dual.LMP(t,n) = length(Cons);
            end
            % 约束
            Cons = [Cons, VarDAT(t).delta(Para.refnode) == 0];
            for b = 1:Num.Branch
                node1 = Para.branch(b).Node1;
                node2 = Para.branch(b).Node2;               
                Cons = [Cons, (VarDAT(t).delta(node1) - VarDAT(t).delta(node2)) * Para.branch(b).Bvalue == VarDAT(t).Pl(b)];
                Cons = [Cons, VarDAT(t).Pl(b) <= Para.branch(b).Pmax];
                Cons = [Cons, VarDAT(t).Pl(b) >= -Para.branch(b).Pmax];  
            end
        end
        % 净负荷的分段长度约束
        if Iter.integer == 1
            Cons = [Cons,  VarDAT(t).Pnetl <= Para.costcurve.Pmax .* VarDAT(t).bnetl];
            Cons = [Cons,  VarDAT(t).Pnetl >= Para.costcurve.Pmin .* VarDAT(t).bnetl];
        else
            Cons = [Cons,  VarDAT(t).Pnetl <= Para.costcurve.Pmax .* Iter.bnetT(t).bnetl];
            Cons = [Cons,  VarDAT(t).Pnetl >= Para.costcurve.Pmin .* Iter.bnetT(t).bnetl];
        end 
        % 将净负荷分摊到分段
        Cons = [Cons,  sum(VarDAT(t).Pnetl) ==  VarDAT(t).Pnet];
        Cons = [Cons,  VarDAT(t).Pnet == sum(sum(VarDAT(t).Pd)) - sum(sum(VarDAT(t).Pr)) - sum(sum(VarDAT(t).Pdis)) + sum(sum(VarDAT(t).Pcha))];
        if Iter.integer == 1
            Cons = [Cons,  sum(VarDAT(t).bnetl) ==  1];
        end

        
        
        % 进行求解
        Result(t).solution = optimize(Cons,-obj,ops);
        
        % 结果赋值
        Result(t).Pd  = value(VarDAT(t).Pd);
        Result(t).Pg  = value(VarDAT(t).Pg);
        Result(t).Pcha  = value(VarDAT(t).Pcha);
        Result(t).Pdis  = value(VarDAT(t).Pdis);
        Result(t).Pr  = value(VarDAT(t).Pr);
        Result(t).Pnet = value(VarDAT(t).Pnet);
        Result(t).Pnetl = value(VarDAT(t).Pnetl);
        Result(t).Pdsum = sum(sum(Result(t).Pd));
        Result(t).Pgsum = sum(sum(Result(t).Pg));
        Result(t).Pchasum = sum(sum(Result(t).Pcha));
        Result(t).Pdissum = sum(sum(Result(t).Pdis));
        Result(t).Prsum = sum(sum(Result(t).Pr));
        Result(t).sumrenewable = Para.sumrenewable(t);
        Result(t).sumdemand = Para.sumdemand(t);
        
        if Iter.topo == 1
            Result(t).delta = value(VarDAT(t).delta);
            Result(t).Pl = value(VarDAT(t).Pl);
        end 
        
        if Iter.integer == 1
                Result(t).bnetl = value(VarDAT(t).bnetl);
        else
            if Iter.topo == 0
                Result(t).MCP = dual(Cons(Dual.MCP(t)));
            else
%                 Result(t).MCP = dual(Cons(Dual.MCP(t)));
%                 Result(t).Plmiumax = dual(Cons(Dual.Plmiumax(t,:)));
%                 Result(t).Plmiumin = dual(Cons(Dual.Plmiumin(t,:)));
%                 Result(t).LMP = Result(t).MCP - Para.GSDF_lb' * Result(t).Plmiumax + Para.GSDF_lb' * Result(t).Plmiumin; 
                Result(t).LMP = dual(Cons(Dual.LMP(t,:)));
            end
            Result(t).capprice = sum((Para.costcurve.x .* Result(t).Pnetl) + (Para.costcurve.y .* Iter.bnetT(t).bnetl));
            Result(t).Pdmiumax = dual(Cons(Dual.Pdmiumax(t)));
            Result(t).Pdmiumin = dual(Cons(Dual.Pdmiumin(t)));
            Result(t).Prmiumax = dual(Cons(Dual.Prmiumax(t)));
            Result(t).Prmiumin = dual(Cons(Dual.Prmiumin(t)));
            Result(t).Pdismiumax = dual(Cons(Dual.Pdismiumax(t)));
            Result(t).Pdismiumin = dual(Cons(Dual.Pdismiumin(t)));
            Result(t).activex = sum(Para.costcurve.x .* Iter.bnetT(t).bnetl);
            Result(t).activey = sum(Para.costcurve.y .* Iter.bnetT(t).bnetl);
        end
    end
end

            
    
    
    


